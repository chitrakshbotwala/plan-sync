import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/util/app_version.dart';

void main() {
  group('AppVersion parsing', () {
    test('splits a dotted version string into integer parts', () {
      expect(AppVersion('4.1.3').parts, [4, 1, 3]);
    });

    test('throws on non-numeric segments', () {
      expect(() => AppVersion('1.2.beta'), throwsFormatException);
    });
  });

  group('AppVersion.isGreaterThan', () {
    test('detects greater patch version', () {
      expect(AppVersion('1.2.4').isGreaterThan(AppVersion('1.2.3')), isTrue);
    });

    test('detects greater minor version even when patch is smaller', () {
      expect(AppVersion('1.3.0').isGreaterThan(AppVersion('1.2.9')), isTrue);
    });

    test('detects greater major version even when minor is smaller', () {
      expect(AppVersion('2.0.0').isGreaterThan(AppVersion('1.9.9')), isTrue);
    });

    test('equal versions are not greater', () {
      expect(AppVersion('1.2.3').isGreaterThan(AppVersion('1.2.3')), isFalse);
    });

    test('lower version reports not greater', () {
      expect(AppVersion('1.2.3').isGreaterThan(AppVersion('1.3.0')), isFalse);
    });

    test('extra trailing parts make the longer version greater', () {
      expect(AppVersion('1.0.0.1').isGreaterThan(AppVersion('1.0.0')), isTrue);
    });

    test('shorter version is not greater than longer with same prefix', () {
      // documents current behavior: the loop runs over the LHS parts only,
      // so it returns false when LHS exhausts without finding a difference.
      expect(AppVersion('1.0.0').isGreaterThan(AppVersion('1.0.0.1')), isFalse);
    });
  });
}
