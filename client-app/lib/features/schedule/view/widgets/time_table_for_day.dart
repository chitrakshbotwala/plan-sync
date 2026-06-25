import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/material.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';

import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/core/util/extensions.dart';
import 'package:plan_sync/features/schedule/view/widgets/no_schedule_widget.dart';
import 'package:plan_sync/features/schedule/view/widgets/indicators/schedule_freshness_indicator.dart';
import 'package:plan_sync/features/schedule/view/widgets/subject_tile.dart';
import 'package:provider/provider.dart';

class TimeTableForDay extends StatefulWidget {
  const TimeTableForDay({
    super.key,
    required this.data,
    required this.day,
    required this.showSigmaEmoji,
    this.overrideEntries,
  });

  final Timetable data;
  final String day;
  final bool showSigmaEmoji;

  /// When provided, these entries are displayed instead of data.data[day].
  /// Used for merged regular+elective views. Already sorted by the caller.
  final List<ScheduleEntry>? overrideEntries;

  @override
  State<TimeTableForDay> createState() => _TimeTableForDayState();
}

class _TimeTableForDayState extends State<TimeTableForDay> {
  List<ScheduleEntry> _displayEntries = [];

  late FilterViewModel filterProvider;

  @override
  void initState() {
    super.initState();
    filterProvider = Provider.of<FilterViewModel>(context, listen: false);
    _displayEntries = _buildEntries();
  }

  @override
  void didUpdateWidget(TimeTableForDay oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.day != widget.day ||
        oldWidget.data != widget.data ||
        oldWidget.overrideEntries != widget.overrideEntries) {
      setState(() {
        _displayEntries = _buildEntries();
      });
    }
  }

  List<ScheduleEntry> _buildEntries() {
    final entries = widget.overrideEntries ?? widget.data.data[widget.day] ?? [];
    return List<ScheduleEntry>.from(entries)
      ..sort((a, b) => _startMinutes(a.time).compareTo(_startMinutes(b.time)));
  }

  /// Parses the leading time token from strings like:
  ///   "10:00 AM - 11:00 AM", "10:00 - 11:00", "10AM-11AM"
  /// Returns minutes-since-midnight for the start time, or 0 on parse failure.
  static int _startMinutes(String? timeStr) {
    if (timeStr == null || timeStr.isEmpty) return 0;
    final match = RegExp(r'(\d{1,2}):?(\d{2})?\s*(AM|PM)?',
            caseSensitive: false)
        .firstMatch(timeStr);
    if (match == null) return 0;
    int hours = int.tryParse(match.group(1) ?? '0') ?? 0;
    int minutes = int.tryParse(match.group(2) ?? '0') ?? 0;
    final period = match.group(3)?.toUpperCase();
    if (period == 'PM' && hours != 12) hours += 12;
    if (period == 'AM' && hours == 12) hours = 0;
    return hours * 60 + minutes;
  }

  @override
  void dispose() {
    EasyDebounce.cancel('_searchElective');
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (_displayEntries.isEmpty && widget.overrideEntries == null &&
        widget.data.data[widget.day] == null) {
      return const NoScheduleWidget();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 8.0),
          child: Row(
            children: [
              Text(
                widget.day.capitalizeFirst(),
                style: TextStyle(
                  color: colorScheme.onSurfaceVariant,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                  letterSpacing: 0.24,
                ),
              ),
              const Spacer(),
              ScheduleFreshnessIndicator(
                isFresh: widget.data.isFresh,
                showSigmaEmoji: widget.showSigmaEmoji,
              ),
              const SizedBox(width: 8),
            ],
          ),
        ),
        const SizedBox(height: 8),
        if (_displayEntries.isEmpty)
          const NoScheduleWidget()
        else
          ListView.separated(
            key: const ValueKey('TimeTableForDay._buildForTimetable'),
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemBuilder: (context, index) {
              return SubjectTile(
                starred: false,
                showStar: false,
                entry: _displayEntries[index],
                academicYear: filterProvider.activeYear ?? '',
                semester: filterProvider.activeSemester ?? '',
                scheme: filterProvider.activeElectiveScheme ?? '',
                onStarToggle: null,
              );
            },
            separatorBuilder: (context, index) => const SizedBox(height: 8),
            itemCount: _displayEntries.length,
          ),
      ],
    );
  }
}
