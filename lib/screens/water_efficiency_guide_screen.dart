/// Su Tasarrufu ve Sulama Yontemleri Rehberi.
///
/// Statik, kaynakli ve offline-first. Veri kaynagi:
/// `assets/data/irrigation_methods.json` (TAGEM, SYGM, suverimliligi.gov.tr).
library;

import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../data/irrigation_methods_repository.dart';
import '../data/water_prices_repository.dart';
import '../services/irrigation_cost_engine.dart';
import '../services/irrigation_savings_pdf_service.dart';
import '../theme/app_theme.dart';

class WaterEfficiencyGuideScreen extends StatefulWidget {
  const WaterEfficiencyGuideScreen({super.key});

  @override
  State<WaterEfficiencyGuideScreen> createState() =>
      _WaterEfficiencyGuideScreenState();
}

class _WaterEfficiencyGuideScreenState
    extends State<WaterEfficiencyGuideScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabs;
  IrrigationGuideData? _data;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabs = TabController(length: 5, vsync: this);
    _load();
  }

  Future<void> _load() async {
    try {
      final d = await IrrigationMethodsRepository.instance.load();
      if (!mounted) return;
      setState(() => _data = d);
    } catch (e) {
      if (!mounted) return;
      setState(() => _error = 'Rehber yuklenemedi: $e');
    }
  }

  @override
  void dispose() {
    _tabs.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Su Tasarrufu Rehberi'),
        backgroundColor: AppColors.emeraldDark,
        foregroundColor: AppColors.textOnDark,
        bottom: TabBar(
          controller: _tabs,
          isScrollable: true,
          labelColor: AppColors.textOnDark,
          unselectedLabelColor: AppColors.textOnDarkMuted,
          indicatorColor: AppColors.wheat,
          tabs: const [
            Tab(text: 'Yöntemler'),
            Tab(text: 'Geçiş & Tasarruf'),
            Tab(text: 'Hesaplayıcı'),
            Tab(text: 'Genel İpuçları'),
            Tab(text: 'Destekler & Kaynaklar'),
          ],
        ),
      ),
      body: _error != null
          ? Center(child: Padding(
              padding: const EdgeInsets.all(24),
              child: Text(_error!, textAlign: TextAlign.center),
            ))
          : _data == null
              ? const Center(child: CircularProgressIndicator())
              : TabBarView(
                  controller: _tabs,
                  children: [
                    _MethodsTab(data: _data!),
                    _TransitionsTab(data: _data!),
                    _CalculatorTab(guide: _data!),
                    _TipsTab(data: _data!),
                    _SourcesTab(data: _data!),
                  ],
                ),
    );
  }
}

// ─── Sekme 1: Yöntemler ─────────────────────────────────────────────────────

class _MethodsTab extends StatelessWidget {
  final IrrigationGuideData data;
  const _MethodsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    final categories = <String, List<IrrigationMethod>>{};
    for (final m in data.methods) {
      categories.putIfAbsent(m.category, () => []).add(m);
    }
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _DisclaimerCard(text: data.disclaimer),
        const SizedBox(height: 12),
        for (final entry in _orderedCategories(categories)) ...[
          _CategoryHeader(title: _categoryName(entry.key)),
          const SizedBox(height: 8),
          for (final m in entry.value)
            Padding(
              padding: const EdgeInsets.only(bottom: 10),
              child: _MethodCard(method: m, data: data),
            ),
          const SizedBox(height: 8),
        ],
      ],
    );
  }

  List<MapEntry<String, List<IrrigationMethod>>> _orderedCategories(
      Map<String, List<IrrigationMethod>> map) {
    const order = ['surface', 'sprinkler', 'drip', 'micro'];
    final out = <MapEntry<String, List<IrrigationMethod>>>[];
    for (final k in order) {
      if (map.containsKey(k)) out.add(MapEntry(k, map[k]!));
    }
    return out;
  }

  String _categoryName(String c) {
    switch (c) {
      case 'surface':
        return 'YÜZEY (SALMA) SULAMA';
      case 'sprinkler':
        return 'YAĞMURLAMA SULAMA';
      case 'drip':
        return 'DAMLA SULAMA';
      case 'micro':
        return 'MİKRO YAĞMURLAMA / SİSLEME';
      default:
        return c.toUpperCase();
    }
  }
}

