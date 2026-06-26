import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/core/util/attendance_status.dart';

void main() {
  group('AttendanceRecord.fromScrape', () {
    test('coerces string cells from the portal into numbers', () {
      final r = AttendanceRecord.fromScrape({
        'subject': 'Chemistry',
        'absent': '5',
        'present': '25',
        'totalDays': '30',
        'percentage': '83.33',
        'facultyId': '12345',
        'facultyName': 'Dr. X',
        'excuses': '0',
      });

      expect(r.subject, 'Chemistry');
      expect(r.absent, 5);
      expect(r.present, 25);
      expect(r.totalDays, 30);
      expect(r.percentage, closeTo(83.33, 0.001));
    });

    test('tolerates decimal-formatted counts and blanks', () {
      final r = AttendanceRecord.fromScrape({
        'subject': 'English',
        'absent': '25.00',
        'present': '6.00',
        'totalDays': '31.00',
        'percentage': '19.35',
        'facultyId': '',
        'facultyName': '',
        'excuses': '',
      });

      expect(r.absent, 25);
      expect(r.present, 6);
      expect(r.totalDays, 31);
      expect(r.excuses, 0);
    });
  });

  group('AttendanceResult derived totals', () {
    final result = AttendanceResult.fromScrape(
      {
        'records': [
          {
            'subject': 'A',
            'absent': '2',
            'present': '8',
            'totalDays': '10',
            'percentage': '80.00',
          },
          {
            'subject': 'B',
            'absent': '4',
            'present': '6',
            'totalDays': '10',
            'percentage': '60.00',
          },
        ],
        'student': {'name': 'Test Student', 'rollNo': '111'},
      },
      academicYear: '2025-2026',
      session: 'Spring',
    );

    test('overall percentage is weighted by total classes, not averaged', () {
      // (8 + 6) / (10 + 10) = 70%, NOT (80 + 60) / 2 = 70 here, but the
      // weighting matters for uneven class counts; verify the present/total
      // formula directly.
      expect(result.totalPresent, 14);
      expect(result.totalClasses, 20);
      expect(result.overallPercentage, closeTo(70.0, 0.001));
    });

    test('counts subjects below the 75% threshold', () {
      expect(result.subjectsBelowThreshold, 1);
    });

    test('parses student details', () {
      expect(result.student?.name, 'Test Student');
      expect(result.student?.rollNo, '111');
    });
  });

  group('attendanceLevelFor thresholds', () {
    test('>= 75 is good', () {
      expect(attendanceLevelFor(75), AttendanceLevel.good);
      expect(attendanceLevelFor(92.5), AttendanceLevel.good);
    });
    test('65..<75 is warning', () {
      expect(attendanceLevelFor(74.99), AttendanceLevel.warning);
      expect(attendanceLevelFor(65), AttendanceLevel.warning);
    });
    test('< 65 is critical', () {
      expect(attendanceLevelFor(64.99), AttendanceLevel.critical);
      expect(attendanceLevelFor(0), AttendanceLevel.critical);
    });
  });

  group('AttendanceRecord.canSkip', () {
    test('is 0 when already below 75%', () {
      final r = AttendanceRecord.fromScrape({
        'subject': 'X',
        'absent': '5',
        'present': '5',
        'totalDays': '10',
        'percentage': '50.00',
      });
      expect(r.canSkip, 0);
    });

    test('reports skippable classes when comfortably above threshold', () {
      // 90/100 = 90%. floor(90/0.75)=120 max days -> can miss 20 more.
      final r = AttendanceRecord.fromScrape({
        'subject': 'Y',
        'absent': '10',
        'present': '90',
        'totalDays': '100',
        'percentage': '90.00',
      });
      expect(r.canSkip, 20);
    });

    test('is 0 at exactly 75% (no buffer to skip)', () {
      // 75/100 = 75%. floor(75/0.75)=100 max days -> 100-100 = 0.
      final r = AttendanceRecord.fromScrape({
        'subject': 'Z',
        'absent': '25',
        'present': '75',
        'totalDays': '100',
        'percentage': '75.00',
      });
      expect(r.canSkip, 0);
    });
  });

  group('AttendanceResult edge cases', () {
    AttendanceResult build(List<Map<String, dynamic>> records) =>
        AttendanceResult.fromScrape(
          {'records': records},
          academicYear: '2025-2026',
          session: 'Spring',
        );

    test('empty result: totals are zero and isEmpty is true', () {
      final r = build([]);
      expect(r.isEmpty, isTrue);
      expect(r.totalPresent, 0);
      expect(r.totalClasses, 0);
      expect(r.subjectsBelowThreshold, 0);
    });

    test('overallPercentage is 0 when there are no classes (no divide-by-zero)',
        () {
      expect(build([]).overallPercentage, 0);
    });

    test('a subject at exactly 75% is not counted as below threshold', () {
      final r = build([
        {
          'subject': 'A',
          'absent': '25',
          'present': '75',
          'totalDays': '100',
          'percentage': '75.00',
        },
      ]);
      expect(r.subjectsBelowThreshold, 0);
      expect(r.isEmpty, isFalse);
    });
  });
}
