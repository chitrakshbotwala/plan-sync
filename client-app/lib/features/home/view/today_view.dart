import 'dart:async';

import 'package:flutter/material.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/core/util/extensions.dart';
import 'package:plan_sync/features/electives/viewmodel/electives_view_model.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/features/home/view/widgets/today_class_timeline.dart';
import 'package:plan_sync/features/home/view/widgets/today_hero_card.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';
import 'package:plan_sync/features/schedule/viewmodel/schedule_view_model.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';
import 'package:provider/provider.dart';

class TodayView extends StatefulWidget {
  const TodayView({super.key});

  @override
  State<TodayView> createState() => _TodayViewState();
}

class _TodayViewState extends State<TodayView> {
  Timer? _ticker;

  @override
  void initState() {
    super.initState();
    _ticker = Timer.periodic(const Duration(minutes: 1), (_) {
      if (mounted) setState(() {});
    });
  }

  @override
  void dispose() {
    _ticker?.cancel();
    super.dispose();
  }

  // ── info dialog ───────────────────────────────────────────────────────────

  void _showMoreInfo(Timetable data, ColorScheme colorScheme) {
    showAdaptiveDialog(
      context: context,
      barrierDismissible: true,
      barrierColor: colorScheme.onSurface.withValues(alpha: 0.32),
      builder: (_) => Dialog(
        backgroundColor: colorScheme.surface,
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Align(
                alignment: Alignment.topCenter,
                child: Text(
                  'About this schedule',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              _infoRow('Section', '  ${data.meta.section ?? ''}'.toUpperCase(), colorScheme),
              const SizedBox(height: 8),
              _infoRow('Schedule Type', '  ${data.meta.type ?? ''}'.toUpperCase(), colorScheme),
              const SizedBox(height: 8),
              _infoRow('Schedule Version', '  ${data.meta.revision ?? ''}', colorScheme),
              const SizedBox(height: 8),
              _infoRow('Effective from', '  ${data.meta.effectiveDate ?? ''}', colorScheme),
              const SizedBox(height: 8),
              _infoRow('Contributor', '  ${data.meta.contributor ?? ''}', colorScheme),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow(String label, String value, ColorScheme colorScheme) {
    return RichText(
      text: TextSpan(
        text: label,
        style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.bold),
        children: [
          TextSpan(
            text: value,
            style: TextStyle(color: colorScheme.onSurface, fontWeight: FontWeight.normal),
          ),
        ],
      ),
    );
  }

  // ── time helpers ──────────────────────────────────────────────────────────

  static int _nowMinutes() {
    final now = TimeOfDay.now();
    return now.hour * 60 + now.minute;
  }

  static int _parseToken(String token) {
    final match = RegExp(r'(\d{1,2}):?(\d{2})?\s*(AM|PM)?', caseSensitive: false)
        .firstMatch(token.trim());
    if (match == null) return -1;
    int h = int.tryParse(match.group(1) ?? '0') ?? 0;
    int min = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && h != 12) h += 12;
    if (period == 'AM' && h == 12) h = 0;
    return h * 60 + min;
  }

  static final _separatorRe = RegExp(r'\s*[-–]\s*');

  static int _startMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return -1;
    return _parseToken(timeStr.split(_separatorRe).first);
  }

  static int _endMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return -1;
    final parts = timeStr.split(_separatorRe);
    if (parts.length < 2) return -1;
    return _parseToken(parts.last);
  }

  // ── entry helpers ─────────────────────────────────────────────────────────

  List<ScheduleEntry> _sorted(List<ScheduleEntry> entries) =>
      List<ScheduleEntry>.from(entries)
        ..sort((a, b) => _startMinutes(a.time).compareTo(_startMinutes(b.time)));

  static List<ScheduleEntry>? _mergedEntries({
    required FilterViewModel filterVm,
    required ElectivesViewModel electivesVm,
    required String day,
    required List<ScheduleEntry> regularEntries,
  }) {
    final chosen1 = filterVm.chosenElective1;
    final chosen2 = filterVm.chosenElective2;
    if (chosen1 == null && chosen2 == null) return null;
    if (!electivesVm.hasData) return null;

    final electiveEntries = electivesVm.timetable?.data[day] ?? [];
    final chosenToday = <ScheduleEntry>[];
    for (final subject in [chosen1, chosen2]) {
      if (subject == null) continue;
      final entry = electiveEntries.firstWhere(
        (e) => e.subject == subject,
        orElse: () => ScheduleEntry(),
      );
      if (entry.subject != null) chosenToday.add(entry);
    }
    if (chosenToday.isEmpty) return null;

    var replacementIdx = 0;
    final result = <ScheduleEntry>[];
    for (final entry in regularEntries) {
      if (entry.subject == 'Electives' && replacementIdx < chosenToday.length) {
        final scheme = chosenToday[replacementIdx++];
        result.add(ScheduleEntry(
          subject: scheme.subject,
          room: scheme.room ?? entry.room,
          // Prefer the placeholder's time (authoritative); fall back to the
          // elective timetable's own time if the placeholder has no time field.
          time: entry.time ?? scheme.time,
        ));
      } else {
        result.add(entry);
      }
    }
    // Electives that had no placeholder: keep them only if they have a valid time.
    while (replacementIdx < chosenToday.length) {
      final scheme = chosenToday[replacementIdx++];
      if (scheme.time != null && scheme.time!.isNotEmpty) {
        result.add(scheme);
      }
    }
    return result;
  }

  ScheduleEntry? _currentEntry(List<ScheduleEntry> entries) {
    final now = _nowMinutes();
    for (final e in entries) {
      final start = _startMinutes(e.time);
      final end = _endMinutes(e.time);
      if (start >= 0 && end >= 0 && now >= start && now < end) return e;
    }
    return null;
  }

  ScheduleEntry? _nextEntry(List<ScheduleEntry> entries, ScheduleEntry current) {
    final idx = entries.indexOf(current);
    if (idx < 0 || idx >= entries.length - 1) return null;
    return entries[idx + 1];
  }

  int _minutesLeft(ScheduleEntry entry) {
    final end = _endMinutes(entry.time);
    if (end < 0) return 0;
    return (end - _nowMinutes()).clamp(0, 999);
  }

  // ── heading block (Time Sheet title + effective date + Info/Report) ─────────

  Widget _headingBlock(String dayKey, Timetable timetable, ColorScheme colorScheme) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.center,
          children: [
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Time Sheet',
                    style: TextStyle(
                      color: colorScheme.onSurfaceVariant,
                      fontSize: 24,
                    ),
                  ),
                  Text(
                    'Effective from ${timetable.meta.effectiveDate ?? ''}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: colorScheme.onSurface,
                    ),
                  ),
                ],
              ),
            ),
            OutlinedButton.icon(
              onPressed: () => _showMoreInfo(timetable, colorScheme),
              icon: Icon(Icons.info_outline_rounded, color: colorScheme.tertiary, size: 16),
              label: Text('Info', style: TextStyle(color: colorScheme.tertiary)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.tertiary),
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
            const SizedBox(width: 8),
            OutlinedButton.icon(
              onPressed: () => PopupsWrapper.reportError(
                context: context,
                scheduleType: ScheduleType.regular,
              ),
              icon: Icon(Icons.flag_rounded, color: colorScheme.error, size: 16),
              label: Text('Report', style: TextStyle(color: colorScheme.error)),
              style: OutlinedButton.styleFrom(
                side: BorderSide(color: colorScheme.error),
                shape: const StadiumBorder(),
                visualDensity: VisualDensity.compact,
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              ),
            ),
          ],
        ),
        const SizedBox(height: 16),
        Padding(
          padding: const EdgeInsets.only(left: 4),
          child: Text(
            dayKey.capitalizeFirst(),
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<ScheduleViewModel>();
    final filterVm = context.watch<FilterViewModel>();
    final electivesVm = context.watch<ElectivesViewModel>();

    final dayKey = filterVm.weekday.key;
    final isToday = dayKey == Weekday.today().key;
    final sectionName = filterVm.activeSection ?? filterVm.activeSectionCode ?? '';

    if (vm.isLoading && !vm.hasData) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.secondary),
      );
    }

    if (!vm.hasData) {
      return Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(Icons.info, color: colorScheme.secondary, size: 40),
            const SizedBox(height: 16),
            Text(
              'No section selected.',
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      );
    }

    final rawEntries = vm.timetable!.data[dayKey] ?? [];
    final merged = _mergedEntries(
      filterVm: filterVm,
      electivesVm: electivesVm,
      day: dayKey,
      regularEntries: rawEntries,
    );
    final entries = _sorted(merged ?? rawEntries);

    if (entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headingBlock(dayKey, vm.timetable!, colorScheme),
          const SizedBox(height: 24),
          Center(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const SizedBox(height: 40),
                Icon(
                  Icons.weekend_outlined,
                  size: 48,
                  color: colorScheme.onSurfaceVariant.withValues(alpha: 0.4),
                ),
                const SizedBox(height: 16),
                Text(
                  'No classes today',
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final current = isToday ? _currentEntry(entries) : null;
    final next = current != null ? _nextEntry(entries, current) : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headingBlock(dayKey, vm.timetable!, colorScheme),
        const SizedBox(height: 16),
        if (current != null) ...[
          TodayHeroCard(
            entry: current,
            sectionName: sectionName,
            minutesLeft: _minutesLeft(current),
            nextEntry: next,
          ),
          const SizedBox(height: 20),
        ],
        TodayClassTimeline(
          entries: entries,
          currentEntry: current,
        ),
      ],
    );
  }
}
