import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/models/hud_notices_model.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository_impl.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';
import 'package:plan_sync/features/home/viewmodel/home_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../mock_controllers/app_tour_controller_mock.dart';
import '../mock_controllers/notification_controller_mock.dart';
import '../mock_controllers/remote_config_controller_mock.dart';

class _FakeRemoteConfigWithNotices extends MockRemoteConfigController {
  final List<HudNoticeModel> _notices;
  _FakeRemoteConfigWithNotices(this._notices);

  @override
  List<HudNoticeModel> getNotices() => _notices;
}

const _notice1 = HudNoticeModel(id: 1, title: 'Notice 1', description: 'Desc 1');
const _notice2 = HudNoticeModel(id: 2, title: 'Notice 2', description: 'Desc 2');

HomeViewModel _buildVm({
  required AppPreferencesRepositoryImpl preferences,
  RemoteConfigService? remoteConfig,
}) {
  return HomeViewModel(
    appTour: MockAppTourController(),
    appPreferences: preferences,
    remoteConfig: remoteConfig ?? MockRemoteConfigController(),
    notifications: MockNotificationService(),
  );
}

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppPreferencesRepositoryImpl preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferencesRepositoryImpl();
    await preferences.onInit();
  });

  group('notices loading', () {
    test('notices is empty when remoteConfig returns no notices', () {
      final vm = _buildVm(preferences: preferences);
      expect(vm.notices, isEmpty);
    });

    test('all notices shown when none have been dismissed', () {
      final vm = _buildVm(
        preferences: preferences,
        remoteConfig: _FakeRemoteConfigWithNotices([_notice1, _notice2]),
      );
      expect(vm.notices.length, 2);
    });

    test('dismissed notice is filtered out on construction', () async {
      await preferences.dismissNotice(_notice1.id);

      final vm = _buildVm(
        preferences: preferences,
        remoteConfig: _FakeRemoteConfigWithNotices([_notice1, _notice2]),
      );

      expect(vm.notices.length, 1);
      expect(vm.notices.first.id, _notice2.id);
    });
  });

  group('dismissNotice', () {
    test('removes notice from in-memory list', () {
      final vm = _buildVm(
        preferences: preferences,
        remoteConfig: _FakeRemoteConfigWithNotices([_notice1, _notice2]),
      );
      expect(vm.notices.length, 2);

      vm.dismissNotice(_notice1.id);

      expect(vm.notices.length, 1);
      expect(vm.notices.first.id, _notice2.id);
    });

    test('persists dismissal so notice is absent on next construction', () async {
      final vm = _buildVm(
        preferences: preferences,
        remoteConfig: _FakeRemoteConfigWithNotices([_notice1, _notice2]),
      );
      vm.dismissNotice(_notice1.id);

      final vm2 = _buildVm(
        preferences: preferences,
        remoteConfig: _FakeRemoteConfigWithNotices([_notice1, _notice2]),
      );
      expect(vm2.notices.length, 1);
      expect(vm2.notices.first.id, _notice2.id);
    });
  });

  group('shouldInitializeNotifications', () {
    test('returns false when tutorial has not been completed', () {
      final vm = _buildVm(preferences: preferences);
      expect(vm.shouldInitializeNotifications, isFalse);
    });

    test('returns true when tutorial is marked complete', () async {
      await preferences.saveTutorialStatus(true);
      final vm = _buildVm(preferences: preferences);
      expect(vm.shouldInitializeNotifications, isTrue);
    });
  });
}
