import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../services/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/tap_scale.dart';

/// Tarlam Günlüğü — tüm tarlaların kronolojik aktivite akışı.
/// Gruplama: Bugün / Dün / Bu Hafta / Bu Ay / Daha Eski.
class FarmJournalScreen extends ConsumerStatefulWidget {
  const FarmJournalScreen({super.key, this.fieldId});

  /// Null ise tüm tarlalar listelenir; aksi halde sadece ilgili tarla.
  final String? fieldId;

  @override
  ConsumerState<FarmJournalScreen> createState() => _FarmJournalScreenState();
}

class _FarmJournalScreenState extends ConsumerState<FarmJournalScreen> {
  String? _fieldFilter;
  final Set<String> _typeFilter = <String>{};

  @override
  void initState() {
    super.initState();
    _fieldFilter = widget.fieldId;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(localDataRepositoryProvider);
    final fieldsAsync = ref.watch(fieldMapsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Tarlam Günlüğü', style: AppText.h2(context)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(fieldsAsync),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: repo.watchActivityLog(
                fieldId: _fieldFilter,
                types: _typeFilter,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = snap.data ?? const [];
                if (entries.isEmpty) {
                  return _buildEmpty();
                }
                return _buildGroupedList(entries);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AsyncValue<List<Map<String, dynamic>>> fieldsAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 8),
      color: AppColors.surface,
      child: SizedBox(
        height: 36,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFieldChip(fieldsAsync),
            const SizedBox(width: 8),
            ...ActivityType.quickLogOrder.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTypeChip(t),
                )),
            _buildTypeChip(ActivityType.planting),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldChip(AsyncValue<List<Map<String, dynamic>>> fieldsAsync) {
    final fields = fieldsAsync.value ?? const <Map<String, dynamic>>[];
    final selectedName = _fieldFilter == null
        ? 'Tüm Tarlalar'
        : (fields.firstWhere(
              (f) => f['id'] == _fieldFilter,
              orElse: () => <String, dynamic>{},
            )['name'] as String? ??
            'Tarla');
    return TapScale(
      onTap: () async {
        final picked = await showModalBottomSheet<String?>(
          context: context,
          builder: (_) => _FieldPickerSheet(
            fields: fields,
            selected: _fieldFilter,
          ),
        );
        if (picked == '__none__') {
          setState(() => _fieldFilter = null);
        } else if (picked != null) {
          setState(() => _fieldFilter = picked);
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: _fieldFilter == null
              ? AppColors.mint
              : AppColors.emerald.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.landscape_rounded,
                size: 16, color: AppColors.emeraldDark),
            const SizedBox(width: 4),
            Text(
              selectedName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 4),
            const Icon(Icons.arrow_drop_down, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final active = _typeFilter.contains(type);
    final color = ActivityType.color(type);
    return TapScale(
      onTap: () => setState(() {
        if (active) {
          _typeFilter.remove(type);
        } else {
          _typeFilter.add(type);
        }
      }),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.2) : AppColors.bg,
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: active
                ? color.withValues(alpha: 0.5)
                : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ActivityType.icon(type), size: 14, color: color),
            const SizedBox(width: 4),
            Text(
              ActivityType.label(type),
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                size: 48,
                color: AppColors.emeraldDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz aktivite yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Tarla detayından "Suladım" veya "Gübreledim"\ndiyerek ilk kaydını oluşturabilirsin.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupedList(List<Map<String, dynamic>> entries) {
    final groups = _groupByBucket(entries);
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      itemCount: groups.length,
      itemBuilder: (_, idx) {
        final label = groups.keys.elementAt(idx);
        final items = groups[label]!;
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(4, 14, 0, 6),
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w700,
                  color: AppColors.textTertiary,
                  letterSpacing: 0.8,
                ),
              ),
            ),
            ...items.map(_buildEntryCard),
          ],
        );
      },
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final type = entry['type'] as String? ?? ActivityType.other;
    final color = ActivityType.color(type);
    final date = entry['date'] as DateTime;
    final meta = entry['metadata'] as Map<String, dynamic>?;
    final fieldName = entry['field_name'] as String?;
    return TapScale(
      onTap: () => _showEntryOptions(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 8),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                shape: BoxShape.circle,
              ),
              child: Icon(ActivityType.icon(type), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        ActivityType.label(type),
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const Spacer(),
                      Text(
                        _formatTime(date),
                        style: TextStyle(
                          fontSize: 12,
                          color: AppColors.textTertiary,
                        ),
                      ),
                    ],
                  ),
                  if (fieldName != null) ...[
                    const SizedBox(height: 2),
                    Text(
                      fieldName,
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  if (meta != null) _buildMetaLine(type, meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetaLine(String type, Map<String, dynamic> meta) {
    final parts = <String>[];
    final qty = meta['quantity'];
    final unit = meta['quantity_unit'] ?? ActivityType.quantityUnit(type);
    if (qty is num && unit != null) {
      parts.add('${_formatQty(qty)} $unit');
    }
    final cropName = meta['cropName'];
    if (cropName is String && cropName.isNotEmpty) parts.add(cropName);
    final note = meta['note'];
    if (note is String && note.isNotEmpty) parts.add(note);
    if (parts.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 4),
      child: Text(
        parts.join(' · '),
        style: TextStyle(
          fontSize: 12,
          color: AppColors.textSecondary,
          height: 1.3,
        ),
      ),
    );
  }

  String _formatQty(num v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  Future<void> _showEntryOptions(Map<String, dynamic> entry) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                'Kaydı sil',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Kapat'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (action == 'delete') {
      final repo = ref.read(localDataRepositoryProvider);
      await repo.deleteActivity(entry['id'] as String);
      if (!mounted) return;
      AppToast.show(context,
          message: 'Kayıt silindi', type: ToastType.success);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByBucket(
      List<Map<String, dynamic>> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final groups = <String, List<Map<String, dynamic>>>{
      'BUGÜN': [],
      'DÜN': [],
      'BU HAFTA': [],
      'BU AY': [],
      'DAHA ESKİ': [],
    };

    for (final e in entries) {
      final d = e['date'] as DateTime;
      final dayStart = DateTime(d.year, d.month, d.day);
      if (dayStart == today) {
        groups['BUGÜN']!.add(e);
      } else if (dayStart == yesterday) {
        groups['DÜN']!.add(e);
      } else if (dayStart.isAfter(weekStart.subtract(const Duration(days: 1)))) {
        groups['BU HAFTA']!.add(e);
      } else if (dayStart.isAfter(monthStart.subtract(const Duration(days: 1)))) {
        groups['BU AY']!.add(e);
      } else {
        groups['DAHA ESKİ']!.add(e);
      }
    }
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    final dayStart = DateTime(d.year, d.month, d.day);
    final todayStart = DateTime(now.year, now.month, now.day);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (dayStart == todayStart) return '$hh:$mm';
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$dd.$mo · $hh:$mm';
  }
}

class _FieldPickerSheet extends StatelessWidget {
  const _FieldPickerSheet({required this.fields, required this.selected});

  final List<Map<String, dynamic>> fields;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  'Tarla Seç',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.public, color: AppColors.emeraldDark),
            title: const Text('Tüm Tarlalar'),
            selected: selected == null,
            onTap: () => Navigator.pop(context, '__none__'),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fields.length,
              itemBuilder: (_, i) {
                final f = fields[i];
                final id = f['id'] as String?;
                return ListTile(
                  leading:
                      const Icon(Icons.landscape_rounded, color: AppColors.soil),
                  title: Text(f['name'] as String? ?? 'Tarla'),
                  selected: id != null && id == selected,
                  onTap: () => Navigator.pop(context, id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
