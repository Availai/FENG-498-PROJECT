/// 7 Günlük Saatlik Hava Tahmini — Alt-Sheet
///
/// T.C. Meteoroloji Genel Müdürlüğü (MGM) gerçek istasyon tahminleri öncelikli,
/// kapsanmayan saatler için Open-Meteo modeli ile tamamlanır. Kaynak rozeti
/// her zaman ekranın üstünde gösterilir — kullanıcı verinin nereden geldiğini
/// görür.
library;

import 'package:flutter/material.dart';

import '../services/unified_weather_service.dart';
import '../theme/app_theme.dart';
import 'fade_slide_in.dart';

/// Sheet'i açan kısayol.
Future<void> showHourlyWeatherSheet(
  BuildContext context, {
  required double lat,
  required double lon,
}) {
  return showModalBottomSheet(
    context: context,
    backgroundColor: AppColors.bg,
    isScrollControlled: true,
    useSafeArea: true,
    constraints: BoxConstraints(
      maxHeight: MediaQuery.of(context).size.height * 0.88,
    ),
    shape: const RoundedRectangleBorder(
      borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
    ),
    builder: (_) => _HourlyWeatherSheet(lat: lat, lon: lon),
  );
}

class _HourlyWeatherSheet extends StatefulWidget {
  const _HourlyWeatherSheet({required this.lat, required this.lon});
  final double lat;
  final double lon;

  @override
  State<_HourlyWeatherSheet> createState() => _HourlyWeatherSheetState();
}

class _HourlyWeatherSheetState extends State<_HourlyWeatherSheet> {
  late Future<UnifiedHourlyForecast> _future;

  @override
  void initState() {
    super.initState();
    _future = UnifiedWeatherService.fetchHourly(
      lat: widget.lat,
      lon: widget.lon,
    );
  }

  void _refresh() {
    setState(() {
      _future = UnifiedWeatherService.fetchHourly(
        lat: widget.lat,
        lon: widget.lon,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _SheetGrip(),
          const SizedBox(height: 6),
          _SheetTitle(onRefresh: _refresh),
          const Divider(height: 1, color: AppColors.divider),
          Flexible(
            child: FutureBuilder<UnifiedHourlyForecast>(
              future: _future,
              builder: (context, snap) {
                if (snap.connectionState != ConnectionState.done) {
                  return const _LoadingState();
                }
                if (snap.hasError || snap.data == null || snap.data!.isEmpty) {
                  return _ErrorState(onRetry: _refresh);
                }
                return _ForecastList(forecast: snap.data!);
              },
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Header parçaları
// ─────────────────────────────────────────────────────────────────────────────

class _SheetGrip extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      width: 42,
      height: 4,
      margin: const EdgeInsets.only(top: 10),
      decoration: BoxDecoration(
        color: AppColors.borderDark,
        borderRadius: BorderRadius.circular(2),
      ),
    );
  }
}

class _SheetTitle extends StatelessWidget {
  const _SheetTitle({required this.onRefresh});
  final VoidCallback onRefresh;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 10, 8, 12),
      child: Row(
        children: [
          const Icon(Icons.schedule_rounded, color: AppColors.emeraldDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Saatlik Hava — 7 Gün',
              style: AppText.h3(context),
            ),
          ),
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh_rounded,
                color: AppColors.textSecondary),
            onPressed: onRefresh,
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// State'ler
// ─────────────────────────────────────────────────────────────────────────────

class _LoadingState extends StatelessWidget {
  const _LoadingState();

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 40),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(color: AppColors.emerald),
          const SizedBox(height: 14),
          Text(
            'MGM ve yedek kaynak alınıyor…',
            style: AppText.sm(context),
          ),
        ],
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  const _ErrorState({required this.onRetry});
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(28),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.cloud_off_rounded,
              size: 42, color: AppColors.textTertiary),
          const SizedBox(height: 10),
          Text(
            'Hava verisi alınamadı',
            style: AppText.bodyMd(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 4),
          Text(
            'İnternet bağlantını kontrol edip tekrar dene. MGM ve Open-Meteo '
            'sunucularına ulaşılamıyor olabilir.',
            style: AppText.sm(context),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: onRetry,
            icon: const Icon(Icons.refresh_rounded),
            label: const Text('Tekrar dene'),
            style: FilledButton.styleFrom(
              backgroundColor: AppColors.emerald,
            ),
          ),
        ],
      ),
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Liste
// ─────────────────────────────────────────────────────────────────────────────

class _ForecastList extends StatelessWidget {
  const _ForecastList({required this.forecast});
  final UnifiedHourlyForecast forecast;

