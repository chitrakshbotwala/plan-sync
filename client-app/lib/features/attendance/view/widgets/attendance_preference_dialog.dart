import 'package:flutter/material.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:provider/provider.dart';

// ---------------------------------------------------------------------------
// Button — sits in the AppBar, same style as SchedulePreferenceButton
// ---------------------------------------------------------------------------

class AttendancePreferenceButton extends StatelessWidget {
  const AttendancePreferenceButton({super.key, required this.viewModel});

  final AttendanceViewModel viewModel;

  String get _label {
    // Shorten "2025-2026" → "25-26"
    final parts = viewModel.academicYear.split('-');
    final shortYear = parts.length == 2
        ? '${parts[0].substring(2)}-${parts[1].substring(2)}'
        : viewModel.academicYear;
    return '$shortYear · ${viewModel.session.substring(0, 3)}';
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final appTheme = Provider.of<ThemeService>(context, listen: false);

    return ElevatedButton(
      onPressed: () => showDialog<void>(
        context: context,
        builder: (_) => AttendancePreferenceDialog(viewModel: viewModel),
      ),
      style: ButtonStyle(
        backgroundColor: WidgetStatePropertyAll(
          appTheme.isDarkMode ? colorScheme.primary : colorScheme.onSurface,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            _label,
            style: TextStyle(
              color: appTheme.isDarkMode
                  ? colorScheme.onPrimary
                  : colorScheme.surface,
              fontSize: 13,
            ),
          ),
          const SizedBox(width: 6),
          Icon(
            Icons.keyboard_arrow_down_rounded,
            size: 18,
            color: appTheme.isDarkMode
                ? colorScheme.onPrimary
                : colorScheme.surface,
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Dialog — same structure as SchedulePreferenceDialog
// ---------------------------------------------------------------------------

class AttendancePreferenceDialog extends StatefulWidget {
  const AttendancePreferenceDialog({super.key, required this.viewModel});

  final AttendanceViewModel viewModel;

  @override
  State<AttendancePreferenceDialog> createState() =>
      _AttendancePreferenceDialogState();
}

class _AttendancePreferenceDialogState
    extends State<AttendancePreferenceDialog> {
  late String _year;
  late String _session;

  @override
  void initState() {
    super.initState();
    _year = widget.viewModel.academicYear;
    _session = widget.viewModel.session;
  }

  void _onApply() {
    widget.viewModel.changeSelection(year: _year, session: _session);
    widget.viewModel.applySelection();
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dialog(
      backgroundColor: colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          // Header
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 16),
            child: Row(
              children: [
                Text(
                  'Attendance Period',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: colorScheme.onSurface,
                  ),
                ),
              ],
            ),
          ),

          // Registration ID row (read-only)
          if (widget.viewModel.registrationNumber != null)
            _PreferenceRow(
              icon: Icons.badge_outlined,
              label: 'Registration ID',
              colorScheme: colorScheme,
              trailing: Text(
                widget.viewModel.registrationNumber!,
                style: TextStyle(
                  color: colorScheme.onSurface,
                  fontWeight: FontWeight.w500,
                  fontSize: 13,
                ),
              ),
            ),

          // Academic Year row
          _PreferenceRow(
            icon: Icons.calendar_today_outlined,
            label: 'Academic Year',
            colorScheme: colorScheme,
            trailing: _PillDropdown<String>(
              value: _year,
              items: widget.viewModel.yearOptions,
              colorScheme: colorScheme,
              onChanged: (v) {
                if (v != null) setState(() => _year = v);
              },
            ),
          ),

          // Session row
          _PreferenceRow(
            icon: Icons.wb_sunny_outlined,
            label: 'Session',
            colorScheme: colorScheme,
            trailing: _PillDropdown<String>(
              value: _session,
              items: widget.viewModel.sessionOptions,
              colorScheme: colorScheme,
              onChanged: (v) {
                if (v != null) setState(() => _session = v);
              },
            ),
          ),

          const SizedBox(height: 12),

          // Footer buttons
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 4, 12, 12),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: [
                TextButton(
                  onPressed: () => Navigator.of(context).pop(),
                  child: Text(
                    'Cancel',
                    style: TextStyle(color: colorScheme.onSurface),
                  ),
                ),
                const SizedBox(width: 8),
                ElevatedButton(
                  style: ButtonStyle(
                    backgroundColor:
                        WidgetStatePropertyAll(colorScheme.secondary),
                    foregroundColor:
                        WidgetStatePropertyAll(colorScheme.onSecondary),
                  ),
                  onPressed: _onApply,
                  child: Text(
                    'Apply',
                    style: TextStyle(color: colorScheme.onSecondary),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------------------------------------------------------------------
// Shared sub-widgets (mirrors schedule_preference.dart private widgets)
// ---------------------------------------------------------------------------

class _PreferenceRow extends StatelessWidget {
  const _PreferenceRow({
    required this.icon,
    required this.label,
    required this.trailing,
    required this.colorScheme,
  });

  final IconData icon;
  final String label;
  final Widget trailing;
  final ColorScheme colorScheme;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Row(
        children: [
          Icon(icon, color: colorScheme.onSurface, size: 20),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: TextStyle(color: colorScheme.onSurface),
              overflow: TextOverflow.ellipsis,
            ),
          ),
          const SizedBox(width: 8),
          trailing,
        ],
      ),
    );
  }
}

class _PillDropdown<T> extends StatelessWidget {
  const _PillDropdown({
    required this.value,
    required this.items,
    required this.colorScheme,
    required this.onChanged,
  });

  final T value;
  final List<T> items;
  final ColorScheme colorScheme;
  final ValueChanged<T?> onChanged;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: ShapeDecoration(
        shape: const StadiumBorder(),
        color: colorScheme.onSurface,
      ),
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: SizedBox(
        width: 136,
        height: 44,
        child: DropdownButtonHideUnderline(
          child: DropdownButton<T>(
            isExpanded: true,
            elevation: 0,
            style: TextStyle(color: colorScheme.surface, fontSize: 13),
            icon: Icon(Icons.arrow_drop_down, color: colorScheme.surface),
            value: value,
            dropdownColor: colorScheme.onSurface,
            menuMaxHeight: 280,
            items: items
                .map((e) => DropdownMenuItem<T>(
                      value: e,
                      child: Text(
                        e.toString(),
                        style: TextStyle(color: colorScheme.surface),
                        overflow: TextOverflow.ellipsis,
                      ),
                    ))
                .toList(),
            onChanged: onChanged,
          ),
        ),
      ),
    );
  }
}
