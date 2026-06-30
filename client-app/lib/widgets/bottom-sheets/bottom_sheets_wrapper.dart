import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_sync/features/home/view/widgets/contribute_schedule.dart';
import 'package:plan_sync/features/home/view/widgets/report_error.dart';
import 'package:plan_sync/features/home/view/widgets/share_app.dart';
import 'package:plan_sync/widgets/bottom-sheets/attendance_info_sheet.dart';
import 'package:plan_sync/widgets/bottom-sheets/kiit_credentials_sheet.dart';
import 'package:plan_sync/widgets/bottom-sheets/more_options_sheet.dart';

class BottomSheets {
  /// "More" tab sheet: quick links to Settings and the Holiday List.
  ///
  /// Background is transparent and the sheet paints its own surface so the
  /// theme can update live when the in-sheet theme toggle is tapped (the
  /// modal route otherwise freezes a snapshot of the ancestor theme).
  static void moreOptions({
    required BuildContext context,
  }) {
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: Colors.transparent,
      builder: (sheetContext) => MoreOptionsSheet(
        onSettings: () {
          Navigator.of(sheetContext).pop();
          context.pushNamed('settings_screen');
        },
        onHolidayList: () {
          Navigator.of(sheetContext).pop();
          context.pushNamed('holidays_screen');
        },
      ),
    );
  }

  static void reportError({
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHighest,
      builder: (context) => const ReportErrorBottomSheet(),
    );
  }

  static void contributeTimeTable({
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHighest,
      builder: (context) => const ContributeScheduleBottomSheet(),
    );
  }

  /// Prompt for / update the student's KIIT portal login.
  static void kiitCredentials({
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surfaceContainerHighest,
      builder: (context) => const KiitCredentialsSheet(),
    );
  }

  /// "More info" sheet on the attendance screen.
  static void attendanceInfo({
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      isScrollControlled: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surfaceContainerHighest,
      builder: (_) => AttendanceInfoSheet(
        onChangeCredentials: () => kiitCredentials(context: context),
      ),
    );
  }

  static void shareAppBottomSheet({
    required BuildContext context,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      showDragHandle: true,
      enableDrag: true,
      useRootNavigator: true,
      backgroundColor: colorScheme.surfaceContainerHighest,
      barrierColor: colorScheme.onSurface.withOpacity(0.16),
      builder: (context) => const ShareAppSheet(),
    );
  }
}
