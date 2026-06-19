import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plan_sync/controllers/version_controller.dart';
import 'package:plan_sync/core/services/api_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VersionController controller;

  setUp(() {
    controller = VersionController(apiClient: ApiClient());
  });

  group('clientVersion setter', () {
    test('valid assignment updates value and notifies', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.clientVersion = '2.0.0';
      expect(controller.clientVersion, '2.0.0');
      expect(notifications, 1);
    });

    test('null assignment is dropped and does not notify', () {
      controller.clientVersion = '1.0.0';
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.clientVersion = null;
      expect(controller.clientVersion, '1.0.0');
      expect(notifications, 0);
    });
  });

  group('appBuild setter', () {
    test('valid assignment updates value and notifies', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.appBuild = '99';
      expect(controller.appBuild, '99');
      expect(notifications, 1);
    });

    test('null assignment is dropped and does not notify', () {
      controller.appBuild = '42';
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.appBuild = null;
      expect(controller.appBuild, '42');
      expect(notifications, 0);
    });
  });

  group('plain boolean setters notify', () {
    test('isError', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.isError = true;
      expect(controller.isError, isTrue);
      expect(notifications, 1);
    });

    test('isUpdateAvailable', () {
      var notifications = 0;
      controller.addListener(() => notifications++);
      controller.isUpdateAvailable = true;
      expect(controller.isUpdateAvailable, isTrue);
      expect(notifications, 1);
    });
  });

  group('immediateUpdateCondition', () {
    // PackageInfo.fromPlatform() can't run in widget tests, so we seed
    // controller.packageInfo directly. The real onReady path populates
    // this from the platform channel.
    void seedBuildNumber(String buildNumber) {
      controller.packageInfo = PackageInfo(
        appName: 'plan_sync',
        packageName: 'com.example.plan_sync',
        version: '4.1.3',
        buildNumber: buildNumber,
      );
    }

    test('returns true when the available version code is >5 ahead', () {
      seedBuildNumber('100');
      final info = _fakeUpdateInfo(availableVersionCode: 106);
      expect(controller.immediateUpdateCondition(info), isTrue);
    });

    test('returns false at the boundary (difference == 5)', () {
      seedBuildNumber('100');
      final info = _fakeUpdateInfo(availableVersionCode: 105);
      expect(controller.immediateUpdateCondition(info), isFalse);
    });

    test('returns false when current build is already ahead', () {
      seedBuildNumber('120');
      final info = _fakeUpdateInfo(availableVersionCode: 100);
      expect(controller.immediateUpdateCondition(info), isFalse);
    });
  });
}

AppUpdateInfo _fakeUpdateInfo({required int availableVersionCode}) {
  return AppUpdateInfo(
    updateAvailability: UpdateAvailability.updateAvailable,
    immediateUpdateAllowed: true,
    immediateAllowedPreconditions: const [],
    flexibleUpdateAllowed: false,
    flexibleAllowedPreconditions: const [],
    availableVersionCode: availableVersionCode,
    installStatus: InstallStatus.unknown,
    packageName: 'plan_sync',
    clientVersionStalenessDays: 0,
    updatePriority: 0,
  );
}
