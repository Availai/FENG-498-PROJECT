import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:intl/intl.dart';
import '../services/app_providers.dart';
import '../widgets/floating_toast.dart';

class SensorDataScreen extends ConsumerStatefulWidget {
  const SensorDataScreen({super.key});

  @override
  ConsumerState<SensorDataScreen> createState() => _SensorDataScreenState();
}

class _SensorDataScreenState extends ConsumerState<SensorDataScreen> {
  static const _sensorBoxName = 'sensor_data';

  Timer? _timer;
  final _random = math.Random();
  String? _selectedFieldId;

  Box get _sensorBox => Hive.box(_sensorBoxName);

  bool get _isStreaming => _timer?.isActive == true;

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  List<Map<String, dynamic>> _sensorRows() {
    final rows = _sensorBox.values
        .whereType<Map>()
        .map((e) => Map<String, dynamic>.from(e))
        .where((row) => row['fieldId'] == _selectedFieldId)
        .toList();

    rows.sort((a, b) =>
        (a['timestamp'] as int? ?? 0).compareTo(b['timestamp'] as int? ?? 0));
    return rows;
  }

  void _toggleStream() {
    if (_selectedFieldId == null) {
      AppToast.show(
        context,
        message: 'Önce bir tarla seçin.',
        type: ToastType.warning,
      );
      return;
    }

    if (_isStreaming) {
      _timer?.cancel();
      setState(() {});
      return;
    }

    _pushSample();
    _timer = Timer.periodic(const Duration(seconds: 5), (_) => _pushSample());
    setState(() {});
  }

  void _pushSample() {
    if (_selectedFieldId == null) return;

    final now = DateTime.now();
    final baseTemp = 18 + _random.nextDouble() * 12;
    final humidity = 35 + _random.nextDouble() * 45;
    final soilMoisture = 20 + _random.nextDouble() * 55;

    _sensorBox.add({
      'fieldId': _selectedFieldId,
      'timestamp': now.millisecondsSinceEpoch,
      'temperature': double.parse(baseTemp.toStringAsFixed(1)),
      'humidity': double.parse(humidity.toStringAsFixed(1)),
      'soilMoisture': double.parse(soilMoisture.toStringAsFixed(1)),
      'source': 'simülasyon',
    });

    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final fieldsAsync = ref.watch(fieldMapsProvider);
    final fields = (fieldsAsync.asData?.value ?? const [])
        .where((f) => f['id'] != null)
        .toList();
    if (_selectedFieldId == null && fields.isNotEmpty) {
      _selectedFieldId = fields.first['id']?.toString();
    }

    final rows = _sensorRows();
    final latest = rows.isNotEmpty ? rows.last : null;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Sensör Verisi'),
        actions: [
          IconButton(
            onPressed: () => setState(() {}),
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: fields.isEmpty
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'Sensör verisi için önce en az bir tarla ekleyin.',
                  textAlign: TextAlign.center,
                ),
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                DropdownButtonFormField<String>(
                  initialValue: _selectedFieldId,
                  decoration: const InputDecoration(
                    labelText: 'Tarla Seçimi',
                    border: OutlineInputBorder(),
                  ),
                  items: fields
                      .map(
                        (f) => DropdownMenuItem(
                          value: f['id'].toString(),
                          child: Text((f['name'] ?? 'İsimsiz Tarla').toString()),
                        ),
                      )
                      .toList(),
                  onChanged: (val) {
                    setState(() => _selectedFieldId = val);
                  },
                ),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: _toggleStream,
                  icon: Icon(_isStreaming ? Icons.pause : Icons.play_arrow),
                  label: Text(_isStreaming
                      ? 'Canlı Akışı Durdur'
                      : 'Canlı Akışı Başlat (5 sn)'),
                ),
                const SizedBox(height: 16),
                _MetricRow(latest: latest),
                const SizedBox(height: 18),
                _SensorChartCard(
                  title: 'Sıcaklık (°C)',
                  unit: '°C',
                  values: rows
                      .map((e) => (e['temperature'] as num?)?.toDouble() ?? 0)
                      .toList(),
                  color: Colors.deepOrange,
                ),
                const SizedBox(height: 12),
                _SensorChartCard(
                  title: 'Nem (%)',
                  unit: '%',
                  values: rows
                      .map((e) => (e['humidity'] as num?)?.toDouble() ?? 0)
                      .toList(),
                  color: Colors.blue,
                ),
                const SizedBox(height: 12),
                _SensorChartCard(
                  title: 'Toprak Nemi (%)',
                  unit: '%',
                  values: rows
                      .map((e) => (e['soilMoisture'] as num?)?.toDouble() ?? 0)
                      .toList(),
                  color: Colors.green,
                ),
                const SizedBox(height: 8),
                Text(
                  latest == null
                      ? 'Henüz kayıt yok.'
                      : 'Son veri: ${DateFormat('dd.MM.yyyy HH:mm:ss').format(DateTime.fromMillisecondsSinceEpoch(latest['timestamp'] as int))}',
                  style: Theme.of(context)
                      .textTheme
                      .bodySmall
                      ?.copyWith(color: Colors.grey.shade600),
                ),
              ],
            ),
    );
  }
}

