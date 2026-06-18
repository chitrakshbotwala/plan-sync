import 'package:flutter/material.dart';
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:get/get.dart';
import 'package:plan_sync/controllers/filter_controller.dart';
import 'package:plan_sync/controllers/git_service.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository.dart';
import 'package:plan_sync/util/enums.dart';
import 'package:plan_sync/widgets/time_table.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../main.dart';
import '../mock_controllers/filter_controller_mock.dart';
import '../mock_controllers/git_service_mock.dart';
import '../mock_controllers/schedule_repository_mock.dart';

void main() {
  Future<void> pumpBaseWidget(WidgetTester tester) async {
    return tester.pumpWidget(testApp(child: Scaffold(
        body: SingleChildScrollView(
          child: TimeTableWidget(),
        ),
      ),
    ));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
  });

  testWidgets('TimeTableWidget renders schedule if available',
      (WidgetTester tester) async {
    final gitService = Get.find<GitService>() as MockGitService;
    final filterController =
        Get.find<FilterController>() as MockFilterController;
    final scheduleRepo =
        Get.find<ScheduleRepository>() as MockScheduleRepository;

    scheduleRepo.stage = MockScheduleRepositoryStage.success;
    gitService.selectedYear = '2024';
    filterController.activeSemester = 'SEM1';
    filterController.activeSectionCode = 'A';

    filterController.weekday = Weekday.monday;
    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();
    expect(find.text('Monday', skipOffstage: false), findsOneWidget);

    filterController.weekday = Weekday.tuesday;
    await pumpBaseWidget(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Tuesday', skipOffstage: false), findsOneWidget);

    filterController.weekday = Weekday.wednesday;
    await pumpBaseWidget(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Wednesday', skipOffstage: false), findsOneWidget);

    filterController.weekday = Weekday.thursday;
    await pumpBaseWidget(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Thursday', skipOffstage: false), findsOneWidget);

    filterController.weekday = Weekday.friday;
    await pumpBaseWidget(tester);
    await tester.pump(const Duration(seconds: 1));
    expect(find.text('Friday', skipOffstage: false), findsOneWidget);

    await tester.pumpAndSettle(const Duration(seconds: 3));
  });

  testWidgets('TimeTableWidget renders info page if schedule is updating',
      (WidgetTester tester) async {
    final gitService = Get.find<GitService>() as MockGitService;
    final filterController =
        Get.find<FilterController>() as MockFilterController;
    final scheduleRepo =
        Get.find<ScheduleRepository>() as MockScheduleRepository;

    scheduleRepo.stage = MockScheduleRepositoryStage.scheduleUpdating;
    gitService.selectedYear = '2024';
    filterController.activeSemester = 'SEM1';
    filterController.activeSectionCode = 'A';

    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    expect(find.text('Monday'), findsNothing);
    expect(find.text('Tuesday'), findsNothing);
    expect(find.text('Wednesday'), findsNothing);
    expect(find.text('Thursday'), findsNothing);
    expect(find.text('Friday'), findsNothing);

    //returns info page when updating
    expect(find.byIcon(Icons.settings_outlined), findsOneWidget);
    expect(find.text("We're working on this timetable,"), findsOneWidget);
    expect(find.text('Check back in soon!'), findsOneWidget);
  });

  /// Skipping as we've added offline support using caching
  testWidgets('TimeTableWidget renders error if no internet', skip: true,
      (WidgetTester tester) async {
    final gitService = Get.find<GitService>() as MockGitService;
    final filterController =
        Get.find<FilterController>() as MockFilterController;
    final scheduleRepo =
        Get.find<ScheduleRepository>() as MockScheduleRepository;

    scheduleRepo.stage = MockScheduleRepositoryStage.noInternet;
    gitService.selectedYear = '2024';
    filterController.activeSemester = 'SEM1';
    filterController.activeSectionCode = 'A';

    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    // returns error page when no connectivity
    expect(find.byIcon(Icons.error), findsOneWidget);
    expect(
      find.byWidgetPredicate(
        (widget) =>
            widget is MarkdownBody && widget.data.contains('No Internet'),
      ),
      findsOneWidget,
    );
    expect(
      find.text(
        'A status report has been sent, this issue will be looked into.',
      ),
      findsOneWidget,
    );
  });

  testWidgets('TimeTableWidget renders info page if no section is selected',
      (WidgetTester tester) async {
    // Leave year/semester/section unset — ScheduleViewModel won't call repository.
    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    expect(find.text('Monday'), findsNothing);
    expect(find.text('Tuesday'), findsNothing);
    expect(find.text('Wednesday'), findsNothing);
    expect(find.text('Thursday'), findsNothing);
    expect(find.text('Friday'), findsNothing);

    //returns info page when no data is returned
    expect(find.byIcon(Icons.info), findsOneWidget);
    expect(find.text("No section selected."), findsOneWidget);
  });
}