class _CategoryHeader extends StatelessWidget {
  final String title;
  const _CategoryHeader({required this.title});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Container(width: 4, height: 18, color: AppColors.emerald),
            const SizedBox(width: 8),
            Expanded(
              child: Text(title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                      color: AppColors.textSecondary,
                      letterSpacing: 0.5)),
            ),
          ],
        ),
      );
}

class _MethodCard extends StatelessWidget {
  final IrrigationMethod method;
  final IrrigationGuideData data;
  const _MethodCard({required this.method, required this.data});

  String _range(List<int> r, String unit) =>
      r[0] == r[1] ? '${r[0]} $unit' : '${r[0]}-${r[1]} $unit';

  String _tlRange(List<int> r) {
    String fmt(int v) {
      if (v >= 1000) return '${(v / 1000).toStringAsFixed(v % 1000 == 0 ? 0 : 1)}K';
      return '$v';
    }

    if (r[0] == 0 && r[1] == 0) return 'Yatırım gerekmez';
    return '${fmt(r[0])}-${fmt(r[1])} TL/da';
  }

  Color _categoryColor(String c) {
    switch (c) {
      case 'drip':
        return AppColors.emerald;
      case 'sprinkler':
        return AppColors.info;
      case 'micro':
        return AppColors.emeraldLight;
      default:
        return AppColors.soil;
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = _categoryColor(method.category);
    return Card(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () => _showDetail(context),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(Icons.water_drop, color: color, size: 22),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(method.nameTr,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 16)),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(method.summary,
                  style: const TextStyle(
                      fontSize: 13, color: AppColors.textSecondary)),
              const SizedBox(height: 10),
              Wrap(
                spacing: 6,
                runSpacing: 6,
                children: [
                  _Chip(
                    label: 'Verim: ${_range(method.efficiencyPctRange, "%")}',
                    color: AppColors.successBg,
                    textColor: AppColors.emeraldDark,
                  ),
                  if (method.waterSavingVsFurrowPctRange != null)
                    _Chip(
                      label:
                          'Su tasarrufu: ${_range(method.waterSavingVsFurrowPctRange!, "%")}',
                      color: AppColors.infoBg,
                      textColor: AppColors.info,
                    ),
                  _Chip(
                    label: _tlRange(method.initialInvestmentTlPerDecareRange),
                    color: AppColors.warningBg,
                    textColor: AppColors.warning,
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  const Icon(Icons.info_outline,
                      size: 14, color: AppColors.textTertiary),
                  const SizedBox(width: 4),
                  Expanded(
                    child: Text(
                      'Detay için dokunun • Kaynaklı bilgi',
                      style: TextStyle(
                          fontSize: 11, color: AppColors.textTertiary),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showDetail(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
          borderRadius:
              BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => DraggableScrollableSheet(
        expand: false,
        initialChildSize: 0.85,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        builder: (_, scroll) => _MethodDetailSheet(
            method: method, data: data, controller: scroll),
      ),
    );
  }
}

class _MethodDetailSheet extends StatelessWidget {
  final IrrigationMethod method;
  final IrrigationGuideData data;
  final ScrollController controller;
  const _MethodDetailSheet(
      {required this.method, required this.data, required this.controller});

  String _range(List<int> r, String unit) =>
      r[0] == r[1] ? '${r[0]} $unit' : '${r[0]}-${r[1]} $unit';

  String _level(String v) {
    switch (v) {
      case 'very_low':
        return 'Çok düşük';
      case 'low':
        return 'Düşük';
      case 'low_medium':
        return 'Düşük-Orta';
      case 'medium':
        return 'Orta';
      case 'medium_high':
        return 'Orta-Yüksek';
      case 'high':
        return 'Yüksek';
      case 'very_high':
        return 'Çok yüksek';
      default:
        return v;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ListView(
      controller: controller,
      padding: const EdgeInsets.all(20),
      children: [
        Center(
          child: Container(
            width: 40,
            height: 4,
            decoration: BoxDecoration(
                color: AppColors.border,
                borderRadius: BorderRadius.circular(4)),
          ),
        ),
        const SizedBox(height: 12),
        Text(method.nameTr,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.bold)),
        const SizedBox(height: 6),
        Text(method.summary,
            style: const TextStyle(
                fontSize: 14, color: AppColors.textSecondary)),
        const SizedBox(height: 16),
        _DetailGrid(items: [
          _GridItem(
              label: 'Sulama verimi (randıman)',
              value: _range(method.efficiencyPctRange, '%')),
          if (method.waterSavingVsFurrowPctRange != null)
            _GridItem(
                label: 'Salmaya göre su tasarrufu',
                value: _range(method.waterSavingVsFurrowPctRange!, '%')),
          _GridItem(
              label: 'İlk yatırım',
              value:
                  '${method.initialInvestmentTlPerDecareRange[0]}-${method.initialInvestmentTlPerDecareRange[1]} TL/da'),
          _GridItem(
              label: 'İşletme maliyeti',
              value: _level(method.operationalCostLevel)),
          _GridItem(
              label: 'Enerji ihtiyacı',
              value: _level(method.energyRequirement)),
          _GridItem(
              label: 'İşçilik',
              value: _level(method.laborRequirement)),
        ]),
        const SizedBox(height: 16),
        _SectionTitle('Uygun ürünler'),
        Wrap(
          spacing: 6,
          runSpacing: 6,
          children: method.suitableCrops
              .map((c) => _Chip(
                  label: c,
                  color: AppColors.mint,
                  textColor: AppColors.emeraldDark))
              .toList(),
        ),
        const SizedBox(height: 12),
        _SectionTitle('Arazi/koşul'),
        Text(method.suitableTerrain),
        const SizedBox(height: 16),
        _SectionTitle('Artıları'),
        ...method.pros.map((p) => _BulletLine(text: p, icon: Icons.check_circle,
            color: AppColors.emerald)),
        const SizedBox(height: 12),
        _SectionTitle('Eksileri / dikkat'),
        ...method.cons.map((p) => _BulletLine(
            text: p, icon: Icons.error_outline, color: AppColors.warning)),
        const SizedBox(height: 16),
        if (method.requiresExpertConfirmation)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
                color: AppColors.warningBg,
                borderRadius: BorderRadius.circular(12)),
            child: const Row(
              children: [
                Icon(Icons.engineering, color: AppColors.warning),
                SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Bu sistem kurulum öncesi ziraat mühendisi veya DSİ/sulama birliği görüşü gerektirir.',
                    style: TextStyle(fontSize: 13),
                  ),
                ),
              ],
            ),
          ),
        const SizedBox(height: 16),
        _SectionTitle('Kaynaklar'),
        for (final ev in method.evidence)
          _EvidenceTile(evidence: ev, source: data.sourceById(ev.sourceId)),
      ],
    );
  }
}

// ─── Sekme 2: Geçiş Tasarrufları ─────────────────────────────────────────────

class _TransitionsTab extends StatelessWidget {
  final IrrigationGuideData data;
  const _TransitionsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(14),
          decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: BorderRadius.circular(14)),
          child: const Row(
            children: [
              Icon(Icons.savings, color: AppColors.emeraldDark),
              SizedBox(width: 10),
              Expanded(
                child: Text(
                  'Mevcut yönteminizden modern bir sisteme geçerseniz beklenen tasarruf ve verim artışı. Devlet hibe destekleri (KKYDP) geri ödeme süresini kısaltabilir.',
                  style: TextStyle(fontSize: 13),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        for (final t in data.transitions) ...[
          _TransitionCard(transition: t, data: data),
          const SizedBox(height: 12),
        ],
        const SizedBox(height: 8),
        _CalcDisclaimer(),
      ],
    );
  }
}

class _TransitionCard extends StatelessWidget {
  final TransitionExample transition;
  final IrrigationGuideData data;
  const _TransitionCard({required this.transition, required this.data});

  String _range(List<int> r, String unit) =>
      r[0] == r[1] ? '${r[0]} $unit' : '${r[0]}-${r[1]} $unit';

  @override
  Widget build(BuildContext context) {
    final from = data.methodById(transition.fromMethodId);
    final to = data.methodById(transition.toMethodId);
    return Card(
      color: AppColors.surface,
      shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(from?.nameTr ?? transition.fromMethodId,
                      style: const TextStyle(
                          fontWeight: FontWeight.w600,
                          color: AppColors.textSecondary)),
                ),
                const Icon(Icons.arrow_forward, color: AppColors.emerald),
                Expanded(
                  child: Text(to?.nameTr ?? transition.toMethodId,
                      textAlign: TextAlign.right,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          color: AppColors.emeraldDark)),
                ),
              ],
            ),
            const Divider(height: 20),
            _MetricRow(
                icon: Icons.water_drop,
                label: 'Su tasarrufu',
                value: _range(transition.waterSavingPctRange, '%')),
            if (transition.yieldIncreasePctRange != null)
              _MetricRow(
                  icon: Icons.eco,
                  label: 'Verim artışı',
                  value: _range(transition.yieldIncreasePctRange!, '%')),
            if (transition.paybackYearsRange != null)
              _MetricRow(
                  icon: Icons.schedule,
                  label: 'Geri ödeme süresi',
                  value: _range(transition.paybackYearsRange!, 'yıl')),
            if (transition.note != null) ...[
              const SizedBox(height: 8),
              Text(transition.note!,
                  style: const TextStyle(
                      fontSize: 12,
                      color: AppColors.textTertiary,
                      fontStyle: FontStyle.italic)),
            ],
            const SizedBox(height: 8),
            for (final ev in transition.evidence)
              _EvidenceTile(evidence: ev, source: data.sourceById(ev.sourceId)),
          ],
        ),
      ),
    );
  }
}

