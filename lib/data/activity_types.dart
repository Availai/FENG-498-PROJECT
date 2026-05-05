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

  /// Çapalama — yabancı ot kontrolü ve toprak havalandırma. (v8)
  static const hoeing = 'hoeing';

  /// Seyreltme — fazla fideleri çıkararak optimum bitki yoğunluğu. (v8)
  static const thinning = 'thinning';
  static const other = 'other';

  /// Sistem üretimi uyarı kaydı — `AlertJournalService` tarafından yazılır.
  /// Çiftçi manuel logu değildir; quickLogOrder'a girmez, filtrelenebilir
  /// ama kaldırılamaz. Tarlam Günlüğü'nde "Sistem Uyarısı" rozetiyle render
  /// edilir. Subtype alanına alert kind (`frost_critical`, `heat_critical`,
  /// `growth_stage`, vb.) yazılır.
  static const systemAlert = 'system_alert';

  /// Hızlı-log UI'sında gösterilen sırada.
  /// Çapalama ve seyreltme ayçiçeği için kritik (v8); aynı satıra eklendi.
  static const quickLogOrder = <String>[
    watering,
    fertilizing,
    hoeing,
    thinning,
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
      case hoeing:
        return 'Çapalama';
      case thinning:
        return 'Seyreltme';
      case systemAlert:
        return 'Sistem Uyarısı';
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
      case hoeing:
        return 'Çapaladım';
      case thinning:
        return 'Seyrelttim';
      case systemAlert:
        return 'Sistem Uyarısı';
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
      case hoeing:
        return Icons.handyman_rounded;
      case thinning:
        return Icons.content_cut_rounded;
      case systemAlert:
        return Icons.notifications_active_rounded;
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
      case hoeing:
        return AppColors.soil;
      case thinning:
        return AppColors.sage;
      case systemAlert:
        return AppColors.error;
      default:
        return AppColors.textTertiary;
    }
  }

  static const alertSeverityInfo = 'info';
  static const alertSeverityWarning = 'warning';
  static const alertSeverityCritical = 'critical';

  static String normalizeAlertSeverity(Object? raw) {
    switch (raw?.toString().toLowerCase().trim()) {
      case alertSeverityCritical:
      case 'kritik':
        return alertSeverityCritical;
      case alertSeverityWarning:
      case 'uyari':
      case 'uyarı':
        return alertSeverityWarning;
      case alertSeverityInfo:
      case 'bilgi':
      default:
        return alertSeverityInfo;
    }
  }

  static String alertSeverityLabel(Object? raw) {
    switch (normalizeAlertSeverity(raw)) {
      case alertSeverityCritical:
        return 'Kritik';
      case alertSeverityWarning:
        return 'Uyarı';
      case alertSeverityInfo:
      default:
        return 'Bilgi';
    }
  }

  static IconData alertSeverityIcon(Object? raw) {
    switch (normalizeAlertSeverity(raw)) {
      case alertSeverityCritical:
        return Icons.priority_high_rounded;
      case alertSeverityWarning:
        return Icons.warning_amber_rounded;
      case alertSeverityInfo:
      default:
        return Icons.info_outline_rounded;
    }
  }

  static Color alertSeverityColor(Object? raw) {
    switch (normalizeAlertSeverity(raw)) {
      case alertSeverityCritical:
        return AppColors.error;
      case alertSeverityWarning:
        return AppColors.warning;
      case alertSeverityInfo:
      default:
        return AppColors.info;
    }
  }

  static Color alertSeverityBackground(Object? raw) {
    switch (normalizeAlertSeverity(raw)) {
      case alertSeverityCritical:
        return AppColors.errorBg;
      case alertSeverityWarning:
        return AppColors.warningBg;
      case alertSeverityInfo:
      default:
        return AppColors.infoBg;
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

/// Aktivite alt-tipleri — eventType ile birlikte daha spesifik bir
/// sınıflandırma sağlar. CalendarEvents.subtype kolonuna yazılır (v8).
///
/// Kullanım örneği: scouting eventType'ı altında diseaseObservation
/// alt-tipi → "Gözlem yaptım, hastalık belirtisi gördüm" akışı. note
/// alt-tipi other eventType'ı ile çiftçinin serbest metin notunu temsil eder.
class ActivitySubtype {
  static const diseaseObservation = 'disease_observation';
  static const pestObservation = 'pest_observation';
  static const note = 'note';

  static String? label(String? subtype) {
    switch (subtype) {
      case diseaseObservation:
        return 'Hastalık gözlemi';
      case pestObservation:
        return 'Zararlı gözlemi';
      case note:
        return 'Not';
      default:
        return null;
    }
  }

  static IconData icon(String? subtype) {
    switch (subtype) {
      case diseaseObservation:
        return Icons.coronavirus_rounded;
      case pestObservation:
        return Icons.bug_report_rounded;
      case note:
        return Icons.edit_note_rounded;
      default:
        return Icons.label_outline_rounded;
    }
  }
}

/// Aktivitenin uygulandığı kapsam — CalendarEvents.targetScope kolonuna
/// `name` değeri yazılır (`field` | `zone` | `plant`). null saklama →
/// geriye uyum için tarla varsayılır.
enum ActivityScope { field, zone, plant }

class ActivityScopeMeta {
  static String label(ActivityScope scope) {
    switch (scope) {
      case ActivityScope.field:
        return 'Tüm tarla';
      case ActivityScope.zone:
        return 'Bölge';
      case ActivityScope.plant:
        return 'Bu bitki';
    }
  }

  static IconData icon(ActivityScope scope) {
    switch (scope) {
      case ActivityScope.field:
        return Icons.crop_landscape_rounded;
      case ActivityScope.zone:
        return Icons.dashboard_rounded;
      case ActivityScope.plant:
        return Icons.local_florist_rounded;
    }
  }

  /// DB string → enum dönüşü; tanımsız/null değerlerde field varsayılır.
  static ActivityScope parse(String? value) {
    switch (value) {
      case 'plant':
        return ActivityScope.plant;
      case 'zone':
        return ActivityScope.zone;
      case 'field':
      default:
        return ActivityScope.field;
    }
  }
}
