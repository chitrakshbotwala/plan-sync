import 'package:flutter/material.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/widgets/bottom-sheets/bottom_sheets_wrapper.dart';

class AttendanceNeedsCredentials extends StatelessWidget {
  const AttendanceNeedsCredentials({super.key, required this.viewModel});
  final AttendanceViewModel viewModel;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.fact_check_outlined,
                size: 72,
                color: colorScheme.primary.withOpacity(0.8)),
            const SizedBox(height: 20),
            Text(
              'Track your attendance',
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Connect your KIIT portal login and Plan Sync will pull your '
              'subject-wise attendance for you.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.7),
                fontSize: 14,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () =>
                  BottomSheets.kiitCredentials(context: context),
              icon: const Icon(Icons.link_rounded),
              label: const Text('Connect KIIT Portal'),
              style: ElevatedButton.styleFrom(
                backgroundColor: colorScheme.primary,
                foregroundColor: colorScheme.onPrimary,
                padding: const EdgeInsets.symmetric(
                    horizontal: 24, vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
