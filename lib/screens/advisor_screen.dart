import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../models/advisor_models.dart';
import '../services/app_providers.dart';
import '../services/rules/recommendation.dart';
import '../services/verified_advisor_service.dart';
import '../theme/app_theme.dart';

class AdvisorScreen extends ConsumerStatefulWidget {
  const AdvisorScreen({
    super.key,
    this.serviceOverride,
    this.showFieldPicker = true,
  });

  final VerifiedAdvisorService? serviceOverride;
  final bool showFieldPicker;

  @override
  ConsumerState<AdvisorScreen> createState() => _AdvisorScreenState();
}

class _AdvisorScreenState extends ConsumerState<AdvisorScreen> {
  final _controller = TextEditingController();
  String _selectedFieldId = '';
  AdvisorAnswer? _answer;
  String? _inputError;
  bool _loading = false;

  static const _examples = [
    'Yeni tarla nasıl çizerim?',
    'Maliyetleri nereden takip ederim?',
    'Bu hafta sulama gerekir mi?',
    'Domateste yaprak lekesi var',
  ];

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  Future<void> _submit([String? preset]) async {
    final question = (preset ?? _controller.text).trim();
    if (preset != null) {
      _controller.text = preset;
    }
    if (question.isEmpty) {
      setState(() {
        _inputError = 'Lütfen sorunuzu veya isteğinizi yazın.';
        _answer = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _inputError = null;
    });

    try {
      final VerifiedAdvisorService service =
          widget.serviceOverride ?? ref.read(advisorServiceProvider);
      final answer = await service.answer(
        AdvisorQuery(
          text: question,
          appContext: await _loadAppContext(),
          fieldContext: await _loadFieldContext(),
        ),
      );
      if (!mounted) return;
      setState(() => _answer = answer);
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _answer = AdvisorAnswer.noVerifiedSource(
          question: question,
          intent: AdvisorIntent.general,
        );
      });
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<AdvisorAppContext> _loadAppContext() async {
    if (!widget.showFieldPicker) return const AdvisorAppContext();
    final fields = ref.read(fieldMapsProvider).valueOrNull ?? const [];
    return AdvisorAppContext(
      fields: fields
          .map((field) {
            final id = field['id']?.toString() ?? '';
            if (id.isEmpty) return null;
            final crop = field['crop']?.toString();
            return AdvisorFieldSummary(
              fieldId: id,
              fieldName: field['name']?.toString() ?? 'Tarla',
              cropName: crop == null || crop.trim().isEmpty ? null : crop,
              areaDekar: _asDouble(field['area_dekar'] ?? field['areaDekar']),
            );
          })
          .whereType<AdvisorFieldSummary>()
          .toList(growable: false),
    );
  }

  double? _asDouble(Object? value) {
    if (value is num) return value.toDouble();
    if (value == null) return null;
    return double.tryParse(value.toString().replaceAll(',', '.'));
  }

  Future<AdvisorFieldContext?> _loadFieldContext() async {
    if (!widget.showFieldPicker || _selectedFieldId.isEmpty) return null;
    final fields = ref.read(fieldMapsProvider).valueOrNull ?? const [];
    Map<String, dynamic>? field;
    for (final item in fields) {
      if (item['id']?.toString() == _selectedFieldId) {
        field = item;
        break;
      }
    }
    if (field == null) return null;

    var crops = const <Map<String, dynamic>>[];
    var recs = const <Recommendation>[];
    try {
      crops = await ref
          .read(localDataRepositoryProvider)
          .loadFieldCrops(_selectedFieldId)
          .timeout(const Duration(seconds: 3));
    } catch (_) {}
    try {
      recs = await ref
          .read(fieldLiveTodosProvider(_selectedFieldId).future)
          .timeout(const Duration(seconds: 8));
    } catch (_) {}

    return AdvisorFieldContext(
      fieldId: _selectedFieldId,
      fieldName: field['name']?.toString() ?? 'Tarla',
      cropNames: crops
          .map((crop) => crop['name']?.toString() ?? '')
          .where((name) => name.isNotEmpty)
          .toList(growable: false),
      recommendations: recs
          .where((rec) => rec.sourceRefs.isNotEmpty)
          .map(
            (rec) => AdvisorFieldRecommendation(
              title: rec.title,
              reasonText: rec.reasonText,
              actionHint: rec.actionHint,
              activityType: rec.command?.activityType,
              sourceRefs: rec.sourceRefs,
            ),
          )
          .toList(growable: false),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: const Text('Danışmana Sor'),
      ),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
        children: [
          _IntroPanel(),
          const SizedBox(height: 14),
          _QuestionBox(
            controller: _controller,
            errorText: _inputError,
            loading: _loading,
            onSubmit: () => _submit(),
          ),
          const SizedBox(height: 10),
          _ExampleChips(
            examples: _examples,
            onSelected: (example) => _submit(example),
          ),
          if (widget.showFieldPicker) ...[
            const SizedBox(height: 14),
            _FieldPicker(
              selectedFieldId: _selectedFieldId,
              onChanged: (value) {
                setState(() => _selectedFieldId = value ?? '');
              },
            ),
          ],
          const SizedBox(height: 18),
          if (_loading)
            const Center(child: CircularProgressIndicator())
          else if (_answer != null)
            _AnswerCard(answer: _answer!),
        ],
      ),
    );
  }
}

