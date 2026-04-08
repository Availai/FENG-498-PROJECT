import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Bölge çizme modundaki alt toolbar.
/// Seçilen bitkinin adını, renk önizlemesini ve nokta sayısını gösterir.
/// "Geri Al", "Tamamla", "İptal" aksiyonları sunar.
class ZoneDrawingToolbar extends StatelessWidget {
  final String plantName;
  final Color plantColor;
  final int pointCount;
  final VoidCallback onUndo;
  final VoidCallback onComplete;
  final VoidCallback onCancel;

  const ZoneDrawingToolbar({
    super.key,
    required this.plantName,
    required this.plantColor,
    required this.pointCount,
    required this.onUndo,
    required this.onComplete,
    required this.onCancel,
  });

  @override
  Widget build(BuildContext context) {
    final canComplete = pointCount >= 3;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: const Color(0xFF0D1811).withValues(alpha: 0.95),
        border: Border.all(
          color: plantColor.withValues(alpha: 0.6),
          width: 1.5,
        ),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Üst bilgi satırı
          Row(
            children: [
              Container(
                width: 14,
                height: 14,
                decoration: BoxDecoration(
                  color: plantColor,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  '$plantName — Bölge Çiz',
                  style: GoogleFonts.outfit(
                    color: Colors.white,
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: canComplete
                      ? const Color(0xFF00E676).withValues(alpha: 0.2)
                      : Colors.white.withValues(alpha: 0.08),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(
                  '$pointCount nokta',
                  style: TextStyle(
                    color: canComplete ? const Color(0xFF00E676) : Colors.white54,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          // Yardım metni
          Text(
            pointCount < 3
                ? 'Haritaya dokunarak bölge köşelerini işaretleyin (en az 3)'
                : 'Bölge çizilebilir. Tamamla veya daha fazla nokta ekle.',
            style: const TextStyle(color: Colors.white38, fontSize: 10),
          ),
          const SizedBox(height: 10),
          // Aksiyon butonları
          Row(
            children: [
              // İptal
              Expanded(
                child: _ToolbarButton(
                  icon: Icons.close_rounded,
                  label: 'İptal',
                  color: Colors.red.shade400,
                  onTap: onCancel,
                ),
              ),
              const SizedBox(width: 8),
              // Geri Al
              Expanded(
                child: _ToolbarButton(
                  icon: Icons.undo_rounded,
                  label: 'Geri Al',
                  color: Colors.orange.shade400,
                  onTap: pointCount > 0 ? onUndo : null,
                ),
              ),
              const SizedBox(width: 8),
              // Tamamla
              Expanded(
                flex: 2,
                child: _ToolbarButton(
                  icon: Icons.check_circle_rounded,
                  label: 'Tamamla',
                  color: const Color(0xFF00E676),
                  filled: canComplete,
                  onTap: canComplete ? onComplete : null,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ToolbarButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final bool filled;
  final VoidCallback? onTap;

  const _ToolbarButton({
    required this.icon,
    required this.label,
    required this.color,
    this.filled = false,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final disabled = onTap == null;
    final effectiveColor = disabled ? Colors.white24 : color;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: filled
              ? effectiveColor.withValues(alpha: 0.25)
              : Colors.white.withValues(alpha: 0.06),
          border: Border.all(
            color: effectiveColor.withValues(alpha: 0.5),
            width: 1,
          ),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(icon, color: effectiveColor, size: 16),
            const SizedBox(width: 4),
            Text(
              label,
              style: TextStyle(
                color: effectiveColor,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
