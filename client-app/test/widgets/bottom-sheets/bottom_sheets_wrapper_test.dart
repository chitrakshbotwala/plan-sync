import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/widgets/bottom-sheets/bottom_sheets_wrapper.dart';
import 'package:plan_sync/features/home/view/widgets/contribute_schedule.dart';
import 'package:plan_sync/features/home/view/widgets/report_error.dart';
import 'package:plan_sync/features/schedule/view/widgets/schedule_preference.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../main.dart';

void main() {
  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
  });
  testWidgets(
    'PopupsWrapper.changeSectionPreference returns correct widget',
    (WidgetTester tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        testApp(child: Scaffold(
            body: Builder(
              builder: (context) {
                savedContext = context;
                return Container();
              },
            ),
          ),
        ),
      );

      PopupsWrapper.changeSectionPreference(context: savedContext);

      await tester.pumpAndSettle();
      expect(find.byType(SchedulePreferenceDialog), findsOneWidget);
      expect(find.byType(ReportErrorBottomSheet), findsNothing);
      expect(find.byType(ContributeScheduleBottomSheet), findsNothing);
    },
  );

  testWidgets(
    'BottomSheetsWrapper.contributeTimeTable returns correct widget',
    (WidgetTester tester) async {
      late BuildContext savedContext;

      await tester.pumpWidget(
        testApp(child: Scaffold(
            body: Builder(
              builder: (context) {
                savedContext = context;
                return Container();
              },
            ),
          ),
        ),
      );

      BottomSheets.contributeTimeTable(context: savedContext);

      await tester.pumpAndSettle();
      expect(find.byType(SchedulePreferenceDialog), findsNothing);
      expect(find.byType(ReportErrorBottomSheet), findsNothing);
      expect(find.byType(ContributeScheduleBottomSheet), findsOneWidget);
    },
  );
}
