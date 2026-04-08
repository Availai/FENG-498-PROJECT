import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/glass_panel.dart';

/// Ekili bölgelerin renk kodlu lejant kartı.
/// Haritanın sol altında gösterilir.
class CropZoneLegend extends StatelessWidget {
  /// Her eleman: {'name': 'Buğday', 'color': Color, 'percent': 35.0}
  final List<Map<String, dynamic>> zones;

  const CropZoneLegend({super.key, required this.zones});

  @override
  Widget build(BuildContext context) {
    if (zones.isEmpty) return const SizedBox.shrink();

    return GlassPanel(
      baseColor: const Color(0xFF1B5E20),
      borderRadius: 14,
      padding: const EdgeInsets.all(10),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 140),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              children: [
                const Icon(Icons.layers_rounded, color: Color(0xFF00E676), size: 13),
                const SizedBox(width: 5),
                Text(
                  'Bölge Dağılımı',
                  style: GoogleFonts.outfit(
                    fontSize: 11,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            ...zones.take(8).map((zone) {
              final color = zone['color'] as Color? ?? const Color(0xFF66BB6A);
              final name = zone['name']?.toString() ?? 'Bitki';
              final hasZone = zone['has_zone'] == true;
              return Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: color,
                        borderRadius: BorderRadius.circular(3),
                        border: Border.all(
                          color: Colors.white24,
                          width: 0.5,
                        ),
                      ),
                    ),
                    const SizedBox(width: 6),
                    Expanded(
                      child: Text(
                        name,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 10,
                        ),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    Icon(
                      hasZone
                          ? Icons.crop_square_rounded
                          : Icons.crop_free_rounded,
                      color: hasZone
                          ? const Color(0xFF00E676)
                          : Colors.white24,
                      size: 12,
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
