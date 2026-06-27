import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/util/enums.dart';
import 'package:plan_sync/features/home/view/home_screen.dart';
import 'package:plan_sync/features/home/view/widgets/date_widget.dart';
import 'package:plan_sync/features/home/view/widgets/schedule_preferences_button.dart';
import 'package:plan_sync/features/schedule/view/widgets/sections_bar.dart';
import 'package:plan_sync/features/schedule/view/widgets/semester_bar.dart';
import 'package:plan_sync/features/schedule/view/widgets/year_bar.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../mock_controllers/electives_repository_mock.dart';
import '../mock_controllers/schedule_repository_mock.dart';

/// Full end-to-end flow through the real provider tree:
/// HomeScreen -> open preferences dialog -> drive Year/Semester/Section +
/// elective dropdowns -> tap Done -> assert the timetable renders with the
/// chosen elective substituted in place of the "Electives" placeholder.
///
/// Repositories are mocked (no network); everything above them
/// (FilterViewModel, ScheduleViewModel, ElectivesViewModel, the widgets) is
/// the real implementation wired by [testApp]/[injectMockDependencies].
void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();

    mockScheduleRepository.stage = MockScheduleRepositoryStage.success;
    mockElectivesRepository.stage = MockElectivesRepositoryStage.success;

    // Mark the tutorial complete so HomeScreen.initState doesn't launch the
    // app-tour overlay (MockNotificationService already declines permission,
    // so no notification dialog appears either).
    await mockPreferences.saveTutorialStatus(true);

    // Render the day the mock schedule + electives both have data for.
    mockFilterViewModel.weekday = Weekday.monday;

    // Sections the dialog's SectionsBar reads (the mock leaves this null).
    mockFilterViewModel.sections = {'A16': 'A-16', 'B16': 'B-16'};

    // Scheme code is auto-derived from the section by the real FilterViewModel;
    // the mock has no auto-derivation, so set it directly. This lets the
    // ElectivesViewModel load once year + semester are chosen.
    mockFilterViewModel.activeElectiveSchemeCode = 'a';
  });

  Future<void> pumpHome(WidgetTester tester) async {
    await tester.pumpWidget(testApp(child: const HomeScreen()));
    await tester.pumpAndSettle();
  }

  /// Opens a closed dropdown [bar] and taps the menu entry labelled [option].
  Future<void> pickFromBar(
    WidgetTester tester,
    Finder bar,
    String option,
  ) async {
    await tester.tap(bar);
    await tester.pumpAndSettle();
    // The label also exists on the (now-closed) button after selection, so
    // target the overlay menu entry with `.last`.
    await tester.tap(find.text(option).last);
    await tester.pumpAndSettle();
  }

  /// Opens the preferences dialog and selects year -> semester -> section.
  Future<void> selectScheduleFilters(WidgetTester tester) async {
    await tester.tap(find.byType(SchedulePreferenceButton));
    await tester.pumpAndSettle();
    expect(find.text('Preferences'), findsOneWidget);

    await pickFromBar(tester, find.byType(YearBar), '2024');
    await pickFromBar(tester, find.byType(SemesterBar), 'SEM1');
    await pickFromBar(tester, find.byType(SectionsBar), 'A-16');
  }

  Future<void> tapDone(WidgetTester tester) async {
    await tester.tap(find.text('Done'));
    // Confirmation snackbar auto-closes after 5s; pump past it so no timers
    // remain pending, then settle the close animation.
    await tester.pump(const Duration(seconds: 6));
    await tester.pumpAndSettle();
  }

  testWidgets(
      'full flow: select filters + elective renders substituted timetable',
      (WidgetTester tester) async {
    await pumpHome(tester);

    // Nothing selected yet.
    expect(find.text('No section selected.'), findsOneWidget);

    await selectScheduleFilters(tester);

    // Electives loaded once year + semester were chosen; the dialog now shows
    // the elective dropdowns. Pick "Machine Learning" for Elective 1.
    final electiveDropdowns = find.byType(DropdownButton<String?>);
    expect(electiveDropdowns, findsWidgets);
    await tester.tap(electiveDropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Machine Learning').last);
    await tester.pumpAndSettle();

    await tapDone(tester);

    // Monday: the "Electives" placeholder is replaced by the chosen elective.
    expect(find.text('No section selected.'), findsNothing);
    expect(find.text('Monday', skipOffstage: false), findsOneWidget);
    expect(find.text('Machine Learning', skipOffstage: false), findsOneWidget);
    expect(find.text('Electives', skipOffstage: false), findsNothing);
  });

  testWidgets('selecting filters without an elective shows the raw placeholder',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await selectScheduleFilters(tester);
    await tapDone(tester);

    // No elective chosen -> placeholder stays, no substitution.
    expect(find.text('Monday', skipOffstage: false), findsOneWidget);
    expect(find.text('Electives', skipOffstage: false), findsOneWidget);
    expect(find.text('Machine Learning', skipOffstage: false), findsNothing);
  });

  testWidgets('schedule-updating state surfaces the working-on-it notice',
      (WidgetTester tester) async {
    mockScheduleRepository.stage = MockScheduleRepositoryStage.scheduleUpdating;

    await pumpHome(tester);
    await selectScheduleFilters(tester);
    await tapDone(tester);

    expect(
      find.text("We're working on this timetable,", skipOffstage: false),
      findsOneWidget,
    );
    expect(find.text('Monday', skipOffstage: false), findsNothing);
  });

  testWidgets('repository error surfaces the error UI end-to-end',
      (WidgetTester tester) async {
    mockScheduleRepository.stage = MockScheduleRepositoryStage.noInternet;

    await pumpHome(tester);
    await selectScheduleFilters(tester);
    await tapDone(tester);

    // ScheduleViewModel.onError -> TimeTableWidget error branch.
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(
      find.text(
        'A status report has been sent, this issue will be looked into.',
        skipOffstage: false,
      ),
      findsOneWidget,
    );
    expect(find.text('Monday', skipOffstage: false), findsNothing);
  });

  testWidgets('clearing preferences reverts to the empty state',
      (WidgetTester tester) async {
    await pumpHome(tester);

    // Select a schedule, confirm it renders.
    await selectScheduleFilters(tester);
    await tapDone(tester);
    expect(find.text('Monday', skipOffstage: false), findsOneWidget);
    expect(find.text('No section selected.'), findsNothing);

    // Reopen the dialog and tap the clear-preferences (delete) button.
    await tester.tap(find.byType(SchedulePreferenceButton));
    await tester.pumpAndSettle();
    await tester.tap(find.byIcon(Icons.delete_outline_rounded));
    await tester.pumpAndSettle();

    // Close the dialog; the timetable falls back to the empty state.
    await tester.tap(find.text('Cancel'));
    await tester.pumpAndSettle();

    expect(find.text('No section selected.'), findsOneWidget);
    expect(find.text('Monday', skipOffstage: false), findsNothing);
  });

  testWidgets('switching day via DateWidget re-renders that day',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await selectScheduleFilters(tester);
    await tapDone(tester);
    expect(find.text('Monday', skipOffstage: false), findsOneWidget);

    // DateWidget renders one tappable cell per day (Sun=0 .. Sat=6).
    // Tap Tuesday (index 2).
    final tuesdayCell = find
        .descendant(
          of: find.byType(DateWidget),
          matching: find.byType(InkWell),
        )
        .at(2);
    await tester.tap(tuesdayCell);
    await tester.pumpAndSettle();

    expect(find.text('Tuesday', skipOffstage: false), findsOneWidget);
    expect(find.text('Monday', skipOffstage: false), findsNothing);
  });

  testWidgets('chosen elective not scheduled that day keeps the placeholder',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await selectScheduleFilters(tester);

    // Choose "Machine Learning" (present Mon/Tue/Wed in electives, absent Fri).
    final electiveDropdowns = find.byType(DropdownButton<String?>);
    await tester.tap(electiveDropdowns.first);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Machine Learning').last);
    await tester.pumpAndSettle();
    await tapDone(tester);

    // Monday: substituted.
    expect(find.text('Machine Learning', skipOffstage: false), findsOneWidget);

    // Friday (index 5): no elective data that day -> raw placeholder remains.
    final fridayCell = find
        .descendant(
          of: find.byType(DateWidget),
          matching: find.byType(InkWell),
        )
        .at(5);
    await tester.tap(fridayCell);
    await tester.pumpAndSettle();

    expect(find.text('Friday', skipOffstage: false), findsOneWidget);
    expect(find.text('Electives', skipOffstage: false), findsOneWidget);
    expect(find.text('Machine Learning', skipOffstage: false), findsNothing);
  });

  testWidgets('More Info opens the schedule details dialog',
      (WidgetTester tester) async {
    await pumpHome(tester);

    await selectScheduleFilters(tester);
    await tapDone(tester);
    expect(find.text('Monday', skipOffstage: false), findsOneWidget);

    await tester.tap(find.text('Info'));
    await tester.pumpAndSettle();

    // Details live in RichText TextSpans; the plain-text title confirms the
    // dialog opened.
    expect(find.text('About this schedule'), findsOneWidget);
  });

  testWidgets('two chosen electives both render on a day that has them',
      (WidgetTester tester) async {
    await pumpHome(tester);
    await selectScheduleFilters(tester);

    // Elective 1 = Machine Learning, Elective 2 = Data Structures.
    final elective1 = find.byType(DropdownButton<String?>).first;
    await tester.ensureVisible(elective1);
    await tester.tap(elective1);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Machine Learning').last);
    await tester.pumpAndSettle();

    final elective2 = find.byType(DropdownButton<String?>).at(1);
    await tester.ensureVisible(elective2);
    await tester.pumpAndSettle();
    await tester.tap(elective2);
    await tester.pumpAndSettle();
    await tester.tap(find.text('Data Structures').last);
    await tester.pumpAndSettle();

    await tapDone(tester);

    // Tuesday (index 2): electives has both subjects; the single "Electives"
    // placeholder is replaced and the extra elective is appended.
    final tuesdayCell = find
        .descendant(
          of: find.byType(DateWidget),
          matching: find.byType(InkWell),
        )
        .at(2);
    await tester.tap(tuesdayCell);
    await tester.pumpAndSettle();

    expect(find.text('Tuesday', skipOffstage: false), findsOneWidget);
    expect(find.text('Machine Learning', skipOffstage: false), findsOneWidget);
    expect(find.text('Data Structures', skipOffstage: false), findsOneWidget);
    expect(find.text('Electives', skipOffstage: false), findsNothing);
  });

  testWidgets('notification dialog: granting requests permission',
      (WidgetTester tester) async {
    mockNotificationService.needsPermissionResult = true;
    mockPreferences.promptForNotifications = true;

    await pumpHome(tester);

    expect(find.text('Enable Notifications'), findsOneWidget);

    await tester.tap(find.text('Yes'));
    await tester.pumpAndSettle();

    expect(mockNotificationService.requestPermissionCalls, 1);
    expect(find.text('Enable Notifications'), findsNothing);
  });

  testWidgets('notification dialog: declining records the dismissal',
      (WidgetTester tester) async {
    mockNotificationService.needsPermissionResult = true;
    mockPreferences.promptForNotifications = true;

    await pumpHome(tester);

    expect(find.text('Enable Notifications'), findsOneWidget);

    await tester.tap(find.text('No'));
    await tester.pumpAndSettle();

    expect(mockNotificationService.requestPermissionCalls, 0);
    expect(mockPreferences.notificationDialogDismissedCalls, 1);
    expect(find.text('Enable Notifications'), findsNothing);
  });
}
