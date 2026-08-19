import 'package:flutter/material.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/widgets/animations/fade_slide_in.dart';

/// Shown for the moment between tapping "Load attendance" and the saved copy
/// being read out of the cache. Without it the tap looks like it did nothing —
/// which is exactly how it feels after a fresh log-in, when the cache read is
/// the only work happening before data appears.
class AttendanceRestoringState extends StatefulWidget {
  const AttendanceRestoringState({super.key, required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  State<AttendanceRestoringState> createState() =>
      _AttendanceRestoringStateState();
}

class _AttendanceRestoringStateState extends State<AttendanceRestoringState>
    with SingleTickerProviderStateMixin {
  late final AnimationController _spin = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1400),
  )..repeat();

  @override
  void dispose() {
    _spin.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final period = '${widget.viewModel.session} '
        '${widget.viewModel.academicYear}';

    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            FadeSlideIn(
              child: RotationTransition(
                turns: _spin,
                child: Container(
                  width: 84,
                  height: 84,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: colorScheme.primary.withValues(alpha: 0.12),
                  ),
                  child: Icon(
                    Icons.cached_rounded,
                    size: 38,
                    color: colorScheme.primary,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 20),
            FadeSlideIn(
              delay: const Duration(milliseconds: 80),
              child: Text(
                'Checking your saved copy',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 8),
            FadeSlideIn(
              delay: const Duration(milliseconds: 140),
              child: Text(
                'Looking for saved attendance for $period. '
                'If none is stored, we\'ll fetch it from the KIIT portal.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.65),
                  fontSize: 13,
                  height: 1.45,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
