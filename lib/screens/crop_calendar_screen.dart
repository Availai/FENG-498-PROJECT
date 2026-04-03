import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:table_calendar/table_calendar.dart';

import '../services/app_providers.dart';

/// Crop Cycle & Guide Calendar.
/// Fulfills: "Crop Cycle and Guide Calendar (Crop Calendar)"
/// (Proposal Section 6.1.2.1).
///
/// Events shown:
///  🟢 Ekim (planting date)
///  🟠 Tahmini Hasat (expected harvest)
///  🔵 Sulama Hatırlatıcısı (watering reminders, weekly)
///  🟣 Tarla Kaydı (field registration date)
class CropCalendarScreen extends ConsumerStatefulWidget {
  const CropCalendarScreen({super.key});

  @override
  ConsumerState<CropCalendarScreen> createState() => _CropCalendarScreenState();
}

class _CropCalendarScreenState extends ConsumerState<CropCalendarScreen> {
  DateTime _focusedDay = DateTime.now();
  DateTime? _selectedDay;
  Map<DateTime, List<_CalEvent>> _events = {};

  @override
  void initState() {
    super.initState();
    _selectedDay = DateTime.now();
    _buildEventsFromRepository();
  }

  // ── Event Building ────────────────────────────────────────────────────────

  Future<void> _buildEventsFromRepository() async {
    final map = <DateTime, List<_CalEvent>>{};

    void add(DateTime dt, _CalEvent ev) {
      final key = DateTime.utc(dt.year, dt.month, dt.day);
      map.putIfAbsent(key, () => []).add(ev);
    }

    final entries = await ref.read(localDataRepositoryProvider).loadCalendarEntries();
    for (final entry in entries) {
      final date = entry['date'];
      if (date is! DateTime) continue;
      add(
        date,
        _CalEvent(
          title: entry['title']?.toString() ?? 'Etkinlik',
          type: _eventTypeFromName(entry['type']?.toString() ?? 'registration'),
        ),
      );
    }

    if (!mounted) return;
    setState(() => _events = map);
  }

