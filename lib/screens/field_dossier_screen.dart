import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:intl/intl.dart';

import '../data/activity_types.dart';
import '../data/app_database.dart';
import '../services/app_providers.dart';
import '../theme/app_theme.dart';
import 'farm_journal_screen.dart';
import 'soil_test_entry_screen.dart';

/// Tarla Dosyası — bir tarlanın tüm geçmişini ve güncel durumunu tek sayfada
/// toplayan **canlı** özet. Mevcut Drift tablolarını (FieldCrops,
/// CalendarEvents, SoilTests, CropGrowthStates, FieldPlantInstances) stream
/// olarak okur; veri değiştikçe ekran kendiliğinden güncellenir.
///
/// Yeni veri modeli/migration yoktur (CLAUDE.md §6) — yalnızca okuma + sunum.
/// Detaylı kronolojik aktivite akışı için [FarmJournalScreen]'e yönlendirir;
/// burada özet + statik kayıtlar (ürünler, toprak analizi, sağlık) gösterilir.
class FieldDossierScreen extends ConsumerWidget {
  final String fieldId;
  final Map<String, dynamic> fieldData;

  const FieldDossierScreen({
    super.key,
    required this.fieldId,
    required this.fieldData,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final cropsAsync = ref.watch(fieldCropsStreamProvider(fieldId));
    final activityAsync = ref.watch(fieldActivityLogProvider(fieldId));
    final soilAsync = ref.watch(fieldSoilTestsProvider(fieldId));
    final growthAsync = ref.watch(fieldGrowthStatesProvider(fieldId));
    final plantsAsync = ref.watch(fieldPlantInstancesProvider(fieldId));

    final fieldName = fieldData['name']?.toString() ?? 'Tarla';

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Tarla Dosyası — $fieldName'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(14),
        children: [
          _identityCard(),
          const SizedBox(height: 12),

          // Ekili ürünler — dikim/hasat/su + canlı büyüme durumu
          _SectionHeader(
            icon: Icons.eco_rounded,
            color: AppColors.emeraldDark,
            title: 'Ekili Ürünler',
          ),
          cropsAsync.when(
            data: (crops) => _cropsSection(
              crops,
              growthAsync.valueOrNull ?? const <CropGrowthState>[],
            ),
            loading: () => const _LoadingTile(),
            error: (_, __) => const _ErrorTile('Ürünler yüklenemedi.'),
          ),
          const SizedBox(height: 16),

          // Aktivite özeti — tam günlük FarmJournalScreen'de
          _SectionHeader(
            icon: Icons.history_rounded,
            color: AppColors.soil,
            title: 'Aktivite Geçmişi',
          ),
          activityAsync.when(
            data: (entries) => _activitySection(context, entries),
            loading: () => const _LoadingTile(),
            error: (_, __) => const _ErrorTile('Aktiviteler yüklenemedi.'),
          ),
          const SizedBox(height: 16),

          // Toprak analizleri
          _SectionHeader(
            icon: Icons.science_outlined,
            color: const Color(0xFF6D4C41),
            title: 'Toprak Analizleri',
          ),
          soilAsync.when(
            data: (tests) => _soilSection(context, tests),
            loading: () => const _LoadingTile(),
            error: (_, __) => const _ErrorTile('Analizler yüklenemedi.'),
          ),
          const SizedBox(height: 16),

          // Bitki sağlığı gözlemleri
          _SectionHeader(
            icon: Icons.local_florist_rounded,
            color: AppColors.warning,
            title: 'Bitki Sağlığı',
          ),
          plantsAsync.when(
            data: (plants) => _healthSection(plants),
            loading: () => const _LoadingTile(),
            error: (_, __) => const _ErrorTile('Sağlık kayıtları yüklenemedi.'),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  // ── Künye ─────────────────────────────────────────────────────────────
  Widget _identityCard() {
    final area = (fieldData['area_dekar'] as num?)?.toDouble() ??
        (fieldData['areaDekar'] as num?)?.toDouble();
    final lat = (fieldData['latitude'] as num?)?.toDouble();
    final lng = (fieldData['longitude'] as num?)?.toDouble();
    final createdRaw = fieldData['date']?.toString();

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: AppColors.emerald.withValues(alpha: 0.14),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(Icons.landscape_rounded,
                    color: AppColors.emeraldDark),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  fieldData['name']?.toString() ?? 'Tarla',
                  style: GoogleFonts.outfit(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          if (area != null) _kv('Alan', '${area.toStringAsFixed(1)} dekar'),
          if (lat != null && lng != null)
            _kv('Konum',
                '${lat.toStringAsFixed(5)}, ${lng.toStringAsFixed(5)}'),
          if (createdRaw != null && createdRaw.isNotEmpty)
            _kv('Kayıt tarihi', createdRaw),
        ],
      ),
    );
  }

  // ── Ekili ürünler ─────────────────────────────────────────────────────
  Widget _cropsSection(
    List<Map<String, dynamic>> crops,
    List<CropGrowthState> growth,
  ) {
    if (crops.isEmpty) {
      return const _EmptyTile('Bu tarlaya henüz ürün eklenmemiş.');
    }
    final growthById = {for (final g in growth) g.cropId: g};
    return Column(
      children: crops.map((c) {
        final id = c['id']?.toString();
        final g = id == null ? null : growthById[id];
        return _cropCard(c, g);
      }).toList(),
    );
  }

  Widget _cropCard(Map<String, dynamic> c, CropGrowthState? g) {
    final name = c['name']?.toString() ?? 'Ürün';
    final planted =
        c['plantedDate']?.toString() ?? c['planted_date']?.toString();
    final harvestDays = (c['harvestDays'] as num?)?.toInt() ??
        (c['harvest_days'] as num?)?.toInt();
    final waterInterval = (c['waterIntervalDays'] as num?)?.toInt() ??
        (c['water_interval_days'] as num?)?.toInt();

    String? harvestEstimate;
    final plantedDate = _parseDate(planted);
    if (plantedDate != null && harvestDays != null) {
      final h = plantedDate.add(Duration(days: harvestDays));
      harvestEstimate = _fmtDate(h);
    }

    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.local_florist_rounded,
                  color: AppColors.emerald, size: 20),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  name,
                  style: const TextStyle(
                      fontSize: 15, fontWeight: FontWeight.w700),
                ),
              ),
              if (g != null) _stagePill(g.currentStageKey),
            ],
          ),
          const SizedBox(height: 8),
          if (plantedDate != null) _kv('Dikim', _fmtDate(plantedDate)),
          if (harvestEstimate != null) _kv('Tahmini hasat', harvestEstimate),
          if (waterInterval != null)
            _kv('Sulama aralığı', '$waterInterval günde bir'),
          if (g != null) ...[
            const SizedBox(height: 6),
            _growthBars(g),
          ],
        ],
      ),
    );
  }

  Widget _stagePill(String stageKey) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: AppColors.emerald.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        _stageLabel(stageKey),
        style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: AppColors.emeraldDark),
      ),
    );
  }

  Widget _growthBars(CropGrowthState g) {
    return Column(
      children: [
        _stressBar('Su açığı', (g.waterDeficitMm / 40).clamp(0.0, 1.0),
            AppColors.frost),
        _stressBar(
            'Azot stresi', g.nStressIdx.clamp(0.0, 1.0), AppColors.emeraldDark),
        _stressBar('Hastalık baskısı', g.diseasePressure.clamp(0.0, 1.0),
            AppColors.warning),
      ],
    );
  }

  Widget _stressBar(String label, double value, Color color) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 96,
            child: Text(label,
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: value,
                minHeight: 6,
                backgroundColor: AppColors.border,
                color: color,
              ),
            ),
          ),
        ],
      ),
    );
  }

  // ── Aktivite ──────────────────────────────────────────────────────────
  Widget _activitySection(
      BuildContext context, List<Map<String, dynamic>> entries) {
    final real = entries
        .where((e) => e['source']?.toString() != 'auto_seed')
        .toList(growable: false);
    if (real.isEmpty) {
      return Column(
        children: [
          const _EmptyTile(
              'Henüz aktivite kaydı yok. Sulama, gübre, ilaç, hasat ve gözlemler burada birikir.'),
          const SizedBox(height: 8),
          _openJournalButton(context),
        ],
      );
    }

    // Tip bazında özet sayım + son 3 kayıt önizleme.
    final counts = <String, int>{};
    for (final e in real) {
      final t = e['type']?.toString() ?? ActivityType.other;
      counts[t] = (counts[t] ?? 0) + 1;
    }
    final preview = real.take(3).toList(growable: false);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _Card(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Toplam ${real.length} kayıt',
                  style: const TextStyle(
                      fontSize: 13, fontWeight: FontWeight.w700)),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: counts.entries.map((e) {
                  final color = ActivityType.color(e.key);
                  return Container(
                    padding:
                        const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      color: color.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(ActivityType.icon(e.key), size: 14, color: color),
                        const SizedBox(width: 5),
                        Text('${ActivityType.label(e.key)}: ${e.value}',
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: AppColors.textPrimary)),
                      ],
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 12),
              const Text('Son kayıtlar',
                  style: TextStyle(
                      fontSize: 12.5,
                      fontWeight: FontWeight.w700,
                      color: AppColors.textSecondary)),
              const SizedBox(height: 6),
              ...preview.map(_activityPreviewRow),
            ],
          ),
        ),
        const SizedBox(height: 8),
        _openJournalButton(context),
      ],
    );
  }

  Widget _activityPreviewRow(Map<String, dynamic> e) {
    final type = e['type']?.toString() ?? ActivityType.other;
    final date = e['date'];
    final color = ActivityType.color(type);
    final cropName = e['crop_name']?.toString();
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        children: [
          Icon(ActivityType.icon(type), size: 16, color: color),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              [
                ActivityType.label(type),
                if (cropName != null && cropName.isNotEmpty) cropName,
              ].join(' · '),
              style: const TextStyle(fontSize: 13),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ),
          if (date is DateTime)
            Text(_fmtDate(date),
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textTertiary)),
        ],
      ),
    );
  }

  Widget _openJournalButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => FarmJournalScreen(fieldId: fieldId),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: AppColors.soil,
        side: BorderSide(color: AppColors.soil.withValues(alpha: 0.5)),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.event_note_rounded, size: 18),
      label: const Text('Tam günlüğü aç'),
    );
  }

  // ── Toprak analizleri ─────────────────────────────────────────────────
  Widget _soilSection(BuildContext context, List<SoilTest> tests) {
    if (tests.isEmpty) {
      return Column(
        children: [
          const _EmptyTile('Bu tarla için kayıtlı toprak analizi yok.'),
          const SizedBox(height: 8),
          _openSoilButton(context),
        ],
      );
    }
    return Column(
      children: [
        ...tests.map(_soilCard),
        const SizedBox(height: 4),
        _openSoilButton(context),
      ],
    );
  }

  Widget _soilCard(SoilTest t) {
    final values = <String>[
      if (t.ph != null) 'pH ${_n(t.ph!)}',
      if (t.organicMatterPct != null) 'OM %${_n(t.organicMatterPct!)}',
      if (t.phosphorusKgDa != null) 'P ${_n(t.phosphorusKgDa!)} kg/da',
      if (t.potassiumKgDa != null) 'K ${_n(t.potassiumKgDa!)} kg/da',
      if (t.nitrogenPct != null) 'N %${_n(t.nitrogenPct!)}',
      if (t.saltPct != null) 'Tuz %${_n(t.saltPct!)}',
      if (t.ecDsM != null) 'EC ${_n(t.ecDsM!)} dS/m',
      if (t.limePct != null) 'Kireç %${_n(t.limePct!)}',
    ];
    final when = t.sampledAt ?? t.createdAt;
    return _Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  t.sampleLabel?.isNotEmpty == true
                      ? t.sampleLabel!
                      : 'Toprak analizi',
                  style: const TextStyle(
                      fontSize: 14, fontWeight: FontWeight.w700),
                ),
              ),
              Text(_fmtDate(when.toLocal()),
                  style: const TextStyle(
                      fontSize: 11.5, color: AppColors.textTertiary)),
            ],
          ),
          if (t.labName?.isNotEmpty == true) ...[
            const SizedBox(height: 2),
            Text(t.labName!,
                style: const TextStyle(
                    fontSize: 12, color: AppColors.textSecondary)),
          ],
          if (t.sampleRadius != null)
            Text(
                'Örnek alanı yarıçapı: ${t.sampleRadius!.toStringAsFixed(0)} m',
                style: const TextStyle(
                    fontSize: 11.5, color: AppColors.textTertiary)),
          if (values.isNotEmpty) ...[
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: values
                  .map((v) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 9, vertical: 5),
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(color: AppColors.border),
                        ),
                        child: Text(v,
                            style: const TextStyle(
                                fontSize: 12, fontWeight: FontWeight.w600)),
                      ))
                  .toList(),
            ),
          ] else
            const Padding(
              padding: EdgeInsets.only(top: 6),
              child: Text('Değer girilmemiş.',
                  style:
                      TextStyle(fontSize: 12, color: AppColors.textTertiary)),
            ),
        ],
      ),
    );
  }

  Widget _openSoilButton(BuildContext context) {
    return OutlinedButton.icon(
      onPressed: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => SoilTestEntryScreen(
            fieldId: fieldId,
            fieldName: fieldData['name']?.toString() ?? 'Tarla',
          ),
        ),
      ),
      style: OutlinedButton.styleFrom(
        foregroundColor: const Color(0xFF6D4C41),
        side: const BorderSide(color: Color(0x556D4C41)),
        minimumSize: const Size.fromHeight(46),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
      icon: const Icon(Icons.add_rounded, size: 18),
      label: const Text('Toprak analizi ekle / görüntüle'),
    );
  }

  // ── Bitki sağlığı ─────────────────────────────────────────────────────
  Widget _healthSection(List<FieldPlantInstance> plants) {
    if (plants.isEmpty) {
      return const _EmptyTile(
          'Tekil bitki sağlık kaydı yok. Haritadan bitki işaretleyince durumları burada görünür.');
    }
    final diseased = plants.where((p) => p.healthStatus == 'diseased').toList();
    final dead = plants.where((p) => p.healthStatus == 'dead').toList();
    final healthy = plants.length - diseased.length - dead.length;

    return _Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _healthPill('Sağlıklı', healthy, AppColors.emerald),
              const SizedBox(width: 8),
              _healthPill('Hastalıklı', diseased.length, AppColors.warning),
              const SizedBox(width: 8),
              _healthPill('Ölü', dead.length, AppColors.error),
            ],
          ),
          if (diseased.isNotEmpty) ...[
            const SizedBox(height: 12),
            const Text('Hastalıklı bitkiler',
                style: TextStyle(
                    fontSize: 12.5,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textSecondary)),
            const SizedBox(height: 6),
            ...diseased.take(5).map((p) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 3),
                  child: Row(
                    children: [
                      const Icon(Icons.coronavirus_rounded,
                          size: 15, color: AppColors.warning),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          [
                            p.cropName,
                            if (p.diseaseType?.isNotEmpty == true)
                              p.diseaseType!,
                          ].join(' · '),
                          style: const TextStyle(fontSize: 13),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }

  Widget _healthPill(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.1),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text('$count',
                style: TextStyle(
                    fontSize: 18, fontWeight: FontWeight.w800, color: color)),
            Text(label,
                style: const TextStyle(
                    fontSize: 11, color: AppColors.textSecondary)),
          ],
        ),
      ),
    );
  }

  // ── Ortak yardımcılar ─────────────────────────────────────────────────
  Widget _kv(String k, String v) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2.5),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(k,
                style: const TextStyle(
                    fontSize: 12.5, color: AppColors.textSecondary)),
          ),
          Expanded(
            child: Text(v,
                style:
                    const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          ),
        ],
      ),
    );
  }

  static String _stageLabel(String key) => switch (key) {
        'cimlenme' => 'Çimlenme',
        'vejetatif' => 'Vejetatif',
        'ciceklenme' => 'Çiçeklenme',
        'meyve_dolumu' => 'Meyve dolumu',
        'olgunlasma' => 'Olgunlaşma',
        'hasat' => 'Hasat',
        _ => 'Ekim sonrası',
      };

  static String _n(double v) {
    if (v == v.roundToDouble()) return v.toStringAsFixed(0);
    return v.toStringAsFixed(1);
  }

  static DateTime? _parseDate(String? raw) {
    if (raw == null || raw.isEmpty) return null;
    return DateTime.tryParse(raw);
  }

  static String _fmtDate(DateTime d) => DateFormat('dd.MM.yyyy').format(d);
}

