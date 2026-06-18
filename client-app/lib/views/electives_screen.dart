import 'package:flutter/material.dart';
import 'package:plan_sync/widgets/buttons/elective_preferences_button.dart';
import 'package:plan_sync/widgets/date_widget.dart';
import 'package:plan_sync/widgets/time_table.dart';

class ElectiveScreen extends StatelessWidget {
  const ElectiveScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      extendBody: true,
      appBar: AppBar(
        backgroundColor: colorScheme.surfaceContainerHighest,
        elevation: 0.0,
        toolbarHeight: 80,
        shape: const RoundedRectangleBorder(
            borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(32),
        )),
        title: Text(
          "Electives",
          style: TextStyle(
            color: colorScheme.onSurface,
            fontWeight: FontWeight.bold,
            letterSpacing: 0.2,
          ),
        ),
        actions: const [
          ElectivePreferenceButton(),
          SizedBox(width: 16),
        ],
      ),
      body: const Padding(
        padding: EdgeInsets.symmetric(horizontal: 12.0),
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 12),
              DateWidget(),
              SizedBox(height: 8),
              TimeTableWidget(isElective: true),
            ],
          ),
        ),
      ),
    );
  }
}
