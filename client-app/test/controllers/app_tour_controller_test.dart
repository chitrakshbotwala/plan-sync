import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/app_preferences_controller.dart';
import 'package:plan_sync/controllers/app_tour_controller.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  late AppTourController controller;
  late AppPreferencesController preferences;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    preferences = AppPreferencesController();
    await preferences.onInit();
    controller = AppTourController();
  });

  Future<void> pump(WidgetTester tester) async {
    await tester.pumpWidget(
      ChangeNotifierProvider<AppPreferencesController>.value(
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
    expect(controller.appPreferencesController, same(preferences));
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
