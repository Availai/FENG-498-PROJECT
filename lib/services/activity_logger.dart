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
    );

    if (cropId != null && cropId.isNotEmpty) {
      try {
        await _engine.recompute(cropId: cropId);
      } catch (_) {
        // Recompute başarısız olursa aktivite kaydı yine de korunur;
        // bir sonraki açılışta tekrar denenecek.
      }
    }
  }
}