class _CalcDisclaimer extends StatelessWidget {
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.warningBg,
            borderRadius: BorderRadius.circular(12)),
        child: const Row(
          children: [
            Icon(Icons.info_outline, color: AppColors.warning),
            SizedBox(width: 8),
            Expanded(
              child: Text(
                'Verilen aralıklar kamu kaynaklarındaki ortalamalardır. Tarlanıza özel kesin hesap için il/ilçe tarım müdürlüğü veya DSİ ile görüşün.',
                style: TextStyle(fontSize: 12),
              ),
            ),
          ],
        ),
      );
}

// ─── Sekme 3: Genel İpuçları ────────────────────────────────────────────────

class _TipsTab extends StatelessWidget {
  final IrrigationGuideData data;
  const _TipsTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        for (final t in data.generalTips) ...[
          Card(
            color: AppColors.surface,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.lightbulb,
                          color: AppColors.warning, size: 22),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(t.title,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15)),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(t.detail,
                      style: const TextStyle(
                          fontSize: 13, color: AppColors.textSecondary)),
                  const SizedBox(height: 8),
                  for (final sid in t.sourceIds)
                    _SourceChip(source: data.sourceById(sid), id: sid),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
      ],
    );
  }
}

// ─── Sekme 4: Destekler & Kaynaklar ─────────────────────────────────────────