  @override
  Widget build(BuildContext context) {
    final grouped = forecast.groupedByDay();
    final dayEntries = grouped.entries.toList();

    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      children: [
        _SourceBadge(forecast: forecast),
        const SizedBox(height: 12),
        for (var i = 0; i < dayEntries.length; i++)
          FadeSlideIn(
            index: i,
            child: _DaySection(
              day: dayEntries[i].key,
              points: dayEntries[i].value,
              isToday: _isSameDay(dayEntries[i].key, DateTime.now()),
            ),
          ),
        const SizedBox(height: 8),
        _SafetyFooter(),
      ],
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;
}

// ─────────────────────────────────────────────────────────────────────────────
// Kaynak rozeti
// ─────────────────────────────────────────────────────────────────────────────

class _SourceBadge extends StatelessWidget {
  const _SourceBadge({required this.forecast});
  final UnifiedHourlyForecast forecast;

  @override
  Widget build(BuildContext context) {
    final src = forecast.source;
    final mgmActive = src.contains('MGM');
    final primaryLabel = mgmActive
        ? 'MGM (T.C. Meteoroloji Genel Müdürlüğü)'
        : 'Open-Meteo (açık veri)';
    final descr = mgmActive
        ? src == 'MGM'
            ? 'Gerçek istasyon verisi — Türkiye için en güvenilir resmi kaynak.'
            : 'MGM resmi istasyon verisi + uzak saatler için Open-Meteo modeli.'
        : 'MGM istasyonuna ulaşılamadı; ücretsiz Open-Meteo modeli kullanıldı.';
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: mgmActive ? AppColors.mint : AppColors.surfaceAlt,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: (mgmActive ? AppColors.emeraldDark : AppColors.borderDark)
              .withValues(alpha: 0.3),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            mgmActive ? Icons.verified_rounded : Icons.cloud_queue_rounded,
            color: mgmActive ? AppColors.emeraldDark : AppColors.textSecondary,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Kaynak: $primaryLabel',
                  style: AppText.bodyMd(context).copyWith(fontSize: 14),
                ),
                const SizedBox(height: 2),
                Text(descr, style: AppText.xs(context)),
                const SizedBox(height: 4),
                Row(
                  children: [
                    const Icon(Icons.place_outlined,
                        size: 12, color: AppColors.textTertiary),
                    const SizedBox(width: 4),
                    Expanded(
                      child: Text(
                        '${forecast.stationLabel} · ${_fmtTime(forecast.fetchedAt)} alındı',
                        style: AppText.xs(context),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  static String _fmtTime(DateTime t) {
    final hh = t.hour.toString().padLeft(2, '0');
    final mm = t.minute.toString().padLeft(2, '0');
    return '$hh:$mm';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Gün bölümü
// ─────────────────────────────────────────────────────────────────────────────

class _DaySection extends StatefulWidget {
  const _DaySection({
    required this.day,
    required this.points,
    required this.isToday,
  });

  final DateTime day;
  final List<UnifiedHourlyPoint> points;
  final bool isToday;

  @override
  State<_DaySection> createState() => _DaySectionState();
}

class _DaySectionState extends State<_DaySection> {
  late bool _expanded;

  @override
  void initState() {
    super.initState();
    _expanded = widget.isToday; // Bugün varsayılan açık, diğerleri kapalı
  }

  @override
  Widget build(BuildContext context) {
    final temps = widget.points.map((p) => p.tempC).toList();
    final minT = temps.reduce((a, b) => a < b ? a : b);
    final maxT = temps.reduce((a, b) => a > b ? a : b);
    final maxRain = widget.points
        .map((p) => p.precipMm)
        .fold<double>(0, (a, b) => b > a ? b : a);

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      clipBehavior: Clip.antiAlias,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          InkWell(
            onTap: () => setState(() => _expanded = !_expanded),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Container(
                    width: 38,
                    height: 38,
                    alignment: Alignment.center,
                    decoration: BoxDecoration(
                      color:
                          widget.isToday ? AppColors.emerald : AppColors.mint,
                      borderRadius: AppRadius.sm,
                    ),
                    child: Text(
                      widget.day.day.toString(),
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: widget.isToday
                            ? AppColors.textOnDark
                            : AppColors.emeraldDark,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.isToday
                              ? 'Bugün · ${_dayLabel(widget.day)}'
                              : _dayLabel(widget.day),
                          style: AppText.bodyMd(context),
                        ),
                        const SizedBox(height: 2),
                        Text(
                          '${widget.points.length} saatlik nokta · '
                          'min ${minT.toStringAsFixed(0)}° · '
                          'maks ${maxT.toStringAsFixed(0)}°'
                          '${maxRain > 0.1 ? ' · ${maxRain.toStringAsFixed(1)} mm yağış' : ''}',
                          style: AppText.xs(context),
                        ),
                      ],
                    ),
                  ),
                  AnimatedRotation(
                    turns: _expanded ? 0.5 : 0,
                    duration: const Duration(milliseconds: 200),
                    child: const Icon(Icons.expand_more_rounded,
                        color: AppColors.textTertiary),
                  ),
                ],
              ),
            ),
          ),
          AnimatedSize(
            duration: const Duration(milliseconds: 220),
            curve: Curves.easeOutCubic,
            alignment: Alignment.topCenter,
            child: _expanded
                ? Column(
                    children: [
                      const Divider(height: 1, color: AppColors.divider),
                      for (final p in widget.points)
                        _HourRow(point: p, isToday: widget.isToday),
                    ],
                  )
                : const SizedBox.shrink(),
          ),
        ],
      ),
    );
  }