class _IntroPanel extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 42,
            height: 42,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: AppColors.mint,
              borderRadius: AppRadius.sm,
            ),
            child: const Icon(
              Icons.verified_rounded,
              color: AppColors.emeraldDark,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Uygulama ve tarım danışmanı', style: AppText.h3(context)),
                const SizedBox(height: 4),
                Text(
                  'Uygulama kullanımı için yerel ekran bilgisini, tarımsal kararlar için yalnız Türkiye kaynaklı resmi kayıtları kullanır.',
                  style: AppText.sm(context),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _QuestionBox extends StatelessWidget {
  const _QuestionBox({
    required this.controller,
    required this.errorText,
    required this.loading,
    required this.onSubmit,
  });

  final TextEditingController controller;
  final String? errorText;
  final bool loading;
  final VoidCallback onSubmit;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        TextField(
          controller: controller,
          minLines: 3,
          maxLines: 5,
          textInputAction: TextInputAction.newline,
          decoration: InputDecoration(
            hintText: 'Sorununuzu veya isteğinizi yazın',
            errorText: errorText,
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: const BorderSide(color: AppColors.border),
            ),
            prefixIcon: const Icon(Icons.edit_note_rounded),
          ),
        ),
        const SizedBox(height: 10),
        SizedBox(
          height: 48,
          child: ElevatedButton.icon(
            onPressed: loading ? null : onSubmit,
            icon: const Icon(Icons.send_rounded),
            label: const Text('Yanıtla'),
          ),
        ),
      ],
    );
  }
}

class _ExampleChips extends StatelessWidget {
  const _ExampleChips({
    required this.examples,
    required this.onSelected,
  });

  final List<String> examples;
  final ValueChanged<String> onSelected;

  @override
  Widget build(BuildContext context) {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: [
        for (final example in examples)
          ActionChip(
            label: Text(example),
            avatar: const Icon(Icons.lightbulb_outline_rounded, size: 16),
            onPressed: () => onSelected(example),
          ),
      ],
    );
  }
}

class _FieldPicker extends ConsumerWidget {
  const _FieldPicker({
    required this.selectedFieldId,
    required this.onChanged,
  });

  final String selectedFieldId;
  final ValueChanged<String?> onChanged;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final fieldsAsync = ref.watch(fieldMapsProvider);
    return fieldsAsync.when(
      loading: () => const LinearProgressIndicator(),
      error: (_, __) => const SizedBox.shrink(),
      data: (fields) {
        if (fields.isEmpty) {
          return const SizedBox.shrink();
        }
        final value = fields.any((f) => f['id']?.toString() == selectedFieldId)
            ? selectedFieldId
            : '';
        return DropdownButtonFormField<String>(
          initialValue: value,
          decoration: InputDecoration(
            labelText: 'Tarla bağlamı',
            filled: true,
            fillColor: AppColors.surface,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
            ),
          ),
          items: [
            const DropdownMenuItem(
              value: '',
              child: Text('Tarla seçilmedi'),
            ),
            for (final field in fields)
              DropdownMenuItem(
                value: field['id']?.toString() ?? '',
                child: Text(field['name']?.toString() ?? 'Tarla'),
              ),
          ],
          onChanged: onChanged,
        );
      },
    );
  }
}

class _AnswerCard extends StatelessWidget {
  const _AnswerCard({required this.answer});

  final AdvisorAnswer answer;

  @override
  Widget build(BuildContext context) {
    final verified = answer.hasVerifiedSources;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: AppRadius.md,
        border: Border.all(
          color: verified ? AppColors.emerald : AppColors.warning,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                verified
                    ? Icons.verified_rounded
                    : Icons.report_gmailerrorred_rounded,
                color: verified ? AppColors.emeraldDark : AppColors.warning,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  answer.confidence.label,
                  style: AppText.label(context).copyWith(
                    color: verified ? AppColors.emeraldDark : AppColors.warning,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text('Kısa yanıt', style: AppText.h3(context)),
          const SizedBox(height: 4),
          Text(answer.shortAnswer, style: AppText.body(context)),
          if (answer.understoodSignals.isNotEmpty) ...[
            const SizedBox(height: 10),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                for (final signal in answer.understoodSignals)
                  Chip(
                    label: Text(signal),
                    visualDensity: VisualDensity.compact,
                  ),
              ],
            ),
          ],
          for (final section in answer.sections) ...[
            const SizedBox(height: 14),
            Text(section.title, style: AppText.h3(context)),
            const SizedBox(height: 5),
            for (final bullet in section.bullets)
              Padding(
                padding: const EdgeInsets.only(bottom: 5),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Padding(
                      padding: EdgeInsets.only(top: 7),
                      child: Icon(
                        Icons.circle,
                        size: 5,
                        color: AppColors.emeraldDark,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(child: Text(bullet, style: AppText.sm(context))),
                  ],
                ),
              ),
          ],
          const SizedBox(height: 14),
          Text('Kaynaklar', style: AppText.h3(context)),
          const SizedBox(height: 5),
          if (answer.sources.isEmpty)
            Text(
              'Bu konu için doğrulanmış kayıt bulunamadı.',
              style: AppText.sm(context),
            )
          else
            for (final source in answer.sources)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      source.isTrusted
                          ? Icons.menu_book_rounded
                          : Icons.info_outline_rounded,
                      size: 16,
                      color: source.isTrusted
                          ? AppColors.emeraldDark
                          : AppColors.textTertiary,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        source.displayTitle,
                        style: AppText.xs(context),
                      ),
                    ),
                  ],
                ),
              ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: AppColors.warningBg,
              borderRadius: AppRadius.sm,
            ),
            child: Text(answer.safetyNote, style: AppText.xs(context)),
          ),
        ],
      ),
    );
  }
}