class _SourcesTab extends StatelessWidget {
  final IrrigationGuideData data;
  const _SourcesTab({required this.data});

  @override
  Widget build(BuildContext context) {
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Devlet destekleri'),
        for (final inc in data.incentives) ...[
          Card(
            color: AppColors.successBg,
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(inc.title,
                      style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                          color: AppColors.emeraldDark)),
                  const SizedBox(height: 6),
                  Text(inc.detail, style: const TextStyle(fontSize: 13)),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.all(10),
                    decoration: BoxDecoration(
                        color: AppColors.bg,
                        borderRadius: BorderRadius.circular(8)),
                    child: Row(
                      children: [
                        const Icon(Icons.assignment_turned_in,
                            color: AppColors.emerald, size: 18),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(inc.userAction,
                              style: const TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
        ],
        const SizedBox(height: 16),
        _SectionTitle('Resmi kaynaklar'),
        for (final s in data.sources) ...[
          Card(
            shape: const RoundedRectangleBorder(borderRadius: AppRadius.md),
            child: ListTile(
              leading: Icon(
                s.sourceType == 'official'
                    ? Icons.verified
                    : Icons.public,
                color: AppColors.emeraldDark,
              ),
              title: Text(s.title,
                  style: const TextStyle(
                      fontWeight: FontWeight.bold, fontSize: 13)),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.institution,
                      style: const TextStyle(fontSize: 12)),
                  Text(
                    'Güvenilirlik: ${s.reliability} • Erişim: ${s.retrievedAt}',
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textTertiary),
                  ),
                ],
              ),
              trailing: const Icon(Icons.open_in_new, size: 18),
              onTap: () => _open(s.url),
            ),
          ),
        ],
      ],
    );
  }

  Future<void> _open(String url) async {
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

// ─── Ortak ufak widget'lar ──────────────────────────────────────────────────

class _DisclaimerCard extends StatelessWidget {
  final String text;
  const _DisclaimerCard({required this.text});
  @override
  Widget build(BuildContext context) => Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(12),
            border: Border.all(color: AppColors.info.withValues(alpha: 0.3))),
        child: Row(
          children: [
            const Icon(Icons.info, color: AppColors.info),
            const SizedBox(width: 8),
            Expanded(
                child: Text(text,
                    style: const TextStyle(fontSize: 12, height: 1.4))),
          ],
        ),
      );
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final Color textColor;
  const _Chip(
      {required this.label, required this.color, required this.textColor});
  @override
  Widget build(BuildContext context) => Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration:
            BoxDecoration(color: color, borderRadius: BorderRadius.circular(20)),
        child: Text(label,
            style: TextStyle(
                color: textColor,
                fontSize: 12,
                fontWeight: FontWeight.w600)),
      );
}