// ── Yeniden kullanılabilir küçük parçalar ─────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String title;
  const _SectionHeader(
      {required this.icon, required this.color, required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, left: 2),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 8),
          Text(
            title,
            style: GoogleFonts.outfit(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}

class _Card extends StatelessWidget {
  final Widget child;
  final EdgeInsets? margin;
  const _Card({required this.child, this.margin});

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: margin,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.border),
      ),
      child: child,
    );
  }
}

class _EmptyTile extends StatelessWidget {
  final String text;
  const _EmptyTile(this.text);

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const Icon(Icons.info_outline_rounded,
              size: 18, color: AppColors.textTertiary),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}

class _LoadingTile extends StatelessWidget {
  const _LoadingTile();

  @override
  Widget build(BuildContext context) {
    return const _Card(
      child: Center(
        child: Padding(
          padding: EdgeInsets.all(8),
          child: SizedBox(
            width: 22,
            height: 22,
            child: CircularProgressIndicator(strokeWidth: 2.4),
          ),
        ),
      ),
    );
  }
}

class _ErrorTile extends StatelessWidget {
  final String text;
  const _ErrorTile(this.text);

  @override
  Widget build(BuildContext context) {
    return _Card(
      child: Row(
        children: [
          const Icon(Icons.error_outline_rounded,
              size: 18, color: AppColors.error),
          const SizedBox(width: 8),
          Expanded(
            child: Text(text,
                style: const TextStyle(
                    fontSize: 13, color: AppColors.textSecondary)),
          ),
        ],
      ),
    );
  }
}
