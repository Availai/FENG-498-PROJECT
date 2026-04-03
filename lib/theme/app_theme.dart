/// Premium AgriApp Design System
///
/// Palette: Deep forest green × ivory white × warm amber
/// Typography: Outfit (headings) / Inter (body)
/// Effects: Glassmorphism cards, soft shadows, subtle gradients
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

// ─────────────────────────────────────────────────────────────────────────────
// RENK PALETİ
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppColors {
  // Backgrounds
  static const bg = Color(0xFFF4F7F3);          // very light sage
  static const bgDark = Color(0xFF0F1C14);       // deep forest
  static const surface = Color(0xFFFFFFFF);
  static const surfaceDark = Color(0xFF172218);  // dark card

  // Primary greens
  static const emerald = Color(0xFF059669);       // primary CTA
  static const emeraldLight = Color(0xFF34D399);  // highlights
  static const emeraldDark = Color(0xFF064E3B);   // deep accent
  static const forest = Color(0xFF1B4332);        // hero backgrounds
  static const sage = Color(0xFF6EAD8A);          // muted green
  static const mint = Color(0xFFA7F3D0);          // soft tag bg

  // Text
  static const textPrimary = Color(0xFF111827);
  static const textSecondary = Color(0xFF6B7280);
  static const textTertiary = Color(0xFF9CA3AF);
  static const textOnDark = Color(0xFFF9FAFB);
  static const textOnDarkMuted = Color(0xFF9DC4AE);

  // Semantic
  static const warning = Color(0xFFF59E0B);
  static const warningBg = Color(0xFFFFF7ED);
  static const error = Color(0xFFDC2626);
  static const errorBg = Color(0xFFFEF2F2);
  static const info = Color(0xFF0EA5E9);
  static const infoBg = Color(0xFFF0F9FF);
  static const success = Color(0xFF059669);
  static const successBg = Color(0xFFF0FDF4);

  // Borders & dividers
  static const border = Color(0xFFE5E7EB);
  static const borderDark = Color(0xFF1F3027);
  static const divider = Color(0xFFF3F4F6);

  // Glass overlay
  static const glassLight = Color(0xB3FFFFFF);   // 70% white
  static const glassDark = Color(0x26FFFFFF);    // 15% white
}

// ─────────────────────────────────────────────────────────────────────────────
// SHADOWS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppShadows {
  static const sm = [
    BoxShadow(color: Color(0x0A000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x06000000), blurRadius: 2, offset: Offset(0, 1)),
  ];

  static const md = [
    BoxShadow(color: Color(0x10000000), blurRadius: 8, offset: Offset(0, 2)),
    BoxShadow(color: Color(0x08000000), blurRadius: 4, offset: Offset(0, 1)),
  ];

  static const lg = [
    BoxShadow(color: Color(0x18000000), blurRadius: 16, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x0A000000), blurRadius: 8, offset: Offset(0, 2)),
  ];

  static const emeraldGlow = [
    BoxShadow(color: Color(0x30059669), blurRadius: 20, offset: Offset(0, 4)),
  ];

  static const card = [
    BoxShadow(color: Color(0x08000000), blurRadius: 12, offset: Offset(0, 4)),
    BoxShadow(color: Color(0x05000000), blurRadius: 4, offset: Offset(0, 1)),
    BoxShadow(color: Color(0x06FFFFFF), blurRadius: 1, offset: Offset(0, -1)),
  ];
}

// ─────────────────────────────────────────────────────────────────────────────
// BORDER RADIUS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppRadius {
  static const xs = BorderRadius.all(Radius.circular(6));
  static const sm = BorderRadius.all(Radius.circular(10));
  static const md = BorderRadius.all(Radius.circular(14));
  static const lg = BorderRadius.all(Radius.circular(20));
  static const xl = BorderRadius.all(Radius.circular(28));
  static const full = BorderRadius.all(Radius.circular(999));
}

// ─────────────────────────────────────────────────────────────────────────────
// TYPOGRAPHY
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppText {
  // Outfit — display / heading
  static TextStyle display(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 32, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.15);
  static TextStyle h1(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textPrimary, height: 1.2);
  static TextStyle h2(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 20, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.25);
  static TextStyle h3(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textPrimary, height: 1.3);

  // Inter — body / captions
  static TextStyle body(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textPrimary, height: 1.5);
  static TextStyle bodyMd(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.5);
  static TextStyle sm(BuildContext context) =>
      GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w400, color: AppColors.textSecondary, height: 1.4);
  static TextStyle xs(BuildContext context) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w500, color: AppColors.textTertiary, height: 1.3);
  static TextStyle label(BuildContext context) =>
      GoogleFonts.inter(fontSize: 11, fontWeight: FontWeight.w600, color: AppColors.textSecondary, letterSpacing: 0.8, height: 1.2);
  static TextStyle mono(BuildContext context) =>
      GoogleFonts.robotoMono(fontSize: 13, fontWeight: FontWeight.w500, color: AppColors.textPrimary, height: 1.4);

  // Dark variants
  static TextStyle h1Dark(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 24, fontWeight: FontWeight.w700, color: AppColors.textOnDark, height: 1.2);
  static TextStyle h3Dark(BuildContext context) =>
      GoogleFonts.outfit(fontSize: 16, fontWeight: FontWeight.w600, color: AppColors.textOnDark, height: 1.3);
  static TextStyle bodyDark(BuildContext context) =>
      GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w400, color: AppColors.textOnDarkMuted, height: 1.5);
}

