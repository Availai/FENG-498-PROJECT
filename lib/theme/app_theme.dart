/// AgriApp Tasarım Sistemi — Çiftçi Dostu Sade Tema
///
/// Palet: Beyaz arka plan × krem kartlar × yonca yeşili aksan
/// Tipografi: Outfit (başlıklar) / Inter (gövde) — sabah güneşinde okunaklı
/// Hedef: Yüksek kontrast, dev fontlar, glassmorphism yok, blur yok.
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RENK PALETİ — Doğal, sıcak, kontrastlı
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppColors {
  // Zeminler — beyaz scaffold, krem kart
  static const bg = Color(0xFFFFFFFF); // scaffold: saf beyaz
  static const bgDark = Color(0xFFF5F0E1); // (legacy) — artık krem
  static const surface = Color(0xFFFBF7EC); // kart: sıcak krem
  static const surfaceDark = Color(0xFFF0EADA); // (legacy) — koyu krem
  static const surfaceAlt = Color(0xFFF8F4E8); // ikincil kart krem

  // Yonca yeşili aksanlar (neon değil, doğal)
  static const emerald = Color(0xFF43A047); // ana CTA — yonca yeşili
  static const emeraldLight = Color(0xFF81C784); // açık vurgu
  static const emeraldDark = Color(0xFF2E7D32); // koyu yaprak
  static const forest = Color(0xFF1B5E20); // hero / yoğun yeşil
  static const sage = Color(0xFF8BAE8F); // yumuşak adaçayı
  static const mint = Color(0xFFE8F5E9); // chip arka plan

  // Toprak tonları
  static const soil = Color(0xFF8D6E63); // toprak kahve
  static const soilLight = Color(0xFFD7CCC8); // açık toprak
  static const wheat = Color(0xFFE8D48A); // buğday sarısı

  // Metin — yüksek kontrast, göz yormayan koyu gri
  static const textPrimary = Color(0xFF1F2937); // neredeyse siyah
  static const textSecondary = Color(0xFF4B5563); // koyu gri
  static const textTertiary = Color(0xFF6B7280); // orta gri
  static const textOnDark = Color(0xFFFFFFFF); // yeşil hero üstünde beyaz
  static const textOnDarkMuted = Color(0xFFE0F2E4);

  // Semantik — sade, uyarıcı tonlar
  static const warning = Color(0xFFE67E22); // hasat / uyarı turuncu
  static const warningBg = Color(0xFFFFF4E6);
  static const error = Color(0xFFD32F2F);
  static const errorBg = Color(0xFFFFEBEE);
  static const info = Color(0xFF1976D2);
  static const infoBg = Color(0xFFE3F2FD);
  static const success = Color(0xFF43A047);
  static const successBg = Color(0xFFE8F5E9);
  static const frost = Color(0xFF0288D1); // zirai don mavisi
  static const frostBg = Color(0xFFE1F5FE);

  // Çizgiler
  static const border = Color(0xFFE5E1D3); // krem kenarlık
  static const borderDark = Color(0xFFCBC3AE);
  static const divider = Color(0xFFEEE9DA);

  // (legacy) Glass — artık tamamen opak, blur yok
  static const glassLight = Color(0xFFFBF7EC);
  static const glassDark = Color(0xFFF0EADA);
}

// ─────────────────────────────────────────────────────────────────────────────
// GÖLGELER — Çok hafif, blursuz kart yükseltisi
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppShadows {
  static const sm = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 3, offset: Offset(0, 1)),
  ];

  static const md = [
    BoxShadow(color: Color(0x14000000), blurRadius: 6, offset: Offset(0, 2)),
  ];

  static const lg = [
    BoxShadow(color: Color(0x1A000000), blurRadius: 10, offset: Offset(0, 3)),
  ];

  // (legacy) Neon glow → sade emerald gölgesi
  static const emeraldGlow = [
    BoxShadow(color: Color(0x264CAF50), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const card = [
    BoxShadow(color: Color(0x0F000000), blurRadius: 6, offset: Offset(0, 2)),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// KÖŞE YUMUŞAKLIĞI
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppRadius {
  static const xs = BorderRadius.all(Radius.circular(8));
  static const sm = BorderRadius.all(Radius.circular(12));
  static const md = BorderRadius.all(Radius.circular(16));
  static const lg = BorderRadius.all(Radius.circular(22));
  static const xl = BorderRadius.all(Radius.circular(28));
  static const full = BorderRadius.all(Radius.circular(999));
}

// ─────────────────────────────────────────────────────────────────────────────
// TİPOGRAFİ — Çiftçi gözü yormasın diye büyük, net
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppText {
  // Outfit — başlık
  static TextStyle display(BuildContext context) => GoogleFonts.outfit(
      fontSize: 36,
      fontWeight: FontWeight.w800,
      color: AppColors.textPrimary,
      height: 1.15);
  static TextStyle h1(BuildContext context) => GoogleFonts.outfit(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.2);
  static TextStyle h2(BuildContext context) => GoogleFonts.outfit(
      fontSize: 22,
      fontWeight: FontWeight.w700,
      color: AppColors.textPrimary,
      height: 1.25);
  static TextStyle h3(BuildContext context) => GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.3);

  // Inter — gövde
  static TextStyle body(BuildContext context) => GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w400,
      color: AppColors.textPrimary,
      height: 1.5);
  static TextStyle bodyMd(BuildContext context) => GoogleFonts.inter(
      fontSize: 16,
      fontWeight: FontWeight.w600,
      color: AppColors.textPrimary,
      height: 1.5);
  static TextStyle sm(BuildContext context) => GoogleFonts.inter(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textSecondary,
      height: 1.45);
  static TextStyle xs(BuildContext context) => GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w600,
      color: AppColors.textTertiary,
      height: 1.3);
  static TextStyle label(BuildContext context) => GoogleFonts.inter(
      fontSize: 12,
      fontWeight: FontWeight.w700,
      color: AppColors.textSecondary,
      letterSpacing: 0.6,
      height: 1.2);
  static TextStyle mono(BuildContext context) => GoogleFonts.robotoMono(
      fontSize: 14,
      fontWeight: FontWeight.w500,
      color: AppColors.textPrimary,
      height: 1.4);

  // Koyu zemin varyantları (yeşil hero kartlar için)
  static TextStyle h1Dark(BuildContext context) => GoogleFonts.outfit(
      fontSize: 28,
      fontWeight: FontWeight.w700,
      color: AppColors.textOnDark,
      height: 1.2);
  static TextStyle h3Dark(BuildContext context) => GoogleFonts.outfit(
      fontSize: 18,
      fontWeight: FontWeight.w600,
      color: AppColors.textOnDark,
      height: 1.3);
  static TextStyle bodyDark(BuildContext context) => GoogleFonts.inter(
      fontSize: 15,
      fontWeight: FontWeight.w500,
      color: AppColors.textOnDarkMuted,
      height: 1.5);
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADYANLAR — Doğal, cam/neon olmayan
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppGradients {
  static const forestHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF2E7D32), Color(0xFF1B5E20)],
  );

  static const emeraldCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF43A047), Color(0xFF2E7D32)],
  );

  static const warmCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFE67E22), Color(0xFFD35400)],
  );

  static const bgSubtle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFFFFFFF), Color(0xFFFBF7EC)],
  );

  static const dangerCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFD32F2F), Color(0xFFB71C1C)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIALAPP TEMA
