import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/app_database.dart';
import '../data/disease_types.dart';
import '../services/app_providers.dart';
import '../services/guide_engine.dart' show AlertSeverity;
import '../services/rules/recommendation.dart';
import '../theme/app_theme.dart';
import '../widgets/animated_route.dart';
import '../widgets/recommendation_card.dart';
import '../widgets/tap_scale.dart';
import 'field_detail_screen.dart';

/// Yapılacaklar Paneli — tüm tarlaların canlı tavsiye listesini tek ekranda
/// toplar. Aktivite panelindeki bildirimleri burada aksiyona çevrilebilir
/// kart olarak gösterir; her bitkinin sağlık durumu (hasta/cansız) ve
/// büyüme aşamasına göre öncelik düzenler.
///
/// Veri kaynağı: `fieldLiveTodosProvider` — tarla başına `Recommendation` listesi.
/// Her tarla için ayrı bir provider tetiklenir; tek bir aktivite log'u
/// güncellendiğinde sadece o tarlanın listesi tazelenir.
class TodoPanelScreen extends ConsumerWidget {
  const TodoPanelScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldMapsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Yapılacaklar'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Yenile',
            onPressed: () {
              ref.invalidate(fieldMapsProvider);
              for (final f in fieldsAsync.valueOrNull ?? const []) {
                final id = f['id']?.toString();
                if (id != null && id.isNotEmpty) {
                  ref.invalidate(fieldLiveTodosProvider(id));
                }
              }
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
              'Liste yüklenemedi: $e',
              textAlign: TextAlign.center,
              style: AppText.body(context),
            ),
          ),
        ),
        data: (fields) {
          if (fields.isEmpty) return _buildEmpty(context);
          return _AggregatedTodos(fields: fields);
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
              child: const Icon(Icons.checklist_rtl_rounded,
                  size: 56, color: AppColors.emerald),
            ),
            const SizedBox(height: 16),
            Text('Henüz Görev Yok',
                textAlign: TextAlign.center, style: AppText.h2(context)),
            const SizedBox(height: 6),
            Text(
              'Tarla eklediğinizde "Yapılacaklar" burada listelenir. '
              'Aktivite panelindeki uyarılar bu listede aksiyon kartlarına dönüşür.',
              textAlign: TextAlign.center,
              style: AppText.body(context),
            ),
          ],
        ),
      ),
    );
  }
}

/// Birden çok tarladan gelen tavsiyeleri tek listede toplar.
/// Aciliyet sırasına göre gruplandırır: ACİL → BUGÜN → BU HAFTA → İZLE.
class _AggregatedTodos extends ConsumerWidget {
  const _AggregatedTodos({required this.fields});

  final List<Map<String, dynamic>> fields;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    // Tarlaları tek tek gözleyip hepsinin Recommendation listesini birleştir.
    // Her tarla kendi `fieldLiveTodosProvider` üzerinden bağımsız çalışır.
    final aggregated = <_FieldTodo>[];
    bool anyLoading = false;

    for (final field in fields) {
      final fieldId = field['id']?.toString();
      if (fieldId == null || fieldId.isEmpty) continue;
      final asyncTodos = ref.watch(fieldLiveTodosProvider(fieldId));
      asyncTodos.when(
        loading: () => anyLoading = true,
        error: (_, __) {},
        data: (recs) {
          // CLAUDE.md sec 12 — bu panel aksiyon listesidir; uygunluk/bölge/
          // toprak bilgi notları (isInformational) görev olarak gösterilmez,
          // ürün ansiklopedisi ve tarla takip ekranındaki ayrı bölümde kalır.
          for (final r in recs) {
            if (r.isInformational) continue;
            aggregated.add(_FieldTodo(field: field, recommendation: r));
          }
        },
      );
    }

