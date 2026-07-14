import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/features/attendance/model/scrape_exception.dart';

void main() {
  group('Weekday.fromIndex', () {
    test('index 0 → sunday', () {
      expect(Weekday.fromIndex(0), Weekday.sunday);
    });
    test('index 1 → monday', () {
      expect(Weekday.fromIndex(1), Weekday.monday);
    });
    test('index 5 → friday', () {
      expect(Weekday.fromIndex(5), Weekday.friday);
    });
    test('index 6 → saturday', () {
      expect(Weekday.fromIndex(6), Weekday.saturday);
    });
  });

  group('ScrapeErrorKind.fromKey', () {
    test('known key returns corresponding enum value', () {
      expect(
        ScrapeErrorKind.fromKey('invalidCredentials'),
        ScrapeErrorKind.invalidCredentials,
      );
      expect(
        ScrapeErrorKind.fromKey('portalUnavailable'),
        ScrapeErrorKind.portalUnavailable,
      );
      expect(
        ScrapeErrorKind.fromKey('timeout'),
        ScrapeErrorKind.timeout,
      );
    });

    test('unknown key falls back to unknown', () {
      expect(ScrapeErrorKind.fromKey('something_weird'), ScrapeErrorKind.unknown);
    });

    test('null falls back to unknown', () {
      expect(ScrapeErrorKind.fromKey(null), ScrapeErrorKind.unknown);
    });
  });

  group('ScrapeException.title', () {
    test('invalidCredentials → Incorrect credentials', () {
      const e = ScrapeException(ScrapeErrorKind.invalidCredentials, '');
      expect(e.title, 'Incorrect credentials');
    });

    test('portalUnavailable → Portal unavailable', () {
      const e = ScrapeException(ScrapeErrorKind.portalUnavailable, '');
      expect(e.title, 'Portal unavailable');
    });

    test('timeout → Request timed out', () {
      const e = ScrapeException(ScrapeErrorKind.timeout, '');
      expect(e.title, 'Request timed out');
    });

    test('unknown → Something went wrong', () {
      const e = ScrapeException(ScrapeErrorKind.unknown, '');
      expect(e.title, 'Something went wrong');
    });

    test('toString includes kind name and message', () {
      const e = ScrapeException(ScrapeErrorKind.noData, 'No records found');
      expect(e.toString(), contains('noData'));
      expect(e.toString(), contains('No records found'));
    });
  });
}
