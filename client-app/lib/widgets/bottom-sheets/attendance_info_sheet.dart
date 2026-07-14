import 'package:flutter/material.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:provider/provider.dart';

/// "More info" sheet: explains the colour thresholds, shows the scraped student
/// details + when it was last updated, and lets the user manage credentials.
class AttendanceInfoSheet extends StatelessWidget {
  const AttendanceInfoSheet({super.key, this.onChangeCredentials});

  /// Invoked (after this sheet closes) to re-open the credentials sheet.
  final VoidCallback? onChangeCredentials;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final viewModel = context.watch<AttendanceViewModel>();
    final student = viewModel.result?.student;
    final fetchedAt = viewModel.result?.fetchedAt;

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 8, 20, 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'About your attendance',
            style: TextStyle(
              color: colorScheme.onSurface,
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Pulled live from the KIIT SAP portal — Student Self Service › '
            'Student Attendance Details.',
            style: TextStyle(
              color: colorScheme.onSurface.withOpacity(0.7),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 18),

          // colour legend
          _LegendRow(
            color: colorScheme.primary,
            label: 'Safe',
            detail: '75% and above',
          ),
          const SizedBox(height: 8),
          _LegendRow(
            color: colorScheme.tertiary,
            label: 'Warning',
            detail: '65% – 74%',
          ),
          const SizedBox(height: 8),
          _LegendRow(
            color: colorScheme.error,
            label: 'Critical',
            detail: 'Below 65%',
          ),

          if (student != null) ...[
            const SizedBox(height: 20),
            Divider(
                color: colorScheme.onSurfaceVariant.withOpacity(0.32)),
            const SizedBox(height: 8),
            _detailRow(context, 'Name', student.name),
            _detailRow(context, 'Roll No.', student.rollNo),
            _detailRow(context, 'Registration', student.regNo),
            _detailRow(context, 'Programme', student.program),
            _detailRow(context, 'Semester', student.semester),
          ],

          if (fetchedAt != null) ...[
            const SizedBox(height: 14),
            Text(
              'Last updated ${_formatTime(fetchedAt)}',
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.5),
                fontSize: 12,
              ),
            ),
          ],

          const SizedBox(height: 20),
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    Navigator.of(context).pop();
                    onChangeCredentials?.call();
                  },
                  icon: const Icon(Icons.key_outlined, size: 18),
                  label: const Text('Change login'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.onSurface,
                    side: BorderSide(
                      color:
                          colorScheme.onSurfaceVariant.withOpacity(0.4),
                    ),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: () {
                    viewModel.disconnect();
                    Navigator.of(context).pop();
                  },
                  icon: const Icon(Icons.link_off_rounded, size: 18),
                  label: const Text('Disconnect'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: colorScheme.error,
                    side: BorderSide(
                        color: colorScheme.error.withOpacity(0.6)),
                    padding:
                        const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _detailRow(BuildContext context, String label, String? value) {
    if (value == null || value.isEmpty) return const SizedBox.shrink();
    final colorScheme = Theme.of(context).colorScheme;
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 110,
            child: Text(
              label,
              style: TextStyle(
                color: colorScheme.onSurface.withOpacity(0.6),
                fontSize: 13,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                color: colorScheme.onSurface,
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  static String _formatTime(DateTime dt) {
    final local = dt.toLocal();
    final h = local.hour % 12 == 0 ? 12 : local.hour % 12;
    final m = local.minute.toString().padLeft(2, '0');
    final ampm = local.hour < 12 ? 'AM' : 'PM';
    return 'at $h:$m $ampm';
  }
}

class _LegendRow extends StatelessWidget {
  const _LegendRow({
    required this.color,
    required this.label,
    required this.detail,
  });

  final Color color;
  final String label;
  final String detail;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      children: [
        Container(
          width: 14,
          height: 14,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(4),
          ),
        ),
        const SizedBox(width: 10),
        Text(
          label,
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.w600,
            fontSize: 13,
          ),
        ),
        const SizedBox(width: 8),
        Text(
          detail,
          style: TextStyle(
            color: colorScheme.onSurface.withOpacity(0.6),
            fontSize: 13,
          ),
        ),
      ],
    );
  }
}
