import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/backend/models/in_app_review_model.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/core/services/app_review_service.dart';
import 'package:plan_sync/core/services/version_service.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../mock_controllers/remote_config_controller_mock.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('InAppReviewCacheModel JSON round-trip', () {
    test('toJson then fromJson recovers all fields', () {
      final original = InAppReviewCacheModel(
        firstOpen: 1700000000000,
        lastRequested: 1700500000000,
        lastAppVersion: '4.1.3',
      );

      final restored = InAppReviewCacheModel.fromJson(original.toJson());

      expect(restored.firstOpen, original.firstOpen);
      expect(restored.lastRequested, original.lastRequested);
      expect(restored.lastAppVersion, original.lastAppVersion);
    });

    test('fromJson tolerates missing optional fields', () {
      final restored = InAppReviewCacheModel.fromJson({
        'firstOpen': 1700000000000,
      });

      expect(restored.firstOpen, 1700000000000);
      expect(restored.lastRequested, isNull);
      expect(restored.lastAppVersion, isNull);
    });
  });

  group('shouldRequestReview', () {
    late AppReviewService service;
    late VersionViewModel version;
    late AppPreferencesController preferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = AppPreferencesController();
      await preferences.onInit();
      version = VersionViewModel(
        versionService: VersionService(apiClient: ApiClient()),
        remoteConfig: MockRemoteConfigController(),
        preferences: preferences,
      );
      version.clientVersion = '4.1.3';
      service = AppReviewService(preferences: preferences, version: version);
    });

    test(
      'first-open: returns false when less than 7 days have elapsed',
      () {
        final model = InAppReviewCacheModel(
          firstOpen: DateTime.now()
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch,
        );

        expect(service.shouldRequestReview(model), isFalse);
        expect(model.lastRequested, isNull);
      },
    );

    test(
      'first-open: returns true after 7 days and stamps lastRequested',
      () {
        final model = InAppReviewCacheModel(
          firstOpen: DateTime.now()
              .subtract(const Duration(days: 8))
              .millisecondsSinceEpoch,
        );

        expect(service.shouldRequestReview(model), isTrue);
        expect(model.lastRequested, isNotNull);
        expect(model.lastAppVersion, '4.1.3');
      },
    );

    test(
      'follow-up: skips when last request was within 30 days',
      () {
        final model = InAppReviewCacheModel(
          firstOpen: DateTime.now()
              .subtract(const Duration(days: 60))
              .millisecondsSinceEpoch,
          lastRequested: DateTime.now()
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
          lastAppVersion: '4.1.3',
        );

        expect(service.shouldRequestReview(model), isFalse);
      },
    );

    test(
      'follow-up: requests again after 30 days',
      () {
        final earlier = DateTime.now()
            .subtract(const Duration(days: 40))
            .millisecondsSinceEpoch;
        final model = InAppReviewCacheModel(
          firstOpen: earlier,
          lastRequested: earlier,
          lastAppVersion: '4.1.3',
        );

        expect(service.shouldRequestReview(model), isTrue);
        expect(model.lastRequested, greaterThan(earlier));
      },
    );

    test(
      'version bump unblocks a previously-suppressed window',
      () {
        // Last request was recent (would normally suppress), but the app
        // version has changed — the model clears lastRequested so the
        // first-open path runs again. firstOpenDate is captured before the
        // version-bump branch resets firstOpen, so the original 9-day-old
        // value is what gets checked against the 7-day threshold.
        version.clientVersion = '5.0.0';
        final model = InAppReviewCacheModel(
          firstOpen: DateTime.now()
              .subtract(const Duration(days: 9))
              .millisecondsSinceEpoch,
          lastRequested: DateTime.now()
              .subtract(const Duration(days: 1))
              .millisecondsSinceEpoch,
          lastAppVersion: '4.1.3',
        );

        expect(service.shouldRequestReview(model), isTrue);
        expect(model.lastAppVersion, '5.0.0');
        expect(model.lastRequested, isNotNull);
      },
    );
  });
}
