import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/activity_types.dart';
import '../services/app_providers.dart';
import '../theme/app_theme.dart';
import '../widgets/floating_toast.dart';
import '../widgets/tap_scale.dart';

/// Tarlam Günlüğü — tüm tarlaların kronolojik aktivite akışı.
/// Gruplama: Bugün / Dün / Bu Hafta / Bu Ay / Daha Eski.
class FarmJournalScreen extends ConsumerStatefulWidget {
  const FarmJournalScreen({super.key, this.fieldId});

  /// Null ise tüm tarlalar listelenir; aksi halde sadece ilgili tarla.
  final String? fieldId;

  @override
  ConsumerState<FarmJournalScreen> createState() => _FarmJournalScreenState();
}

class _FarmJournalScreenState extends ConsumerState<FarmJournalScreen> {
  String? _fieldFilter;
  final Set<String> _typeFilter = <String>{};

  @override
  void initState() {
    super.initState();
    _fieldFilter = widget.fieldId;
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(localDataRepositoryProvider);
    final fieldsAsync = ref.watch(fieldMapsProvider);

    return Scaffold(
      backgroundColor: AppColors.bg,
      appBar: AppBar(
        title: Text('Tarlam Günlüğü', style: AppText.h2(context)),
        backgroundColor: AppColors.surface,
        elevation: 0,
      ),
      body: Column(
        children: [
          _buildFilters(fieldsAsync),
          Expanded(
            child: StreamBuilder<List<Map<String, dynamic>>>(
              stream: repo.watchActivityLog(
                fieldId: _fieldFilter,
                types: _typeFilter,
              ),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting &&
                    !snap.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final entries = (snap.data ?? const [])
                    .where(
                        (entry) => entry['source']?.toString() != 'auto_seed')
                    .toList(growable: false);
                if (entries.isEmpty) {
                  return _buildEmpty();
                }
                return _buildGroupedList(entries);
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFilters(AsyncValue<List<Map<String, dynamic>>> fieldsAsync) {
    return Container(
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      color: AppColors.surface,
      child: SizedBox(
        height: 48,
        child: ListView(
          scrollDirection: Axis.horizontal,
          children: [
            _buildFieldChip(fieldsAsync),
            const SizedBox(width: 8),
            ...ActivityType.quickLogOrder.map((t) => Padding(
                  padding: const EdgeInsets.only(right: 8),
                  child: _buildTypeChip(t),
                )),
            _buildTypeChip(ActivityType.planting),
          ],
        ),
      ),
    );
  }

  Widget _buildFieldChip(AsyncValue<List<Map<String, dynamic>>> fieldsAsync) {
    final fields = fieldsAsync.value ?? const <Map<String, dynamic>>[];
    final selectedName = _fieldFilter == null
        ? 'Tüm Tarlalar'
        : (fields.firstWhere(
              (f) => f['id'] == _fieldFilter,
              orElse: () => <String, dynamic>{},
            )['name'] as String? ??
            'Tarla');
    return TapScale(
      onTap: () async {
        final picked = await showModalBottomSheet<String?>(
          context: context,
          builder: (_) => _FieldPickerSheet(
            fields: fields,
            selected: _fieldFilter,
          ),
        );
        if (picked == '__none__') {
          setState(() => _fieldFilter = null);
        } else if (picked != null) {
          setState(() => _fieldFilter = picked);
        }
      },
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: _fieldFilter == null
              ? AppColors.mint
              : AppColors.emerald.withValues(alpha: 0.18),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.emerald.withValues(alpha: 0.35)),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(Icons.landscape_rounded,
                size: 18, color: AppColors.emeraldDark),
            const SizedBox(width: 6),
            Text(
              selectedName,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(width: 6),
            const Icon(Icons.arrow_drop_down, size: 18),
          ],
        ),
      ),
    );
  }

  Widget _buildTypeChip(String type) {
    final active = _typeFilter.contains(type);
    final color = ActivityType.color(type);
    return TapScale(
      onTap: () => setState(() {
        if (active) {
          _typeFilter.remove(type);
        } else {
          _typeFilter.add(type);
        }
      }),
      child: Container(
        constraints: const BoxConstraints(minHeight: 48),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: active ? color.withValues(alpha: 0.2) : AppColors.bg,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: active ? color.withValues(alpha: 0.5) : AppColors.border,
          ),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(ActivityType.icon(type), size: 17, color: color),
            const SizedBox(width: 6),
            Text(
              ActivityType.label(type),
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: active ? AppColors.textPrimary : AppColors.textSecondary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmpty() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 96,
              height: 96,
              decoration: const BoxDecoration(
                color: AppColors.mint,
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.event_note_rounded,
                size: 48,
                color: AppColors.emeraldDark,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              'Henüz günlük kaydı yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: AppColors.textPrimary,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'Sulama, gübreleme, gözlem, ilaçlama ve hasat kayıtların burada tarih sırasıyla birikir.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: AppColors.textSecondary,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 14),
            _buildEmptyHint(
              Icons.check_circle_outline_rounded,
              'İlk kayıt için tarla detayında yaptığın işi seç.',
            ),
            const SizedBox(height: 8),
            _buildEmptyHint(
              Icons.notes_rounded,
              'Miktar, ürün ve not girersen kayıtlar daha okunaklı olur.',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyHint(IconData icon, String text) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Icon(icon, size: 18, color: AppColors.emeraldDark),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              text,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildGroupedList(List<Map<String, dynamic>> entries) {
    final groups = _groupByBucket(entries);
    final children = <Widget>[
      _buildGuideCard(entries),
      const SizedBox(height: 4),
    ];
    for (final label in groups.keys) {
      final items = groups[label]!;
      children.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 14, 0, 6),
          child: Text(
            label,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w800,
              color: AppColors.textTertiary,
              letterSpacing: 0.5,
            ),
          ),
        ),
      );
      children.addAll(items.map(_buildEntryCard));
    }

    return ListView(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      children: children,
    );
  }

  Widget _buildGuideCard(List<Map<String, dynamic>> entries) {
    final today = DateTime.now();
    final todayStart = DateTime(today.year, today.month, today.day);
    final todayCount = entries.where((entry) {
      final date = entry['date'];
      if (date is! DateTime) return false;
      final dayStart = DateTime(date.year, date.month, date.day);
      return dayStart == todayStart;
    }).length;
    final last = entries.isEmpty ? null : entries.first;
    final lastType = last == null
        ? null
        : ActivityType.label(last['type'] as String? ?? ActivityType.other);
    final guide = _guideTextForLastEntry(last);
    final activeFilters = _typeFilter.map(ActivityType.label).join(', ');

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: AppColors.mint,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.emerald.withValues(alpha: 0.25)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: AppColors.emeraldDark.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Icon(Icons.assignment_turned_in_rounded,
                    color: AppColors.emeraldDark, size: 20),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Günlük özeti',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: [
              _summaryPill('Bugün', '$todayCount kayıt'),
              _summaryPill('Toplam', '${entries.length} kayıt'),
              if (lastType != null) _summaryPill('Son işlem', lastType),
              if (activeFilters.isNotEmpty)
                _summaryPill('Filtre', activeFilters),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            guide,
            style: const TextStyle(
              fontSize: 14,
              height: 1.4,
              color: AppColors.textSecondary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _summaryPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Text(
        '$label: $value',
        style: const TextStyle(
          fontSize: 13,
          fontWeight: FontWeight.w700,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildEntryCard(Map<String, dynamic> entry) {
    final type = entry['type'] as String? ?? ActivityType.other;
    final color = ActivityType.color(type);
    final date = entry['date'] as DateTime;
    final meta = entry['metadata'] as Map<String, dynamic>?;
    final fieldName = entry['field_name'] as String?;
    final cropName =
        entry['crop_name'] as String? ?? _stringValue(meta?['crop_name']);
    return TapScale(
      onTap: () => _showEntryOptions(entry),
      child: Container(
        margin: const EdgeInsets.only(bottom: 10),
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: AppColors.border),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(ActivityType.icon(type), color: color, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Expanded(
                        child: Text(
                          _entryTitle(type),
                          style: const TextStyle(
                            fontSize: 15,
                            fontWeight: FontWeight.w800,
                            color: AppColors.textPrimary,
                          ),
                        ),
                      ),
                      Text(
                        _formatTime(date),
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textTertiary,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  if (fieldName != null || cropName != null) ...[
                    const SizedBox(height: 4),
                    Text(
                      [
                        if (fieldName != null) fieldName,
                        if (cropName != null) cropName,
                      ].join(' · '),
                      style: const TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textSecondary,
                      ),
                    ),
                  ],
                  _buildDetailPills(entry, type, meta),
                  _buildNoteBlock(meta),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailPills(
    Map<String, dynamic> entry,
    String type,
    Map<String, dynamic>? meta,
  ) {
    final details = _entryDetails(entry, type, meta);
    if (details.isEmpty) return const SizedBox.shrink();
    return Padding(
      padding: const EdgeInsets.only(top: 10),
      child: Wrap(
        spacing: 8,
        runSpacing: 8,
        children: details
            .map((item) => _detailPill(item.$1, item.$2))
            .toList(growable: false),
      ),
    );
  }

  Widget _detailPill(String label, String value) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: RichText(
        text: TextSpan(
          style: const TextStyle(
            fontSize: 13,
            height: 1.25,
            color: AppColors.textSecondary,
          ),
          children: [
            TextSpan(
              text: '$label: ',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimary,
              ),
            ),
            TextSpan(text: value),
          ],
        ),
      ),
    );
  }

  Widget _buildNoteBlock(Map<String, dynamic>? meta) {
    final note = _stringValue(meta?['note']);
    if (note == null) return const SizedBox.shrink();
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 10),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.bg,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(Icons.notes_rounded,
              size: 16, color: AppColors.textTertiary),
          const SizedBox(width: 6),
          Expanded(
            child: Text(
              note,
              style: const TextStyle(
                fontSize: 13,
                color: AppColors.textSecondary,
                height: 1.35,
              ),
            ),
          ),
        ],
      ),
    );
  }

  List<(String, String)> _entryDetails(
    Map<String, dynamic> entry,
    String type,
    Map<String, dynamic>? meta,
  ) {
    final details = <(String, String)>[];
    final seen = <String>{};
    void add(String label, Object? raw, {String? unit}) {
      final value = _displayValue(raw, unit: unit);
      if (value == null) return;
      final key = '$label|$value'.toLowerCase();
      if (seen.add(key)) details.add((label, value));
    }

    final qty = entry['quantity'] ?? meta?['quantity'];
    final unit = entry['unit'] ??
        meta?['quantity_unit'] ??
        ActivityType.quantityUnit(type);

    switch (type) {
      case ActivityType.watering:
        add('Süre', qty, unit: unit?.toString());
        add('Yöntem',
            meta?['irrigation_method'] ?? meta?['application_method']);
        add('Su', meta?['water_liters'], unit: 'L');
        add('Etkili su', meta?['effective_water_mm'], unit: 'mm');
        add('Dönem', meta?['stage_label']);
        break;
      case ActivityType.fertilizing:
        add('Miktar', qty, unit: unit?.toString());
        add('Gübre', meta?['fertilizer_name'] ?? meta?['fertilizer_formula']);
        add('Dönem', meta?['growth_stage']);
        break;
      case ActivityType.spraying:
        add('Karışım', qty, unit: unit?.toString());
        add('İlaç', meta?['pesticide_name']);
        add('Etken madde', meta?['active_ingredient']);
        add('Hedef', meta?['target_pest']);
        add('Hasat bekleme', meta?['preharvest_interval_days'], unit: 'gün');
        break;
      case ActivityType.scouting:
        add('Konu', meta?['target_pest'] ?? meta?['scouting_target']);
        final decision = meta?['ipm_decision'];
        if (decision is Map) {
          add('Durum', decision['status_label']);
          add('Eşik', decision['threshold']);
        } else {
          add('Durum', _thresholdLabel(meta?['threshold_status']));
        }
        break;
      case ActivityType.harvest:
        add('Hasat', qty, unit: unit?.toString());
        add('Kalite', meta?['quality_note']);
        break;
      case ActivityType.planting:
        add('Toprak', _soilTypeLabel(meta?['soil_type']));
        add('Sulama planı', _irrigationMethodLabel(meta?['irrigation_method']));
        add('Tarım şekli', _productionSystemLabel(meta?['production_system']));
        add('Adet hedefi', meta?['target_plant_count'], unit: 'bitki');
        add('Sıra arası', meta?['row_spacing_cm'], unit: 'cm');
        add('Bitki arası', meta?['plant_spacing_cm'], unit: 'cm');
        add('Sulama aralığı', meta?['water_interval_days'], unit: 'gün');
        break;
      default:
        add('Miktar', qty, unit: unit?.toString());
    }

    return details.take(6).toList(growable: false);
  }

  String _entryTitle(String type) {
    switch (type) {
      case ActivityType.watering:
        return 'Sulama kaydı';
      case ActivityType.fertilizing:
        return 'Gübreleme kaydı';
      case ActivityType.spraying:
        return 'İlaçlama kaydı';
      case ActivityType.scouting:
        return 'Gözlem kaydı';
      case ActivityType.harvest:
        return 'Hasat kaydı';
      case ActivityType.planting:
        return 'Ekim kaydı';
      default:
        return 'Tarla notu';
    }
  }

  String _guideTextForLastEntry(Map<String, dynamic>? last) {
    if (last == null) {
      return 'Günlük, tarladaki gerçek işlemleri sade bir sıraya dizer.';
    }
    final type = last['type'] as String? ?? ActivityType.other;
    switch (type) {
      case ActivityType.watering:
        return 'Son işlem sulama. Bir sonraki kontrolde toprağın nemini ve yapraklarda solma olup olmadığını birlikte değerlendir.';
      case ActivityType.fertilizing:
        return 'Son işlem gübreleme. Besinin yıkanmaması için aşırı sulamadan kaçın ve gelişim dönemini notlarla takip et.';
      case ActivityType.spraying:
        return 'Son işlem ilaçlama. Hasat bekleme süresini, rüzgarı ve hedef zararlıyı aynı kayıtta tutmak karar vermeyi kolaylaştırır.';
      case ActivityType.scouting:
        return 'Son işlem gözlem. Aynı noktaları birkaç gün içinde tekrar kontrol etmek zararlı baskısını daha net gösterir.';
      case ActivityType.harvest:
        return 'Son işlem hasat. Miktar ve kalite notları sezon sonunda gelir-maliyet hesabını güçlendirir.';
      case ActivityType.planting:
        return 'Son işlem ekim. Sıra arası, bitki arası ve sulama aralığı kayıtları bakım planının temelidir.';
      default:
        return 'Son kayıt tarla notu. Kısa ve ölçülebilir notlar sonraki kararı daha net hale getirir.';
    }
  }

  String? _displayValue(Object? raw, {String? unit}) {
    if (raw == null) return null;
    final text = raw is num ? _formatQty(raw) : raw.toString().trim();
    if (text.isEmpty) return null;
    if (unit == null || unit.trim().isEmpty) return text;
    return '$text ${unit.trim()}';
  }

  String? _stringValue(Object? raw) {
    if (raw == null) return null;
    final text = raw.toString().trim();
    return text.isEmpty ? null : text;
  }

  String? _thresholdLabel(Object? raw) {
    switch (raw?.toString()) {
      case 'belowThreshold':
        return 'Eşik altında';
      case 'followUp':
        return 'Takip gerekli';
      case 'chemicalAllowed':
        return 'Eşik aşıldı';
      case 'criticalNoChemical':
        return 'Kritik uyarı';
      default:
        return _stringValue(raw);
    }
  }

  String? _soilTypeLabel(Object? raw) {
    switch (raw?.toString()) {
      case 'loamy':
        return 'Tınlı';
      case 'clay':
        return 'Killi';
      case 'sandy':
        return 'Kumlu';
      case 'volcanic':
        return 'Volkanik';
      default:
        return _stringValue(raw);
    }
  }

  String? _irrigationMethodLabel(Object? raw) {
    switch (raw?.toString()) {
      case 'drip':
        return 'Damla sulama';
      case 'furrow':
        return 'Karık sulama';
      case 'sprinkler':
        return 'Yağmurlama';
      case 'hand':
        return 'El ile sulama';
      default:
        return _stringValue(raw);
    }
  }

  String? _productionSystemLabel(Object? raw) {
    switch (raw?.toString()) {
      case 'openField':
        return 'Açık tarla';
      case 'greenhouse':
        return 'Örtüaltı / sera';
      case 'goodAgriculture':
        return 'İyi tarım uygulaması';
      case 'organic':
        return 'Organik tarım';
      case 'dryFarming':
        return 'Kuru tarım';
      default:
        return _stringValue(raw);
    }
  }

  String _formatQty(num v) {
    if (v == v.toInt()) return v.toInt().toString();
    return v.toStringAsFixed(1);
  }

  Future<void> _showEntryOptions(Map<String, dynamic> entry) async {
    final action = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: AppColors.bg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (_) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: const Icon(Icons.delete_outline, color: AppColors.error),
              title: Text(
                'Kaydı sil',
                style: TextStyle(color: AppColors.error),
              ),
              onTap: () => Navigator.pop(context, 'delete'),
            ),
            ListTile(
              leading: const Icon(Icons.close),
              title: const Text('Kapat'),
              onTap: () => Navigator.pop(context),
            ),
          ],
        ),
      ),
    );
    if (action == 'delete') {
      final repo = ref.read(localDataRepositoryProvider);
      await repo.deleteActivity(entry['id'] as String);
      if (!mounted) return;
      AppToast.show(context, message: 'Kayıt silindi', type: ToastType.success);
    }
  }

  Map<String, List<Map<String, dynamic>>> _groupByBucket(
      List<Map<String, dynamic>> entries) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final weekStart = today.subtract(Duration(days: now.weekday - 1));
    final monthStart = DateTime(now.year, now.month, 1);

    final groups = <String, List<Map<String, dynamic>>>{
      'BUGÜN': [],
      'DÜN': [],
      'BU HAFTA': [],
      'BU AY': [],
      'DAHA ESKİ': [],
    };

    for (final e in entries) {
      final d = e['date'] as DateTime;
      final dayStart = DateTime(d.year, d.month, d.day);
      if (dayStart == today) {
        groups['BUGÜN']!.add(e);
      } else if (dayStart == yesterday) {
        groups['DÜN']!.add(e);
      } else if (dayStart
          .isAfter(weekStart.subtract(const Duration(days: 1)))) {
        groups['BU HAFTA']!.add(e);
      } else if (dayStart
          .isAfter(monthStart.subtract(const Duration(days: 1)))) {
        groups['BU AY']!.add(e);
      } else {
        groups['DAHA ESKİ']!.add(e);
      }
    }
    groups.removeWhere((_, v) => v.isEmpty);
    return groups;
  }

  String _formatTime(DateTime d) {
    final now = DateTime.now();
    final dayStart = DateTime(d.year, d.month, d.day);
    final todayStart = DateTime(now.year, now.month, now.day);
    final hh = d.hour.toString().padLeft(2, '0');
    final mm = d.minute.toString().padLeft(2, '0');
    if (dayStart == todayStart) return '$hh:$mm';
    final dd = d.day.toString().padLeft(2, '0');
    final mo = d.month.toString().padLeft(2, '0');
    return '$dd.$mo · $hh:$mm';
  }
}

class _FieldPickerSheet extends StatelessWidget {
  const _FieldPickerSheet({required this.fields, required this.selected});

  final List<Map<String, dynamic>> fields;
  final String? selected;

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 8),
            child: Row(
              children: [
                Text(
                  'Tarla Seç',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: AppColors.textPrimary,
                  ),
                ),
              ],
            ),
          ),
          ListTile(
            leading: const Icon(Icons.public, color: AppColors.emeraldDark),
            title: const Text('Tüm Tarlalar'),
            selected: selected == null,
            onTap: () => Navigator.pop(context, '__none__'),
          ),
          const Divider(height: 1),
          Flexible(
            child: ListView.builder(
              shrinkWrap: true,
              itemCount: fields.length,
              itemBuilder: (_, i) {
                final f = fields[i];
                final id = f['id'] as String?;
                return ListTile(
                  leading: const Icon(Icons.landscape_rounded,
                      color: AppColors.soil),
                  title: Text(f['name'] as String? ?? 'Tarla'),
                  selected: id != null && id == selected,
                  onTap: () => Navigator.pop(context, id),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