// ─────────────────────────────────────────────────────────────────────────────
// GRADIENTS
// ─────────────────────────────────────────────────────────────────────────────

abstract class AppGradients {
  static const forestHero = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF0F4C2A), Color(0xFF1B6B3A)],
  );

  static const emeraldCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFF059669), Color(0xFF047857)],
  );

  static const warmCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFF59E0B), Color(0xFFD97706)],
  );

  static const bgSubtle = LinearGradient(
    begin: Alignment.topCenter,
    end: Alignment.bottomCenter,
    colors: [Color(0xFFF4F7F3), Color(0xFFF0F4EF)],
  );

  static const dangerCard = LinearGradient(
    begin: Alignment.topLeft,
    end: Alignment.bottomRight,
    colors: [Color(0xFFDC2626), Color(0xFFB91C1C)],
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// MATERIALAPP THEME
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
      backgroundColor: AppColors.surface,
      elevation: 0,
      scrolledUnderElevation: 1,
      shadowColor: const Color(0x14000000),
      surfaceTintColor: Colors.transparent,
      centerTitle: false,
      titleTextStyle: GoogleFonts.outfit(
        fontSize: 18,
        fontWeight: FontWeight.w600,
        color: AppColors.textPrimary,
      ),
      iconTheme: const IconThemeData(color: AppColors.textPrimary, size: 22),
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
        borderSide: const BorderSide(color: AppColors.emerald, width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
      hintStyle: GoogleFonts.inter(fontSize: 14, color: AppColors.textTertiary),
    ),
    elevatedButtonTheme: ElevatedButtonThemeData(
      style: ElevatedButton.styleFrom(
        backgroundColor: AppColors.emerald,
        foregroundColor: Colors.white,
        elevation: 0,
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
        shape: const RoundedRectangleBorder(borderRadius: AppRadius.sm),
        textStyle: GoogleFonts.inter(fontSize: 14, fontWeight: FontWeight.w600),
      ),
    ),
    chipTheme: ChipThemeData(
      backgroundColor: AppColors.mint,
      labelStyle: GoogleFonts.inter(fontSize: 12, fontWeight: FontWeight.w500, color: AppColors.emeraldDark),
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.full),
      side: BorderSide.none,
    ),
  );
}

// ─────────────────────────────────────────────────────────────────────────────
// SHARED WIDGETS — kullanışlı atom bileşenler
// ─────────────────────────────────────────────────────────────────────────────

/// Premium section header
class AppSectionHeader extends StatelessWidget {
  final String title;
  final String? subtitle;
  final Widget? trailing;
  const AppSectionHeader({super.key, required this.title, this.subtitle, this.trailing});

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: AppText.h3(context)),
              if (subtitle != null)
                Padding(
                  padding: const EdgeInsets.only(top: 2),
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

/// Premium stat tile
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
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        boxShadow: AppShadows.sm,
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            if (icon != null) ...[
              Icon(icon, size: 14, color: c),
              const SizedBox(width: 4),
            ],
            Text(label, style: AppText.xs(context)),
          ]),
          const SizedBox(height: 6),
          Row(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(value, style: AppText.h2(context).copyWith(color: c)),
              if (unit != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 3, left: 3),
                  child: Text(unit!, style: AppText.xs(context)),
                ),
            ],
          ),
        ],
      ),
    );
  }
}

/// Badge / tag chip
class AppTag extends StatelessWidget {
  final String label;
  final Color? color;
  final Color? bgColor;
  const AppTag(this.label, {super.key, this.color, this.bgColor});

  @override
  Widget build(BuildContext context) {
    final c = color ?? AppColors.emerald;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor ?? c.withValues(alpha: 0.1),
        borderRadius: AppRadius.full,
      ),
      child: Text(
        label,
        style: GoogleFonts.inter(
          fontSize: 11,
          fontWeight: FontWeight.w600,
          color: c,
        ),
      ),
    );
  }
}

/// Progress bar with label
class AppProgressBar extends StatelessWidget {
  final double value; // 0-1
  final Color? color;
  final double height;
  const AppProgressBar({super.key, required this.value, this.color, this.height = 6});

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