    if (anyLoading && aggregated.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    // Bitki sağlık özetleri — paneli aksiyon listesinin önünde gösterir.
    final healthSummary = _buildHealthSummary(ref);

    if (aggregated.isEmpty && healthSummary.isEmpty) {
      return _buildAllClearState(context);
    }

    aggregated.sort(_compareTodos);

    final urgent = aggregated
        .where((t) => t.recommendation.severity == AlertSeverity.critical)
        .toList();
    final today = aggregated
        .where((t) =>
            t.recommendation.severity == AlertSeverity.warning &&
            t.recommendation.gate == RecommendationGate.actionable)
        .toList();
    final week = aggregated
        .where((t) =>
            t.recommendation.severity == AlertSeverity.info &&
            t.recommendation.gate == RecommendationGate.actionable)
        .toList();
    final watch = aggregated
        .where((t) =>
            t.recommendation.gate != RecommendationGate.actionable &&
            t.recommendation.severity != AlertSeverity.critical)
        .toList();

    return RefreshIndicator(
      onRefresh: () async {
        for (final field in fields) {
          final id = field['id']?.toString();
          if (id != null && id.isNotEmpty) {
            ref.invalidate(fieldLiveTodosProvider(id));
          }
        }
        await Future<void>.delayed(const Duration(milliseconds: 300));
      },
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _buildHeaderCard(
            context,
            urgent: urgent.length,
            today: today.length,
            week: week.length,
          ),
          const SizedBox(height: 14),
          if (healthSummary.isNotEmpty) ...[
            _SectionHeader(label: 'BİTKİ SAĞLIĞI', count: healthSummary.length),
            for (final w in healthSummary) w,
            const SizedBox(height: 16),
          ],
          if (urgent.isNotEmpty) ...[
            _SectionHeader(label: 'ACİL', count: urgent.length),
            for (final t in urgent) _buildTodoCard(context, ref, t),
            const SizedBox(height: 16),
          ],
          if (today.isNotEmpty) ...[
            _SectionHeader(label: 'BUGÜN', count: today.length),
            for (final t in today) _buildTodoCard(context, ref, t),
            const SizedBox(height: 16),
          ],
          if (week.isNotEmpty) ...[
            _SectionHeader(label: 'BU HAFTA', count: week.length),
            for (final t in week) _buildTodoCard(context, ref, t),
            const SizedBox(height: 16),
          ],
          if (watch.isNotEmpty) ...[
            _SectionHeader(label: 'İZLE', count: watch.length),
            for (final t in watch) _buildTodoCard(context, ref, t),
            const SizedBox(height: 16),
          ],
        ],
      ),
    );
  }

  Widget _buildAllClearState(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.check_circle_rounded,
                size: 72, color: AppColors.emerald),
            const SizedBox(height: 16),
            Text('Bugün Acil Bir Şey Yok',
                textAlign: TextAlign.center, style: AppText.h2(context)),
            const SizedBox(height: 8),
            Text(
              'Bitkilerin yolunda. Aktivite kaydı yaptıkça liste tazelenir.',
              textAlign: TextAlign.center,
              style: AppText.body(context),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildHeaderCard(
    BuildContext context, {
    required int urgent,
    required int today,
    required int week,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: AppGradients.emeraldCard,
        borderRadius: BorderRadius.circular(18),
        boxShadow: AppShadows.md,
      ),
      child: Row(
        children: [
          const Icon(Icons.checklist_rtl_rounded,
              color: Colors.white, size: 28),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Yapılacaklar',
                  style: AppText.h3(context).copyWith(color: Colors.white),
                ),
                const SizedBox(height: 4),
                Wrap(
                  spacing: 8,
                  runSpacing: 4,
                  children: [
                    if (urgent > 0)
                      _miniChip(
                          color: const Color(0xFFFFEBEE),
                          fg: const Color(0xFFB71C1C),
                          text: '$urgent acil'),
                    if (today > 0)
                      _miniChip(
                          color: const Color(0xFFFFF8E1),
                          fg: const Color(0xFFF57C00),
                          text: '$today bugün'),
                    if (week > 0)
                      _miniChip(
                          color: Colors.white.withValues(alpha: 0.18),
                          fg: Colors.white,
                          text: '$week bu hafta'),
                    if (urgent == 0 && today == 0 && week == 0)
                      _miniChip(
                          color: Colors.white.withValues(alpha: 0.18),
                          fg: Colors.white,
                          text: 'Hepsi yolunda'),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _miniChip(
      {required Color color, required Color fg, required String text}) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          color: fg,
          fontSize: 11,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }

  /// Tüm tarlalardaki hasta/cansız bitkilerin özetini liste olarak verir.
  /// Her tarla için ayrı satır — kullanıcı tıklayınca o tarlanın detayına gider.
  List<Widget> _buildHealthSummary(WidgetRef ref) {
    final widgets = <Widget>[];
    for (final field in fields) {
      final id = field['id']?.toString();
      if (id == null || id.isEmpty) continue;
      final plants =
          ref.watch(fieldPlantInstancesProvider(id)).valueOrNull ?? const [];
      final diseasedPlants = plants
          .where((p) => p.healthStatus == DiseaseTypes.statusDiseased)
          .toList();
      final deadPlants = plants
          .where((p) => p.healthStatus == DiseaseTypes.statusDead)
          .toList();
      if (diseasedPlants.isEmpty && deadPlants.isEmpty) continue;
      widgets.add(_PlantHealthRow(
        field: field,
        diseased: diseasedPlants,
        dead: deadPlants,
      ));
    }
    return widgets;
  }

  Widget _buildTodoCard(BuildContext context, WidgetRef ref, _FieldTodo todo) {
    return _TodoListItem(
      fieldName: todo.field['name']?.toString() ?? 'Tarla',
      onFieldTap: () {
        Navigator.of(context).push(
          AnimatedRoute.scaleFade(FieldDetailScreen(fieldData: todo.field)),
        );
      },
      child: RecommendationCard(
        recommendation: todo.recommendation,
        onShown: () {
          ref.read(recommendationLedgerProvider).markShown(
                ruleKey: todo.recommendation.ruleKey,
                target: todo.recommendation.target,
              );
        },
        onLogged: () {
          final fieldId = todo.field['id']?.toString();
          if (fieldId != null) {
            ref.invalidate(fieldLiveTodosProvider(fieldId));
          }
        },
      ),
    );
  }

  static int _compareTodos(_FieldTodo a, _FieldTodo b) {
    final sa = _severityOrder(a.recommendation.severity);
    final sb = _severityOrder(b.recommendation.severity);
    if (sa != sb) return sa - sb;
    return a.recommendation.ruleKey.compareTo(b.recommendation.ruleKey);
  }

  static int _severityOrder(AlertSeverity s) {
    switch (s) {
      case AlertSeverity.critical:
        return 0;
      case AlertSeverity.warning:
        return 1;
      case AlertSeverity.info:
        return 2;
    }
  }
}

class _FieldTodo {
  final Map<String, dynamic> field;
  final Recommendation recommendation;

  const _FieldTodo({required this.field, required this.recommendation});
}

/// Tarla başlığı + içine yerleşen `RecommendationCard`. Aynı tarladaki
/// arka arkaya gelen kartlar için tek başlık tekrarına gerek yok ama
/// burada okunabilirlik için her kart kendi başlığını taşır.
class _TodoListItem extends StatelessWidget {
  const _TodoListItem({
    required this.fieldName,
    required this.onFieldTap,
    required this.child,
  });

  final String fieldName;
  final VoidCallback onFieldTap;
  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          TapScale(
            onTap: onFieldTap,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
              child: Row(
                children: [
                  const Icon(Icons.landscape_rounded,
                      size: 14, color: AppColors.emeraldDark),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Text(
                      fieldName,
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary,
                        letterSpacing: 0.3,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 14, color: AppColors.textTertiary),
                ],
              ),
            ),
          ),
          child,
        ],
      ),
    );
  }
}