  static const _days = [
    'Pazartesi',
    'Salı',
    'Çarşamba',
    'Perşembe',
    'Cuma',
    'Cumartesi',
    'Pazar',
  ];
  static const _months = [
    'Ocak',
    'Şubat',
    'Mart',
    'Nisan',
    'Mayıs',
    'Haziran',
    'Temmuz',
    'Ağustos',
    'Eylül',
    'Ekim',
    'Kasım',
    'Aralık',
  ];

  static String _dayLabel(DateTime d) {
    final wd = _days[(d.weekday - 1).clamp(0, 6)];
    final m = _months[(d.month - 1).clamp(0, 11)];
    return '$wd, ${d.day} $m';
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Saat satırı
// ─────────────────────────────────────────────────────────────────────────────

class _HourRow extends StatelessWidget {
  const _HourRow({required this.point, required this.isToday});
  final UnifiedHourlyPoint point;
  final bool isToday;

  @override
  Widget build(BuildContext context) {
    final hh = point.time.hour.toString().padLeft(2, '0');
    final isCurrent = isToday &&
        point.time.hour == DateTime.now().hour &&
        _isSameDay(point.time, DateTime.now());
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: isCurrent
            ? AppColors.mint.withValues(alpha: 0.5)
            : Colors.transparent,
        border: const Border(
          top: BorderSide(color: AppColors.divider, width: 0.5),
        ),
      ),
      child: Row(
        children: [
          SizedBox(
            width: 44,
            child: Text(
              '$hh:00',
              style: AppText.bodyMd(context).copyWith(fontSize: 14),
            ),
          ),
          Icon(_iconFor(point.description),
              color: _iconColor(point.description), size: 22),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              point.description,
              style: AppText.sm(context),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (point.precipProbPct != null && point.precipProbPct! > 0) ...[
            const Icon(Icons.water_drop_rounded,
                size: 13, color: AppColors.frost),
            const SizedBox(width: 2),
            Text('%${point.precipProbPct}',
                style: AppText.xs(context).copyWith(color: AppColors.frost)),
            const SizedBox(width: 8),
          ] else if (point.precipMm > 0.1) ...[
            const Icon(Icons.water_drop_rounded,
                size: 13, color: AppColors.frost),
            const SizedBox(width: 2),
            Text('${point.precipMm.toStringAsFixed(1)}mm',
                style: AppText.xs(context).copyWith(color: AppColors.frost)),
            const SizedBox(width: 8),
          ],
          Row(
            children: [
              const Icon(Icons.air_rounded,
                  size: 13, color: AppColors.textTertiary),
              const SizedBox(width: 2),
              Text(point.windMs.toStringAsFixed(1), style: AppText.xs(context)),
            ],
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 46,
            child: Text(
              '${point.tempC.toStringAsFixed(0)}°',
              textAlign: TextAlign.right,
              style: AppText.bodyMd(context).copyWith(
                fontSize: 16,
                color: _tempColor(point.tempC),
              ),
            ),
          ),
        ],
      ),
    );
  }

