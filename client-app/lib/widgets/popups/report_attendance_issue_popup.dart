import 'package:flutter/material.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/util/external_links.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:provider/provider.dart';

class ReportAttendanceIssuePopup extends StatelessWidget {
  const ReportAttendanceIssuePopup({super.key});

  Future<void> _reportIssue(BuildContext context) async {
    try {
      final viewModel = context.read<AttendanceViewModel>();
      final preferences = context.read<AppPreferencesRepository>();
      await ExternalLinks.reportAttendanceIssueViaMail(
        academicYear: viewModel.academicYear,
        semester: viewModel.result?.student?.semester ??
            preferences.getPrimarySemesterPreference(),
        section: preferences.getPrimarySectionPreference(),
        debugInfoLines: viewModel.reportDiagnosticsLines(),
      );
    } catch (_) {
      if (!context.mounted) return;

      CustomSnackbar.error(
        'Failed to launch mail app',
        'Could not open your mail application. Please try again.',
        context,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Dialog(
      backgroundColor: colorScheme.surface,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Report an Attendance Issue',
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Having trouble with Attendance Tracker? We\'ll help you sort it out.\n\n'
                'We\'ll prefill an email with technical information like your academic year, semester, section, app version and device details so we can investigate faster.\n\n'
                'Your SAP username and password are never included in the report.\n\n'
                'Before sending, please include:\n'
                '- What you were trying to do\n'
                '- What happened instead\n'
                '- Whether the issue happens every time or only sometimes\n'
                '- A screenshot (if possible)\n\n'
                'We\'ll look into it as soon as we can.',
                style: TextStyle(
                  color: colorScheme.onSurface.withValues(alpha: 0.82),
                  height: 1.35,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () => _reportIssue(context),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: colorScheme.primary,
                    foregroundColor: colorScheme.onPrimary,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  icon: const Icon(Icons.mail_outline_rounded, size: 18),
                  label: const Text('Report Issue'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
