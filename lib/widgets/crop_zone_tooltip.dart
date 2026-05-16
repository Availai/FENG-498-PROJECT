import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/crop_lifecycle.dart';

/// Bölgeye dokunulduğunda gösterilen bilgi kartı.
/// Bitki adı, ekim tarihi, olgunluk %, sil butonu.
class CropZoneTooltip extends StatelessWidget {
  final String cropName;
  final Color cropColor;
  final String? plantedDate;
  final int harvestDays;
  final double maturityPercent;

  /// seed_plants.json stable_id (ör. `crop.orange`). Verilirse çok
  /// yıllık ürün ayrımı için kullanılır.
  final String? stableId;

  /// Ürün kategorisi (`Meyve`, `Sebze`, `Endustri Bitkisi` vb.).
  /// stable_id yoksa fallback olarak değerlendirilir.
  final String? category;

  /// Çok yıllık ürünlerde her yıl tekrarlanan hasat ay aralığı
  /// (1-12). Verilirse tek seferlik "kalan gün" yerine "her yıl X-Y
  /// arası hasat" satırı gösterilir.
  final List<int>? harvestMonths;

  final VoidCallback onDelete;
  final VoidCallback onClose;

  const CropZoneTooltip({
    super.key,
    required this.cropName,
    required this.cropColor,
    this.plantedDate,
    required this.harvestDays,
    required this.maturityPercent,
    this.stableId,
    this.category,
    this.harvestMonths,
    required this.onDelete,
    required this.onClose,
  });

  @override
  Widget build(BuildContext context) {
    DateTime? planted;
    if (plantedDate != null) {
      final parts = plantedDate!.split('.');
      if (parts.length == 3) {
        planted = DateTime.tryParse('${parts[2]}-${parts[1]}-${parts[0]}');
      }
      planted ??= DateTime.tryParse(plantedDate!);
    }

    final cycle = cycleTypeFor(stableId: stableId, category: category);
    final isPerennial = cycle == CropCycleType.perennial;
    final harvestDate = planted?.add(Duration(days: harvestDays));
    final remaining = harvestDate?.difference(DateTime.now()).inDays;
    final annualWindow =
        isPerennial ? annualHarvestWindow(harvestMonths) : null;

    return Container(
      width: 220,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1811).withValues(alpha: 0.95),
        border: Border.all(
          color: cropColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.4),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Başlık + kapat
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: cropColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  cropName,
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              GestureDetector(
                onTap: onClose,
                child: const Icon(Icons.close, color: Colors.white38, size: 18),
              ),
            ],
          ),
          const SizedBox(height: 10),
          const Divider(color: Colors.white12, height: 1),
          const SizedBox(height: 10),

          // Bilgi satırları
          if (planted != null)
            _infoRow(
              isPerennial ? '🌳 Dikim Tarihi' : '📅 Ekim Tarihi',
              DateFormat('dd.MM.yyyy').format(planted),
            ),
          if (isPerennial) ...[
            _infoRow(
              '🗓️ İlk Hasat',
              harvestDaysLabel(harvestDays: harvestDays, cycle: cycle),
            ),
            if (annualWindow != null) _infoRow('🌾 Hasat Dönemi', annualWindow),
          ] else ...[
            if (harvestDate != null)
              _infoRow('🗓️ Tah. Hasat',
                  DateFormat('dd.MM.yyyy').format(harvestDate)),
            if (remaining != null)
              _infoRow(
                '⏳ Kalan',
                remaining > 0 ? '$remaining gün' : 'Hasat zamanı!',
              ),
          ],

          // Olgunluk barı
          const SizedBox(height: 10),
          Row(
            children: [
              const Text('🌱 Olgunluk',
                  style: TextStyle(color: Colors.white54, fontSize: 11)),
              const Spacer(),
              Text(
                '%${maturityPercent.toStringAsFixed(0)}',
                style: TextStyle(
                  color: maturityPercent >= 90
                      ? const Color(0xFF00E676)
                      : Colors.white,
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: maturityPercent / 100,
              minHeight: 6,
              backgroundColor: Colors.white.withValues(alpha: 0.1),
              valueColor: AlwaysStoppedAnimation(
                maturityPercent >= 90
                    ? const Color(0xFF00E676)
                    : const Color(0xFF4CAF50),
              ),
            ),
          ),

          // Sil butonu
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: GestureDetector(
              onTap: onDelete,
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: Colors.red.shade900.withValues(alpha: 0.3),
                  border: Border.all(
                    color: Colors.red.shade400.withValues(alpha: 0.5),
                  ),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.delete_outline_rounded,
                        color: Colors.red.shade300, size: 16),
                    const SizedBox(width: 6),
                    Text(
                      'Bu Bölgeyi Sil',
                      style: TextStyle(
                        color: Colors.red.shade300,
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _infoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 4),
      child: Row(
        children: [
          Text(label,
              style: const TextStyle(color: Colors.white54, fontSize: 11)),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 12,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }
}
