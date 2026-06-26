import 'package:flutter/material.dart';
import 'package:plan_sync/features/attendance/view/widgets/attendance_actions_row.dart';
import 'package:plan_sync/features/attendance/view/widgets/attendance_filter_bar.dart';
import 'package:plan_sync/features/attendance/view/widgets/attendance_inline_notice.dart';
import 'package:plan_sync/features/attendance/view/widgets/overall_attendance_card.dart';
import 'package:plan_sync/features/attendance/view/widgets/subject_attendance_tile.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';

class AttendanceSuccessState extends StatelessWidget {
  const AttendanceSuccessState({super.key, required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final result = viewModel.result!;

    return RefreshIndicator(
      onRefresh: viewModel.refresh,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(
          parent: BouncingScrollPhysics(),
        ),
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 80),
        children: [
          AttendanceFilterBar(viewModel: viewModel, enabled: true),
          const SizedBox(height: 16),
          OverallAttendanceCard(result: result),
          const SizedBox(height: 20),
          Text(
            'Attendance',
            style: TextStyle(
              color: colorScheme.onSurfaceVariant,
              fontSize: 22,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          const AttendanceActionsRow(),
          const SizedBox(height: 8),
          if (result.isEmpty)
            AttendanceInlineNotice(
              icon: Icons.inbox_outlined,
              text: 'No subjects found for ${result.academicYear} '
                  '· ${result.session}.',
            )
          else
            ...result.records.map(
              (r) => Padding(
                padding: const EdgeInsets.only(bottom: 10),
                child: SubjectAttendanceTile(record: r),
              ),
            ),
        ],
      ),
    );
  }
}
