import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';

import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../data/disease_types.dart';
import '../services/app_providers.dart';
import '../services/task_directive_service.dart';
import '../services/weather_soil_service.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_route.dart';
import '../widgets/tap_scale.dart';
import 'field_detail_screen.dart';
import 'todo_panel_screen.dart';

/// Aktivite Paneli — tarlaların hava + bitki durumuna göre günün ve haftanın
/// önemli bildirimlerini özetler. "Bugün 21:00'da yağmur var, sulamayı atla"
/// türü öneriler burada toplanır. Kullanıcı tıklayınca ilgili tarla detayına
/// gider veya Yapılacaklar paneline atlar.
class ActivityPanelScreen extends ConsumerWidget {
  const ActivityPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldMapsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Aktivite', style: AppText.h2(context)),
        backgroundColor: AppColors.surface,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: () {
              ref.invalidate(fieldMapsProvider);
            },
          ),
        ],
      ),
      body: fieldsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Text(
              'Aktivite verileri yüklenemedi: $e',
              textAlign: TextAlign.center,
              style: AppText.body(context),
            ),
          ),
        ),
        data: (fields) {
          if (fields.isEmpty) {
            return _buildEmpty(context);
          }
          return RefreshIndicator(
            onRefresh: () async {
              ref.invalidate(fieldMapsProvider);
              for (final f in fields) {
                final id = f['id']?.toString();
                if (id != null && id.isNotEmpty) {
                  ref.invalidate(fieldDirectivesSummaryProvider(id));
                  ref.invalidate(fieldPlantInstancesProvider(id));
                  ref.invalidate(fieldActivityLogProvider(id));
                }
              }
              await Future<void>.delayed(const Duration(milliseconds: 300));
            },
            child: ListView(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
              children: [
                _buildHeaderCard(context),
                const SizedBox(height: 14),
                _buildSectionHeader(
                  context,
                  icon: Icons.today_rounded,
                  title: 'BUGÜN',
                  subtitle: _todayString(),
                ),
                const SizedBox(height: 8),
                for (final f in fields)
                  _FieldActivityCard(field: f, scope: _Scope.today),
                const SizedBox(height: 20),
                _buildSectionHeader(
                  context,
                  icon: Icons.calendar_view_week_rounded,
                  title: 'BU HAFTA',
                  subtitle: 'Yaklaşan görevler ve uyarılar',
                ),
                const SizedBox(height: 8),
                for (final f in fields)
                  _FieldActivityCard(field: f, scope: _Scope.thisWeek),
                const SizedBox(height: 20),
                _buildTodoLink(context),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildEmpty(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: AppColors.emerald.withValues(alpha: 0.1),
                shape: BoxShape.circle,
              ),
              child: const Icon(Icons.notifications_off_rounded,
                  size: 56, color: AppColors.emerald),
            ),
            const SizedBox(height: 16),
            Text('Henüz Tarla Yok',
                textAlign: TextAlign.center, style: AppText.h2(context)),
            const SizedBox(height: 6),
            Text(
              'Önce "Tarlalar" ekranından tarlanızı çizin. Hava durumu ve bitki '
              'durumu üzerinden günlük öneriler burada listelenir.',
              textAlign: TextAlign.center,
              style: AppText.body(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.emeraldCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          const Icon(Icons.campaign_rounded, color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Aktivite Akışı',
                  style: AppText.h3(context).copyWith(color: Colors.white),
                ),
                const SizedBox(height: 2),
                Text(
                  'Hava ve bitki durumu üzerine canlı öneriler',
                  style: AppText.xs(context).copyWith(
                    color: Colors.white.withValues(alpha: 0.85),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionHeader(
    BuildContext context, {
    required IconData icon,
    required String title,
    required String subtitle,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(7),
          decoration: BoxDecoration(
            color: AppColors.emerald.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(9),
          ),
          child: Icon(icon, size: 16, color: AppColors.emeraldDark),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emeraldDark,
                  letterSpacing: 1.2,
                ),
              ),
              Text(subtitle, style: AppText.xs(context)),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildTodoLink(BuildContext context) {
    return TapScale(
      onTap: () {
        Navigator.of(context).push(
          AnimatedRoute.slideX(const TodoPanelScreen()),
        );
      },
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.3)),
          boxShadow: AppShadows.sm,
        ),
        child: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                gradient: AppGradients.emeraldCard,
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Icon(Icons.checklist_rtl_rounded,
                  color: Colors.white, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Yapılacaklar Paneline Git',
                      style: AppText.h3(context)),
                  const SizedBox(height: 2),
                  Text(
                    'Bu aktivitelerin canlı öneri listesi ve aksiyonları',
                    style: AppText.xs(context),
                  ),
                ],
              ),
            ),
            const Icon(Icons.arrow_forward_ios_rounded,
                size: 14, color: AppColors.textTertiary),
          ],
        ),
      ),
    );
  }

  static String _todayString() {
    final now = DateTime.now();
    try {
      return DateFormat('d MMMM EEEE', 'tr_TR').format(now);
    } catch (_) {
      return '${now.day}/${now.month}/${now.year}';
    }
  }
}

