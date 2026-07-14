import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/home/today_schedule.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';

ScheduleEntry _e({String? subject, String? room, String? time}) =>
    ScheduleEntry(subject: subject, room: room, time: time);

void main() {
  group('parseToken', () {
    test('parses 12-hour with AM/PM', () {
      expect(TodaySchedule.parseToken('9:00 AM'), 9 * 60);
      expect(TodaySchedule.parseToken('1:30 PM'), 13 * 60 + 30);
    });

    test('handles 12 AM (midnight) and 12 PM (noon)', () {
      expect(TodaySchedule.parseToken('12:00 AM'), 0);
      expect(TodaySchedule.parseToken('12:00 PM'), 12 * 60);
    });

    test('parses 24-hour and bare-hour tokens', () {
      expect(TodaySchedule.parseToken('14:30'), 14 * 60 + 30);
      expect(TodaySchedule.parseToken('9'), 9 * 60);
    });

    test('returns -1 for unparseable input', () {
      expect(TodaySchedule.parseToken('lunch'), -1);
    });
  });

  group('start/endMinutes', () {
    test('splits a hyphen range', () {
      expect(TodaySchedule.startMinutes('9:00 AM - 10:00 AM'), 9 * 60);
      expect(TodaySchedule.endMinutes('9:00 AM - 10:00 AM'), 10 * 60);
    });

    test('splits an en-dash range', () {
      expect(TodaySchedule.startMinutes('9:00 – 10:00'), 9 * 60);
      expect(TodaySchedule.endMinutes('9:00 – 10:00'), 10 * 60);
    });

    test('returns -1 when no end is present or input is empty', () {
      expect(TodaySchedule.endMinutes('9:00 AM'), -1);
      expect(TodaySchedule.startMinutes(null), -1);
      expect(TodaySchedule.startMinutes(''), -1);
    });
  });

  group('splitTime', () {
    test('returns (start, end) for a range', () {
      expect(TodaySchedule.splitTime('9:00 - 10:00'), ('9:00', '10:00'));
    });

    test('returns (value, "") when no separator and ("","") for null', () {
      expect(TodaySchedule.splitTime('9:00'), ('9:00', ''));
      expect(TodaySchedule.splitTime(null), ('', ''));
    });
  });

  group('sorted', () {
    test('orders entries by start time without mutating the input', () {
      final input = [
        _e(subject: 'B', time: '11:00 AM - 12:00 PM'),
        _e(subject: 'A', time: '9:00 AM - 10:00 AM'),
      ];
      final out = TodaySchedule.sorted(input);
      expect(out.map((e) => e.subject), ['A', 'B']);
      expect(input.first.subject, 'B'); // original untouched
    });
  });

  group('mergeElectives', () {
    final regular = [
      _e(subject: 'Math', room: 'R1', time: '9:00 AM - 10:00 AM'),
      _e(subject: 'Electives', room: 'R2', time: '10:00 AM - 11:00 AM'),
    ];

    test('returns null when no electives are chosen', () {
      final out = TodaySchedule.mergeElectives(
        chosen1: null,
        chosen2: null,
        electivesHasData: true,
        electiveEntriesForDay: const [],
        regularEntries: regular,
      );
      expect(out, isNull);
    });

    test('returns null when the elective scheme is not loaded', () {
      final out = TodaySchedule.mergeElectives(
        chosen1: 'AI',
        chosen2: null,
        electivesHasData: false,
        electiveEntriesForDay: const [],
        regularEntries: regular,
      );
      expect(out, isNull);
    });

    test('placeholder time/room are authoritative over the elective', () {
      final out = TodaySchedule.mergeElectives(
        chosen1: 'AI',
        chosen2: null,
        electivesHasData: true,
        electiveEntriesForDay: [
          _e(subject: 'AI', room: 'E9', time: '8:00 AM - 9:00 AM'),
        ],
        regularEntries: regular,
      );
      expect(out, isNotNull);
      final elective = out![1];
      expect(elective.subject, 'AI');
      expect(elective.time, '10:00 AM - 11:00 AM'); // placeholder wins
      expect(elective.room, 'E9'); // elective room kept (placeholder R2 too)
    });

    test('falls back to the elective time/room when placeholder omits them', () {
      final out = TodaySchedule.mergeElectives(
        chosen1: 'AI',
        chosen2: null,
        electivesHasData: true,
        electiveEntriesForDay: [
          _e(subject: 'AI', room: 'E9', time: '8:00 AM - 9:00 AM'),
        ],
        regularEntries: [_e(subject: 'Electives')], // no time/room on placeholder
      );
      final elective = out![0];
      expect(elective.time, '8:00 AM - 9:00 AM');
      expect(elective.room, 'E9');
    });

    test('appends a second elective (with its own time) when only one '
        'placeholder exists', () {
      final out = TodaySchedule.mergeElectives(
        chosen1: 'AI',
        chosen2: 'ML',
        electivesHasData: true,
        electiveEntriesForDay: [
          _e(subject: 'AI', time: '10:00 AM - 11:00 AM'),
          _e(subject: 'ML', room: 'E2', time: '11:00 AM - 12:00 PM'),
        ],
        regularEntries: regular, // only one "Electives" slot
      );
      expect(out!.map((e) => e.subject), ['Math', 'AI', 'ML']);
      expect(out.last.time, '11:00 AM - 12:00 PM');
    });

    test('matches a placeholder with stray whitespace (" Electives")', () {
      // Mirrors real schedule data, where the placeholder has a leading space
      // and the room reads "See Electives Page".
      final out = TodaySchedule.mergeElectives(
        chosen1: 'EML-1',
        chosen2: null,
        electivesHasData: true,
        electiveEntriesForDay: [
          _e(subject: 'EML-1', room: 'B-301', time: '12:20 - 13:20'),
        ],
        regularEntries: [
          _e(subject: 'PHY', room: 'B-301', time: '11:20 - 12:20'),
          _e(subject: ' Electives', room: 'See Electives Page', time: '12:20 - 13:20'),
        ],
      );
      // Placeholder replaced (no raw "Electives" row left), real room shown.
      expect(out!.map((e) => e.subject), ['PHY', 'EML-1']);
      expect(out.last.room, 'B-301');
      expect(out.last.time, '12:20 - 13:20');
    });

    test('drops an appended elective that has no time of its own', () {
      final out = TodaySchedule.mergeElectives(
        chosen1: 'AI',
        chosen2: 'ML',
        electivesHasData: true,
        electiveEntriesForDay: [
          _e(subject: 'AI', time: '10:00 AM - 11:00 AM'),
          _e(subject: 'ML'), // no time → can't be placed
        ],
        regularEntries: regular,
      );
      expect(out!.map((e) => e.subject), ['Math', 'AI']);
    });
  });

  group('current/next/minutesLeft', () {
    final entries = [
      _e(subject: 'A', time: '9:00 AM - 10:00 AM'),
      _e(subject: 'B', time: '10:00 AM - 11:00 AM'),
    ];

    test('currentEntry matches [start, end)', () {
      expect(TodaySchedule.currentEntry(entries, 9 * 60 + 30)?.subject, 'A');
      expect(TodaySchedule.currentEntry(entries, 10 * 60)?.subject, 'B');
      expect(TodaySchedule.currentEntry(entries, 8 * 60), isNull);
    });

    test('nextEntry returns the following class, or null at the end', () {
      expect(TodaySchedule.nextEntry(entries, entries[0])?.subject, 'B');
      expect(TodaySchedule.nextEntry(entries, entries[1]), isNull);
    });

    test('minutesLeft is the remaining whole minutes, never negative', () {
      expect(TodaySchedule.minutesLeft(entries[0], 9 * 60 + 45), 15);
      expect(TodaySchedule.minutesLeft(entries[0], 11 * 60), 0);
    });
  });
}
