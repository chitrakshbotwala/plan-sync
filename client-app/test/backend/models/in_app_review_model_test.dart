import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/backend/models/in_app_review_model.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/controllers/version_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    late VersionController version;
    late AppPreferencesController preferences;

    setUp(() async {
      SharedPreferences.setMockInitialValues({});
      preferences = AppPreferencesController();
      await preferences.onInit();
      version = VersionController();
      version.clientVersion = '4.1.3';
    });

    Future<bool> evaluate(
      WidgetTester tester,
      InAppReviewCacheModel model,
    ) async {
      late bool result;
      await tester.pumpWidget(
        MultiProvider(
          providers: [
            ChangeNotifierProvider<VersionController>.value(value: version),
            ChangeNotifierProvider<AppPreferencesController>.value(
              value: preferences,
            ),
          ],
          child: MaterialApp(
            home: Builder(
              builder: (ctx) {
                // ignore: discarded_futures
                model.shouldRequestReview(ctx).then((v) => result = v);
                return const SizedBox();
              },
            ),
          ),
        ),
      );
      await tester.pumpAndSettle();
      return result;
    }

    testWidgets(
      'first-open: returns false when less than 7 days have elapsed',
      (tester) async {
        final model = InAppReviewCacheModel(
          firstOpen: DateTime.now()
              .subtract(const Duration(days: 3))
              .millisecondsSinceEpoch,
        );

        expect(await evaluate(tester, model), isFalse);
        // first-time path must not record a request when conditions are unmet
        expect(model.lastRequested, isNull);
      },
    );

    testWidgets(
      'first-open: returns true after 7 days and stamps lastRequested',
      (tester) async {
        final model = InAppReviewCacheModel(
          firstOpen: DateTime.now()
              .subtract(const Duration(days: 8))
              .millisecondsSinceEpoch,
        );

        expect(await evaluate(tester, model), isTrue);
        expect(model.lastRequested, isNotNull);
        expect(model.lastAppVersion, '4.1.3');
      },
    );

    testWidgets(
      'follow-up: skips when last request was within 30 days',
      (tester) async {
        final model = InAppReviewCacheModel(
          firstOpen: DateTime.now()
              .subtract(const Duration(days: 60))
              .millisecondsSinceEpoch,
          lastRequested: DateTime.now()
              .subtract(const Duration(days: 10))
              .millisecondsSinceEpoch,
          lastAppVersion: '4.1.3',
        );

        expect(await evaluate(tester, model), isFalse);
      },
    );

    testWidgets(
      'follow-up: requests again after 30 days',
      (tester) async {
        final earlier = DateTime.now()
            .subtract(const Duration(days: 40))
            .millisecondsSinceEpoch;
        final model = InAppReviewCacheModel(
          firstOpen: earlier,
          lastRequested: earlier,
          lastAppVersion: '4.1.3',
        );

        expect(await evaluate(tester, model), isTrue);
        expect(model.lastRequested, greaterThan(earlier));
      },
    );

    testWidgets(
      'version bump unblocks a previously-suppressed window',
      (tester) async {
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

        expect(await evaluate(tester, model), isTrue);
        // updateLastRequested ran and stamped the new app version
        expect(model.lastAppVersion, '5.0.0');
        expect(model.lastRequested, isNotNull);
      },
    );
  });
}