class _SectionTitle extends StatelessWidget {
  final String text;
  const _SectionTitle(this.text);
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 8),
        child: Text(text.toUpperCase(),
            style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
                letterSpacing: 0.6,
                color: AppColors.textSecondary)),
      );
}

class _BulletLine extends StatelessWidget {
  final String text;
  final IconData icon;
  final Color color;
  const _BulletLine(
      {required this.text, required this.icon, required this.color});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 3),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(icon, color: color, size: 16),
            const SizedBox(width: 6),
            Expanded(
                child: Text(text, style: const TextStyle(fontSize: 13))),
          ],
        ),
      );
}

class _MetricRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  const _MetricRow(
      {required this.icon, required this.label, required this.value});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 4),
        child: Row(
          children: [
            Icon(icon, size: 18, color: AppColors.emerald),
            const SizedBox(width: 8),
            Expanded(
                child: Text(label, style: const TextStyle(fontSize: 13))),
            Text(value,
                style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    color: AppColors.emeraldDark)),
          ],
        ),
      );
}

class _GridItem {
  final String label;
  final String value;
  const _GridItem({required this.label, required this.value});
}

class _DetailGrid extends StatelessWidget {
  final List<_GridItem> items;
  const _DetailGrid({required this.items});
  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: items
          .map((i) => Container(
                width: (MediaQuery.of(context).size.width - 56) / 2,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: AppColors.border)),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(i.label,
                        style: const TextStyle(
                            fontSize: 11,
                            color: AppColors.textTertiary)),
                    const SizedBox(height: 4),
                    Text(i.value,
                        style: const TextStyle(
                            fontWeight: FontWeight.bold,
                            fontSize: 14,
                            color: AppColors.emeraldDark)),
                  ],
                ),
              ))
          .toList(),
    );
  }
}

class _EvidenceTile extends StatelessWidget {
  final IrrigationEvidence evidence;
  final IrrigationSource? source;
  const _EvidenceTile({required this.evidence, required this.source});

