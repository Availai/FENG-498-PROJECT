/// HarvestOracleScreen — Hava Durumu & Hasat Penceresi (Premium UI)
library;

import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import '../models/harvest_oracle_models.dart';
import '../models/seed_models.dart';
import '../services/harvest_oracle.dart';
import '../services/offline_rule_engine.dart' show RiskLevel;
import '../theme/app_theme.dart';
import '../widgets/glass_panel.dart';
import '../widgets/help_panel.dart';

class HarvestOracleScreen extends StatefulWidget {
  final double lat;
  final double lon;
  final SeedVariety? variety;
  final TurkishRegion region;

  const HarvestOracleScreen({
    super.key,
    this.lat = 41.01,
    this.lon = 28.97,
    this.variety,
    this.region = TurkishRegion.trakya,
  });

  @override
  State<HarvestOracleScreen> createState() => _HarvestOracleScreenState();
}

class _HarvestOracleScreenState extends State<HarvestOracleScreen> {
  bool _loading = false;
  String? _error;
  List<WeatherEventAlert> _alerts = [];
  List<HarvestWindow> _windows = [];
  List<HourlyForecastRecord> _forecast = [];

  @override
  void initState() {
    super.initState();
    _fetch();
  }

  Future<void> _fetch() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      if (widget.variety != null) {
        final result = await HarvestOracle.analyze(
          lat: widget.lat,
          lon: widget.lon,
          variety: widget.variety!,
          remainingDays: 30,
          region: widget.region,
        );
        setState(() {
          _alerts = result.alerts;
          _windows = result.windows;
          _forecast = result.forecast;
        });
      } else {
        final forecast =
            await HarvestOracle.fetchForecast(lat: widget.lat, lon: widget.lon);
        setState(() {
          _forecast = forecast;
          _alerts = HarvestOracle.detectEvents(
              forecast: forecast, region: widget.region);
        });
      }
    } catch (e) {
      setState(() {
        _error = e.toString();
      });
    } finally {
      setState(() {
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Hasat Oracle'),
        actions: [
          if (!_loading)
            IconButton(
              icon: const Icon(Icons.refresh_rounded),
              onPressed: _fetch,
            ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.harvestOracle),
          ),
        ],
      ),
      body: _loading
          ? const _LoadingView()
          : _error != null
              ? _ErrorView(error: _error!, onRetry: _fetch)
              : _Body(alerts: _alerts, windows: _windows, forecast: _forecast),
    );
  }
}

class _LoadingView extends StatelessWidget {
  const _LoadingView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const CircularProgressIndicator(
              color: AppColors.emerald, strokeWidth: 2),
          const SizedBox(height: 16),
          Text('Hava verileri alınıyor…', style: AppText.sm(context)),
        ],
      ),
    );
  }
}

class _ErrorView extends StatelessWidget {
  final String error;
  final VoidCallback onRetry;
  const _ErrorView({required this.error, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 72,
              height: 72,
              decoration: BoxDecoration(
                  color: AppColors.errorBg, borderRadius: AppRadius.lg),
              child: const Center(
                  child: Icon(Icons.cloud_off_rounded,
                      color: AppColors.error, size: 36)),
            ),
            const SizedBox(height: 16),
            Text('Hava verisi alınamadı', style: AppText.h3(context)),
            const SizedBox(height: 6),
            Text(error,
                style: AppText.sm(context), textAlign: TextAlign.center),
            const SizedBox(height: 20),
            ElevatedButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Tekrar Dene'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Ana İçerik ────────────────────────────────────────────────────────────

class _Body extends StatelessWidget {
  final List<WeatherEventAlert> alerts;
  final List<HarvestWindow> windows;
  final List<HourlyForecastRecord> forecast;

  const _Body(
      {required this.alerts, required this.windows, required this.forecast});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
      children: [
        if (forecast.isNotEmpty) ...[
          _ForecastStrip(forecast: forecast),
          const SizedBox(height: 20),
        ],
        if (alerts.isNotEmpty) ...[
          AppSectionHeader(
              title: 'Hava Uyarıları',
              subtitle: '${alerts.length} aktif uyarı'),
          const SizedBox(height: 10),
          ...alerts.map((a) => _AlertCard(alert: a)),
          const SizedBox(height: 20),
        ],
        if (windows.isNotEmpty) ...[
          AppSectionHeader(
              title: 'Hasat Pencereleri',
              subtitle: 'Önümüzdeki 7 gün için optimal aralıklar'),
          const SizedBox(height: 10),
          ...windows.map((w) => _WindowCard(window: w)),
        ],
        if (alerts.isEmpty && windows.isEmpty && forecast.isNotEmpty) ...[
          const SizedBox(height: 32),
          Center(
            child: Column(children: [
              const Text('✅', style: TextStyle(fontSize: 48)),
              const SizedBox(height: 12),
              Text('Aktif uyarı yok', style: AppText.h3(context)),
              const SizedBox(height: 6),
              Text('Hava koşulları normal seyrediyor.',
                  style: AppText.sm(context)),
            ]),
          ),
        ],
      ],
    );
  }
}