  static bool _isSameDay(DateTime a, DateTime b) =>
      a.year == b.year && a.month == b.month && a.day == b.day;

  static IconData _iconFor(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('açık')) return Icons.wb_sunny_rounded;
    if (d.contains('az bulutlu')) return Icons.wb_cloudy_outlined;
    if (d.contains('parçalı')) return Icons.cloud_queue_rounded;
    if (d.contains('çok bulutlu') || d.contains('kapalı')) {
      return Icons.cloud_rounded;
    }
    if (d.contains('sağanak') || d.contains('yağmur')) {
      return Icons.umbrella_rounded;
    }
    if (d.contains('çisenti')) return Icons.grain_rounded;
    if (d.contains('kar')) return Icons.ac_unit_rounded;
    if (d.contains('sis') || d.contains('pus')) return Icons.foggy;
    if (d.contains('fırtına') || d.contains('gök gürül')) {
      return Icons.thunderstorm_rounded;
    }
    if (d.contains('rüzgâr') || d.contains('rüzgar')) return Icons.air_rounded;
    return Icons.cloud_queue_rounded;
  }

  static Color _iconColor(String desc) {
    final d = desc.toLowerCase();
    if (d.contains('açık')) return AppColors.warning;
    if (d.contains('yağmur') ||
        d.contains('sağanak') ||
        d.contains('çisenti')) {
      return AppColors.frost;
    }
    if (d.contains('kar')) return AppColors.info;
    if (d.contains('fırtına')) return AppColors.error;
    return AppColors.textSecondary;
  }

  static Color _tempColor(double t) {
    if (t >= 32) return AppColors.error;
    if (t >= 25) return AppColors.warning;
    if (t <= 0) return AppColors.frost;
    return AppColors.textPrimary;
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// Footer — kaynak güvencesi
// ─────────────────────────────────────────────────────────────────────────────

class _SafetyFooter extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: AppColors.infoBg,
        borderRadius: AppRadius.sm,
        border: Border.all(color: AppColors.info.withValues(alpha: 0.25)),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.info_outline_rounded,
              color: AppColors.info, size: 18),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'MGM (servis.mgm.gov.tr) Türkiye için resmi gözlem ve tahmin '
              'kaynağıdır. MGM saatlik tahminleri yaklaşık 3 güne kadar '
              'kapsar; daha uzun saatler için açık veri Open-Meteo '
              '(api.open-meteo.com) modeli ile tamamlanır. Kritik tarım '
              'kararları için en güncel MGM uyarılarını ve il/ilçe '
              'müdürlüğü teknik notlarını da kontrol edin.',
              style: AppText.xs(context)
                  .copyWith(color: AppColors.textPrimary, height: 1.45),
            ),
          ),
        ],
      ),
    );
  }
}