  Future<void> _open() async {
    if (source == null) return;
    final uri = Uri.parse(source!.url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
          color: AppColors.infoBg, borderRadius: BorderRadius.circular(8)),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('"${evidence.evidenceText}"',
              style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 6),
          InkWell(
            onTap: source != null ? _open : null,
            child: Row(
              children: [
                const Icon(Icons.link, size: 14, color: AppColors.info),
                const SizedBox(width: 4),
                Expanded(
                  child: Text(
                    source?.title ?? evidence.sourceId,
                    style: const TextStyle(
                        fontSize: 11,
                        color: AppColors.info,
                        decoration: TextDecoration.underline),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Sekme: Finansal Hesaplayıcı ────────────────────────────────────────────

class _CalculatorTab extends StatefulWidget {
  final IrrigationGuideData guide;
  const _CalculatorTab({required this.guide});
  @override
  State<_CalculatorTab> createState() => _CalculatorTabState();
}

class _CalculatorTabState extends State<_CalculatorTab> {
  static const _methods = [
    'Salma sulama',
    'Karık sulama',
    'Yağmurlama',
    'Center-pivot',
    'Mikro yağmurlama',
    'Damla sulama',
    'Yüzey altı damla (SDI)',
    'Elle sulama',
  ];

  String _current = 'Karık sulama';
  String _alternative = 'Damla sulama';
  final _areaCtrl = TextEditingController(text: '5');
  final _seasonMmCtrl = TextEditingController(text: '400');
  WaterPricesData? _prices;
  String _province = 'Konya';
  bool _deepWell = false;
  bool _withSubsidy = true;

  @override
  void initState() {
    super.initState();
    WaterPricesRepository.instance.load().then((d) {
      if (mounted) setState(() => _prices = d);
    });
  }

  @override
  void dispose() {
    _areaCtrl.dispose();
    _seasonMmCtrl.dispose();
    super.dispose();
  }

  CostResult? _calculate() {
    final p = _prices;
    if (p == null) return null;
    final area = double.tryParse(_areaCtrl.text.replaceAll(',', '.'));
    final mm = double.tryParse(_seasonMmCtrl.text.replaceAll(',', '.'));
    if (area == null || mm == null || area <= 0 || mm <= 0) return null;

    final waterPrice = p.waterPriceFor(_province);
    final pumpKwh = _deepWell
        ? p.defaults.pumpKwhPerM3DeepWell
        : p.defaults.pumpKwhPerM3ShallowWell;
    final invest = IrrigationCostEngine.investmentTlPerDecareFromGuide(
      guide: widget.guide,
      methodNameTr: _alternative,
    );

    return const IrrigationCostEngine().compute(CostFacts(
      areaDekar: area,
      seasonNetMmTotal: mm,
      currentMethod: _current,
      alternativeMethod: _alternative,
      waterTlPerM3: waterPrice,
      electricityTlPerKwh: p.defaults.electricityTlPerKwh,
      pumpKwhPerM3: pumpKwh,
      estimatedInvestmentTlPerDecare: invest,
      subsidyPct: _withSubsidy ? 0.50 : 0.0,
    ));
  }

  Future<void> _exportPdf(CostResult result) async {
    final p = _prices;
    if (p == null) return;
    final area = double.tryParse(_areaCtrl.text.replaceAll(',', '.')) ?? 0;
    final mm = double.tryParse(_seasonMmCtrl.text.replaceAll(',', '.')) ?? 0;
    final pumpKwh = _deepWell
        ? p.defaults.pumpKwhPerM3DeepWell
        : p.defaults.pumpKwhPerM3ShallowWell;

    try {
      await const IrrigationSavingsPdfService().generateAndOpen(
        IrrigationSavingsPdfInput(
          fieldName: 'Tarla',
          province: _province.isEmpty ? null : _province,
          areaDekar: area,
          seasonNetMm: mm,
          cropName: 'Genel',
          result: result,
          waterTlPerM3: p.waterPriceFor(_province),
          electricityTlPerKwh: p.defaults.electricityTlPerKwh,
          pumpKwhPerM3: pumpKwh,
          withSubsidy: _withSubsidy,
          farmerName: 'Çiftçi',
          createdAt: DateTime.now(),
        ),
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('PDF oluşturuldu ve açıldı.')),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('PDF oluşturulamadı: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_prices == null) {
      return const Center(child: CircularProgressIndicator());
    }
    final result = _calculate();
    final provinces = ['Türkiye ortalaması', ..._prices!.regions.map((r) => r.province)];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        _SectionTitle('Tarla Bilgileri'),
        const SizedBox(height: 8),
        Row(
          children: [
            Expanded(
              child: _NumField(
                controller: _areaCtrl,
                label: 'Alan (dekar)',
                suffix: 'da',
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: _NumField(
                controller: _seasonMmCtrl,
                label: 'Sezonluk ihtiyaç',
                suffix: 'mm',
              ),
            ),
          ],
        ),
        const SizedBox(height: 8),
        const Text(
          'Sezonluk ihtiyaç: bitkinin tüm sezon boyu kullandığı net su (mm). Domates ≈ 400-600, mısır ≈ 500-700.',
          style: TextStyle(fontSize: 11, color: AppColors.textTertiary),
        ),
        const SizedBox(height: 16),

        _SectionTitle('Mevcut → Alternatif'),
        const SizedBox(height: 8),
        _MethodDropdown(
          label: 'Şu anki yöntem',
          value: _current,
          values: _methods,
          onChanged: (v) => setState(() => _current = v),
        ),
        const SizedBox(height: 10),
        _MethodDropdown(
          label: 'Geçmek istediğin yöntem',
          value: _alternative,
          values: _methods,
          onChanged: (v) => setState(() => _alternative = v),
        ),
        const SizedBox(height: 16),

        _SectionTitle('Maliyet Ayarları'),
        const SizedBox(height: 8),
        _MethodDropdown(
          label: 'Bölge (su tarifesi için)',
          value: provinces.contains(_province) ? _province : provinces.first,
          values: provinces,
          onChanged: (v) => setState(
              () => _province = v == 'Türkiye ortalaması' ? '' : v),
        ),
        const SizedBox(height: 10),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _deepWell,
          onChanged: (v) => setState(() => _deepWell = v),
          title: const Text('Derin kuyu (pompa enerjisi yüksek)',
              style: TextStyle(fontSize: 13)),
          subtitle: Text(
            _deepWell
                ? '${_prices!.defaults.pumpKwhPerM3DeepWell} kWh/m³'
                : '${_prices!.defaults.pumpKwhPerM3ShallowWell} kWh/m³ (sığ kuyu)',
            style: const TextStyle(fontSize: 11),
          ),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          dense: true,
          value: _withSubsidy,
          onChanged: (v) => setState(() => _withSubsidy = v),
          title: const Text('KKYDP hibe desteği (%50)',
              style: TextStyle(fontSize: 13)),
          subtitle: const Text('Geri ödeme süresine etkisi',
              style: TextStyle(fontSize: 11)),
        ),
        const SizedBox(height: 16),

        if (result == null)
          Container(
            padding: const EdgeInsets.all(14),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Text(
              'Geçerli alan ve sezonluk ihtiyaç girin.',
              style: TextStyle(color: AppColors.warning),
            ),
          )
        else ...[
          _ResultPanel(result: result, disclaimer: _prices!.disclaimer),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: () => _exportPdf(result),
              icon: const Icon(Icons.picture_as_pdf_rounded),
              label: const Text('PDF Olarak İndir'),
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.emeraldDark,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ),
            ),
          ),
        ],
      ],
    );
  }
}

class _NumField extends StatelessWidget {
  final TextEditingController controller;
  final String label;
  final String suffix;
  const _NumField({
    required this.controller,
    required this.label,
    required this.suffix,
  });
  @override
  Widget build(BuildContext context) => Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: AppColors.textSecondary)),
          const SizedBox(height: 4),
          TextField(
            controller: controller,
            keyboardType:
                const TextInputType.numberWithOptions(decimal: true),
            onChanged: (_) => (context as Element).markNeedsBuild(),
            decoration: InputDecoration(
              suffixText: suffix,
              filled: true,
              fillColor: AppColors.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(10),
                borderSide: BorderSide(color: AppColors.border),
              ),
              isDense: true,
            ),
          ),
        ],
      );
}

