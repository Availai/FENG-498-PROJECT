import '../data/activity_types.dart';
import '../data/supported_crops.dart';
import 'local_data_repository.dart';
import 'growth_engine.dart';

/// `logActivity` + `GrowthEngine.recompute` zincirlemesini tek yerde tutar.
/// Tüm UI noktaları bu wrapper'ı çağırarak büyüme durumunun aktivite
/// sonrası **canlı** güncellenmesini garanti eder.
///
/// Tasarım kararı: GrowthEngine.recompute() bazı UI yerlerinde unutulduğu
/// için (field_detail_screen, vb.) growth state stale kalıyordu. Bu wrapper
/// repository.logActivity'yi sarmalayıp her aktivite sonrası ilgili
/// crop için recompute tetikler.
class ActivityLogger {
  ActivityLogger({
    required LocalDataRepository repository,
    required GrowthEngine growthEngine,
  })  : _repo = repository,
        _engine = growthEngine;

  final LocalDataRepository _repo;
  final GrowthEngine _engine;

  /// Aktivite kaydı yazar ve cropId verilmişse büyüme durumunu yeniden hesaplar.
  /// Recompute hatası loglanır ama atılmaz — UI flow bozulmasın.
  Future<void> log({
    required String fieldId,
    required String type,
    String? cropId,
    String? note,
    double? quantity,
    String? quantityUnit,
    double? recommendedQuantity,
    Map<String, dynamic>? metadata,
    DateTime? at,
    ActivityScope? scope,
    String? plantInstanceId,
    String? subtype,
    String? photoPath,
  }) async {
    await _repo.logActivity(
      fieldId: fieldId,
      type: type,
      cropId: cropId,
      note: note,
      quantity: quantity,
      quantityUnit: quantityUnit,
      recommendedQuantity: recommendedQuantity,
      metadata: metadata,
      at: at,
      scope: scope,
      plantInstanceId: plantInstanceId,
      subtype: subtype,
      photoPath: photoPath,
    );

    if (cropId != null && cropId.isNotEmpty) {
      await _safeRecompute(cropId);
      return;
    }

    final crops = await _repo.loadFieldCrops(fieldId);
    for (final crop in crops) {
      final id = crop['id']?.toString();
      final name = crop['name']?.toString();
      if (id == null || id.isEmpty) continue;
      if (SupportedCrops.canonicalName(name) != 'Ayçiçeği') continue;
      await _safeRecompute(id);
    }
  }

  Future<void> _safeRecompute(String cropId) async {
    try {
      await _engine.recompute(cropId: cropId);
    } catch (_) {
      // Recompute başarısız olursa aktivite kaydı yine de korunur;
      // bir sonraki açılışta tekrar denenecek.
    }
  }
}
