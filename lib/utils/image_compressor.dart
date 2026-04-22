import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter_image_compress/flutter_image_compress.dart';
import 'package:path/path.dart' as p;
import 'package:path_provider/path_provider.dart';

/// Fotoğrafları upload öncesi WebP formatına sıkıştırır.
///
/// AGENTS.md kuralı: "Compress photos to WebP before upload when relevant."
///
/// `flutter_image_compress` paketi platform native encoder'ları (Android:
/// libwebp, iOS: WebP through libwebp) kullanarak gerçek WebP çıktısı verir.
/// JPEG'e kıyasla ~%25-30 daha küçük dosya boyutu sağlar.
class ImageCompressor {
  /// Verilen [imageFile]'ı WebP formatına dönüştürür.
  ///
  /// - Zaten `.webp` uzantılıysa doğrudan döner.
  /// - Çok küçük dosyalar (< 80 KB) sıkıştırılmaz.
  /// - [maxDimension]: En büyük kenar bu değere küçültülür (varsayılan 1280px).
  /// - [quality]: WebP kalitesi 0-100 (varsayılan 75 — görsel olarak kayıpsıza yakın).
  /// - Hata durumunda orijinal dosyayı döner (graceful fallback).
  static Future<File> compressToWebP(
    File imageFile, {
    int maxDimension = 1280,
    int quality = 75,
  }) async {
    try {
      if (p.extension(imageFile.path).toLowerCase() == '.webp') {
        return imageFile;
      }

      final fileSize = await imageFile.length();
      if (fileSize < 80 * 1024) {
        return imageFile;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = p.join(tempDir.path, 'compressed_$timestamp.webp');

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        outPath,
        format: CompressFormat.webp,
        quality: quality,
        minWidth: maxDimension,
        minHeight: maxDimension,
      );

      if (result == null) {
        debugPrint(
            '[ImageCompressor] WebP encode başarısız — orijinal kullanılıyor.');
        return imageFile;
      }

      final compressedFile = File(result.path);
      final compressedSize = await compressedFile.length();
      final savedPercent =
          ((1 - compressedSize / fileSize) * 100).toStringAsFixed(0);
      debugPrint(
        '[ImageCompressor] WebP sıkıştırma: '
        '${(fileSize / 1024).toStringAsFixed(0)} KB → '
        '${(compressedSize / 1024).toStringAsFixed(0)} KB '
        '(%$savedPercent küçültme)',
      );

      return compressedFile;
    } catch (e) {
      debugPrint(
          '[ImageCompressor] Sıkıştırma hatası: $e — orijinal kullanılıyor.');
      return imageFile;
    }
  }

  /// Verilen [imageFile]'ı JPEG formatına dönüştürür.
  ///
  /// PlantNet gibi WebP kabul etmeyen API'ler için kullanılır.
  /// `.jpg` / `.jpeg` uzantılıysa doğrudan döner. Hata durumunda orijinal dosya
  /// döner — caller fallback'i kendisi yönetir.
  static Future<File> compressToJpeg(
    File imageFile, {
    int maxDimension = 1280,
    int quality = 85,
  }) async {
    try {
      final ext = p.extension(imageFile.path).toLowerCase();
      if (ext == '.jpg' || ext == '.jpeg') {
        final size = await imageFile.length();
        if (size < 2 * 1024 * 1024) return imageFile;
      }

      final tempDir = await getTemporaryDirectory();
      final timestamp = DateTime.now().millisecondsSinceEpoch;
      final outPath = p.join(tempDir.path, 'plantnet_$timestamp.jpg');

      final result = await FlutterImageCompress.compressAndGetFile(
        imageFile.absolute.path,
        outPath,
        format: CompressFormat.jpeg,
        quality: quality,
        minWidth: maxDimension,
        minHeight: maxDimension,
      );

      if (result == null) {
        debugPrint(
            '[ImageCompressor] JPEG encode başarısız — orijinal kullanılıyor.');
        return imageFile;
      }
      return File(result.path);
    } catch (e) {
      debugPrint(
          '[ImageCompressor] JPEG sıkıştırma hatası: $e — orijinal kullanılıyor.');
      return imageFile;
    }
  }
}
