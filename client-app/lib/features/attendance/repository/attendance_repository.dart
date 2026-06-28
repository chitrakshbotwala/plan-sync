import 'package:plan_sync/features/attendance/model/attendance_record.dart';

/// Owns the attendance Hive cache, freshness policy, and portal scrape.
///
/// Uses [Future]s rather than a cache-then-refresh [Stream]: a scrape is
/// expensive (headless WebView) and explicitly triggered, so the cache read
/// ([cached]) and the network fetch ([fetch]) are separate, caller-driven steps.
abstract class AttendanceRepository {
  /// Cached result for the period, or null. Never hits the network.
  Future<AttendanceResult?> cached({
    required String registrationNumber,
    required String academicYear,
    required String session,
  });

  bool isStale(AttendanceResult result);

  /// Scrapes, writes to the cache, and returns the result. May throw.
  Future<AttendanceResult> fetch({
    required String registrationNumber,
    required String password,
    required String academicYear,
    required String session,
    required void Function(String step) onLog,
  });
}
