import 'package:flutter/material.dart';
import 'package:plan_sync/features/attendance/view/widgets/attendance_actions_row.dart';
import 'package:plan_sync/features/attendance/view/widgets/attendance_inline_notice.dart';
import 'package:plan_sync/features/attendance/view/widgets/overall_attendance_card.dart';
import 'package:plan_sync/features/attendance/view/widgets/subject_attendance_tile.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';

class AttendanceSuccessState extends StatelessWidget {
  const AttendanceSuccessState({super.key, required this.viewModel});
  final AttendanceViewModel viewModel;

  String _formatFetchedAt(DateTime dt) {
    final now = DateTime.now();
    final hour = dt.hour > 12
        ? dt.hour - 12
        : (dt.hour == 0 ? 12 : dt.hour);
    final minute = dt.minute.toString().padLeft(2, '0');
    final period = dt.hour >= 12 ? 'PM' : 'AM';
    final time = '$hour:$minute $period';

    final sameDay = now.year == dt.year &&
        now.month == dt.month &&
        now.day == dt.day;
    if (sameDay) return 'Last updated at $time';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];
    return 'Last updated ${dt.day} ${months[dt.month - 1]}, $time';
  }

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
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 120),
        children: [
          OverallAttendanceCard(result: result),
          const SizedBox(height: 20),
          AttendanceActionsRow(viewModel: viewModel),
          const SizedBox(height: 4),
          Text(
            _formatFetchedAt(result.fetchedAt),
            style: TextStyle(
              color: colorScheme.onSurfaceVariant.withValues(alpha: 0.5),
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 10),
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