class _MethodDropdown extends StatelessWidget {
  final String label;
  final String value;
  final List<String> values;
  final ValueChanged<String> onChanged;
  const _MethodDropdown({
    required this.label,
    required this.value,
    required this.values,
    required this.onChanged,
  });
  @override
  Widget build(BuildContext context) {
    final effective = values.contains(value) ? value : values.first;
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: AppColors.textSecondary)),
        const SizedBox(height: 4),
        DropdownButtonFormField<String>(
          initialValue: effective,
          isExpanded: true,
          items: values
              .map((v) => DropdownMenuItem(value: v, child: Text(v)))
              .toList(),
          onChanged: (v) => onChanged(v ?? values.first),
          decoration: InputDecoration(
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(10),
              borderSide: BorderSide(color: AppColors.border),
            ),
            isDense: true,
          ),
        ),
      ],
    );
  }
}

class _ResultPanel extends StatelessWidget {
  final CostResult result;
  final String disclaimer;
  const _ResultPanel({required this.result, required this.disclaimer});

  static String _vol(double m3) {
    if (m3 >= 1000) return '${(m3 / 1000).toStringAsFixed(1)} bin m³';
    return '${m3.toStringAsFixed(0)} m³';
  }

  static String _tl(double v) {
    if (v.abs() >= 1000000) return '${(v / 1000000).toStringAsFixed(1)} M TL';
    if (v.abs() >= 1000) return '${(v / 1000).toStringAsFixed(1)}K TL';
    return '${v.toStringAsFixed(0)} TL';
  }

