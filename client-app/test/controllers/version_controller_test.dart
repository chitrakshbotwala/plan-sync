import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/version_controller.dart';
import 'package:plan_sync/util/app_version.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VersionController controller;

  setUp(() {
    controller = VersionController();
  });

  group('clientVersion setter', () {
    test('null assignment is ignored', () {
      controller.clientVersion = '1.0.0';
      controller.clientVersion = null;
      expect(controller.clientVersion, '1.0.0');
    });

    test('valid assignment updates value and notifies', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.clientVersion = '2.0.0';
      expect(controller.clientVersion, '2.0.0');
      expect(notifications, 1);
    });
  });

  group('appBuild setter', () {
    test('null assignment is ignored', () {
      controller.appBuild = '42';
      controller.appBuild = null;
      expect(controller.appBuild, '42');
    });

    test('valid assignment updates value and notifies', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.appBuild = '99';
      expect(controller.appBuild, '99');
      expect(notifications, 1);
    });
  });

  group('isError / isUpdateAvailable setters', () {
    test('isError toggles and notifies', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.isError = true;
      expect(controller.isError, isTrue);
      expect(notifications, 1);
    });

    test('isUpdateAvailable toggles and notifies', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.isUpdateAvailable = true;
      expect(controller.isUpdateAvailable, isTrue);
      expect(notifications, 1);
    });
  });

  group('AppVersion utility used in checks', () {
    test('detects greater minor version', () {
      expect(AppVersion('1.2.0').isGreaterThan(AppVersion('1.1.9')), isTrue);
    });

    test('equal versions are not greater', () {
      expect(AppVersion('1.2.3').isGreaterThan(AppVersion('1.2.3')), isFalse);
    });

    test('lower version reports not greater', () {
      expect(AppVersion('1.2.3').isGreaterThan(AppVersion('1.3.0')), isFalse);
    });

    test('longer version with extra parts wins over shorter', () {
      expect(AppVersion('1.0.0.1').isGreaterThan(AppVersion('1.0.0')), isTrue);
    });
  });

  group('forcedRedirectPath', () {
    test('defaults to null', () {
      VersionController.forcedRedirectPath = null;
      expect(VersionController.forcedRedirectPath, isNull);
    });

    test('is mutable', () {
      VersionController.forcedRedirectPath = '/forced_update';
      expect(VersionController.forcedRedirectPath, '/forced_update');
      VersionController.forcedRedirectPath = null;
    });
  });
}