class _PlantHealthRow extends StatelessWidget {
  const _PlantHealthRow({
    required this.field,
    required this.diseased,
    required this.dead,
  });

  final Map<String, dynamic> field;
  final List<FieldPlantInstance> diseased;
  final List<FieldPlantInstance> dead;

  @override
  Widget build(BuildContext context) {
    final fieldName = field['name']?.toString() ?? 'Tarla';
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
            border: Border.all(color: AppColors.error.withValues(alpha: 0.25)),
            boxShadow: AppShadows.sm,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(7),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.12),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Icon(Icons.coronavirus_rounded,
                        size: 16, color: AppColors.error),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      fieldName,
                      style: AppText.h3(context),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const Icon(Icons.chevron_right_rounded,
                      size: 18, color: AppColors.textTertiary),
                ],
              ),
              const SizedBox(height: 10),
              if (diseased.isNotEmpty) ...[
                _summaryLine(
                  color: AppColors.error,
                  icon: Icons.priority_high_rounded,
                  text: '${diseased.length} hasta bitki',
                  hint: _diseaseHint(diseased),
                ),
                const SizedBox(height: 6),
              ],
              if (dead.isNotEmpty)
                _summaryLine(
                  color: const Color(0xFF424242),
                  icon: Icons.close_rounded,
                  text: '${dead.length} cansız bitki',
                  hint: 'Hasarı kaldır, çevresindeki bitkileri kontrol et',
                ),
              const SizedBox(height: 8),
              Container(
                padding:
                    const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.mint,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.lightbulb_rounded,
                        size: 13, color: AppColors.emeraldDark),
                    const SizedBox(width: 5),
                    Flexible(
                      child: Text(
                        diseased.isNotEmpty
                            ? 'Öneri: Hasta bitkileri izole et, etiketteki '
                                'doza uygun BKÜ ile uygula'
                            : 'Öneri: Cansız kalıntıları temizle, çevreyi gözle',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: AppColors.emeraldDark,
                          height: 1.3,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _diseaseHint(List<FieldPlantInstance> ds) {
    final unique = <String>{};
    for (final d in ds) {
      final t = d.diseaseType?.trim();
      if (t != null && t.isNotEmpty) unique.add(t);
    }
    if (unique.isEmpty) {
      return 'Hastalık türü kaydedilmedi — yakından kontrol et';
    }
    if (unique.length == 1) return 'Tür: ${unique.first}';
    return 'Türler: ${unique.take(3).join(", ")}';
  }

  Widget _summaryLine({
    required Color color,
    required IconData icon,
    required String text,
    required String hint,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, size: 15, color: color),
        const SizedBox(width: 8),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                text,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w700,
                  color: color,
                ),
              ),
              const SizedBox(height: 1),
              Text(
                hint,
                style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: AppColors.textSecondary,
                  height: 1.3,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}

class _SectionHeader extends StatelessWidget {
  const _SectionHeader({required this.label, this.count});

  final String label;
  final int? count;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8, top: 4),
      child: Row(
        children: [
          Text(
            label,
            style: AppText.label(context).copyWith(
              fontWeight: FontWeight.w800,
              letterSpacing: 1.2,
              color: AppColors.textSecondary,
            ),
          ),
          if (count != null) ...[
            const SizedBox(width: 6),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
              decoration: BoxDecoration(
                color: AppColors.mint,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Text(
                '$count',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w800,
                  color: AppColors.emeraldDark,
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
