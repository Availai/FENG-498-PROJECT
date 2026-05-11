import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../data/plant_render_model.dart';

/// Skor sıralamalı bitki seçici bottom sheet.
/// [scored] listesindeki her eleman: plant (AgriPlant), score (double), reasons (List)
class PlantPickerSheet extends StatefulWidget {
  final List<Map<String, dynamic>> scored;
  final void Function(AgriPlant plant) onPick;
  const PlantPickerSheet(
      {super.key, required this.scored, required this.onPick});

  @override
  State<PlantPickerSheet> createState() => _PlantPickerSheetState();
}

class _PlantPickerSheetState extends State<PlantPickerSheet> {
  final TextEditingController _searchCtrl = TextEditingController();
  String _query = '';

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  String _normalize(String s) => s
      .toLowerCase()
      .replaceAll('ı', 'i')
      .replaceAll('ğ', 'g')
      .replaceAll('ü', 'u')
      .replaceAll('ş', 's')
      .replaceAll('ö', 'o')
      .replaceAll('ç', 'c');

  List<Map<String, dynamic>> get _filtered {
    if (_query.trim().isEmpty) return widget.scored;
    final q = _normalize(_query.trim());
    return widget.scored.where((e) {
      final p = e['plant'] as AgriPlant;
      return _normalize(p.nameTr).contains(q);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filtered = _filtered;
    return Container(
      height: MediaQuery.of(context).size.height * 0.82,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
      child: Column(
        children: [
          Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                  color: Colors.grey.shade300,
                  borderRadius: BorderRadius.circular(2))),
          const SizedBox(height: 12),
          Row(children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                  color: const Color(0xFFE8F5E9),
                  borderRadius: BorderRadius.circular(10)),
              child: const Icon(Icons.add_circle_rounded,
                  color: Color(0xFF2E7D32), size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Tarlaya Bitki Ekle',
                        style: GoogleFonts.outfit(
                            fontSize: 17,
                            fontWeight: FontWeight.w700,
                            color: const Color(0xFF1B5E20))),
                    Text('Hava + toprak verisine göre uygunluk skoru',
                        style: GoogleFonts.inter(
                            fontSize: 12, color: Colors.grey.shade600)),
                  ]),
            ),
          ]),
          const SizedBox(height: 12),
          TextField(
            controller: _searchCtrl,
            onChanged: (v) => setState(() => _query = v),
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Bitki ara (ör. buğday, domates)',
              prefixIcon:
                  const Icon(Icons.search_rounded, color: Color(0xFF2E7D32)),
              suffixIcon: _query.isEmpty
                  ? null
                  : IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () {
                        _searchCtrl.clear();
                        setState(() => _query = '');
                      },
                    ),
              filled: true,
              fillColor: const Color(0xFFF5F7F5),
              contentPadding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 0),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 8),
          const Divider(height: 1),
          Expanded(
            child: filtered.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Sonuç bulunamadı.\nFarklı bir isim deneyin.',
                        textAlign: TextAlign.center,
                        style: GoogleFonts.inter(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filtered.length,
                    itemBuilder: (context, i) {
                      final AgriPlant p = filtered[i]['plant'] as AgriPlant;
                      final int score =
                          (filtered[i]['score'] as double).round();
                      final List<String> reasons =
                          (filtered[i]['reasons'] as List).cast<String>();
                      final Color sColor = score >= 75
                          ? const Color(0xFF2E7D32)
                          : score >= 50
                              ? Colors.orange.shade700
                              : Colors.red.shade700;
                      final String label = score >= 75
                          ? 'UYGUN'
                          : score >= 50
                              ? 'KOŞULLU'
                              : 'UYGUN DEĞİL';
                      return Padding(
                        padding: const EdgeInsets.symmetric(vertical: 4),
                        child: Material(
                          color: Colors.grey.shade50,
                          borderRadius: BorderRadius.circular(12),
                          child: InkWell(
                            borderRadius: BorderRadius.circular(12),
                            onTap: () => widget.onPick(p),
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Row(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  CircleAvatar(
                                    backgroundColor: p.renderColor,
                                    radius: 20,
                                    child: const Icon(Icons.eco,
                                        color: Colors.white, size: 18),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(p.nameTr,
                                            style: const TextStyle(
                                                fontWeight: FontWeight.bold,
                                                fontSize: 15)),
                                        const SizedBox(height: 2),
                                        Text(
                                            'Hasat: ${p.daysToHarvest} gün • pH ${p.minPh}-${p.maxPh} • ${p.minTemp.toInt()}-${p.maxTemp.toInt()}°C',
                                            style: TextStyle(
                                                fontSize: 11,
                                                color: Colors.grey.shade700)),
                                        if (reasons.isNotEmpty) ...[
                                          const SizedBox(height: 4),
                                          ...reasons.map((r) => Padding(
                                                padding: const EdgeInsets.only(
                                                    top: 2),
                                                child: Row(
                                                  crossAxisAlignment:
                                                      CrossAxisAlignment.start,
                                                  children: [
                                                    const Icon(
                                                        Icons
                                                            .warning_amber_rounded,
                                                        size: 12,
                                                        color: Colors.orange),
                                                    const SizedBox(width: 4),
                                                    Expanded(
                                                      child: Text(r,
                                                          style: const TextStyle(
                                                              fontSize: 11,
                                                              color: Colors
                                                                  .black87)),
                                                    ),
                                                  ],
                                                ),
                                              )),
                                        ],
                                      ],
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Column(
                                    crossAxisAlignment: CrossAxisAlignment.end,
                                    children: [
                                      Text('%$score',
                                          style: TextStyle(
                                              color: sColor,
                                              fontWeight: FontWeight.bold,
                                              fontSize: 18)),
                                      Text(label,
                                          style: TextStyle(
                                              color: sColor,
                                              fontWeight: FontWeight.w600,
                                              fontSize: 10)),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