// ── 7 Günlük Tahmin Şeridi ────────────────────────────────────────────────

class _ForecastStrip extends StatelessWidget {
  final List<HourlyForecastRecord> forecast;
  const _ForecastStrip({required this.forecast});

  static const _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  @override
  Widget build(BuildContext context) {
    final days = <HourlyForecastRecord>[];
    final seen = <String>{};
    for (final h in forecast) {
      final key = '${h.time.year}-${h.time.month}-${h.time.day}';
      if (!seen.contains(key) && h.time.hour >= 11 && h.time.hour <= 13) {
        days.add(h);
        seen.add(key);
      }
      if (days.length >= 7) break;
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('7 Günlük Tahmin', style: AppText.h3(context)),
        const SizedBox(height: 10),
        SizedBox(
          height: 96,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: days.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (_, i) => _DayCell(
                record: days[i], dayName: _dayNames[days[i].time.weekday - 1]),
          ),
        ),
      ],
    );
  }
}

class _DayCell extends StatelessWidget {
  final HourlyForecastRecord record;
  final String dayName;
  const _DayCell({required this.record, required this.dayName});

  @override
  Widget build(BuildContext context) {
    final t = record.tempC;
    final rain = record.precipMm;
    final isToday = DateTime.now().day == record.time.day;

    return Container(
      width: 64,
      decoration: BoxDecoration(
        color: isToday ? AppColors.emerald : AppColors.surface,
        borderRadius: AppRadius.md,
        border:
            Border.all(color: isToday ? AppColors.emerald : AppColors.border),
        boxShadow: isToday ? AppShadows.md : AppShadows.sm,
      ),
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(
            dayName,
            style: GoogleFonts.inter(
              fontSize: 10,
              fontWeight: FontWeight.w600,
              color: isToday ? Colors.white : AppColors.textSecondary,
            ),
          ),
          Text(
            _weatherIcon(t, rain),
            style: const TextStyle(fontSize: 20),
          ),
          Text(
            '${t.toStringAsFixed(0)}°',
            style: GoogleFonts.outfit(
              fontSize: 16,
              fontWeight: FontWeight.w700,
              color: isToday ? Colors.white : _tempColor(t),
            ),
          ),
          if (rain > 0.5)
            Text(
              '${rain.toStringAsFixed(0)}mm',
              style: GoogleFonts.inter(
                fontSize: 9,
                color: isToday ? Colors.white70 : AppColors.info,
              ),
            )
          else
            const SizedBox(height: 13),
        ],
      ),
    );
  }

  String _weatherIcon(double t, double rain) {
    if (rain > 10) return '🌧️';
    if (rain > 2) return '🌦️';
    if (t > 35) return '🥵';
    if (t < 0) return '🥶';
    if (t < 5) return '❄️';
    return '☀️';
  }

  Color _tempColor(double t) {
    if (t > 35) return AppColors.error;
    if (t < 0) return AppColors.info;
    return AppColors.textPrimary;
  }
}

// ── Uyarı Kartı ───────────────────────────────────────────────────────────

class _AlertCard extends StatefulWidget {
  final WeatherEventAlert alert;
  const _AlertCard({required this.alert});

  @override
  State<_AlertCard> createState() => _AlertCardState();
}

