import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/home/view/home_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

void main() {
  Future<void> pumpTutorialWidget(WidgetTester tester) async {
    await tester.pumpFrames(
      testApp(child: const HomeScreen()),
      const Duration(seconds: 3),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({
      'app-tutorial-status': true,
    });
    await injectMockDependencies();
  });

  testWidgets(
    'Tutorial doesn\'t starts if already completed',
    (WidgetTester tester) async {
      await pumpTutorialWidget(tester);

      expect(find.text('Select your section here'), findsNothing);
      expect(find.text('SKIP'), findsNothing);
    },
  );

  testWidgets(
    'Tutorial stops when skip button is pressed',
    (WidgetTester tester) async {
      final perfs = mockPreferences;
      perfs.saveTutorialStatus(false);

      await pumpTutorialWidget(tester);

      expect(find.text('Select your section here'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);

      // press skip button
      await tester.tapAt(tester.getCenter(find.text("SKIP")));
      await pumpTutorialWidget(tester);

      expect(find.text('Select your section here'), findsNothing);
      expect(find.text('SKIP'), findsNothing);
    },
  );

  testWidgets(
    'Tutorial starts if user has not completed',
    (WidgetTester tester) async {
      final perfs = mockPreferences;

      await perfs.resetPreferencesToNull();

      // using pumpFrames as the tutorial has infinite
      // animation which leads to pumpAndSettle to
      // run infinitely.

      await pumpTutorialWidget(tester);

      // see if animation starts
      expect(find.text('Select your section here'), findsOneWidget);
      expect(find.text('SKIP'), findsOneWidget);
    },
  );
}
