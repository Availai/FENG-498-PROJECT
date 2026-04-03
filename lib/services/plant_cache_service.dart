import 'dart:convert';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// Shared plant knowledge database.
/// Two-tier: Hive (instant, offline) → Firestore (community, cross-device).
/// Only static plant properties are cached (Perenual / Gemini output).
/// Location-specific data (success rate, soil comment, etc.) is always live.
class PlantCacheService {
  static const _hiveBox = 'plant_cache';
  static const _firestoreCol = 'plant_community_cache';

  /// Normalize scientific name to a safe Firestore document key.
  static String _key(String scientificName) =>
      scientificName.toLowerCase().trim().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  // ─── READ ────────────────────────────────────────────────────────────────

  /// Returns cached plant details, or null if not found anywhere.
  /// Priority: local Hive → Firestore community cache.
  static Future<Map<String, dynamic>?> get(String scientificName) async {
    final key = _key(scientificName);

    // 1. Local Hive — always instant
    try {
      final box = Hive.box(_hiveBox);
      final raw = box.get(key);
      if (raw != null) {
        return Map<String, dynamic>.from(jsonDecode(raw as String));
      }
    } catch (_) {}

    // 2. Firestore community cache — shared across all users
    try {
      final doc = await FirebaseFirestore.instance
          .collection(_firestoreCol)
          .doc(key)
          .get()
          .timeout(const Duration(seconds: 6));

      if (doc.exists && doc.data() != null) {
        final data = Map<String, dynamic>.from(doc.data()!);
        data.remove('_cached_at'); // remove server timestamp before returning
        data.remove('_source');
        // Persist locally so next access is instant
        _saveLocal(key, data);
        return data;
      }
    } catch (_) {}

    return null;
  }

  // ─── WRITE ───────────────────────────────────────────────────────────────

  /// Save plant details to both local Hive and Firestore community cache.
  static Future<void> save(
    String scientificName,
    Map<String, dynamic> data,
  ) async {
    if (data.isEmpty) return;
    final key = _key(scientificName);
    _saveLocal(key, data); // fire-and-forget local
    _saveFirestore(key, data); // fire-and-forget Firestore
  }

  static void _saveLocal(String key, Map<String, dynamic> data) {
    try {
      final box = Hive.box(_hiveBox);
      box.put(key, jsonEncode(data));
    } catch (_) {}
  }

  static void _saveFirestore(String key, Map<String, dynamic> data) {
    try {
      // Only store JSON-serializable fields (no Flutter-specific types)
      final clean = Map<String, dynamic>.from(data)
        ..removeWhere((k, v) => v == null);
      FirebaseFirestore.instance
          .collection(_firestoreCol)
          .doc(key)
          .set({
        ...clean,
        '_cached_at': FieldValue.serverTimestamp(),
        '_source': 'auto',
      }, SetOptions(merge: true));
    } catch (_) {}
  }

  // ─── UTIL ─────────────────────────────────────────────────────────────────

  /// Returns how many plants are in the local cache.
  static int get localCount {
    try {
      return Hive.box(_hiveBox).length;
    } catch (_) {
      return 0;
    }
  }
}
