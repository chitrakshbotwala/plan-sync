import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/features/attendance/view/widgets/attendance_activity_log.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';

class AttendanceLoadingState extends StatelessWidget {
  const AttendanceLoadingState({super.key, required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            LoadingAnimationWidget.progressiveDots(
              color: colorScheme.primary,
              size: 48,
            ),
            const SizedBox(height: 24),
            Text(
              viewModel.currentStep ?? 'Fetching your attendance…',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Text(
              'This can take up to a minute on the KIIT portal.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
              ),
            ),
            const SizedBox(height: 16),
            AttendanceActivityLog(logs: viewModel.logs),
          ],
        ),
      ),
    );
  }
}
