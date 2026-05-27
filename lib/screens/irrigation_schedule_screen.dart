/// Akıllı Sulama Programı ekranı.
/// Backend rule_engine + OpenWeather verisiyle 7 günlük plan gösterir.
library;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/crop_protocols.dart' show SoilType;
import '../services/api/openweather_api.dart';
import '../services/app_providers.dart';
import '../services/irrigation_service.dart';
import '../services/water_balance_engine.dart';
import '../widgets/water_balance_panel.dart';
import 'water_efficiency_guide_screen.dart';

class IrrigationScheduleScreen extends ConsumerStatefulWidget {
  final String? fieldId;
  final double latitude;
  final double longitude;
  final String cropTr;
  final String fieldName;
  final double soilMoisturePct;
  final double fieldAreaDekar;
  final SoilType soilType;
  final String defaultIrrigationMethod;

  const IrrigationScheduleScreen({
    super.key,
    this.fieldId,
    required this.latitude,
    required this.longitude,
    required this.cropTr,
    required this.fieldName,
    this.soilMoisturePct = 25,
    this.fieldAreaDekar = 1.0,
    this.soilType = SoilType.loamy,
    this.defaultIrrigationMethod = 'Damla sulama',
  });

  @override
  ConsumerState<IrrigationScheduleScreen> createState() =>
      _IrrigationScheduleScreenState();
}