  @override
  Widget build(BuildContext context) {
    final isPositive = result.savedTlPerSeason > 0;
    final headlineColor =
        isPositive ? AppColors.emerald : AppColors.textTertiary;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Vurgu kartı
        Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: isPositive
                  ? [AppColors.emerald, AppColors.emeraldDark]
                  : [AppColors.textTertiary, AppColors.textSecondary],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(14),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('SEZONLUK TASARRUF',
                  style: TextStyle(
                      color: Colors.white70,
                      fontSize: 11,
                      fontWeight: FontWeight.w700,
                      letterSpacing: 0.5)),
              const SizedBox(height: 4),
              Text(_tl(result.savedTlPerSeason),
                  style: const TextStyle(
                      color: Colors.white,
                      fontSize: 32,
                      fontWeight: FontWeight.w900)),
              Text(
                isPositive
                    ? '${_vol(result.savedM3)} su tasarrufu (yılda)'
                    : 'Bu geçişte finansal kazanç görünmüyor',
                style:
                    const TextStyle(color: Colors.white70, fontSize: 13),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),

        // Kıyas tablosu
        _CompareCard(
          title: 'Şu anki: ${result.current.method}',
          breakdown: result.current,
          color: headlineColor,
        ),
        const SizedBox(height: 8),
        _CompareCard(
          title: 'Alternatif: ${result.alternative.method}',
          breakdown: result.alternative,
          color: AppColors.emerald,
          highlight: true,
        ),
        const SizedBox(height: 12),

        // Yatırım + payback
        if (result.investmentTl != null)
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: AppColors.warning.withValues(alpha: 0.3)),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    const Icon(Icons.account_balance,
                        color: AppColors.warning, size: 18),
                    const SizedBox(width: 6),
                    const Text('Yatırım & Geri Ödeme',
                        style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: AppColors.warning)),
                  ],
                ),
                const SizedBox(height: 8),
                _Row('Tahmini yatırım',
                    _tl(result.investmentTl!)),
                _Row('Hibe sonrası net',
                    _tl(result.investmentAfterSubsidyTl!)),
                if (result.paybackYears != null)
                  _Row('Geri ödeme (hibesiz)',
                      '${result.paybackYears!.toStringAsFixed(1)} yıl'),
                if (result.paybackYearsWithSubsidy != null)
                  _Row('Geri ödeme (hibeli)',
                      '${result.paybackYearsWithSubsidy!.toStringAsFixed(1)} yıl'),
              ],
            ),
          ),
        const SizedBox(height: 12),

        Container(
          padding: const EdgeInsets.all(10),
          decoration: BoxDecoration(
            color: AppColors.infoBg,
            borderRadius: BorderRadius.circular(10),
          ),
          child: Row(
            children: [
              const Icon(Icons.info_outline,
                  size: 14, color: AppColors.info),
              const SizedBox(width: 6),
              Expanded(
                child: Text(disclaimer,
                    style: const TextStyle(
                        fontSize: 11, color: AppColors.textSecondary)),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _CompareCard extends StatelessWidget {
  final String title;
  final MethodCostBreakdown breakdown;
  final Color color;
  final bool highlight;
  const _CompareCard({
    required this.title,
    required this.breakdown,
    required this.color,
    this.highlight = false,
  });

  static String _tl(double v) {
    if (v >= 1000) return '${(v / 1000).toStringAsFixed(1)}K TL';
    return '${v.toStringAsFixed(0)} TL';
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: highlight ? color.withValues(alpha: 0.10) : AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: highlight ? color : AppColors.border,
          width: highlight ? 1.5 : 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(title,
                    style: TextStyle(
                        fontWeight: FontWeight.w800,
                        fontSize: 13,
                        color: color)),
              ),
              Text('verim %${(breakdown.efficiency * 100).toStringAsFixed(0)}',
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ],
          ),
          const SizedBox(height: 8),
          _Row('Verilen su',
              '${breakdown.grossM3.toStringAsFixed(0)} m³'),
          _Row('Su faturası', _tl(breakdown.waterCostTl)),
          _Row('Pompa elektriği', _tl(breakdown.energyCostTl)),
          const Divider(height: 14),
          _Row('Toplam', _tl(breakdown.totalCostTl), bold: true),
        ],
      ),
    );
  }
}

class _Row extends StatelessWidget {
  final String label;
  final String value;
  final bool bold;
  const _Row(this.label, this.value, {this.bold = false});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Row(
          children: [
            Expanded(
              child: Text(label,
                  style: TextStyle(
                      fontSize: 12,
                      fontWeight: bold ? FontWeight.w800 : FontWeight.normal,
                      color: AppColors.textPrimary)),
            ),
            Text(value,
                style: TextStyle(
                    fontSize: 13,
                    fontWeight: bold ? FontWeight.w800 : FontWeight.w600,
                    color: AppColors.textPrimary)),
          ],
        ),
      );
}

class _SourceChip extends StatelessWidget {
  final IrrigationSource? source;
  final String id;
  const _SourceChip({required this.source, required this.id});
  @override
  Widget build(BuildContext context) => Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Row(
          children: [
            const Icon(Icons.verified,
                size: 12, color: AppColors.emeraldDark),
            const SizedBox(width: 4),
            Expanded(
              child: Text(source?.institution ?? id,
                  style: const TextStyle(
                      fontSize: 11, color: AppColors.textTertiary)),
            ),
          ],
        ),
      );
}
