import 'package:flutter/foundation.dart';
import 'package:plan_sync/features/attendance/model/attendance_record.dart';
import 'package:plan_sync/features/attendance/model/scrape_exception.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository.dart';
import 'package:plan_sync/features/attendance/repository/attendance_repository.dart';

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
    required AttendanceRepository repository,
  })  : _credentials = credentialsRepository,
        _repository = repository;

  final AttendanceCredentialsRepository _credentials;
  final AttendanceRepository _repository;

  AttendanceStatus status = AttendanceStatus.needsCredentials;
  AttendanceResult? result;
  ScrapeErrorKind? errorKind;
  String? errorMessage;

  /// True while a background refresh is running (data already exists on screen).
  bool isRefreshing = false;

  /// Live progress lines from the scrape, newest last.
  final List<String> logs = [];
  String? currentStep;

  // Currently *picked* year/session (what the dropdowns show).
  late String academicYear = currentAcademicYear();
  late String session = currentSession();

  // The year/session the loaded [result] actually reflects.
  String? _appliedYear;
  String? _appliedSession;

  /// True when the picked year/session differ from what [result] shows — i.e.
  /// the user changed a dropdown but hasn't applied it yet.
  bool get selectionDirty =>
      academicYear != _appliedYear || session != _appliedSession;

  /// Reads credentials from storage and pre-populates [result] from Hive so the
  /// Attendance tab renders cached data immediately without any loading screen.
  /// Call once at app startup (from [AppInitializer]).
  Future<void> initialize() async {
    await _credentials.initialize();

    if (!_credentials.hasCredentials) {
      status = AttendanceStatus.needsCredentials;
      notifyListeners();
      return;
    }

    // Pre-load from cache so result is non-null before the tab first renders.
    final creds = await _credentials.read();
    if (creds != null) {
      final cached = await _repository.cached(
        registrationNumber: creds.$1,
        academicYear: academicYear,
        session: session,
      );
      if (cached != null) {
        result = cached;
        _appliedYear = cached.academicYear;
        _appliedSession = cached.session;
      }
    }

    status =
        result != null ? AttendanceStatus.success : AttendanceStatus.idle;
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

  /// Called each time the Attendance tab is opened.
  ///
  /// If [result] is already populated (from cache or a prior scrape):
  ///   - fresh data  → no-op, keep showing it
  ///   - stale data  → silent background refresh ([isRefreshing] = true),
  ///                   the existing result stays visible
  /// If there is no [result] yet (first-ever use), a full scrape is started
  /// and the loading screen is shown.
  Future<void> ensureLoaded() async {
    if (!hasCredentials) {
      _set(AttendanceStatus.needsCredentials);
      return;
    }
    if (status == AttendanceStatus.loading || isRefreshing) return;

    if (result != null) {
      // Data is already on screen. Silently refresh only when stale.
      if (_repository.isStale(result!)) {
        await refresh(); // refresh() sees result != null → uses isRefreshing
      }
      return;
    }

    // No data yet (first-ever use) — full scrape with loading screen.
    await refresh();
  }

  Future<void> refresh() async {
    if (status == AttendanceStatus.loading || isRefreshing) return;

    final creds = await _credentials.read();
    if (creds == null) {
      _set(AttendanceStatus.needsCredentials);
      return;
    }

    logs.clear();
    currentStep = 'Starting…';
    errorKind = null;
    errorMessage = null;

    // If data is already on screen, refresh silently (no loading screen).
    final hasData = result != null;
    if (hasData) {
      isRefreshing = true;
      notifyListeners();
    } else {
      _set(AttendanceStatus.loading);
    }

    try {
      final fetched = await _repository.fetch(
        registrationNumber: creds.$1,
        password: creds.$2,
        academicYear: academicYear,
        session: session,
        onLog: pushLog,
      );
      result = fetched;
      _appliedYear = academicYear;
      _appliedSession = session;

      isRefreshing = false;
      _set(AttendanceStatus.success);
    } on ScrapeException catch (e) {
      // Bad credentials are no longer useful — clear them so the user is
      // prompted to reconnect rather than silently failing forever.
      if (e.kind == ScrapeErrorKind.invalidCredentials) {
        await _credentials.clear();
      }
      errorKind = e.kind;
      errorMessage = e.message;
      isRefreshing = false;
      _set(e.kind == ScrapeErrorKind.invalidCredentials
          ? AttendanceStatus.needsCredentials
          : AttendanceStatus.error);
    } catch (e) {
      errorKind = ScrapeErrorKind.unknown;
      errorMessage = e.toString();
      isRefreshing = false;
      _set(AttendanceStatus.error);
    }
  }

  /// Update the picked year/session WITHOUT fetching. The user applies the
  /// choice explicitly (see [applySelection]) so a single dropdown tap doesn't
  /// kick off a whole scrape mid-selection.
  void changeSelection({String? year, String? session}) {
    academicYear = year ?? academicYear;
    this.session = session ?? this.session;
    notifyListeners();
  }

  /// Load the currently-picked year/session, checking cache first before
  /// falling back to a full scrape. Stale cache is shown immediately while a
  /// background refresh runs.
  Future<void> applySelection() async {
    if (!selectionDirty) return;

    final creds = await _credentials.read();
    if (creds != null) {
      final cached = await _repository.cached(
        registrationNumber: creds.$1,
        academicYear: academicYear,
        session: session,
      );
      if (cached != null) {
        // Show whatever we have from cache immediately.
        result = cached;
        _appliedYear = academicYear;
        _appliedSession = session;
        _set(AttendanceStatus.success);

        if (!_repository.isStale(cached)) {
          return; // Fresh — no scrape needed.
        }
        // Stale — fall through; refresh() will use isRefreshing (data is visible).
      }
    }

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
    await refresh();
  }

  Future<void> disconnect() async {
    await _credentials.clear();
    result = null;
    errorKind = null;
    errorMessage = null;
    _set(AttendanceStatus.needsCredentials);
  }

  void _set(AttendanceStatus newStatus) {
    status = newStatus;
    notifyListeners();
  }
}
