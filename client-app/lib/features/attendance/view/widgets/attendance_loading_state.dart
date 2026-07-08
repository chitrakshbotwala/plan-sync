import 'package:flutter/material.dart';
import 'package:loading_animation_widget/loading_animation_widget.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';

class AttendanceLoadingState extends StatelessWidget {
  const AttendanceLoadingState({super.key, required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final stages = AttendanceViewModel.loadingStages;
    final active = viewModel.loadingStage.clamp(0, stages.length - 1);

    return Container(
      color: Theme.of(context).scaffoldBackgroundColor,
      alignment: Alignment.center,
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: LoadingAnimationWidget.progressiveDots(
                color: colorScheme.primary,
                size: 44,
              ),
            ),
            const SizedBox(height: 28),
            for (var i = 0; i < stages.length; i++)
              _StageRow(
                label: stages[i],
                state: i < active
                    ? _StageState.done
                    : (i == active ? _StageState.active : _StageState.pending),
                isLast: i == stages.length - 1,
                colorScheme: colorScheme,
              ),
            const SizedBox(height: 20),
            Center(
              child: Text(
                'This can take up to a minute on the KIIT portal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withOpacity(0.55),
                  fontSize: 12,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

enum _StageState { done, active, pending }

class _StageRow extends StatelessWidget {
  const _StageRow({
    required this.label,
    required this.state,
    required this.isLast,
    required this.colorScheme,
  });

  final String label;
  final _StageState state;
  final bool isLast;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    final primary = colorScheme.primary;
    final done = state == _StageState.done;
    final active = state == _StageState.active;

    final Color markColor = done || active
        ? primary
        : colorScheme.onSurface.withOpacity(0.25);
    final Color textColor = active
        ? colorScheme.onSurface
        : done
            ? colorScheme.onSurface.withOpacity(0.7)
            : colorScheme.onSurface.withOpacity(0.4);

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            SizedBox(
              width: 22,
              height: 22,
              child: _marker(done, active, primary, markColor),
            ),
            const SizedBox(width: 14),
            Text(
              label,
              style: TextStyle(
                color: textColor,
                fontSize: 15,
                fontWeight: active ? FontWeight.w600 : FontWeight.w500,
              ),
            ),
          ],
        ),
        if (!isLast)
          Padding(
            padding: const EdgeInsets.only(left: 10),
            child: Container(
              width: 2,
              height: 16,
              color: (done ? primary : colorScheme.onSurface.withOpacity(0.15)),
            ),
          ),
      ],
    );
  }

  Widget _marker(bool done, bool active, Color primary, Color markColor) {
    if (done) {
      return Icon(Icons.check_circle_rounded, size: 22, color: primary);
    }
    if (active) {
      return Padding(
        padding: const EdgeInsets.all(2),
        child: CircularProgressIndicator(strokeWidth: 2.4, color: primary),
      );
    }
    return Container(
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        border: Border.all(color: markColor, width: 2),
      ),
    );
  }
}