  List<_CalEvent> _eventsForDay(DateTime day) {
    return _events[DateTime.utc(day.year, day.month, day.day)] ?? [];
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final selectedEvents =
        _selectedDay != null ? _eventsForDay(_selectedDay!) : <_CalEvent>[];

    return Scaffold(
      appBar: AppBar(
        title: const Text('Tarım Takvimi'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _buildEventsFromRepository,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: Column(
        children: [
          // ── Legend ──
          Container(
            color: Colors.white,
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            child: Wrap(
              spacing: 12,
              children: _EventType.values.map((t) {
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: t.color,
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(t.label,
                        style:
                            const TextStyle(fontSize: 11, color: Colors.black54)),
                  ],
                );
              }).toList(),
            ),
          ),

          // ── Calendar ──
          TableCalendar<_CalEvent>(
            firstDay: DateTime.utc(2024, 1, 1),
            lastDay: DateTime.utc(2027, 12, 31),
            focusedDay: _focusedDay,
            selectedDayPredicate: (d) => isSameDay(_selectedDay, d),
            eventLoader: _eventsForDay,
            calendarFormat: CalendarFormat.month,
            availableCalendarFormats: const {CalendarFormat.month: 'Ay'},
            startingDayOfWeek: StartingDayOfWeek.monday,
            locale: 'tr_TR',
            onDaySelected: (selected, focused) {
              setState(() {
                _selectedDay = selected;
                _focusedDay = focused;
              });
            },
            onPageChanged: (focused) => _focusedDay = focused,
            calendarStyle: CalendarStyle(
              todayDecoration: BoxDecoration(
                color: Colors.green.shade200,
                shape: BoxShape.circle,
              ),
              selectedDecoration: BoxDecoration(
                color: Colors.green.shade700,
                shape: BoxShape.circle,
              ),
              markerDecoration: const BoxDecoration(
                color: Colors.transparent,
              ),
              markersAutoAligned: false,
              markersOffset: const PositionedOffset(bottom: 4),
            ),
            calendarBuilders: CalendarBuilders(
              markerBuilder: (context, day, events) {
                if (events.isEmpty) return const SizedBox.shrink();
                // Show up to 4 colored dots
                final dots = events.take(4).toList();
                return Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: dots
                      .map((e) => Container(
                            width: 6,
                            height: 6,
                            margin: const EdgeInsets.symmetric(horizontal: 1),
                            decoration: BoxDecoration(
                              color: e.type.color,
                              shape: BoxShape.circle,
                            ),
                          ))
                      .toList(),
                );
              },
            ),
            headerStyle: HeaderStyle(
              formatButtonVisible: false,
              titleCentered: true,
              titleTextStyle: const TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w700,
                color: Color(0xFF1B5E20),
              ),
              leftChevronIcon: const Icon(Icons.chevron_left,
                  color: Color(0xFF2E7D32)),
              rightChevronIcon: const Icon(Icons.chevron_right,
                  color: Color(0xFF2E7D32)),
            ),
          ),

          const Divider(height: 1),

          // ── Events for selected day ──
          Expanded(
            child: selectedEvents.isEmpty
                ? Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.event_available_rounded,
                            size: 56, color: Colors.grey.shade300),
                        const SizedBox(height: 12),
                        Text(
                          'Bu gün için etkinlik yok',
                          style: TextStyle(
                              color: Colors.grey.shade500, fontSize: 15),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Tarlalarınıza bitki dikerek takvim oluşturun',
                          style: TextStyle(
                              color: Colors.grey.shade400, fontSize: 12),
                        ),
                      ],
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: selectedEvents.length,
                    itemBuilder: (ctx, i) {
                      final ev = selectedEvents[i];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        decoration: BoxDecoration(
                          color: ev.type.color.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: ev.type.color.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: ev.type.color.withValues(alpha: 0.2),
                                shape: BoxShape.circle,
                              ),
                              child: Icon(ev.type.icon,
                                  color: ev.type.color, size: 20),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(ev.title,
                                      style: const TextStyle(
                                          fontWeight: FontWeight.w600,
                                          fontSize: 14)),
                                  const SizedBox(height: 2),
                                  Text(ev.type.label,
                                      style: TextStyle(
                                          fontSize: 12,
                                          color: ev.type.color,
                                          fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
      // Manual event adding (planting new crops via prompt)
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showAddEventDialog(),
        backgroundColor: Colors.green.shade700,
        icon: const Icon(Icons.add, color: Colors.white),
        label: const Text('Etkinlik Ekle', style: TextStyle(color: Colors.white)),
      ),
    );
  }

  // ── Add Custom Event Dialog ───────────────────────────────────────────────

  void _showAddEventDialog() {
    final titleCtrl = TextEditingController();
    _EventType selectedType = _EventType.planting;
    DateTime pickedDate = _selectedDay ?? DateTime.now();

    showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDlgState) => AlertDialog(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Text('Yeni Etkinlik',
              style: TextStyle(fontWeight: FontWeight.w700)),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextField(
                controller: titleCtrl,
                decoration: InputDecoration(
                  labelText: 'Etkinlik Adı',
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12)),
                  prefixIcon: const Icon(Icons.edit_outlined),
                ),
              ),
              const SizedBox(height: 14),
              const Text('Tür:', style: TextStyle(fontWeight: FontWeight.w600)),
              const SizedBox(height: 6),
              Wrap(
                spacing: 6,
                children: _EventType.values.map((t) {
                  return ChoiceChip(
                    label: Text(t.label, style: const TextStyle(fontSize: 12)),
                    selected: selectedType == t,
                    selectedColor: t.color.withValues(alpha: 0.25),
                    onSelected: (v) {
                      if (v) setDlgState(() => selectedType = t);
                    },
                    avatar: Icon(t.icon, size: 14, color: t.color),
                  );
                }).toList(),
              ),
              const SizedBox(height: 14),
              // Date picker row
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: ctx,
                    initialDate: pickedDate,
                    firstDate: DateTime(2024),
                    lastDate: DateTime(2027),
                  );
                  if (picked != null) setDlgState(() => pickedDate = picked);
                },
                child: Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.grey.shade300),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_today_outlined,
                          size: 18, color: Colors.green),
                      const SizedBox(width: 8),
                      Text(DateFormat('dd MMMM yyyy', 'tr_TR').format(pickedDate)),
                    ],
                  ),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('İptal'),
            ),
            FilledButton(
              style: FilledButton.styleFrom(
                  backgroundColor: Colors.green.shade700),
              onPressed: () async {
                if (titleCtrl.text.trim().isEmpty) return;
                await ref.read(localDataRepositoryProvider).addCalendarEvent(
                      title: titleCtrl.text.trim(),
                      eventType: selectedType.name,
                      eventDate: pickedDate,
                    );
                await _buildEventsFromRepository();
                if (!mounted) return;
                Navigator.pop(ctx);
              },
              child: const Text('Kaydet'),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Models ────────────────────────────────────────────────────────────────

enum _EventType { planting, harvest, watering, registration }

extension _EventTypeX on _EventType {
  Color get color {
    switch (this) {
      case _EventType.planting:
        return Colors.green.shade600;
      case _EventType.harvest:
        return Colors.orange.shade600;
      case _EventType.watering:
        return Colors.blue.shade500;
      case _EventType.registration:
        return Colors.purple.shade500;
    }
  }

  IconData get icon {
    switch (this) {
      case _EventType.planting:
        return Icons.grass_rounded;
      case _EventType.harvest:
        return Icons.agriculture_rounded;
      case _EventType.watering:
        return Icons.water_drop_rounded;
      case _EventType.registration:
        return Icons.crop_square_rounded;
    }
  }

  String get label {
    switch (this) {
      case _EventType.planting:
        return 'Ekim';
      case _EventType.harvest:
        return 'Hasat';
      case _EventType.watering:
        return 'Sulama';
      case _EventType.registration:
        return 'Tarla Kaydı';
    }
  }
}

class _CalEvent {
  final String title;
  final _EventType type;
  const _CalEvent({required this.title, required this.type});
}

_EventType _eventTypeFromName(String name) {
  switch (name) {
    case 'planting':
      return _EventType.planting;
    case 'harvest':
      return _EventType.harvest;
    case 'watering':
      return _EventType.watering;
    default:
      return _EventType.registration;
  }
}
