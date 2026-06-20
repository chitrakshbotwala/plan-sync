import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/electives/view/widgets/elective_preference.dart';
import 'package:plan_sync/features/electives/view/widgets/elective_year_bar.dart';
import 'package:plan_sync/features/electives/view/widgets/electives_scheme_bar.dart';
import 'package:plan_sync/features/electives/view/widgets/electives_sem_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

void main() {
  Future<void> pumpBaseWidget(
    WidgetTester tester,
  ) async {
    final router = GoRouter(
      navigatorKey: GlobalKey<NavigatorState>(),
      initialLocation: '/home',
      routes: [
        GoRoute(
          path: '/',
          routes: [
            GoRoute(
              path: 'home',
              builder: (context, state) => const Scaffold(
                body: Center(
                  child: ElectivePreferenceBottomSheet(),
                ),
              ),
            )
          ],
          builder: (context, state) => const Scaffold(
              body: SizedBox.expand(
            child: ColoredBox(color: Colors.red),
          )),
        )
      ],
    );
    return tester.pumpWidget(
      wrapWithProviders(
        child: MaterialApp.router(
          theme: ThemeService.lightTheme,
          routeInformationParser: router.routeInformationParser,
          routeInformationProvider: router.routeInformationProvider,
          routerDelegate: router.routerDelegate,
        ),
      ),
    );
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
  });
  testWidgets('ElectivePreferenceBottomSheet switch toggles when clicked',
      (WidgetTester tester) async {
    await pumpBaseWidget(tester);
    final ElectivePreferenceBottomSheetState widgetState = tester.state(
      find.byType(ElectivePreferenceBottomSheet),
    );

    await tester.pump();
    expect(widgetState.savePreferencesOnExit, false);

    await tester.tap(find.byType(Switch));
    await tester.pump();
    expect(widgetState.savePreferencesOnExit, true);
  });

  testWidgets('ElectivePreferenceBottomSheet opens yearbar',
      (WidgetTester tester) async {
    final filterController = mockFilterViewModel;

    await pumpBaseWidget(tester);

    await tester.pump();
    await tester.tap(find.byType(ElectiveYearBar));
    await tester.pumpAndSettle();

    expect(find.text('2024'), findsOneWidget);
    expect(find.text('2023'), findsOneWidget);
    expect(find.text('2022'), findsOneWidget);

    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();

    expect(filterController.selectedElectiveYear, '2024');
  });

  testWidgets('ElectivePreferenceBottomSheet opens SemestersBar',
      (WidgetTester tester) async {
    final filterController = mockFilterViewModel;

    await pumpBaseWidget(tester);

    await tester.pump();
    await tester.tap(find.byType(ElectiveSemesterBar));
    await tester.pumpAndSettle();

    expect(find.text('SEM1'), findsOneWidget);
    expect(find.text('SEM2'), findsOneWidget);
    await tester.tap(find.text('SEM1'));
    await tester.pumpAndSettle();

    expect(filterController.activeElectiveSemester, 'SEM1');
  });

  testWidgets('ElectivePreferenceBottomSheet opens SectionBar',
      (WidgetTester tester) async {
    final filterController = mockFilterViewModel;

    filterController.electiveSchemes = {
      "a": "Scheme A",
      "b": "Scheme B",
    };
    // ElectiveSchemeBar is disabled until an elective semester is selected.
    filterController.activeElectiveSemester = 'SEM1';

    await pumpBaseWidget(tester);
    await tester.pump();

    await tester.tap(find.byType(ElectiveSchemeBar));
    await tester.pumpAndSettle();

    // ensure 3 items are visible
    expect(find.text('Scheme A'), findsOneWidget);
    expect(find.text('Scheme B'), findsOneWidget);

    await tester.tap(find.text('Scheme B'));
    await tester.pumpAndSettle();

    // ensure controller field is updated
    expect(filterController.activeElectiveScheme, 'Scheme B');
  });

  testWidgets(
      'ElectivePreferenceBottomSheet does not save config to SharedPreferences',
      (WidgetTester tester) async {
    final perfs = mockPreferences;
    final filterController = mockFilterViewModel;

    // reset existing SharedPreferences data from previous test
    perfs.resetPreferencesToNull();

    filterController.selectedElectiveYear = '2024';
    filterController.electiveSchemes = {
      "a": "Scheme A",
      "b": "Scheme B",
    };
    filterController.activeElectiveSemester = 'SEM1';
    filterController.activeElectiveScheme = 'Scheme B';
    filterController.activeElectiveSchemeCode = 'b';

    // pump widget with above config
    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    final ElectivePreferenceBottomSheetState widgetState = tester.state(
      find.byType(ElectivePreferenceBottomSheet),
    );

    // test controller mutation
    expect(widgetState.savePreferencesOnExit, false);
    expect(filterController.activeElectiveSemester, 'SEM1');
    expect(filterController.activeElectiveScheme, 'Scheme B');
    expect(filterController.activeElectiveSchemeCode, 'b');
    expect(filterController.selectedElectiveYear, '2024');

    // verify existing perfs
    expect(perfs.getPrimaryElectiveSchemePreference(), isNull);
    expect(perfs.getPrimaryElectiveSemesterPreference(), isNull);
    expect(perfs.getPrimaryElectiveYearPreference(), isNull);

    // save
    await tester.tap(find.text('Done'));
    await pumpBaseWidget(tester);

    // verify post saving perfs
    expect(perfs.getPrimaryElectiveSchemePreference(), isNull);
    expect(perfs.getPrimaryElectiveSemesterPreference(), isNull);
    expect(perfs.getPrimaryElectiveYearPreference(), isNull);
  });

  testWidgets('ElectivePreferenceBottomSheet saves config to SharedPreferences',
      (WidgetTester tester) async {
    final perfs = mockPreferences;
    final filterController = mockFilterViewModel;

    // reset existing SharedPreferences data from previous test
    perfs.resetPreferencesToNull();

    filterController.selectedElectiveYear = '2024';
    filterController.electiveSchemes = {
      "a": "Scheme A",
      "b": "Scheme B",
    };
    filterController.activeElectiveSemester = 'SEM1';
    filterController.activeElectiveScheme = 'Scheme B';
    filterController.activeElectiveSchemeCode = 'b';

    // pump widget with above config
    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    final ElectivePreferenceBottomSheetState widgetState = tester.state(
      find.byType(ElectivePreferenceBottomSheet),
    );

    widgetState.savePreferencesOnExit = true;

    // test controller mutation
    expect(widgetState.savePreferencesOnExit, true);
    expect(filterController.activeElectiveSemester, 'SEM1');
    expect(filterController.activeElectiveScheme, 'Scheme B');
    expect(filterController.activeElectiveSchemeCode, 'b');
    expect(filterController.selectedElectiveYear, '2024');

    // verify existing perfs
    expect(perfs.getPrimaryElectiveSchemePreference(), isNull);
    expect(perfs.getPrimaryElectiveSemesterPreference(), isNull);
    expect(perfs.getPrimaryElectiveYearPreference(), isNull);

    // save
    await tester.tap(find.text('Done'));
    // Toast from exitBottomSheet auto-closes after 5s; pump past it
    // so no toastification timers are left pending at teardown.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    // verify post saving perfs
    expect(perfs.getPrimaryElectiveSchemePreference(), 'b');
    expect(perfs.getPrimaryElectiveSemesterPreference(), 'SEM1');
    expect(perfs.getPrimaryElectiveYearPreference(), '2024');
  });
}