class _AlertCardState extends State<_AlertCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulse;

  @override
  void initState() {
    super.initState();
    _pulse = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 1200));
    if (widget.alert.riskLevel == RiskLevel.critical) {
      _pulse.repeat(reverse: true);
    }
  }

  @override
  void dispose() {
    _pulse.dispose();
    super.dispose();
  }

  Color get _levelColor {
    switch (widget.alert.riskLevel) {
      case RiskLevel.critical:
        return AppColors.error;
      case RiskLevel.warning:
        return AppColors.warning;
      case RiskLevel.info:
        return AppColors.info;
      case RiskLevel.ok:
        return AppColors.success;
    }
  }

  Color get _levelBg {
    switch (widget.alert.riskLevel) {
      case RiskLevel.critical:
        return AppColors.errorBg;
      case RiskLevel.warning:
        return AppColors.warningBg;
      case RiskLevel.info:
        return AppColors.infoBg;
      case RiskLevel.ok:
        return AppColors.successBg;
    }
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _pulse,
      builder: (_, child) {
        return Padding(
          padding: const EdgeInsets.only(bottom: 12),
          child: GlassPanel(
            padding: const EdgeInsets.all(16),
            borderRadius: 16,
            baseColor: _levelColor,
            child: child!,
          ),
        );
      },
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(children: [
            Container(
              width: 44,
              height: 44,
              decoration:
                  BoxDecoration(color: _levelBg, borderRadius: AppRadius.sm),
              child: Center(
                  child: Text(widget.alert.event.emoji,
                      style: const TextStyle(fontSize: 22))),
            ),
            const SizedBox(width: 14),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(widget.alert.event.labelTr,
                      style: AppText.h3(context).copyWith(color: _levelColor)),
                  Text(widget.alert.urgencyLabel,
                      style: AppText.xs(context).copyWith(color: _levelColor)),
                ],
              ),
            ),
            AppTag(widget.alert.urgencyLabel,
                color: _levelColor, bgColor: _levelBg),
          ]),
          const SizedBox(height: 12),
          Text(widget.alert.descriptionTr, style: AppText.body(context)),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
            decoration:
                BoxDecoration(color: _levelBg, borderRadius: AppRadius.sm),
            child: Row(children: [
              Icon(Icons.arrow_forward_ios_rounded,
                  size: 12, color: _levelColor),
              const SizedBox(width: 10),
              Expanded(
                  child: Text(widget.alert.actionTr,
                      style: AppText.sm(context).copyWith(color: _levelColor))),
            ]),
          ),
        ],
      ),
    );
  }
}

// ── Hasat Penceresi Kartı ─────────────────────────────────────────────────

class _WindowCard extends StatelessWidget {
  final HarvestWindow window;
  const _WindowCard({required this.window});

  @override
  Widget build(BuildContext context) {
    final score = window.confidenceScore;
    final isGood = window.isOptimal;
    final color = isGood
        ? AppColors.success
        : window.hasRisk
            ? AppColors.error
            : AppColors.warning;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: GlassPanel(
        padding: const EdgeInsets.all(16),
        borderRadius: 16,
        child: Row(
          children: [
            // Confidence ring
            SizedBox(
              width: 56,
              height: 56,
              child: Stack(
                alignment: Alignment.center,
                children: [
                  CustomPaint(
                    size: const Size(56, 56),
                    painter: _RingPainter(score: score, color: color),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        '%${(score * 100).round()}',
                        style: GoogleFonts.outfit(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                            color: color),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Expanded(
                        child: Text(window.daysLabel,
                            style: AppText.h3(context).copyWith(color: color))),
                    AppTag(window.confidenceLabel,
                        color: color, bgColor: color.withValues(alpha: 0.1)),
                  ]),
                  const SizedBox(height: 6),
                  Wrap(spacing: 12, children: [
                    _WBit(Icons.thermostat_outlined,
                        '${window.avgTempC.toStringAsFixed(0)}°C'),
                    _WBit(Icons.water_drop_outlined,
                        '${window.totalRainMm.toStringAsFixed(0)} mm'),
                    _WBit(Icons.air_outlined,
                        '${window.avgWindMs.toStringAsFixed(1)} m/s'),
                    _WBit(Icons.opacity_outlined,
                        '%${window.avgHumidityPct.round()}'),
                  ]),
                  const SizedBox(height: 8),
                  Text(window.recommendationTr,
                      style: AppText.body(context).copyWith(fontSize: 13),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _WBit extends StatelessWidget {
  final IconData icon;
  final String value;
  const _WBit(this.icon, this.value);

  @override
  Widget build(BuildContext context) {
    return Row(mainAxisSize: MainAxisSize.min, children: [
      Icon(icon, size: 12, color: AppColors.textTertiary),
      const SizedBox(width: 3),
      Text(value, style: AppText.sm(context)),
    ]);
  }
}

class _RingPainter extends CustomPainter {
  final double score;
  final Color color;
  const _RingPainter({required this.score, required this.color});

  @override
  void paint(Canvas canvas, Size size) {
    final cx = size.width / 2;
    final cy = size.height / 2;
    final r = size.width / 2 - 4;
    canvas.drawCircle(
        Offset(cx, cy),
        r,
        Paint()
          ..color = AppColors.border
          ..style = PaintingStyle.stroke
          ..strokeWidth = 5);
    canvas.drawArc(
      Rect.fromCircle(center: Offset(cx, cy), radius: r),
      -1.5707963,
      score * 6.2831853,
      false,
      Paint()
        ..color = color
        ..style = PaintingStyle.stroke
        ..strokeWidth = 5
        ..strokeCap = StrokeCap.round,
    );
  }

  @override
  bool shouldRepaint(_RingPainter old) => old.score != score;
}
