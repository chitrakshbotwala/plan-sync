import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/features/electives/viewmodel/electives_view_model.dart';
import 'package:plan_sync/features/schedule/viewmodel/schedule_view_model.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';
import 'package:plan_sync/features/schedule/view/widgets/time_table_for_day.dart';
import 'package:provider/provider.dart';

class TimeTableWidget extends StatefulWidget {
  final bool isElective;

  const TimeTableWidget({
    super.key,
    this.isElective = false,
  });

  @override
  State<TimeTableWidget> createState() => _TimeTableWidgetState();
}

class _TimeTableWidgetState extends State<TimeTableWidget> {
  int? sortColumnIndex;
  bool sortAscending = false;

  List sortedUniqueTime = [];
  List<DataRow> rowList = [];
  List<DataColumn> columnsList = [];

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

            // section details
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
            // class type
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
            // revision
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
            // effective
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
            // contributor
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

  void reportError() {
    PopupsWrapper.reportError(
      context: context,
      scheduleType: ScheduleType.regular,
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    if (widget.isElective) {
      final vm = context.watch<ElectivesViewModel>();
      final filterController = context.watch<FilterViewModel>();

      if (vm.isLoading && !vm.hasData) {
        return Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const SizedBox(height: 32),
            Center(
                child: CircularProgressIndicator(
              color: colorScheme.secondary,
            )),
          ],
        );
      } else if (vm.errorMessage != null && !vm.hasData) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
            Icon(
              Icons.error,
              color: colorScheme.error,
              size: 40,
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
        return Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
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
              )
            ],
          ),
        );
      } else if (vm.timetable!.meta.isTimetableUpdating ?? false) {
        return Center(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 32),
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
        );
      } else {
        return Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Flexible(
              child: Text(
                "Effective from ${vm.timetable!.meta.effectiveDate}",
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: colorScheme.onSurface,
                ),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              mainAxisSize: MainAxisSize.min,
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                InkWell(
                  onTap: () => showMoreInfo(vm.timetable!, colorScheme),
                  child: Row(
                    children: [
                      Icon(Icons.info_rounded, color: colorScheme.tertiary),
                      const SizedBox(width: 8),
                      Text(
                        'More Info',
                        style: TextStyle(color: colorScheme.tertiary),
                      ),
                    ],
                  ),
                ),
                const Spacer(),
                TextButton.icon(
                  onPressed: () => PopupsWrapper.reportError(
                    context: context,
                    scheduleType: ScheduleType.electives,
                  ),
                  label: Text(
                    'Report Error',
                    style: TextStyle(color: colorScheme.error),
                  ),
                  icon: Icon(
                    Icons.flag_rounded,
                    color: colorScheme.error,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            TimeTableForDay(
              day: filterController.weekday.key,
              data: vm.timetable!,
              showSigmaEmoji: vm.showSigmaEmoji,
              searchEnabled: true,
              isElectiveStarred: vm.isElectiveStarred,
              onStarElective: vm.starElective,
              onUnstarElective: vm.unstarElective,
            ),
          ],
        );
      }
    }

    // Non-elective: ScheduleViewModel owns the subscription.
    final vm = context.watch<ScheduleViewModel>();
    final filterController = context.watch<FilterViewModel>();

    if (vm.isLoading && !vm.hasData) {
      return Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const SizedBox(height: 32),
          Center(
              child: CircularProgressIndicator(
            color: colorScheme.secondary,
          )),
        ],
      );
    } else if (vm.errorMessage != null && !vm.hasData) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisSize: MainAxisSize.min,
        children: [
          const SizedBox(height: 32),
          Icon(
            Icons.error,
            color: colorScheme.error,
            size: 40,
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
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
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
            )
          ],
        ),
      );
    } else if (vm.timetable!.meta.isTimetableUpdating ?? false) {
      return Center(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.center,
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 32),
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
      );
    } else {
      return Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Flexible(
            child: Text(
              "Effective from ${vm.timetable!.meta.effectiveDate}",
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.start,
            children: [
              InkWell(
                onTap: () => showMoreInfo(vm.timetable!, colorScheme),
                child: Row(
                  children: [
                    Icon(Icons.info_rounded, color: colorScheme.tertiary),
                    const SizedBox(width: 8),
                    Text(
                      'More Info',
                      style: TextStyle(color: colorScheme.tertiary),
                    ),
                  ],
                ),
              ),
              const Spacer(),
              TextButton.icon(
                onPressed: () => reportError(),
                label: Text(
                  'Report Error',
                  style: TextStyle(color: colorScheme.error),
                ),
                icon: Icon(
                  Icons.flag_rounded,
                  color: colorScheme.error,
                ),
              )
            ],
          ),
          const SizedBox(height: 16),
          TimeTableForDay(
            day: filterController.weekday.key,
            data: vm.timetable!,
            showSigmaEmoji: vm.showSigmaEmoji,
            searchEnabled: false,
          ),
        ],
      );
    }
  }

  void onSort(int columnIndex, bool ascending) {
    setState(() {
      sortColumnIndex = columnIndex;
      sortAscending = ascending;
    });
  }
}
