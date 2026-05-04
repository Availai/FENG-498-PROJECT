import 'package:flutter/material.dart';

import '../theme/app_theme.dart';

/// Tekil bitki durumu — iki yerde kullanılır:
///   • FieldPlantInstances.conditionFlagsJson — JSON liste (çoklu bayrak)
///   • PlantConditionEvents.condition — tek değer (audit log satırı)
///
/// 11 değer kullanıcının istediği kategorilere birebir denk düşer:
/// sağlıklı / hastalık / zararlı / su stresi / besin eksikliği / gelişim
/// geriliği / çiçeklenme / dane dolumu / hasada yakın / cansız / kaldırılmış.
class PlantCondition {
  static const healthy = 'healthy';
  static const diseaseSymptom = 'disease_symptom';
  static const pestRisk = 'pest_risk';
  static const waterStress = 'water_stress';
  static const nutrientDeficiency = 'nutrient_deficiency';
  static const stunted = 'stunted';
  static const flowering = 'flowering';
  static const grainFilling = 'grain_filling';
  static const nearHarvest = 'near_harvest';
  static const dead = 'dead';
  static const removedByUser = 'removed_by_user';

  /// UI'da çoklu seçim chip grid'inde gösterilen sıra.
  static const allFlags = <String>[
    healthy,
    diseaseSymptom,
    pestRisk,
    waterStress,
    nutrientDeficiency,
    stunted,
    flowering,
    grainFilling,
    nearHarvest,
    dead,
    removedByUser,
  ];

  /// "Sağlık" eksenindeki bayraklar — bu ailedeki birden fazla bayrak aynı
  /// anda mantıklı değil (örn. hem sağlıklı hem hastalık olamaz). UI bu
  /// gruptan tek seçim, fenoloji grubundan çoklu seçim kabul eder.
  static const exclusiveHealthFlags = <String>[
    healthy,
    diseaseSymptom,
    pestRisk,
    waterStress,
    nutrientDeficiency,
    stunted,
    dead,
    removedByUser,
  ];

  /// Fenoloji eksenindeki bayraklar — birden fazlası olağan değildir ama
  /// geçiş anlarında çakışabilir (çiçeklenme + dane dolumu kısa örtüşme).
  static const phenologyFlags = <String>[
    flowering,
    grainFilling,
    nearHarvest,
  ];

  static String label(String c) {
    switch (c) {
      case healthy:
        return 'Sağlıklı';
      case diseaseSymptom:
        return 'Hastalık belirtisi';
      case pestRisk:
        return 'Zararlı riski';
      case waterStress:
        return 'Su stresi';
      case nutrientDeficiency:
        return 'Besin eksikliği';
      case stunted:
        return 'Gelişim geriliği';
      case flowering:
        return 'Çiçeklenme';
      case grainFilling:
        return 'Dane dolumu';
      case nearHarvest:
        return 'Hasada yakın';
      case dead:
        return 'Cansız';
      case removedByUser:
        return 'Kaldırıldı';
      default:
        return c;
    }
  }

  static IconData icon(String c) {
    switch (c) {
      case healthy:
        return Icons.favorite_rounded;
      case diseaseSymptom:
        return Icons.coronavirus_rounded;
      case pestRisk:
        return Icons.bug_report_rounded;
      case waterStress:
        return Icons.water_drop_outlined;
      case nutrientDeficiency:
        return Icons.science_outlined;
      case stunted:
        return Icons.trending_down_rounded;
      case flowering:
        return Icons.local_florist_rounded;
      case grainFilling:
        return Icons.grain_rounded;
      case nearHarvest:
        return Icons.agriculture_rounded;
      case dead:
        return Icons.dangerous_rounded;
      case removedByUser:
        return Icons.delete_outline_rounded;
      default:
        return Icons.help_outline_rounded;
    }
  }

  static Color color(String c) {
    switch (c) {
      case healthy:
        return AppColors.emerald;
      case flowering:
      case grainFilling:
        return AppColors.emeraldDark;
      case nearHarvest:
        return AppColors.wheat;
      case waterStress:
      case nutrientDeficiency:
      case stunted:
        return AppColors.warning;
      case diseaseSymptom:
      case pestRisk:
        return AppColors.error;
      case dead:
      case removedByUser:
        return AppColors.textTertiary;
      default:
        return AppColors.textTertiary;
    }
  }

  /// Bayrakların önceliği — listeyi sıralarken ve "ana durum" gösteriminde
  /// kullanılır. Yüksek değer önce gelir.
  static int priority(String c) {
    switch (c) {
      case dead:
      case removedByUser:
        return 100;
      case diseaseSymptom:
        return 80;
      case pestRisk:
        return 75;
      case waterStress:
        return 60;
      case nutrientDeficiency:
        return 55;
      case stunted:
        return 50;
      case nearHarvest:
        return 30;
      case grainFilling:
        return 25;
      case flowering:
        return 20;
      case healthy:
        return 0;
      default:
        return 10;
    }
  }
}
