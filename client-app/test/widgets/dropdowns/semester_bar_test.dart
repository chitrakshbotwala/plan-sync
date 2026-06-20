import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/schedule/view/widgets/semester_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

void main() {
  Future<void> pumpBaseWidget(
    WidgetTester tester,
  ) async {
    return tester.pumpWidget(
      testApp(
        child: const Scaffold(
          body: Center(
            child: SemesterBar(),
          ),
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
  });

  testWidgets('SemesterBar loads properly', (WidgetTester tester) async {
    // initial state
    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();
    expect(find.text('Semester'), findsOneWidget);

    // expect all options
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    expect(find.text('SEM1'), findsOneWidget);
    expect(find.text('SEM2'), findsOneWidget);
  });

  testWidgets('SemesterBar sets new value', (WidgetTester tester) async {
    final filterController = mockFilterViewModel;
    // initial state
    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();
    expect(find.text('Semester'), findsOneWidget);

    // tap on year
    await tester.tap(find.byIcon(Icons.arrow_drop_down));
    await tester.pumpAndSettle();
    await tester.tap(find.text('SEM2'));
    await tester.pumpAndSettle();

    // check if new value is updated
    // check if new value is updated
    expect(find.text("SEM2"), findsOneWidget);
    expect(filterController.activeSemester, "SEM2");
  });
}
