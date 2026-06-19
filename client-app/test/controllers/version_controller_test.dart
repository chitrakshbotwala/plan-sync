import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository_impl.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/core/services/version_service.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../mock_controllers/remote_config_controller_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late VersionViewModel viewModel;
  late VersionService versionService;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    final prefs = AppPreferencesRepositoryImpl();
    await prefs.onInit();
    versionService = VersionService(apiClient: ApiClient());
    viewModel = VersionViewModel(
      versionService: versionService,
      remoteConfig: MockRemoteConfigController(),
      preferences: prefs,
    );
  });

  group('clientVersion setter', () {
    test('valid assignment updates value and notifies', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      viewModel.clientVersion = '2.0.0';
      expect(viewModel.clientVersion, '2.0.0');
      expect(notifications, 1);
    });

    test('null assignment is dropped and does not notify', () {
      viewModel.clientVersion = '1.0.0';
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      viewModel.clientVersion = null;
      expect(viewModel.clientVersion, '1.0.0');
      expect(notifications, 0);
    });
  });

  group('appBuild setter', () {
    test('valid assignment updates value and notifies', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      viewModel.appBuild = '99';
      expect(viewModel.appBuild, '99');
      expect(notifications, 1);
    });

    test('null assignment is dropped and does not notify', () {
      viewModel.appBuild = '42';
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      viewModel.appBuild = null;
      expect(viewModel.appBuild, '42');
      expect(notifications, 0);
    });
  });

  group('plain boolean setters notify', () {
    test('isError', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      viewModel.isError = true;
      expect(viewModel.isError, isTrue);
      expect(notifications, 1);
    });

    test('isUpdateAvailable', () {
      var notifications = 0;
      viewModel.addListener(() => notifications++);
      viewModel.isUpdateAvailable = true;
      expect(viewModel.isUpdateAvailable, isTrue);
      expect(notifications, 1);
    });
  });

  group('immediateUpdateCondition', () {
    test('returns true when the available version code is >5 ahead', () {
      final info = _fakeUpdateInfo(availableVersionCode: 106);
      expect(versionService.immediateUpdateCondition(info, '100'), isTrue);
    });

    test('returns false at the boundary (difference == 5)', () {
      final info = _fakeUpdateInfo(availableVersionCode: 105);
      expect(versionService.immediateUpdateCondition(info, '100'), isFalse);
    });

    test('returns false when current build is already ahead', () {
      final info = _fakeUpdateInfo(availableVersionCode: 100);
      expect(versionService.immediateUpdateCondition(info, '120'), isFalse);
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
