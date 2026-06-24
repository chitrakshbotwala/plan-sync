import 'package:flutter/material.dart';
import 'package:plan_sync/features/home/view/widgets/contribute_schedule.dart';
import 'package:plan_sync/features/electives/view/widgets/elective_preference.dart';
import 'package:plan_sync/features/home/view/widgets/report_error.dart';
import 'package:plan_sync/features/schedule/view/widgets/schedule_preference.dart';
import 'package:plan_sync/features/home/view/widgets/share_app.dart';
import 'package:plan_sync/widgets/bottom-sheets/attendance_info_sheet.dart';
import 'package:plan_sync/widgets/bottom-sheets/kiit_credentials_sheet.dart';

class BottomSheets {
  static void changeSectionPreference({
    required BuildContext context,
    bool save = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surfaceContainerHighest,
      builder: (context) => SchedulePreferenceBottomSheet(
        save: save,
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

  static void changeElectiveSchemePreference({
    required BuildContext context,
    bool save = false,
  }) {
    final colorScheme = Theme.of(context).colorScheme;
    showModalBottomSheet(
      context: context,
      useRootNavigator: true,
      showDragHandle: true,
      backgroundColor: colorScheme.surfaceContainerHighest,
      builder: (context) => ElectivePreferenceBottomSheet(
        save: save,
      ),
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
