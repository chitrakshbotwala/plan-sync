import 'dart:convert';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/features/schedule/model/timetable_meta.dart';
import 'package:plan_sync/features/schedule/model/timetable_schedule_entry.dart';

Map<String, dynamic> _sampleJson({bool isTimetableUpdating = false}) => {
      'meta': {
        'section': 'b16',
        'type': 'norm-class',
        'revision': 'Revision 1.03',
        'effective-date': 'Jan 15, 2024',
        'contributor': 'Admin',
        'isTimetableUpdating': isTimetableUpdating,
        'name': 'B-16',
      },
      'data': {
        'monday': [
          {'time': '08:00 - 09:00', 'subject': 'Math', 'room': '301'},
          {'time': '09:00 - 10:00', 'subject': 'Physics', 'room': '302'},
        ],
        'tuesday': [
          {'time': '08:00 - 09:00', 'subject': 'Math', 'room': '301'},
        ],
      },
    };

void main() {
  group('ScheduleEntry', () {
    test('fromJson → toJson round-trip', () {
      final json = {
        'time': '08:00 - 09:00',
        'subject': 'Math',
        'room': '301',
        'teacher': ['Dr. ABV'],
      };
      final entry = ScheduleEntry.fromJson(json);
      expect(entry.time, '08:00 - 09:00');
      expect(entry.subject, 'Math');
      expect(entry.room, '301');
      expect(entry.toJson(), json);
    });

    test('fromJson handles null fields', () {
      final entry = ScheduleEntry.fromJson({});
      expect(entry.time, isNull);
      expect(entry.subject, isNull);
      expect(entry.room, isNull);
    });
  });

  group('TimetableMeta', () {
    test('fromJson → toJson round-trip including effective-date key mapping',
        () {
      final json = {
        'section': 'b16',
        'type': 'norm-class',
        'revision': 'Rev 1',
        'effective-date': 'Jan 1, 2024',
        'contributor': 'Admin',
        'isTimetableUpdating': false,
        'name': 'B-16',
      };
      final meta = TimetableMeta.fromJson(json);
      expect(meta.section, 'b16');
      expect(meta.effectiveDate, 'Jan 1, 2024');
      expect(meta.isTimetableUpdating, false);

      final roundTripped = TimetableMeta.fromJson(meta.toJson());
      expect(roundTripped.section, meta.section);
      expect(roundTripped.effectiveDate, meta.effectiveDate);
      expect(roundTripped.revision, meta.revision);
    });

    test('fromJson tolerates missing optional fields', () {
      final meta = TimetableMeta.fromJson({});
      expect(meta.section, isNull);
      expect(meta.isTimetableUpdating, isNull);
    });
  });

  group('Timetable', () {
    test('fromJson parses meta and data correctly', () {
      final t = Timetable.fromJson(json: _sampleJson());
      expect(t.meta.section, 'b16');
      expect(t.data.keys, containsAll(['monday', 'tuesday']));
      expect(t.data['monday']!.length, 2);
      expect(t.data['monday']!.first.subject, 'Math');
    });

    test('isFresh defaults to true', () {
      final t = Timetable.fromJson(json: _sampleJson());
      expect(t.isFresh, isTrue);
    });

    test('isFresh can be set to false', () {
      final t = Timetable.fromJson(json: _sampleJson(), isFresh: false);
      expect(t.isFresh, isFalse);
    });

    test('toJson → fromJson round-trip preserves entries', () {
      final original = Timetable.fromJson(json: _sampleJson());
      final roundTripped = Timetable.fromJson(json: original.toJson());

      expect(roundTripped.meta.section, original.meta.section);
      expect(roundTripped.data['monday']!.length, 2);
      expect(roundTripped.data['tuesday']!.first.subject, 'Math');
    });

    test('parse() decodes a raw JSON string', () {
      final jsonString = jsonEncode(_sampleJson());
      final t = Timetable.parse(jsonString);
      expect(t.meta.section, 'b16');
      expect(t.data['monday']!.length, 2);
    });

    test('isTimetableUpdating flag survives round-trip', () {
      final t =
          Timetable.fromJson(json: _sampleJson(isTimetableUpdating: true));
      expect(t.meta.isTimetableUpdating, isTrue);
    });
  });
}
