import 'package:flutter/material.dart';

class WeeklyWaterCard extends StatelessWidget {
  final List forecast;
  final List waterPlan;
  final String cropName, cropEmoji;

  const WeeklyWaterCard({
    super.key,
    required this.forecast,
    required this.waterPlan,
    required this.cropName,
    required this.cropEmoji,
  });

  static const _dayNames = ['Pzt', 'Sal', 'Çar', 'Per', 'Cum', 'Cmt', 'Paz'];

  String _weatherIcon(int code) {
    if (code == 0) return '☀️';
    if (code <= 3) return '⛅';
    if (code <= 49) return '🌫️';
    if (code <= 69) return '🌧️';
    if (code <= 79) return '🌨️';
    if (code <= 99) return '⛈️';
    return '🌤️';
  }

  @override
  Widget build(BuildContext context) {
    if (forecast.isEmpty) return const SizedBox.shrink();

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(Icons.calendar_today, color: Colors.blue),
                const SizedBox(width: 6),
                const Expanded(
                    child: Text('Haftalık Hava & Sulama Planı',
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 15))),
                Text(cropEmoji, style: const TextStyle(fontSize: 20)),
              ],
            ),
            const SizedBox(height: 12),
            // 7 günlük tablo
            ...List.generate(forecast.length, (i) {
              final f = forecast[i] as Map<String, dynamic>;
              final dateStr = f['date']?.toString() ?? '';
              final tempMax = (f['temp_max'] as num?)?.toDouble() ?? 0;
              final tempMin = (f['temp_min'] as num?)?.toDouble() ?? 0;
              final rainMm = (f['rain_mm'] as num?)?.toDouble() ?? 0;
              final code = (f['code'] as num?)?.toInt() ?? 0;

              // Sulama planından eşleştir
              Map<String, dynamic>? wp;
              if (i < waterPlan.length) {
                wp = waterPlan[i] as Map<String, dynamic>?;
              }
              final waterL = (wp?['water_liters'] as num?)?.toDouble() ?? 0;
              final waterNote = wp?['note']?.toString() ?? '';

              // Gün adı
              String dayName;
              try {
                final dt = DateTime.parse(dateStr);
                dayName = _dayNames[dt.weekday - 1];
              } catch (_) {
                dayName = _dayNames[i % 7];
              }

              final hasRain = rainMm > 1;

              return Container(
                margin: const EdgeInsets.only(bottom: 4),
                padding:
                    const EdgeInsets.symmetric(vertical: 8, horizontal: 10),
                decoration: BoxDecoration(
                  color: i.isEven
                      ? Colors.blue.shade50.withValues(alpha: 0.5)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        SizedBox(
                            width: 32,
                            child: Text(dayName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13))),
                        Text(_weatherIcon(code),
                            style: const TextStyle(fontSize: 18)),
                        const SizedBox(width: 6),
                        SizedBox(
                            width: 65,
                            child: Text(
                                '${tempMin.round()}–${tempMax.round()}°C',
                                style: const TextStyle(fontSize: 12))),
                        if (hasRain) ...[
                          Icon(Icons.water_drop,
                              size: 14, color: Colors.blue.shade400),
                          Text('${rainMm.toStringAsFixed(1)}mm ',
                              style: TextStyle(
                                  fontSize: 11, color: Colors.blue.shade600)),
                        ],
                        const Spacer(),
                        // Sulama miktarı
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 8, vertical: 3),
                          decoration: BoxDecoration(
                            color: waterL > 0
                                ? (hasRain
                                    ? Colors.green.shade100
                                    : Colors.blue.shade100)
                                : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(Icons.water_drop,
                                  size: 13,
                                  color: waterL > 0
                                      ? Colors.blue.shade700
                                      : Colors.grey),
                              const SizedBox(width: 3),
                              Text(
                                  waterL > 0
                                      ? '${waterL.toStringAsFixed(1)}L/bitki'
                                      : 'Sulama yok',
                                  style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: waterL > 0
                                          ? Colors.blue.shade800
                                          : Colors.grey.shade600)),
                            ],
                          ),
                        ),
                      ],
                    ),
                    if (waterNote.isNotEmpty)
                      Padding(
                        padding: const EdgeInsets.only(left: 38, top: 2),
                        child: Text(waterNote,
                            style: TextStyle(
                                fontSize: 11,
                                color: Colors.grey.shade600,
                                fontStyle: FontStyle.italic)),
                      ),
                  ],
                ),
              );
            }),
            const SizedBox(height: 8),
            // Toplam haftalık su
            Builder(builder: (_) {
              double totalWater = 0;
              for (final wp in waterPlan) {
                totalWater +=
                    ((wp as Map<String, dynamic>?)?['water_liters'] as num?)
                            ?.toDouble() ??
                        0;
              }
              double totalRain = 0;
              for (final f in forecast) {
                totalRain += ((f as Map<String, dynamic>)['rain_mm'] as num?)
                        ?.toDouble() ??
                    0;
              }
              return Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.blue.shade50,
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(color: Colors.blue.shade200),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _summaryItem('💧', 'Haftalık Sulama',
                        '${totalWater.toStringAsFixed(1)}L/bitki'),
                    _summaryItem('🌧️', 'Beklenen Yağış',
                        '${totalRain.toStringAsFixed(1)}mm'),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _summaryItem(String emoji, String label, String value) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 20)),
        Text(value,
            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
        Text(label,
            style: TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}