class _IrrigationScheduleScreenState
    extends ConsumerState<IrrigationScheduleScreen> {
  IrrigationSchedule? _schedule;
  WaterBalanceResult? _balance;
  String? _error;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      // Backend planı + lokal bilanço paralel.
      final scheduleF = IrrigationService.buildSchedule(
        lat: widget.latitude,
        lon: widget.longitude,
        cropTr: widget.cropTr,
        soilMoisturePct: widget.soilMoisturePct,
      );
      final balanceF = _computeLocalBalance();
      final s = await scheduleF;
      try {
        _balance = await balanceF;
      } catch (e) {
        debugPrint('[IrrigationScreen] Bilanço hesap hatası: $e');
        _balance = null;
      }
      // Planı yerel Drift'e kaydet ve outbox'a sync job ekle (offline-first).
      if (widget.fieldId != null) {
        try {
          final repo = ref.read(localDataRepositoryProvider);
          await repo.saveSmartIrrigationSchedule(
            fieldId: widget.fieldId!,
            dailyPlan: s.plan
                .map((p) => <String, dynamic>{
                      'date': p.date,
                      'should_irrigate': p.shouldIrrigate,
                      'reason': p.reason,
                      'recommendation': p.recommendation,
                      'title': p.title,
                    })
                .toList(),
          );
        } catch (e) {
          debugPrint('[IrrigationScreen] Yerel kayıt hatası: $e');
        }
      }

      if (!mounted) return;
      setState(() {
        _schedule = s;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error =
            'Plan oluşturulamadı: $e\n\nİnternet bağlantınızı kontrol edin.';
        _loading = false;
      });
    }
  }

  /// 7 günlük OpenWeather forecast'ini WaterBalanceEngine'e besle.
  /// Toprak tipi opsiyonel — bilinmiyorsa loamy varsayılan (TR çoğunluğu).
  Future<WaterBalanceResult> _computeLocalBalance() async {
    final pts = await OpenWeatherApi.forecast5Day(
      lat: widget.latitude,
      lon: widget.longitude,
    );
    final daily = OpenWeatherApi.aggregateDaily(pts);
    final forecast = daily.take(7).map((d) {
      // Min/max nem yaklaşığı: ortalamadan ±15 (forecast detayı yok).
      final rhMean = d.avgHumidityPct.toDouble();
      return DailyForecast(
        date: d.date,
        tMaxC: d.avgTempC + 4,
        tMinC: d.avgTempC - 4,
        rhMaxPct: (rhMean + 15).clamp(0, 100).toDouble(),
        rhMinPct: (rhMean - 15).clamp(0, 100).toDouble(),
        windMs: d.maxWindMs,
        precipMm: d.totalPrecipMm,
      );
    }).toList();

    final fc = WaterBalanceEngine.fieldCapacityMm(widget.soilType);
    final currentMm = (widget.soilMoisturePct / 100.0) * fc;

    const engine = WaterBalanceEngine();
    return engine.compute(WaterBalanceFacts(
      cropNameTr: widget.cropTr,
      plantedDate: null,
      totalSeasonDays: null,
      areaDekar: widget.fieldAreaDekar,
      soilType: widget.soilType,
      irrigationMethod: widget.defaultIrrigationMethod,
      currentSoilMoistureMm: currentMm,
      forecast: forecast,
      latitudeDeg: widget.latitude,
      elevationM: 100,
    ));
  }

  Color _levelColor(String level) {
    switch (level) {
      case 'critical':
        return Colors.red.shade700;
      case 'warning':
        return Colors.orange.shade700;
      case 'info':
        return Colors.blue.shade700;
      default:
        return Colors.green.shade700;
    }
  }

  IconData _levelIcon(String level) {
    switch (level) {
      case 'critical':
        return Icons.warning_amber_rounded;
      case 'warning':
        return Icons.water_drop;
      case 'info':
        return Icons.cloud;
      default:
        return Icons.check_circle;
    }
  }

  String _trDay(DateTime d) {
    const days = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];
    return days[d.weekday - 1];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Akıllı Sulama Programı'),
        actions: [
          IconButton(
            tooltip: 'Su Tasarrufu Rehberi',
            onPressed: () => Navigator.of(context).push(
              MaterialPageRoute(
                builder: (_) => const WaterEfficiencyGuideScreen(),
              ),
            ),
            icon: const Icon(Icons.eco),
          ),
          IconButton(
            tooltip: 'Yenile',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Padding(
                  padding: const EdgeInsets.all(24),
                  child: Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(Icons.cloud_off,
                            size: 64, color: Colors.grey),
                        const SizedBox(height: 16),
                        Text(_error!,
                            textAlign: TextAlign.center,
                            style: const TextStyle(fontSize: 16)),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: _load,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tekrar Dene'),
                        ),
                      ],
                    ),
                  ),
                )
              : _buildContent(),
    );
  }

  Widget _buildContent() {
    final s = _schedule!;
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        if (_balance != null) ...[
          WaterBalancePanel(
            result: _balance!,
            cropName: widget.cropTr,
            method: widget.defaultIrrigationMethod,
          ),
          const SizedBox(height: 12),
        ],
        Card(
          color: Colors.teal.shade50,
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('${widget.fieldName} • ${widget.cropTr}',
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Önümüzdeki ${s.totalDays} gün için plan',
                    style: const TextStyle(color: Colors.black54)),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    _stat('Sulama Günü', '${s.irrigationDays}'),
                    _stat(
                        'Toplam Su', '${s.totalWaterMm.toStringAsFixed(0)} mm'),
                    _stat(
                      'Toplam ETc',
                      '${s.totalCropDemandMm.toStringAsFixed(0)} mm',
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Kc: ${s.kcUsed.toStringAsFixed(2)} • ${s.method}',
                  style: const TextStyle(color: Colors.black54, fontSize: 12),
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 12),
        ...s.plan.map((p) => Card(
              margin: const EdgeInsets.only(bottom: 10),
              child: Padding(
                padding: const EdgeInsets.all(14),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(_levelIcon(p.level),
                        color: _levelColor(p.level), size: 32),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                '${_trDay(p.date)} ${p.date.day}.${p.date.month}',
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 15),
                              ),
                              const Spacer(),
                              if (p.shouldIrrigate)
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 8, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: _levelColor(p.level),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    '${p.estimatedMm.toStringAsFixed(0)} mm',
                                    style: const TextStyle(
                                        color: Colors.white,
                                        fontSize: 12,
                                        fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          const SizedBox(height: 4),
                          Text(p.title,
                              style: TextStyle(
                                  color: _levelColor(p.level),
                                  fontWeight: FontWeight.w600)),
                          const SizedBox(height: 4),
                          Text(p.reason, style: const TextStyle(fontSize: 13)),
                          const SizedBox(height: 4),
                          Text('💧 ${p.recommendation}',
                              style: const TextStyle(
                                  fontSize: 13, color: Colors.black87)),
                          const SizedBox(height: 4),
                          Text(
                            'ET₀ ${p.etoMm.toStringAsFixed(1)} • ETc ${p.etcMm.toStringAsFixed(1)} • Kc ${p.kc.toStringAsFixed(2)}',
                            style: const TextStyle(
                              fontSize: 12,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            )),
      ],
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value,
            style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.bold, color: Colors.teal)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.black54)),
      ],
    );
  }
}
