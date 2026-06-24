import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/electives/view/widgets/electives_scheme_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

void main() {
  Future<void> pumpBaseWidget(
    WidgetTester tester,
  ) async {
    return tester.pumpWidget(testApp(child: Scaffold(
        body: Center(
          child: ElectiveSchemeBar(),
        ),
      ),
    ));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
  });

  testWidgets(
    'ElectiveSchemeBar loads when no data',
    (WidgetTester tester) async {
      // initial state
      await pumpBaseWidget(tester);
      await tester.pumpAndSettle();
      expect(find.text('Select Semester First'), findsOneWidget);
    },
  );

  testWidgets(
    'ElectiveSchemeBar loads when data is availble but not selected',
    (WidgetTester tester) async {
      final filterController = mockFilterViewModel;

      filterController.activeElectiveSemester = "SEM1";
      filterController.electiveSchemes = {
        "a": "Scheme A",
        "b": "Scheme B",
      };

      // initial state
      await pumpBaseWidget(tester);
      await tester.pumpAndSettle();
      expect(find.text('Scheme'), findsOneWidget);
    },
  );

  testWidgets(
    'ElectiveSchemeBar updates data when clicked on item',
    (WidgetTester tester) async {
      final filterController = mockFilterViewModel;

      filterController.activeElectiveSemester = "SEM1";
      filterController.electiveSchemes = {
        "a": "Scheme A",
        "b": "Scheme B",
      };

      // initial state
      await pumpBaseWidget(tester);
      await tester.pumpAndSettle();
      expect(find.text('Scheme'), findsOneWidget);

      // enabled state with dropdown items
      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      // check if supplied data is found
      expect(find.byType(DropdownMenuItem<String>), findsExactly(2));

      await tester.tap(find.text("Scheme A"));
      await tester.pumpAndSettle();

      // check if controller value updates
      expect(filterController.activeElectiveScheme, "Scheme A");
    },
  );
}
