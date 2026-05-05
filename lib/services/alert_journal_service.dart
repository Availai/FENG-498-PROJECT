import '../data/activity_types.dart';
import 'guide_engine.dart';
import 'local_data_repository.dart';

/// Rehber, hava taraması ve büyüme motorundan gelen sistem uyarılarını
/// `CalendarEvents` günlüğüne yazar. Aynı tarla + aynı uyarı anahtarı 24 saat
/// içinde tekrar yazılmaz; bildirimler sık çalışsa bile günlük şişmez.
class AlertJournalService {
  const AlertJournalService({
    required LocalDataRepository repository,
    this.dedupWindow = const Duration(hours: 24),
  }) : _repo = repository;

  final LocalDataRepository _repo;
  final Duration dedupWindow;

  Future<bool> recordGuideResult({
    required String fieldId,
    required String fieldName,
    required GuideResult result,
  }) async {
    var wroteAny = false;
    for (final alert in result.alerts) {
      final wrote = await recordGuideAlert(
        fieldId: fieldId,
        fieldName: fieldName,
        alert: alert,
      );
      wroteAny = wroteAny || wrote;
    }
    return wroteAny;
  }

  Future<bool> recordGuideAlert({
    required String fieldId,
    required String fieldName,
    required EnvAlert alert,
  }) {
    final severity = _severityName(alert.severity);
    return recordSystemAlert(
      fieldId: fieldId,
      alertKey: 'guide_${alert.kind.name}_$severity',
      title: alert.title,
      message: alert.message,
      severity: severity,
      origin: 'guide',
      icon: alert.icon,
      fieldName: fieldName,
      metadata: {
        'kind': alert.kind.name,
      },
    );
  }

  Future<bool> recordWeatherAlert({
    required String fieldId,
    required String fieldName,
    required String alertKey,
    required String title,
    required String message,
    required String severity,
    String? icon,
    Map<String, dynamic>? metadata,
  }) {
    return recordSystemAlert(
      fieldId: fieldId,
      alertKey: 'weather_$alertKey',
      title: title,
      message: message,
      severity: severity,
      origin: 'weather',
      icon: icon,
      fieldName: fieldName,
      metadata: metadata,
    );
  }

  Future<bool> recordGrowthStageTransition({
    required String fieldId,
    required String cropId,
    required String cropName,
    required String previousStageKey,
    required String stageKey,
    required String stageLabel,
    double? accumulatedGdd,
    DateTime? at,
  }) {
    final previousLabel = GrowthEngineStageLabels.label(previousStageKey);
    return recordSystemAlert(
      fieldId: fieldId,
      cropId: cropId,
      alertKey: 'growth_stage_${cropId}_$stageKey',
      title: '$cropName yeni döneme geçti',
      message:
          '$cropName artık $stageLabel döneminde. Önceki dönem: $previousLabel. Rehber bakım önerilerini bu yeni döneme göre güncelledi.',
      severity: ActivityType.alertSeverityInfo,
      origin: 'growth',
      icon: '🌱',
      cropName: cropName,
      at: at,
      metadata: {
        'previous_stage_key': previousStageKey,
        'previous_stage_label': previousLabel,
        'stage_key': stageKey,
        'stage_label': stageLabel,
        if (accumulatedGdd != null) 'accumulated_gdd': accumulatedGdd,
      },
    );
  }

  Future<bool> recordSystemAlert({
    required String fieldId,
    String? cropId,
    required String alertKey,
    required String title,
    required String message,
    required String severity,
    required String origin,
    String? icon,
    String? fieldName,
    String? cropName,
    DateTime? at,
    Map<String, dynamic>? metadata,
  }) async {
    final cleanFieldId = fieldId.trim();
    final cleanAlertKey = alertKey.trim();
    if (cleanFieldId.isEmpty || cleanAlertKey.isEmpty) return false;

    try {
      final exists = await _repo.hasRecentSystemAlert(
        fieldId: cleanFieldId,
        alertKey: cleanAlertKey,
        within: dedupWindow,
      );
      if (exists) return false;

      final normalizedSeverity = ActivityType.normalizeAlertSeverity(severity);
      final meta = <String, dynamic>{
        ...?metadata,
        'alert_key': cleanAlertKey,
        'title': title,
        'message': message,
        'note': message,
        'severity': normalizedSeverity,
        'severity_label': ActivityType.alertSeverityLabel(normalizedSeverity),
        'origin': origin,
        if (icon != null && icon.trim().isNotEmpty) 'icon': icon.trim(),
        if (fieldName != null && fieldName.trim().isNotEmpty)
          'field_name': fieldName.trim(),
        if (cropName != null && cropName.trim().isNotEmpty)
          'crop_name': cropName.trim(),
      };

      await _repo.addCalendarEvent(
        fieldId: cleanFieldId,
        cropId: cropId,
        title: title,
        eventType: ActivityType.systemAlert,
        eventDate: at ?? DateTime.now(),
        source: 'system',
        metadata: meta,
        subtype: cleanAlertKey,
        noteText: message,
      );
      return true;
    } catch (_) {
      return false;
    }
  }

  static String _severityName(AlertSeverity severity) {
    switch (severity) {
      case AlertSeverity.critical:
        return ActivityType.alertSeverityCritical;
      case AlertSeverity.warning:
        return ActivityType.alertSeverityWarning;
      case AlertSeverity.info:
        return ActivityType.alertSeverityInfo;
    }
  }
}

/// UI ve servislerin aynı fenoloji etiketlerini kullanması için küçük yardımcı.
class GrowthEngineStageLabels {
  const GrowthEngineStageLabels._();

  static String label(String? key) {
    switch (key) {
      case 'cimlenme':
        return 'Çimlenme';
      case 'vejetatif':
      case 'vegetatif':
        return 'Vejetatif';
      case 'ciceklenme':
        return 'Çiçeklenme';
      case 'meyve_dolumu':
      case 'meyvelenme':
        return 'Meyve/tane dolumu';
      case 'olgunlasma':
        return 'Olgunlaşma';
      case 'hasat':
        return 'Hasat';
      default:
        return key == null || key.isEmpty ? 'Bilinmeyen dönem' : key;
    }
  }
}
