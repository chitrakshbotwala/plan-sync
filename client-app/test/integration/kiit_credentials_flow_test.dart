import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/services/kiit_attendance_scraper.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository.dart';
import 'package:plan_sync/features/attendance/repository/attendance_repository_impl.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/widgets/bottom-sheets/kiit_credentials_sheet.dart';
import 'package:provider/provider.dart';

import '../helpers/fake_cache_service.dart';

class _FakeCredentials implements AttendanceCredentialsRepository {
  _FakeCredentials({bool hasCredentials = false, String? registrationNumber})
      : _has = hasCredentials,
        _reg = registrationNumber;

  bool _has;
  String? _reg;
  String? savedReg;
  String? savedPass;

  @override
  Future<void> initialize() async {}
  @override
  bool get hasCredentials => _has;
  @override
  String? get registrationNumber => _reg;
  @override
  Future<(String, String)?> read() async =>
      _has ? (_reg ?? '22001234', savedPass ?? 'pw') : null;
  @override
  Future<void> save({
    required String registrationNumber,
    required String password,
  }) async {
    _has = true;
    _reg = registrationNumber;
    savedReg = registrationNumber;
    savedPass = password;
  }

  @override
  Future<void> clear() async {
    _has = false;
    _reg = null;
  }
}

class _FakeScraper extends KiitAttendanceScraper {
  int scrapeCalls = 0;

  @override
  Future<AttendanceResult> scrape({
    required String username,
    required String password,
    required String academicYear,
    required String session,
    void Function(String message)? onLog,
  }) async {
    scrapeCalls++;
    return AttendanceResult(
      records: const [],
      student: null,
      academicYear: academicYear,
      session: session,
      fetchedAt: DateTime(2024, 1, 1),
    );
  }
}

void main() {
  late _FakeCredentials creds;
  late _FakeScraper scraper;

  Future<void> openSheet(WidgetTester tester) async {
    final vm = AttendanceViewModel(
      credentialsRepository: creds,
      repository: AttendanceRepositoryImpl(
        cache: FakeCacheService(),
        scraperFactory: () => scraper,
      ),
    );
    await tester.pumpWidget(
      ChangeNotifierProvider<AttendanceViewModel>.value(
        value: vm,
        child: MaterialApp(
          theme: ThemeService.lightTheme,
          home: Builder(
            builder: (ctx) => Scaffold(
              body: Center(
                child: ElevatedButton(
                  onPressed: () => showModalBottomSheet(
                    context: ctx,
                    isScrollControlled: true,
                    showDragHandle: true,
                    builder: (_) => const KiitCredentialsSheet(),
                  ),
                  child: const Text('open'),
                ),
              ),
            ),
          ),
        ),
      ),
    );
    await tester.tap(find.text('open'));
    await tester.pumpAndSettle();
  }

  setUp(() {
    creds = _FakeCredentials();
    scraper = _FakeScraper();
  });

  testWidgets('renders the credentials form', (tester) async {
    await openSheet(tester);

    expect(find.text('Connect KIIT Portal'), findsNWidgets(2));
    expect(find.byType(TextFormField), findsNWidgets(2));
  });

  testWidgets('empty fields fail validation and do not connect',
      (tester) async {
    await openSheet(tester);

    await tester.tap(find.widgetWithText(ElevatedButton, 'Connect KIIT Portal'));
    await tester.pumpAndSettle();

    expect(find.text('Enter your roll number'), findsOneWidget);
    expect(find.text('Enter your password'), findsOneWidget);
    // Still open, nothing saved/scraped.
    expect(find.text('Connect KIIT Portal'), findsOneWidget);
    expect(scraper.scrapeCalls, 0);
    expect(creds.hasCredentials, isFalse);
  });

  testWidgets('pre-fills the saved registration number', (tester) async {
    creds = _FakeCredentials(hasCredentials: true, registrationNumber: '2205');
    await openSheet(tester);

    expect(find.widgetWithText(TextFormField, '2205'), findsOneWidget);
  });

  testWidgets('valid submit saves credentials, scrapes, and closes the sheet',
      (tester) async {
    await openSheet(tester);

    await tester.enterText(find.byType(TextFormField).first, '2205999');
    await tester.enterText(find.byType(TextFormField).last, 'hunter2');
    await tester.tap(find.widgetWithText(ElevatedButton, 'Connect KIIT Portal'));
    await tester.pumpAndSettle();

    // Sheet popped.
    expect(find.text('Connect KIIT Portal'), findsNothing);
    // Credentials saved and a scrape was kicked off via connect().
    expect(creds.savedReg, '2205999');
    expect(creds.savedPass, 'hunter2');
    expect(scraper.scrapeCalls, 1);
  });

  testWidgets('password visibility toggle flips the obscure icon',
      (tester) async {
    await openSheet(tester);

    expect(find.byIcon(Icons.visibility_outlined), findsOneWidget);

    await tester.tap(find.byIcon(Icons.visibility_outlined));
    await tester.pumpAndSettle();

    expect(find.byIcon(Icons.visibility_off_outlined), findsOneWidget);
  });
}
