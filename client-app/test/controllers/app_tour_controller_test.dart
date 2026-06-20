import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository_impl.dart';
import 'package:plan_sync/core/services/app_tour_service.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppTourService controller;
  late AppPreferencesRepositoryImpl preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferencesRepositoryImpl();
    await preferences.onInit();
    controller = AppTourService();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      Provider<AppPreferencesRepository>.value(
        value: preferences,
        child: MaterialApp(
          home: Builder(builder: (ctx) {
            controller.onInit(ctx);
            return const Scaffold(body: SizedBox());
          }),
        ),
      ),
    );
  }

  testWidgets('onInit wires up keys and preferences', (tester) async {
    await pump(tester);
    expect(controller.schedulePreferencesButtonKey, isA<GlobalKey>());
    expect(controller.sectionBarKey, isA<GlobalKey>());
    expect(controller.savePreferenceSwitchKey, isA<GlobalKey>());
    expect(controller.doneButtonKey, isA<GlobalKey>());
  });

  testWidgets('tourAlreadyCompleted reads from preferences', (tester) async {
    await pump(tester);
    expect(await controller.tourAlreadyCompleted(), isFalse);

    await preferences.saveTutorialStatus(true);
    expect(await controller.tourAlreadyCompleted(), isTrue);
  });

  testWidgets('onTourComplete persists tutorial status', (tester) async {
    await pump(tester);
    expect(preferences.getTutorialStatus(), isNull);
    await controller.onTourComplete();
    expect(preferences.getTutorialStatus(), isTrue);
  });

  testWidgets('getTutorialTargets returns all four focus targets',
      (tester) async {
    await pump(tester);
    final ctx = tester.element(find.byType(Scaffold));
    final targets = controller.getTutorialTargets(ctx);
    expect(targets, hasLength(4));
  });
}
