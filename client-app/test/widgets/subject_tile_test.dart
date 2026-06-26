import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';
import 'package:plan_sync/features/schedule/view/widgets/subject_tile.dart';

Widget _wrap(Widget child) => MaterialApp(
      theme: ThemeData.light(),
      home: Scaffold(body: child),
    );

SubjectTile _tile({
  required ScheduleEntry entry,
  bool showStar = false,
  bool starred = false,
  Function(bool)? onStarToggle,
}) =>
    SubjectTile(
      entry: entry,
      academicYear: '2024',
      semester: 'SEM1',
      scheme: 'a',
      showStar: showStar,
      starred: starred,
      onStarToggle: onStarToggle,
    );

void main() {
  final entry = ScheduleEntry(
    subject: 'Operating Systems',
    room: 'L101',
    time: '09:00 - 10:00',
  );

  group('SubjectTile', () {
    testWidgets('renders subject, room, and time', (tester) async {
      await tester.pumpWidget(_wrap(_tile(entry: entry)));
      expect(find.text('Operating Systems'), findsOneWidget);
      expect(find.text('L101'), findsOneWidget);
      expect(find.text('09:00 - 10:00'), findsOneWidget);
    });

    testWidgets('shows filled star icon when starred=true and showStar=true',
        (tester) async {
      await tester.pumpWidget(_wrap(_tile(
        entry: entry,
        showStar: true,
        starred: true,
        onStarToggle: (_) {},
      )));
      expect(find.byIcon(Icons.star_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    });

    testWidgets('shows outline star icon when starred=false and showStar=true',
        (tester) async {
      await tester.pumpWidget(_wrap(_tile(
        entry: entry,
        showStar: true,
        starred: false,
        onStarToggle: (_) {},
      )));
      expect(find.byIcon(Icons.star_outline_rounded), findsOneWidget);
      expect(find.byIcon(Icons.star_rounded), findsNothing);
    });

    testWidgets('no star icon when showStar=false', (tester) async {
      await tester.pumpWidget(_wrap(_tile(entry: entry, showStar: false)));
      expect(find.byIcon(Icons.star_rounded), findsNothing);
      expect(find.byIcon(Icons.star_outline_rounded), findsNothing);
    });

    testWidgets('tapping star calls onStarToggle with toggled value',
        (tester) async {
      bool? toggled;
      await tester.pumpWidget(_wrap(_tile(
        entry: entry,
        showStar: true,
        starred: false,
        onStarToggle: (v) => toggled = v,
      )));
      await tester.tap(find.byIcon(Icons.star_outline_rounded));
      expect(toggled, isTrue);
    });
  });
}
