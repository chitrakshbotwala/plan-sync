import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/features/home/view/widgets/today_class_timeline.dart';
import 'package:plan_sync/features/home/view/widgets/today_hero_card.dart';
import 'package:plan_sync/features/home/viewmodel/today_view_model.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';
import 'package:provider/provider.dart';

class TodayView extends StatelessWidget {
  const TodayView({super.key});

  // ── info dialog ───────────────────────────────────────────────────────────

  void _showMoreInfo(
    BuildContext context,
    Timetable data,
    ColorScheme colorScheme,
  ) {
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

  // ── heading block (Time Sheet title + effective date + Info/Report) ─────────

  Widget _headingBlock(
    BuildContext context,
    String dayLabel,
    Timetable timetable,
    ColorScheme colorScheme,
  ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Padding(
            padding: const EdgeInsets.only(left: 4),
            child: Text(
              dayLabel,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 22,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        OutlinedButton.icon(
          onPressed: () => _showMoreInfo(context, timetable, colorScheme),
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
    );
  }

  // ── build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final vm = context.watch<TodayViewModel>();

    if (vm.isLoading) {
      return Center(
        child: CircularProgressIndicator(color: colorScheme.secondary),
      );
    }

    if (!vm.hasData) {
      if (vm.errorMessage != null) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(
              'Time Sheet',
              style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 24),
            ),
            const SizedBox(height: 32),
            Center(
              child: Icon(Icons.error, color: colorScheme.error, size: 40),
            ),
            const SizedBox(height: 16),
            Flexible(child: MarkdownBody(data: '```${vm.errorMessage}```')),
            const SizedBox(height: 16),
            Text(
              'A status report has been sent, this issue will be looked into.',
              style: TextStyle(color: colorScheme.error),
            ),
          ],
        );
      }
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

    if (vm.isUpdating) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            'Time Sheet',
            style: TextStyle(color: colorScheme.onSurfaceVariant, fontSize: 24),
          ),
          const SizedBox(height: 32),
          Center(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.center,
              mainAxisAlignment: MainAxisAlignment.center,
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.settings_outlined, color: colorScheme.secondary, size: 40),
                const SizedBox(height: 16),
                Text(
                  "We're working on this timetable,",
                  style: TextStyle(color: colorScheme.onSurface),
                ),
                Text(
                  'Check back in soon!',
                  style: TextStyle(color: colorScheme.onSurface),
                ),
              ],
            ),
          ),
        ],
      );
    }

    final board = vm.board;
    final timetable = vm.timetable!;

    if (board.entries.isEmpty) {
      return Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _headingBlock(context, vm.dayLabel, timetable, colorScheme),
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

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _headingBlock(context, vm.dayLabel, timetable, colorScheme),
        const SizedBox(height: 16),
        if (board.current != null) ...[
          TodayHeroCard(
            entry: board.current!,
            sectionName: vm.sectionName,
            minutesLeft: board.minutesLeft,
            nextEntry: board.next,
          ),
          const SizedBox(height: 20),
        ],
        TodayClassTimeline(
          entries: board.entries,
          currentEntry: board.current,
        ),
      ],
    );
  }
}
