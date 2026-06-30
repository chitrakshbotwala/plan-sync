import 'package:plan_sync/features/holidays/model/holiday.dart';

/// Raised when the year's `holiday.json` does not exist on the remote (404),
/// i.e. the holiday list hasn't been published yet — distinct from a transient
/// network/server failure.
class HolidaysNotPublishedException implements Exception {
  const HolidaysNotPublishedException();
}

abstract class HolidaysRepository {
  /// Emits the cached holiday list first (if any), then the fresh network
  /// value, for the given academic [year].
  ///
  /// Errors only if there was no cache AND the network failed.
  Stream<List<Holiday>> getHolidays({required String year});
}
