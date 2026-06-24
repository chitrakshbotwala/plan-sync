import 'package:plan_sync/features/schedule/model/timetable.dart';

abstract class ScheduleRepository {
  /// Emits cached schedule first (if any), then the fresh network value.
  /// Errors only if there was no cache AND the network failed.
  Stream<Timetable?> getSchedule({
    required String year,
    required String semester,
    required String section,
  });
}
