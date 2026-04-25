import 'dart:io';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import '../services/agri_service.dart';
import '../utils/image_compressor.dart';
import '../utils/location_utils.dart';
import 'analysis_result_screen.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_route.dart';
import '../widgets/floating_toast.dart';
import '../widgets/glass_panel.dart';

class CameraScreen extends StatefulWidget {
  const CameraScreen({super.key});
  @override
  State<CameraScreen> createState() => _CameraScreenState();
}

class _CameraScreenState extends State<CameraScreen> {
  final List<File> _photos = [];
  bool _isLoading = false;

  Future<void> _pick(ImageSource s) async {
    final img = await ImagePicker().pickImage(
      source: s,
      imageQuality: 70,
      maxWidth: 1080,
      maxHeight: 1080,
    );
    if (img == null) return;

    // AGENTS.md: "Compress photos to WebP before upload when relevant."
    final compressed = await ImageCompressor.compressToWebP(File(img.path));
    setState(() => _photos.insert(0, compressed));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Akıllı Asistan Kamerası', style: AppText.h2(context)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        centerTitle: false,
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Expanded(
                  child: ElevatedButton.icon(
                    onPressed: () => _pick(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt_outlined),
                    label: const Text('Kamera Çekimi'),
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pick(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library_outlined),
                    label: const Text('Galeri Kullan'),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.emerald,
                      side: const BorderSide(color: AppColors.emerald),
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                  ),
                ),
              ],
            ),
          ),
          if (_isLoading)
            const LinearProgressIndicator(color: AppColors.emerald),
          if (_photos.isEmpty && !_isLoading)
            Expanded(
              child: Center(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.document_scanner_outlined,
                        size: 80,
                        color: AppColors.emerald.withValues(alpha: 0.2)),
                    const SizedBox(height: 16),
                    Text('Analiz İçin Görsel Seçin',
                        style: AppText.h3(context)),
                    const SizedBox(height: 8),
                    Text(
                      'Hastalık, zararlı böcek\nve bitki türü teşhisi yapar.',
                      textAlign: TextAlign.center,
                      style: AppText.sm(context),
                    ),
                  ],
                ),
              ),
            )
          else
            Expanded(
              child: GridView.builder(
                padding: const EdgeInsets.all(16),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 16,
                  mainAxisSpacing: 16,
                  childAspectRatio: 0.75,
                ),
                itemCount: _photos.length,
                itemBuilder: (context, i) => Container(
                  decoration: BoxDecoration(
                    borderRadius: AppRadius.md,
                    boxShadow: AppShadows.md,
                  ),
                  child: ClipRRect(
                    borderRadius: AppRadius.md,
                    child: Stack(
                      fit: StackFit.expand,
                      children: [
                        Image.file(_photos[i], fit: BoxFit.cover),
                        Positioned(
                          bottom: 0,
                          left: 0,
                          right: 0,
                          child: GlassPanel(
                            borderRadius: 0,
                            padding: const EdgeInsets.all(10),
                            child: ElevatedButton(
                              onPressed: _isLoading ? null : () => _analyze(i),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.emerald,
                                padding:
                                    const EdgeInsets.symmetric(vertical: 12),
                              ),
                              child: const Text('YARDIM AL',
                                  style: TextStyle(letterSpacing: 1.2)),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Future<void> _analyze(int index) async {
    setState(() => _isLoading = true);
    final navigator = Navigator.of(context);
    try {
      final pos = await getCurrentPosition();

      // Upload öncesi WebP sıkıştırma (zaten sıkıştırılmışsa atlar)
      final compressedPhoto =
          await ImageCompressor.compressToWebP(_photos[index]);

      final res = await AgriService.analyzeImage(
        compressedPhoto,
        pos.latitude,
        pos.longitude,
      );
      if (res['type'] != 'error') {
        Hive.box('recognized_plants').add({
          'type': res['type'],
          'title': res['data']?['title'] ?? 'Bilinmeyen',
          'scientific_name': res['data']?['scientific_name'],
          'description': res['data']?['description'],
          'cached': res['data']?['from_cache'] == true,
          'date': DateFormat('dd.MM.yyyy HH:mm').format(DateTime.now()),
        });
      }
      if (mounted) {
        navigator.push(
          AnimatedRoute.scaleFade(
            AnalysisResultScreen(
              image: _photos[index],
              result: res,
            ),
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        AppToast.show(context, message: 'Hata: $e', type: ToastType.error);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }
}
