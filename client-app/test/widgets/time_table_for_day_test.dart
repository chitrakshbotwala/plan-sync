import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/features/schedule/model/timetable_meta.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';
import 'package:plan_sync/features/schedule/view/widgets/time_table_for_day.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../main.dart';

Timetable _buildMockTimetable() {
  return Timetable(
    meta: TimetableMeta(section: 'B13', type: 'schedule'),
    data: {
      'monday': [
        ScheduleEntry(subject: 'Sc LS.', room: 'Room 101', time: '9:00 AM'),
        ScheduleEntry(subject: 'Math', room: 'Room 201', time: '10:00 AM'),
        ScheduleEntry(subject: 'Physics', room: 'Room 301', time: '11:00 AM'),
      ],
      'tuesday': [],
      'wednesday': [],
      'thursday': [],
      'friday': [],
    },
  );
}

void main() {
  Future<void> pumpBaseWidget(
    WidgetTester tester,
    Timetable data,
    String day,
  ) async {
    return tester.pumpWidget(testApp(child: Scaffold(
        body: SingleChildScrollView(
          child: TimeTableForDay(
            data: data,
            day: day,
            showSigmaEmoji: false,
          ),
        ),
      ),
    ));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
  });

  testWidgets('TimeTableForDay Horizontal schedule is rendered', (
    WidgetTester tester,
  ) async {
    final data = _buildMockTimetable();
    const day = 'monday';

    await pumpBaseWidget(tester, data, day);
    await tester.pump(const Duration(seconds: 1));

    // drag until last element is visible
    await tester.dragUntilVisible(
      find.text('Sc LS.'),
      find.byKey(const ValueKey('TimeTableForDay._buildForTimetable')),
      const Offset(0, 500),
    );
    await tester.pump(const Duration(seconds: 1));

    // no error should be raised
    expect(tester.takeException(), null);
  });
}