enum _Scope { today, thisWeek }

class _FieldActivityCard extends ConsumerWidget {
  const _FieldActivityCard({required this.field, required this.scope});

  final Map<String, dynamic> field;
  final _Scope scope;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldId = field['id']?.toString() ?? '';
    final fieldName = field['name']?.toString() ?? 'Tarla';
    if (fieldId.isEmpty) return const SizedBox.shrink();

    final directivesAsync = ref.watch(fieldDirectivesSummaryProvider(fieldId));
    final plantsAsync = ref.watch(fieldPlantInstancesProvider(fieldId));
    final weatherAsync = ref.watch(_fieldHourlyForecastProvider(fieldId));
    final activityAsync = ref.watch(fieldActivityLogProvider(fieldId));

    return directivesAsync.when(
      loading: () => _shell(
        context: context,
        fieldName: fieldName,
        rows: [
          _hintRow(
            color: AppColors.textTertiary,
            icon: Icons.hourglass_top_rounded,
            text: 'Öneriler hesaplanıyor...',
          ),
        ],
      ),
      error: (e, _) => _shell(
        context: context,
        fieldName: fieldName,
        rows: [
          _hintRow(
            color: AppColors.error,
            icon: Icons.error_outline_rounded,
            text: 'Öneriler yüklenemedi.',
          ),
        ],
      ),
      data: (directives) {
        final plants = plantsAsync.valueOrNull ?? const <FieldPlantInstance>[];
        final weather = weatherAsync.valueOrNull;
        final activities =
            activityAsync.valueOrNull ?? const <Map<String, dynamic>>[];
        final notifications = _buildNotifications(
          directives: directives,
          plants: plants,
          weather: weather,
          activities: activities,
          scope: scope,
        );
        if (notifications.isEmpty) return const SizedBox.shrink();
        return _shell(
          context: context,
          fieldName: fieldName,
          rows: notifications,
        );
      },
    );
  }

  List<Widget> _buildNotifications({
    required List<FieldDirective> directives,
    required List<FieldPlantInstance> plants,
    required HourlyForecast? weather,
    required List<Map<String, dynamic>> activities,
    required _Scope scope,
  }) {
    final out = <Widget>[];
    final systemAlertKinds = <String>{};

    for (final alert in _systemAlertsForScope(activities, scope)) {
      final meta = alert['metadata'] as Map<String, dynamic>?;
      final kind = meta?['kind']?.toString() ?? alert['subtype']?.toString();
      if (kind != null && kind.isNotEmpty) systemAlertKinds.add(kind);
      final severity = ActivityType.normalizeAlertSeverity(meta?['severity']);
      out.add(_hintRow(
        color: ActivityType.alertSeverityColor(severity),
        icon: ActivityType.alertSeverityIcon(severity),
        text: _systemAlertText(alert, meta),
        badge: ActivityType.alertSeverityLabel(severity).toUpperCase(),
      ));
    }

    // 1) Bitki sağlık durumu — hasta/cansız bitkiler kritik bildirim.
    if (scope == _Scope.today) {
      final diseasedCount = plants
          .where((p) => p.healthStatus == DiseaseTypes.statusDiseased)
          .length;
      final deadCount =
          plants.where((p) => p.healthStatus == DiseaseTypes.statusDead).length;

      if (diseasedCount > 0) {
        out.add(_hintRow(
          color: AppColors.error,
          icon: Icons.coronavirus_rounded,
          text: '$diseasedCount bitki hasta — yakından izle, yayılım riski',
          badge: 'ACİL',
        ));
      }
      if (deadCount > 0) {
        out.add(_hintRow(
          color: AppColors.textSecondary,
          icon: Icons.dangerous_rounded,
          text: '$deadCount cansız bitki — hasarı kaldır, kalanı koru',
          badge: 'BAKIM',
        ));
      }
    }

    // 2) Hava koşulları — yağmur/sıcak/don akıllı önerileri.
    if (weather != null && !weather.isEmpty) {
      final rainNext24 = weather.rainSumNext(24);
      final minTempNext24 = weather.minTempNext(24);
      final maxTempNext24 = weather.maxTempNext(24);

      if (scope == _Scope.today) {
        // Yağmur → sulamayı ertele
        if (rainNext24 >= 5 && !systemAlertKinds.contains('rainExpected')) {
          final rainHour = _findFirstSignificantRainHour(weather);
          final hourStr = rainHour != null
              ? '${rainHour.hour.toString().padLeft(2, '0')}:00'
              : 'gün içinde';
          out.add(_hintRow(
            color: const Color(0xFF0277BD),
            icon: Icons.umbrella_rounded,
            text: 'Bugün $hourStr civarı '
                'yağmur (~${rainNext24.toStringAsFixed(0)} mm) — sulamayı atla',
            badge: 'BİLGİ',
          ));
        } else if (rainNext24 >= 1) {
          out.add(_hintRow(
            color: const Color(0xFF42A5F5),
            icon: Icons.water_drop_outlined,
            text:
                'Hafif yağmur bekleniyor (${rainNext24.toStringAsFixed(1)} mm)',
          ));
        }

        // Don uyarısı
        if (minTempNext24 != null && minTempNext24 <= 2) {
          out.add(_hintRow(
            color: const Color(0xFF1976D2),
            icon: Icons.ac_unit_rounded,
            text: 'Don riski (~${minTempNext24.toStringAsFixed(0)}°C) — hassas '
                'bitkileri ört',
            badge: 'ACİL',
          ));
        }

        // Aşırı sıcak
        if (maxTempNext24 != null && maxTempNext24 >= 35) {
          out.add(_hintRow(
            color: const Color(0xFFE64A19),
            icon: Icons.wb_sunny_rounded,
            text:
                'Aşırı sıcak (~${maxTempNext24.toStringAsFixed(0)}°C) — sabah erken sula',
            badge: 'UYARI',
          ));
        }
      }
    }

    // 3) Direktifler — bugün vs bu hafta filtrele.
    if (scope == _Scope.today) {
      final urgentToday = directives
          .where((d) => d.urgency >= 2 && d.kind != 'idle')
          .take(3)
          .toList();
      for (final d in urgentToday) {
        out.add(_hintRow(
          color: AppColors.error,
          icon: _iconForKind(d.kind),
          text: d.headline,
          badge: 'BUGÜN',
        ));
      }
    } else {
      final upcoming = directives
          .where((d) => d.urgency == 1 && d.kind != 'idle')
          .take(3)
          .toList();
      for (final d in upcoming) {
        out.add(_hintRow(
          color: const Color(0xFFFFA000),
          icon: _iconForKind(d.kind),
          text: d.headline,
          badge: 'BU HAFTA',
        ));
      }
    }

    return out;
  }

  static IconData _iconForKind(String kind) {
    switch (kind) {
      case 'water_now':
      case 'water_soon':
        return Icons.water_drop_rounded;
      case 'fertilize':
        return Icons.grass_rounded;
      case 'spray':
        return Icons.science_rounded;
      case 'harvest':
        return Icons.agriculture_rounded;
      case 'frost':
        return Icons.ac_unit_rounded;
      case 'heat':
        return Icons.wb_sunny_rounded;
      default:
        return Icons.flag_rounded;
    }
  }

  static DateTime? _findFirstSignificantRainHour(HourlyForecast w) {
    for (final s in w.slots) {
      if (s.rainMm >= 0.5 && s.hour.day == DateTime.now().day) {
        return s.hour;
      }
    }
    return null;
  }

  List<Map<String, dynamic>> _systemAlertsForScope(
    List<Map<String, dynamic>> activities,
    _Scope scope,
  ) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    return activities.where((entry) {
      if (entry['type']?.toString() != ActivityType.systemAlert) {
        return false;
      }
      final date = entry['date'];
      if (date is! DateTime) return false;
      final day = DateTime(date.year, date.month, date.day);
      if (scope == _Scope.today) return day == today;
      return day.isAfter(weekStart.subtract(const Duration(days: 1))) &&
          day != today;
    }).take(3).toList(growable: false);
  }

  String _systemAlertText(
    Map<String, dynamic> entry,
    Map<String, dynamic>? meta,
  ) {
    final message = meta?['message']?.toString().trim();
    if (message != null && message.isNotEmpty) return message;
    final title = meta?['title']?.toString().trim();
    if (title != null && title.isNotEmpty) return title;
    return entry['title']?.toString() ?? 'Sistem uyarısı';
  }

  Widget _shell({
    required BuildContext context,
    required String fieldName,
    required List<Widget> rows,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TapScale(
        scale: 0.97,
        onTap: () {
          Navigator.of(context).push(
            AnimatedRoute.scaleFade(FieldDetailScreen(fieldData: field)),
          );
        },
        child: Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
            color: AppColors.surface,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AppColors.border),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.landscape_rounded,
                      size: 16, color: AppColors.emeraldDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fieldName,
                      style: AppText.h3(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      color: AppColors.textTertiary, size: 18),
                ],
              ),
              const SizedBox(height: 10),
              ...rows,
            ],
          ),
        ),
      ),
    );
  }

  Widget _hintRow({
    required Color color,
    required IconData icon,
    required String text,
    String? badge,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(5),
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(7),
            ),
            child: Icon(icon, size: 14, color: color),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.only(top: 2),
              child: Text(
                text,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textPrimary,
                  height: 1.3,
                ),
              ),
            ),
          ),
          if (badge != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(
                badge,
                style: TextStyle(
                  fontSize: 9,
                  fontWeight: FontWeight.w800,
                  color: color,
                  letterSpacing: 0.5,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}

/// Tarla bazında saatlik forecast cache'i — Aktivite paneli birden çok
/// kart için aynı cache'i okur. Koordinat yoksa null döner.
final _fieldHourlyForecastProvider = FutureProvider.family
    .autoDispose<HourlyForecast?, String>((ref, fieldId) async {
  final repo = ref.watch(localDataRepositoryProvider);
  final fieldMap = await repo.loadFieldById(fieldId);
  final lat = (fieldMap?['latitude'] as num?)?.toDouble();
  final lng = (fieldMap?['longitude'] as num?)?.toDouble();
  if (lat == null || lng == null) return null;
  try {
    return await ref
        .watch(weatherSoilServiceProvider)
        .fetchHourlyForecast(latitude: lat, longitude: lng)
        .timeout(const Duration(seconds: 8));
  } catch (_) {
    return null;
  }
});
