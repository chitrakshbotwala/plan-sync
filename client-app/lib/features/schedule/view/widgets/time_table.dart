import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/features/electives/viewmodel/electives_view_model.dart';
import 'package:plan_sync/features/schedule/viewmodel/schedule_view_model.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';
import 'package:plan_sync/features/schedule/view/widgets/time_table_for_day.dart';
import 'package:provider/provider.dart';

class TimeTableWidget extends StatefulWidget {
  const TimeTableWidget({super.key});

  @override
  State<TimeTableWidget> createState() => _TimeTableWidgetState();
}

class _TimeTableWidgetState extends State<TimeTableWidget> {
  void showMoreInfo(Timetable data, ColorScheme colorScheme) {
    Widget dialog = Dialog(
      backgroundColor: colorScheme.surface,
      elevation: 0.0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(
          horizontal: 16.0,
          vertical: 24.0,
        ),
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
            RichText(
              text: TextSpan(
                  text: 'Section:',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '  ${data.meta.section}'.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.normal,
                      ),
                    )
                  ]),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                  text: 'Schedule Type:',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '  ${data.meta.type}'.toUpperCase(),
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.normal,
                      ),
                    )
                  ]),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                  text: 'Schedule Version:',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '  ${data.meta.revision}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.normal,
                      ),
                    )
                  ]),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                  text: 'Effective from:',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '  ${data.meta.effectiveDate}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.normal,
                      ),
                    )
                  ]),
            ),
            const SizedBox(height: 8),
            RichText(
              text: TextSpan(
                  text: 'Contributor:',
                  style: TextStyle(
                    color: colorScheme.onSurface,
                    fontWeight: FontWeight.bold,
                  ),
                  children: <TextSpan>[
                    TextSpan(
                      text: '  ${data.meta.contributor}',
                      style: TextStyle(
                        color: colorScheme.onSurface,
                        fontWeight: FontWeight.normal,
                      ),
                    )
                  ]),
            ),
          ],
        ),
      ),
    );

    showAdaptiveDialog(
      context: context,
      barrierColor: colorScheme.onSurface.withOpacity(0.32),
      barrierDismissible: true,
      builder: (context) => dialog,
    );
  }

  /// Replaces "Electives" placeholder entries in [regularEntries] with the
  /// user's chosen elective entries for [day]. Returns null when no preferences
  /// are set (caller shows the raw API data unchanged).
  List<ScheduleEntry>? _mergedEntries({
    required FilterViewModel filterVm,
    required ElectivesViewModel electivesVm,
    required String day,
    required List<ScheduleEntry> regularEntries,
  }) {
    final chosen1 = filterVm.chosenElective1;
    final chosen2 = filterVm.chosenElective2;
    if (chosen1 == null && chosen2 == null) return null;

    // Scheme not loaded yet — show raw API data (including "Electives" placeholder)
    if (!electivesVm.hasData) return null;

    // Find which of the chosen electives are scheduled on this specific day.
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

    // No chosen elective runs today — leave the raw "Electives" placeholder.
    if (chosenToday.isEmpty) return null;

    // Replace each "Electives" placeholder with a chosen elective entry.
    // Time comes from the main schedule (authoritative); subject/room from scheme.
    var replacementIdx = 0;
    final result = <ScheduleEntry>[];
    for (final entry in regularEntries) {
      if (entry.subject == 'Electives' && replacementIdx < chosenToday.length) {
        final scheme = chosenToday[replacementIdx++];
        result.add(ScheduleEntry(
          subject: scheme.subject,
          room: scheme.room ?? entry.room,
          time: entry.time,
        ));
      } else {
        result.add(entry);
      }
    }

    // Edge case: more chosen electives on this day than "Electives" placeholders.
    while (replacementIdx < chosenToday.length) {
      result.add(chosenToday[replacementIdx++]);
    }

    return result;
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<ScheduleViewModel>();
    final filterController = context.watch<FilterViewModel>();
    final electivesVm = context.watch<ElectivesViewModel>();

    Widget timesheetTitle = Text(
      "Time Sheet",
      style: TextStyle(
        color: colorScheme.onSurfaceVariant,
        fontSize: 24,
      ),
    );

    if (vm.isLoading && !vm.hasData) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          timesheetTitle,
          const SizedBox(height: 32),
          Center(
              child: CircularProgressIndicator(
            color: colorScheme.secondary,
          )),
        ],
      );
    } else if (vm.errorMessage != null && !vm.hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          timesheetTitle,
          const SizedBox(height: 32),
          Center(
            child: Icon(
              Icons.error,
              color: colorScheme.error,
              size: 40,
            ),
          ),
          const SizedBox(height: 16),
          Flexible(child: MarkdownBody(data: "```${vm.errorMessage}```")),
          const SizedBox(height: 16),
          Text(
            "A status report has been sent, this issue will be looked into.",
            style: TextStyle(
              color: colorScheme.error,
            ),
          )
        ],
      );
    } else if (!vm.hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          timesheetTitle,
          const SizedBox(height: 32),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.info,
                  color: colorScheme.secondary,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  "No section selected.",
                  style: TextStyle(
                    color: colorScheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else if (vm.timetable!.meta.isTimetableUpdating ?? false) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          timesheetTitle,
          const SizedBox(height: 32),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  Icons.settings_outlined,
                  color: colorScheme.secondary,
                  size: 40,
                ),
                const SizedBox(height: 16),
                Text(
                  "We're working on this timetable,",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
                Text(
                  "Check back in soon!",
                  style: TextStyle(
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    } else {
      final day = filterController.weekday.key;
      final regularEntries = vm.timetable!.data[day] ?? [];
      final merged = _mergedEntries(
        filterVm: filterController,
        electivesVm: electivesVm,
        day: day,
        regularEntries: regularEntries,
      );

      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    timesheetTitle,
                    Text(
                      "Effective from ${vm.timetable!.meta.effectiveDate}",
                      style: TextStyle(
                        fontWeight: FontWeight.bold,
                        color: colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              ),
              OutlinedButton.icon(
                onPressed: () => showMoreInfo(vm.timetable!, colorScheme),
                icon: Icon(Icons.info_outline_rounded,
                    color: colorScheme.tertiary, size: 16),
                label: Text(
                  'Info',
                  style: TextStyle(color: colorScheme.tertiary),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.tertiary),
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
              const SizedBox(width: 8),
              OutlinedButton.icon(
                onPressed: () => PopupsWrapper.reportError(
                  context: context,
                  scheduleType: ScheduleType.regular,
                ),
                icon: Icon(Icons.flag_rounded,
                    color: colorScheme.error, size: 16),
                label: Text(
                  'Report',
                  style: TextStyle(color: colorScheme.error),
                ),
                style: OutlinedButton.styleFrom(
                  side: BorderSide(color: colorScheme.error),
                  shape: const StadiumBorder(),
                  visualDensity: VisualDensity.compact,
                  padding:
                      const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          TimeTableForDay(
            day: day,
            data: vm.timetable!,
            showSigmaEmoji: vm.showSigmaEmoji,
            overrideEntries: merged,
          ),
        ],
      );
    }
  }
}
