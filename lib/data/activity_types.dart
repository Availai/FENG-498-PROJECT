import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tarla aktivite tipleri — çiftçinin takip ettiği temel eylemler.
/// CalendarEvents.eventType alanına String sabit olarak yazılır; yeni Drift
/// tablosu gerekmez (şema migration'ı yok).
class ActivityType {
  static const watering = 'watering';
  static const fertilizing = 'fertilizing';
  static const spraying = 'spraying';
  static const scouting = 'scouting';
  static const harvest = 'harvest';
  static const planting = 'planting';
  static const other = 'other';

  /// Hızlı-log UI'sında gösterilen sırada.
  static const quickLogOrder = <String>[
    watering,
    fertilizing,
    scouting,
    spraying,
    harvest,
  ];

  static String label(String type) {
    switch (type) {
      case watering:
        return 'Sulama';
      case fertilizing:
        return 'Gübreleme';
      case spraying:
        return 'İlaçlama';
      case scouting:
        return 'Gözlem';
      case harvest:
        return 'Hasat';
      case planting:
        return 'Ekim';
      default:
        return 'Diğer';
    }
  }

  /// Fiil hali ("Suladım"/"Gübreledim") — chip butonu için.
  static String actionLabel(String type) {
    switch (type) {
      case watering:
        return 'Suladım';
      case fertilizing:
        return 'Gübreledim';
      case spraying:
        return 'İlaçladım';
      case scouting:
        return 'Gözlemledim';
      case harvest:
        return 'Hasat';
      case planting:
        return 'Ekim';
      default:
        return 'Not';
    }
  }

  static IconData icon(String type) {
    switch (type) {
      case watering:
        return Icons.water_drop_rounded;
      case fertilizing:
        return Icons.grass_rounded;
      case spraying:
        return Icons.science_rounded;
      case scouting:
        return Icons.manage_search_rounded;
      case harvest:
        return Icons.agriculture_rounded;
      case planting:
        return Icons.eco_rounded;
      default:
        return Icons.edit_note_rounded;
    }
  }

  static Color color(String type) {
    switch (type) {
      case watering:
        return AppColors.frost;
      case fertilizing:
        return AppColors.emeraldDark;
      case spraying:
        return AppColors.warning;
      case scouting:
        return AppColors.emerald;
      case harvest:
        return AppColors.wheat;
      case planting:
        return AppColors.emerald;
      default:
        return AppColors.textTertiary;
    }
  }

  /// Ölçüm birimi (opsiyonel alan). Null ise miktar alanı gizlenir.
  static String? quantityUnit(String type) {
    switch (type) {
      case watering:
        return 'dk';
      case fertilizing:
        return 'kg';
      case spraying:
        return 'L';
      case harvest:
        return 'kg';
      default:
        return null;
    }
  }
}
