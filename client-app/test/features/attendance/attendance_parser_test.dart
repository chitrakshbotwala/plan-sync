import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/services/kiit_attendance_scraper.dart';

/// Column-mapping tests for the attendance grid parser. The scraper emits the
/// raw table as `{headers, rows}` and the app maps columns to fields, so these
/// lock in that the subject and faculty name never get swapped — the reported
/// bug — even when the header row and the data rows don't line up.
void main() {
  List<String> h(String s) => s.split('|');
  List<List<String>> r(List<String> row) => [row];

  group('attendance grid parser — column mapping', () {
    test('standard KIIT layout maps every field', () {
      final recs = KiitAttendanceScraper.recordsFromGridForTest(
        h('subject|no.of absent|no.of present|total no. of days|'
            'total percentage|faculty id|faculty name|no. of excuses'),
        r(['Chemistry', '5', '25', '30', '83.33', '12345', 'Dr. X', '2']),
      );

      expect(recs, hasLength(1));
      final rec = recs.first;
      expect(rec.subject, 'Chemistry');
      expect(rec.facultyName, 'Dr. X');
      expect(rec.facultyId, '12345');
      expect(rec.present, 25);
      expect(rec.absent, 5);
      expect(rec.totalDays, 30);
      expect(rec.percentage, closeTo(83.33, 0.01));
      expect(rec.excuses, 2);
    });

    test('reordered columns are resolved by header name', () {
      // Faculty name rendered BEFORE the subject; headers move with the data.
      final recs = KiitAttendanceScraper.recordsFromGridForTest(
        h('faculty name|subject|no.of absent|no.of present|'
            'total no. of days|total percentage|faculty id|no. of excuses'),
        r(['Dr. Smith', 'Physics', '5', '25', '30', '83.33', '54321', '0']),
      );

      expect(recs.first.subject, 'Physics');
      expect(recs.first.facultyName, 'Dr. Smith');
    });

    test('faculty name does not leak into subject when the header is missing',
        () {
      // The subject header is absent (mislabeled), and the faculty name is the
      // first text cell in the row — the exact shape that used to surface the
      // faculty name in the subject line.
      final recs = KiitAttendanceScraper.recordsFromGridForTest(
        h('faculty name|sub|no.of absent|no.of present|'
            'total no. of days|total percentage|faculty id|no. of excuses'),
        r(['Dr. Smith', 'Physics', '5', '25', '30', '83.33', '54321', '0']),
      );

      expect(recs.first.subject, 'Physics',
          reason: 'subject must be the course, not the faculty name');
      expect(recs.first.facultyName, 'Dr. Smith');
    });

    test('subject and faculty name are never equal', () {
      final recs = KiitAttendanceScraper.recordsFromGridForTest(
        h('faculty name|subject|no.of absent|no.of present|'
            'total no. of days|total percentage|faculty id|no. of excuses'),
        r(['Dr. Smith', 'Maths', '4', '26', '30', '86.67', '99999', '1']),
      );

      final rec = recs.first;
      expect(rec.subject, isNot(equals(rec.facultyName)));
      expect(rec.subject, 'Maths');
    });

    test('decimal-formatted counts and a blank faculty id still decode', () {
      final recs = KiitAttendanceScraper.recordsFromGridForTest(
        h('subject|no.of absent|no.of present|total no. of days|'
            'total percentage|faculty id|faculty name|no. of excuses'),
        r(['English', '25.00', '6.00', '31.00', '19.35', '', 'Prof. Y', '0']),
      );

      final rec = recs.first;
      expect(rec.subject, 'English');
      expect(rec.present, 6);
      expect(rec.absent, 25);
      expect(rec.totalDays, 31);
      expect(rec.percentage, closeTo(19.35, 0.5));
      expect(rec.facultyName, 'Prof. Y');
    });

    test('multiple rows all map independently', () {
      final recs = KiitAttendanceScraper.recordsFromGridForTest(
        h('subject|no.of absent|no.of present|total no. of days|'
            'total percentage|faculty id|faculty name|no. of excuses'),
        [
          ['Chemistry', '5', '25', '30', '83.33', '12345', 'Dr. A', '0'],
          ['Physics', '2', '28', '30', '93.33', '67890', 'Dr. B', '1'],
        ],
      );

      expect(recs, hasLength(2));
      expect(recs[0].subject, 'Chemistry');
      expect(recs[0].facultyName, 'Dr. A');
      expect(recs[1].subject, 'Physics');
      expect(recs[1].facultyName, 'Dr. B');
    });
  });
}
