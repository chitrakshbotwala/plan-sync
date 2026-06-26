import 'package:flutter/material.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:plan_sync/widgets/bottom-sheets/bottom_sheets_wrapper.dart';

class AttendanceActionsRow extends StatelessWidget {
  const AttendanceActionsRow({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        TextButton.icon(
          onPressed: () => BottomSheets.attendanceInfo(context: context),
          icon: Icon(Icons.info_outline_rounded,
              size: 18, color: colorScheme.tertiary),
          label: Text(
            'More info',
            style: TextStyle(color: colorScheme.onSurface),
          ),
        ),
        TextButton.icon(
          onPressed: () => BottomSheets.reportError(context: context),
          icon: Icon(FontAwesomeIcons.flag,
              size: 15, color: colorScheme.error),
          label: Text(
            'Report Error',
            style: TextStyle(color: colorScheme.error),
          ),
        ),
      ],
    );
  }
}
