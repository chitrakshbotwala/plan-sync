import 'package:flutter/foundation.dart';
import 'package:plan_sync/core/services/kiit_attendance_scraper.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/features/attendance/model/scrape_exception.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository.dart';

enum AttendanceStatus {
  /// No portal credentials stored yet.
  needsCredentials,

  /// Idle with no result yet (credentials present, not fetched).
  idle,

  /// A scrape is in progress.
  loading,

  /// A result is available.
  success,

  /// The last scrape failed.
  error,
}

class AttendanceViewModel extends ChangeNotifier {
  AttendanceViewModel({
    required AttendanceCredentialsRepository credentialsRepository,
  }) : _credentials = credentialsRepository;

  final AttendanceCredentialsRepository _credentials;

  AttendanceStatus status = AttendanceStatus.needsCredentials;
  AttendanceResult? result;
  ScrapeErrorKind? errorKind;
  String? errorMessage;

  /// Live progress lines from the scrape, newest last.
  final List<String> logs = [];
  String? currentStep;

  late String academicYear = currentAcademicYear();
  late String session = currentSession();

  bool _fetchedOnce = false;

  /// Reads credentials from storage and sets the initial status.
  /// Call once at app startup (from [AppInitializer]).
  Future<void> initialize() async {
    await _credentials.initialize();
    status = _credentials.hasCredentials
        ? AttendanceStatus.idle
        : AttendanceStatus.needsCredentials;
    notifyListeners();
  }

  bool get hasCredentials => _credentials.hasCredentials;
  String? get registrationNumber => _credentials.registrationNumber;

  // --- year / session options -----------------------------------------------

  /// KIIT academic year for "now": Autumn (Jul–Dec) belongs to YYYY-(YYYY+1),
  /// Spring (Jan–Jun) belongs to (YYYY-1)-YYYY.
  static String currentAcademicYear() {
    final now = DateTime.now();
    final start = now.month >= 7 ? now.year : now.year - 1;
    return '$start-${start + 1}';
  }

  static String currentSession() =>
      DateTime.now().month >= 7 ? 'Autumn' : 'Spring';

  List<String> get yearOptions {
    final start = int.parse(currentAcademicYear().split('-').first);
    return List.generate(7, (i) {
      final y = start + 1 - i; // a year ahead down to ~5 years back
      return '$y-${y + 1}';
    });
  }

  List<String> get sessionOptions => const ['Autumn', 'Spring'];

  // --- progress -------------------------------------------------------------

  void pushLog(String step) {
    currentStep = step;
    logs.add(step);
    notifyListeners();
  }

  // --- actions --------------------------------------------------------------

  /// Called when the Attendance tab is opened. Fetches once if we have
  /// credentials and haven't fetched yet this session.
  Future<void> ensureLoaded() async {
    if (!hasCredentials) {
      _set(AttendanceStatus.needsCredentials);
      return;
    }
    if (_fetchedOnce || status == AttendanceStatus.loading) return;
    await refresh();
  }

  Future<void> refresh() async {
    if (status == AttendanceStatus.loading) return;

    final creds = await _credentials.read();
    if (creds == null) {
      _set(AttendanceStatus.needsCredentials);
      return;
    }

    logs.clear();
    currentStep = 'Starting…';
    errorKind = null;
    errorMessage = null;
    _set(AttendanceStatus.loading);

    final scraper = KiitAttendanceScraper();
    try {
      final fetched = await scraper.scrape(
        username: creds.$1,
        password: creds.$2,
        academicYear: academicYear,
        session: session,
        onLog: pushLog,
      );
      _fetchedOnce = true;
      result = fetched;
      _set(AttendanceStatus.success);
    } on ScrapeException catch (e) {
      // Bad credentials are no longer useful — clear them so the user is
      // prompted to reconnect rather than silently failing forever.
      if (e.kind == ScrapeErrorKind.invalidCredentials) {
        await _credentials.clear();
      }
      errorKind = e.kind;
      errorMessage = e.message;
      _set(e.kind == ScrapeErrorKind.invalidCredentials
          ? AttendanceStatus.needsCredentials
          : AttendanceStatus.error);
    } catch (e) {
      errorKind = ScrapeErrorKind.unknown;
      errorMessage = e.toString();
      _set(AttendanceStatus.error);
    }
  }

  Future<void> changeSelection({String? year, String? session}) async {
    final newYear = year ?? academicYear;
    final newSession = session ?? this.session;
    if (newYear == academicYear && newSession == this.session) return;
    academicYear = newYear;
    this.session = newSession;
    notifyListeners();
    await refresh();
  }

  /// Save new credentials and immediately fetch.
  Future<void> connect({
    required String registrationNumber,
    required String password,
  }) async {
    await _credentials.save(
      registrationNumber: registrationNumber,
      password: password,
    );
    _fetchedOnce = false;
    await refresh();
  }

  Future<void> disconnect() async {
    await _credentials.clear();
    result = null;
    _fetchedOnce = false;
    errorKind = null;
    errorMessage = null;
    _set(AttendanceStatus.needsCredentials);
  }

  void _set(AttendanceStatus newStatus) {
    status = newStatus;
    notifyListeners();
  }
}
