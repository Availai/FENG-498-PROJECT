import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

import '../services/api/soilgrids_api.dart';
import '../services/soil_fertilization_service.dart';
import '../widgets/help_panel.dart';

/// Modül 6 — Detaylı Toprak Analizi & Gübreleme ekranı.
///
/// SoilGrids'ten profil çeker; hata durumunda statik fallback'e düşer
/// (çevrimdışı uyumlu). NPK tahmini, toprak tipi, kireç/kükürt
/// hesaplayıcısı ve bitki bazlı dönemsel gübreleme takvimini gösterir.
class SoilAnalysisScreen extends StatefulWidget {
  final double latitude;
  final double longitude;
  final String fieldName;
  final String? cropName;

  const SoilAnalysisScreen({
    super.key,
    required this.latitude,
    required this.longitude,
    required this.fieldName,
    this.cropName,
  });

  @override
  State<SoilAnalysisScreen> createState() => _SoilAnalysisScreenState();
}

class _SoilAnalysisScreenState extends State<SoilAnalysisScreen> {
  SoilProfile? _profile;
  bool _isLoading = true;
  String? _error;
  double _targetPh = 6.5;
  bool _usingFallback = false;

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });
    try {
      final profile = await SoilGridsApi.fetchProfile(
        lat: widget.latitude,
        lon: widget.longitude,
      );
      if (!mounted) return;
      setState(() {
        _profile = profile;
        _targetPh = profile.phReal.clamp(5.5, 7.5);
        _isLoading = false;
        _usingFallback = false;
      });
    } catch (e) {
      // Çevrimdışı veya API hatası — Türkiye ortalama profili ile fallback
      if (!mounted) return;
      setState(() {
        _profile = const SoilProfile(
          phH2o: 70, // pH 7.0
          organicCarbonGKg: 12,
          clayGKg: 280,
          sandGKg: 380,
          siltGKg: 340,
          bulkDensityKgM3: 1400,
          cecMmolKg: 180,
          nitrogenGKg: 1.5,
        );
        _targetPh = 6.5;
        _isLoading = false;
        _usingFallback = true;
        _error = 'Çevrimdışı — Türkiye ortalaması gösteriliyor';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF1F8E9),
      appBar: AppBar(
        backgroundColor: const Color(0xFF1B5E20),
        title: Text(
          'Toprak Analizi — ${widget.fieldName}',
          style: GoogleFonts.outfit(
              color: Colors.white, fontSize: 16, fontWeight: FontWeight.w700),
        ),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            tooltip: 'Yenile',
            icon: const Icon(Icons.refresh),
            onPressed: _isLoading ? null : _loadProfile,
          ),
          IconButton(
            icon: const Icon(Icons.help_outline_rounded, color: Colors.white),
            tooltip: 'Yardım',
            onPressed: () => HelpPanel.show(context, HelpContent.soilAnalysis),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(
              child: CircularProgressIndicator(color: Color(0xFF1B5E20)))
          : _profile == null
              ? Center(child: Text(_error ?? 'Veri yüklenemedi'))
              : _buildContent(_profile!),
    );
  }

  Widget _buildContent(SoilProfile p) {
    final npk = SoilFertilizationService.estimateNpk(p);
    final amendment = SoilFertilizationService.amendmentFor(
      profile: p,
      targetPh: _targetPh,
    );
    final crop = (widget.cropName?.trim().isNotEmpty ?? false)
        ? widget.cropName!
        : 'Genel';
    final plan = SoilFertilizationService.fertilizationPlan(crop);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (_usingFallback)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(10),
              margin: const EdgeInsets.only(bottom: 12),
              decoration: BoxDecoration(
                color: Colors.orange.shade100,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.orange.shade300),
              ),
              child: Row(
                children: [
                  Icon(Icons.cloud_off,
                      color: Colors.orange.shade800, size: 18),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _error ?? '',
                      style: TextStyle(
                          fontSize: 12, color: Colors.orange.shade900),
                    ),
                  ),
                ],
              ),
            ),

          // 1. Toprak özet kartı
          _sectionCard(
            icon: Icons.terrain,
            color: const Color(0xFF6D4C41),
            title: 'Toprak Profili',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _kvRow('Doku Sınıfı', p.textureClass),
                _kvRow('pH',
                    '${p.phReal.toStringAsFixed(1)} (${p.phDescription})'),
                _kvRow('Organik Madde',
                    '%${p.organicMatterPct.toStringAsFixed(1)}'),
                _kvRow('Kil', '%${p.clayPct.toStringAsFixed(0)}'),
                _kvRow('Kum', '%${p.sandPct.toStringAsFixed(0)}'),
                _kvRow('Silt', '%${p.siltPct.toStringAsFixed(0)}'),
                _kvRow('CEC', '${p.cecMmolKg.toStringAsFixed(0)} mmol/kg'),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: const Color(0xFFE8F5E9),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(Icons.eco, color: Color(0xFF1B5E20), size: 18),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Bu doku için uygun: ${SoilFertilizationService.suitableCropsForTexture(p.textureClass)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 2. NPK kartı
          _sectionCard(
            icon: Icons.science_outlined,
            color: const Color(0xFF1565C0),
            title: 'NPK Düzeyi (kg/dekar — tahmini)',
            child: Column(
              children: [
                _npkBar('Azot (N)', npk.nitrogenKgDekar, 6.0, npk.nLabel,
                    npk.nLevel),
                _npkBar('Fosfor (P₂O₅)', npk.phosphorusKgDekar, 18.0,
                    npk.pLabel, npk.pLevel),
                _npkBar('Potasyum (K₂O)', npk.potassiumKgDekar, 30.0,
                    npk.kLabel, npk.kLevel),
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: const Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(Icons.info_outline, size: 16, color: Colors.amber),
                      SizedBox(width: 6),
                      Expanded(
                        child: Text(
                          'Bu değerler uydu modeli ve doku tahmininden çıkarılmıştır. '
                          'Kesin doz için il/ilçe TAGEM laboratuvar analizi yaptırın.',
                          style: TextStyle(fontSize: 11),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 3. Kireç / Kükürt hesaplayıcı
          _sectionCard(
            icon: Icons.calculate,
            color: const Color(0xFF6A1B9A),
            title: 'Kireçleme & Kükürtleme Hesaplayıcısı',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Hedef pH: ${_targetPh.toStringAsFixed(1)}',
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
                Slider(
                  value: _targetPh,
                  min: 4.5,
                  max: 8.5,
                  divisions: 40,
                  label: _targetPh.toStringAsFixed(1),
                  activeColor: const Color(0xFF6A1B9A),
                  onChanged: (v) => setState(() => _targetPh = v),
                ),
                Text(
                  'Mevcut pH: ${p.phReal.toStringAsFixed(1)} → Hedef: ${_targetPh.toStringAsFixed(1)}',
                  style: TextStyle(fontSize: 12, color: Colors.grey.shade700),
                ),
                const SizedBox(height: 10),
                if (amendment == null)
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                      color: Colors.green.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: const Row(
                      children: [
                        Icon(Icons.check_circle, color: Colors.green),
                        SizedBox(width: 6),
                        Expanded(
                          child: Text(
                            'pH zaten hedefe yakın. Düzeltme önerilmez.',
                            style: TextStyle(fontSize: 13),
                          ),
                        ),
                      ],
                    ),
                  )
                else
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFEDE7F6),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: const Color(0xFF6A1B9A)),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.scale,
                                color: Color(0xFF6A1B9A), size: 18),
                            const SizedBox(width: 6),
                            Expanded(
                              child: Text(
                                amendment.materialName,
                                style: const TextStyle(
                                    fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                            ),
                            Text(
                              '${amendment.doseKgDekar.toStringAsFixed(0)} kg/dekar',
                              style: const TextStyle(
                                color: Color(0xFF6A1B9A),
                                fontWeight: FontWeight.bold,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Text(
                          amendment.application,
                          style: const TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 12),

          // 4. Gübreleme takvimi
          _sectionCard(
            icon: Icons.event_note,
            color: const Color(0xFFE65100),
            title: 'Gübreleme Takvimi — $crop',
            child: Column(
              children: plan.map((step) {
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.orange.shade50,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: Colors.orange.shade200),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(
                              step.period,
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.orange.shade900,
                              ),
                            ),
                          ),
                          Text(
                            '${step.doseKgDekar.toStringAsFixed(0)} kg/dekar',
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 13),
                          ),
                        ],
                      ),
                      const SizedBox(height: 4),
                      Text('Gübre: ${step.fertilizer}',
                          style: const TextStyle(fontSize: 12)),
                      const SizedBox(height: 2),
                      Text(step.note,
                          style: TextStyle(
                              fontSize: 11,
                              color: Colors.grey.shade700,
                              fontStyle: FontStyle.italic)),
                    ],
                  ),
                );
              }).toList(),
            ),
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _sectionCard({
    required IconData icon,
    required Color color,
    required String title,
    required Widget child,
  }) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title,
                    style: GoogleFonts.outfit(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: color,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 10),
            child,
          ],
        ),
      ),
    );
  }

  Widget _kvRow(String key, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Expanded(
            flex: 2,
            child: Text(key,
                style: const TextStyle(fontSize: 12, color: Colors.black54)),
          ),
          Expanded(
            flex: 3,
            child: Text(value,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  Widget _npkBar(String label, double value, double maxScale, String levelLabel,
      NutrientLevel level) {
    final color = level == NutrientLevel.dusuk
        ? Colors.red
        : level == NutrientLevel.yuksek
            ? Colors.blue
            : Colors.green;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(label,
                    style: const TextStyle(
                        fontSize: 13, fontWeight: FontWeight.w600)),
              ),
              Text('${value.toStringAsFixed(1)} kg/dekar',
                  style: const TextStyle(fontSize: 12)),
              const SizedBox(width: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: color.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(color: color),
                ),
                child: Text(
                  levelLabel,
                  style: TextStyle(
                      fontSize: 10, color: color, fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (value / maxScale).clamp(0.0, 1.0),
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
