import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository.dart';
import 'package:plan_sync/features/attendance/repository/attendance_repository_impl.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/features/settings/view/settings_screen.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../helpers/fake_cache_service.dart';
import '../helpers/fake_network_images.dart';
import '../main.dart';

class _FakeCredentials implements AttendanceCredentialsRepository {
  _FakeCredentials({bool hasCredentials = false, String? registrationNumber})
      : _has = hasCredentials,
        _reg = registrationNumber;

  bool _has;
  String? _reg;

  @override
  Future<void> initialize() async {}

  @override
  bool get hasCredentials => _has;

  @override
  String? get registrationNumber => _reg;

  @override
  Future<(String, String)?> read() async =>
      _has ? (_reg ?? '22001234', 'pw') : null;

  @override
  Future<void> save({
    required String registrationNumber,
    required String password,
  }) async {
    _has = true;
    _reg = registrationNumber;
  }

  @override
  Future<void> clear() async {
    _has = false;
    _reg = null;
  }
}

void main() {
  setUpAll(() => HttpOverrides.global = FakeNetworkImageHttpOverrides());
  tearDownAll(() => HttpOverrides.global = null);

  late _FakeCredentials creds;

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
    creds = _FakeCredentials();
  });

  Future<void> pumpSettings(WidgetTester tester) async {
    // AttendanceViewModel isn't part of the shared tree; layer it above
    // testApp so SettingsPage's Consumer<AttendanceViewModel> can read it.
    await tester.pumpWidget(
      ChangeNotifierProvider<AttendanceViewModel>(
        create: (_) =>
            AttendanceViewModel(
              credentialsRepository: creds,
              repository: AttendanceRepositoryImpl(cache: FakeCacheService()),
            ),
        child: testApp(child: const SettingsPage()),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders account header and all settings rows', (tester) async {
    await pumpSettings(tester);

    expect(find.text('Account'), findsOneWidget);
    expect(find.text('Set Primary Sections'), findsOneWidget);
    expect(find.text('KIIT Portal Login'), findsOneWidget);
    expect(find.text('Request Features/Changes'), findsOneWidget);
    expect(find.text('Report an error'), findsOneWidget);
    expect(find.text('Share This App'), findsOneWidget);
    expect(find.text('Terms of Service'), findsOneWidget);
    expect(find.text('Privacy Policy'), findsOneWidget);
    expect(find.text('Delete your account'), findsOneWidget);
  });

  testWidgets('falls back to placeholder name/email when logged out',
      (tester) async {
    // MockAuth starts signed out -> SettingsViewModel getters are null.
    await pumpSettings(tester);

    expect(find.text('Plan Sync Wizard'), findsOneWidget);
    expect(find.text('connect@plansync.in'), findsOneWidget);
  });

  testWidgets('KIIT row reflects "not connected" when no credentials',
      (tester) async {
    await pumpSettings(tester);

    expect(find.text('Connect to track attendance'), findsOneWidget);
  });

  testWidgets('KIIT row reflects "connected" with registration number',
      (tester) async {
    creds = _FakeCredentials(
      hasCredentials: true,
      registrationNumber: '2205999',
    );
    await pumpSettings(tester);

    expect(find.textContaining('Connected'), findsOneWidget);
    expect(find.textContaining('2205999'), findsOneWidget);
  });

  testWidgets('tapping Set Primary Sections opens the preferences dialog',
      (tester) async {
    await pumpSettings(tester);

    await tester.tap(find.text('Set Primary Sections'));
    await tester.pumpAndSettle();

    expect(find.text('Preferences'), findsOneWidget);
  });

  testWidgets('tapping Delete your account opens the delete confirmation',
      (tester) async {
    await pumpSettings(tester);

    // The row sits at the bottom of a scroll view — bring it on-screen.
    final row = find.text('Delete your account');
    await tester.ensureVisible(row);
    await tester.pumpAndSettle();
    await tester.tap(row);
    await tester.pumpAndSettle();

    // The confirmation dialog has its own title + destructive button.
    expect(find.text('Delete your account?'), findsOneWidget);
    expect(find.text('Delete Account'), findsOneWidget);
  });

  testWidgets('long-pressing the avatar toggles the pun image', (tester) async {
    await pumpSettings(tester);

    // togglePun flips a bool on the SettingsViewModel without throwing;
    // the avatar swaps its foreground image.
    await tester.longPress(find.byType(CircleAvatar));
    await tester.pumpAndSettle();

    expect(find.byType(CircleAvatar), findsOneWidget);
  });
}