// ─────────────────────────────────────────────────────────────────────────────

ThemeData buildAppTheme() {
  final base = ThemeData(
    useMaterial3: true,
    colorScheme: const ColorScheme.light(
      primary: AppColors.emerald,
      onPrimary: Colors.white,
      secondary: AppColors.sage,
      onSecondary: Colors.white,
      surface: AppColors.surface,
      onSurface: AppColors.textPrimary,
      error: AppColors.error,
      onError: Colors.white,
    ),
    scaffoldBackgroundColor: AppColors.bg,
    textTheme: GoogleFonts.interTextTheme(),
  );

  return base.copyWith(
    appBarTheme: AppBarTheme(
      backgroundColor: AppColors.forest, // ana ekrandaki gibi koyu yonca yeşili
      foregroundColor: Colors.white,
      elevation: 0,
      scrolledUnderElevation: 0,
      shadowColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 20,
        fontWeight: FontWeight.w700,
        color: Colors.white,
      ),
      iconTheme: const IconThemeData(color: Colors.white, size: 24),
      actionsIconTheme: const IconThemeData(color: Colors.white, size: 24),
    ),
    cardTheme: CardThemeData(
      elevation: 0,
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: AppRadius.md,
        side: BorderSide(color: AppColors.border, width: 1),
      ),
      margin: EdgeInsets.zero,
    ),
    dividerTheme: const DividerThemeData(
      color: AppColors.divider,
      thickness: 1,
      space: 1,
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: AppColors.surface,
      border: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: const BorderSide(color: AppColors.border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: AppRadius.sm,
        borderSide: const BorderSide(color: AppColors.emerald, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      hintStyle: GoogleFonts.inter(fontSize: 15, color: AppColors.textTertiary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 14),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        textStyle: GoogleFonts.inter(fontSize: 15, fontWeight: FontWeight.w700),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.mint,
      labelStyle: GoogleFonts.inter(
          fontSize: 13,
          fontWeight: FontWeight.w600,
          color: AppColors.emeraldDark),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.full),
      side: BorderSide.none,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// PAYLAŞIMLI WIDGETLAR
// ─────────────────────────────────────────────────────────────────────────────

class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const AppSectionHeader(
      {super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h2(context)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 4),
                  child: Text(subtitle!, style: AppText.sm(context)),
                ),
            ],
          ),
        ),
        if (trailing != null) trailing!,
      ],
    );
  }
}

class AppStatTile extends StatelessWidget {
  final String label;
  final String value;
  final String? unit;
  final Color? color;
  final IconData? icon;
  const AppStatTile({
    super.key,
    required this.label,
    required this.value,
    this.unit,
    this.color,
    this.icon,
  });

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.emerald;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 16, color: c),
              const SizedBox(width: 6),
            ],
            Text(label, style: AppText.label(context)),
          ]),
          const SizedBox(height: 8),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppText.h1(context).copyWith(color: c)),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 5, left: 4),
                  child: Text(unit!, style: AppText.sm(context)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

class AppTag extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bgColor;
  const AppTag(this.label, {super.key, this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.emerald;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: bgColor ?? c.withValues(alpha: 0.12),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 12,
          fontWeight: FontWeight.w700,
          color: c,
        ),
      ),
    );
  }
}

class AppProgressBar extends StatelessWidget {
  final double value; // 0-1
  final Color? color;
  final double height;
  const AppProgressBar(
      {super.key, required this.value, this.color, this.height = 8});

  @override
  Widget build(BuildContext context) {
    return ClipRRect(
      borderRadius: AppRadius.full,
      child: LinearProgressIndicator(
        value: value.clamp(0.0, 1.0),
        minHeight: height,
        backgroundColor: AppColors.border,
        valueColor: AlwaysStoppedAnimation(color ?? AppColors.emerald),
      ),
    );
  }
}