class _MetricRow extends StatelessWidget {
  const _MetricRow({required this.latest});

  final Map<String, dynamic>? latest;

  @override
  Widget build(BuildContext context) {
    Widget tile(String title, String value, IconData icon, Color color) {
      return Expanded(
        child: Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            color: color.withValues(alpha: 0.08),
            border: Border.all(color: color.withValues(alpha: 0.35)),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Icon(icon, color: color),
              const SizedBox(height: 8),
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 4),
              Text(
                value,
                style: Theme.of(context)
                    .textTheme
                    .titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
            ],
          ),
        ),
      );
    }

    return Row(
      children: [
        tile(
          'Sıcaklık',
          latest == null ? '--' : '${latest!['temperature']}°C',
          Icons.thermostat,
          Colors.deepOrange,
        ),
        const SizedBox(width: 8),
        tile(
          'Nem',
          latest == null ? '--' : '${latest!['humidity']}%',
          Icons.water_drop,
          Colors.blue,
        ),
        const SizedBox(width: 8),
        tile(
          'Toprak',
          latest == null ? '--' : '${latest!['soilMoisture']}%',
          Icons.grass,
          Colors.green,
        ),
      ],
    );
  }
}

class _SensorChartCard extends StatelessWidget {
  const _SensorChartCard({
    required this.title,
    required this.values,
    required this.color,
    required this.unit,
  });

  final String title;
  final List<double> values;
  final Color color;
  final String unit;

  @override
  Widget build(BuildContext context) {
    final cappedValues = values.length <= 20
        ? values
        : values.sublist(values.length - 20, values.length);

    final latest = cappedValues.isEmpty ? null : cappedValues.last;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: color.withValues(alpha: 0.35)),
        color: Colors.white,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(fontWeight: FontWeight.w700),
                ),
              ),
              Text(
                latest == null ? '--' : '${latest.toStringAsFixed(1)} $unit',
                style: TextStyle(color: color, fontWeight: FontWeight.w700),
              ),
            ],
          ),
          const SizedBox(height: 10),
          SizedBox(
            height: 96,
            child: CustomPaint(
              painter: _LineChartPainter(values: cappedValues, color: color),
              child: const SizedBox.expand(),
            ),
          ),
        ],
      ),
    );
  }
}

class _LineChartPainter extends CustomPainter {
  _LineChartPainter({required this.values, required this.color});

  final List<double> values;
  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final axis = Paint()
      ..color = Colors.grey.shade300
      ..strokeWidth = 1;
    canvas.drawLine(Offset(0, size.height), Offset(size.width, size.height), axis);
    canvas.drawLine(const Offset(0, 0), Offset(0, size.height), axis);

    if (values.length < 2) return;

    final minVal = values.reduce(math.min);
    final maxVal = values.reduce(math.max);
    final range = math.max(1, maxVal - minVal);

    final line = Paint()
      ..color = color
      ..strokeWidth = 2.2
      ..style = PaintingStyle.stroke;

    final fill = Paint()
      ..shader = LinearGradient(
        colors: [color.withValues(alpha: 0.35), color.withValues(alpha: 0.05)],
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));

    final path = Path();
    final fillPath = Path();

    for (var i = 0; i < values.length; i++) {
      final x = (i / (values.length - 1)) * size.width;
      final y = size.height - (((values[i] - minVal) / range) * size.height);
      if (i == 0) {
        path.moveTo(x, y);
        fillPath.moveTo(x, size.height);
        fillPath.lineTo(x, y);
      } else {
        path.lineTo(x, y);
        fillPath.lineTo(x, y);
      }
    }

    fillPath
      ..lineTo(size.width, size.height)
      ..close();

    canvas.drawPath(fillPath, fill);
    canvas.drawPath(path, line);
  }

  @override
  bool shouldRepaint(covariant _LineChartPainter oldDelegate) {
    return oldDelegate.values != values || oldDelegate.color != color;
  }
}
