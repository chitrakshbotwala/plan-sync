import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/electives/view/widgets/elective_year_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

void main() {
  Future<void> pumpBaseWidget(WidgetTester tester) async {
    return tester.pumpWidget(testApp(
      child: const Scaffold(body: Center(child: ElectiveYearBar())),
    ));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
  });

  testWidgets(
    'ElectiveYearBar loads when data is available but not selected',
    (WidgetTester tester) async {
      await pumpBaseWidget(tester);
      await tester.pumpAndSettle();
      expect(find.text('Year'), findsOneWidget);
    },
  );

  testWidgets(
    'ElectiveYearBar updates data when clicked on item',
    (WidgetTester tester) async {
      final filterController = mockFilterViewModel;

      filterController.electiveYears = ['2024', '2023'];
      filterController.selectedElectiveYear = null;

      await pumpBaseWidget(tester);
      await tester.pumpAndSettle();
      expect(find.text('Year'), findsOneWidget);

      await tester.tap(find.byIcon(Icons.arrow_drop_down));
      await tester.pumpAndSettle();

      expect(find.byType(DropdownMenuItem<String>), findsExactly(2));

      await tester.tap(find.text('2024'));
      await tester.pumpAndSettle();

      expect(filterController.selectedElectiveYear, '2024');
    },
  );
}
