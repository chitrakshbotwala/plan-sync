import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/widgets/bottom-sheets/bottom_sheets_wrapper.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';

class AttendanceActionsRow extends StatelessWidget {
  const AttendanceActionsRow({super.key, required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Text(
          'Attendance',
          style: TextStyle(
            color: colorScheme.onSurfaceVariant,
            fontSize: 22,
            fontWeight: FontWeight.w600,
          ),
        ),
        const Spacer(),
        _RefreshButton(viewModel: viewModel),
        const SizedBox(width: 8),
        _PillButton(
          icon: Icons.info_outline_rounded,
          label: 'Info',
          color: colorScheme.tertiary,
          onTap: () => BottomSheets.attendanceInfo(context: context),
        ),
        const SizedBox(width: 8),
        _PillButton(
          icon: FontAwesomeIcons.flag.data,
          label: 'Report issue',
          color: colorScheme.error,
          iconSize: 13,
          onTap: () => PopupsWrapper.reportAttendanceIssue(context: context),
        ),
      ],
    );
  }
}

class _RefreshButton extends StatelessWidget {
  const _RefreshButton({required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return SizedBox(
      width: 34,
      height: 34,
      child: DecoratedBox(
        decoration: BoxDecoration(
          shape: BoxShape.circle,
          border: Border.all(
            color: colorScheme.primary.withValues(alpha: 0.5),
          ),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: viewModel.isRefreshing
            ? Padding(
                padding: const EdgeInsets.all(8),
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colorScheme.primary,
                ),
              )
            : IconButton(
                padding: EdgeInsets.zero,
                onPressed: viewModel.refresh,
                icon: Icon(
                  Icons.sync_rounded,
                  size: 18,
                  color: colorScheme.primary,
                ),
              ),
      ),
    );
  }
}

class _PillButton extends StatelessWidget {
  const _PillButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
    this.iconSize = 16,
  });

  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;
  final double iconSize;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          border: Border.all(color: color.withValues(alpha: 0.55)),
          color: colorScheme.surfaceContainerHighest,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: iconSize, color: color),
            const SizedBox(width: 5),
            Text(
              label,
              style: TextStyle(
                color: color,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
