import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/schedule/view/widgets/schedule_preference.dart';
import 'package:plan_sync/features/schedule/view/widgets/sections_bar.dart';
import 'package:plan_sync/features/schedule/view/widgets/semester_bar.dart';
import 'package:plan_sync/features/schedule/view/widgets/year_bar.dart';
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
                  child: SchedulePreferenceDialog(),
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

  testWidgets('SchedulePreferenceDialog opens yearbar',
      (WidgetTester tester) async {
    final filterController = mockFilterViewModel;

    await pumpBaseWidget(tester);

    await tester.pump();
    await tester.tap(find.byType(YearBar));
    await tester.pumpAndSettle();

    expect(find.text('2024'), findsOneWidget);
    expect(find.text('2023'), findsOneWidget);
    expect(find.text('2022'), findsOneWidget);

    await tester.tap(find.text('2024'));
    await tester.pumpAndSettle();

    expect(filterController.selectedYear, '2024');
  });

  testWidgets('SchedulePreferenceDialog opens SemestersBar',
      (WidgetTester tester) async {
    final filterController = mockFilterViewModel;

    // Pre-seed sections so the SectionsBar does not flip to its
    // loading state (which spins an infinite animation) once a
    // semester is selected — pumpAndSettle would otherwise time out.
    filterController.sections = {
      "b13": "B13 CSE",
    };

    await pumpBaseWidget(tester);

    await tester.pump();
    await tester.tap(find.byType(SemesterBar));
    await tester.pumpAndSettle();

    expect(find.text('SEM1'), findsOneWidget);
    expect(find.text('SEM2'), findsOneWidget);
    await tester.tap(find.text('SEM1'));
    await tester.pumpAndSettle();

    expect(filterController.activeSemester, 'SEM1');
  });

  testWidgets('SchedulePreferenceDialog opens SectionBar',
      (WidgetTester tester) async {
    final filterController = mockFilterViewModel;

    filterController.sections = {
      "b13": "B13 CSE",
      "b16": "B16 CSE",
      "b18": "B18 CSE",
    };
    // SectionsBar is disabled until a semester is selected.
    filterController.activeSemester = 'SEM1';

    await pumpBaseWidget(tester);
    await tester.pump();

    await tester.tap(find.byType(SectionsBar));
    await tester.pumpAndSettle();

    expect(find.textContaining('B13'), findsOneWidget);
    expect(find.textContaining('B16'), findsOneWidget);
    expect(find.textContaining('B18'), findsOneWidget);

    await tester.tap(find.textContaining('B13'));
    await tester.pumpAndSettle();

    expect(filterController.activeSection, 'B13 CSE');
  });

  testWidgets('Done saves config to SharedPreferences',
      (WidgetTester tester) async {
    final perfs = mockPreferences;
    final filterController = mockFilterViewModel;

    filterController.sections = {
      "b13": "B13 CSE",
      "b16": "B16 CSE",
      "b18": "B18 CSE",
    };
    filterController.selectedYear = '2023';
    filterController.activeSection = 'B18 CSE';
    filterController.activeSectionCode = 'b18';
    filterController.activeSemester = 'SEM2';

    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    expect(filterController.activeSection, 'B18 CSE');
    expect(filterController.activeSectionCode, 'b18');
    expect(filterController.activeSemester, 'SEM2');
    expect(filterController.selectedYear, '2023');

    expect(perfs.getPrimarySectionPreference(), isNull);
    expect(perfs.getPrimarySemesterPreference(), isNull);
    expect(perfs.getPrimaryYearPreference(), isNull);

    await tester.tap(find.text('Done'));
    // Snackbar auto-closes after 5s; pump past it so no timers remain.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();

    expect(perfs.getPrimarySectionPreference(), 'b18');
    expect(perfs.getPrimarySemesterPreference(), 'SEM2');
    expect(perfs.getPrimaryYearPreference(), '2023');
  });

  testWidgets('Cancel does not save config to SharedPreferences',
      (WidgetTester tester) async {
    final perfs = mockPreferences;
    final filterController = mockFilterViewModel;

    perfs.resetPreferencesToNull();

    filterController.sections = {
      "b13": "B13 CSE",
      "b16": "B16 CSE",
      "b18": "B18 CSE",
    };
    filterController.selectedYear = '2023';
    filterController.activeSection = 'B18 CSE';
    filterController.activeSectionCode = 'b18';
    filterController.activeSemester = 'SEM2';

    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    expect(perfs.getPrimarySectionPreference(), isNull);
    expect(perfs.getPrimarySemesterPreference(), isNull);
    expect(perfs.getPrimaryYearPreference(), isNull);

    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(perfs.getPrimarySectionPreference(), isNull);
    expect(perfs.getPrimarySemesterPreference(), isNull);
    expect(perfs.getPrimaryYearPreference(), isNull);
  });
}
