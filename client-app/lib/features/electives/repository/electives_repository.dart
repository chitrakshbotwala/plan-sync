import 'package:plan_sync/features/schedule/model/timetable.dart';

abstract class ElectivesRepository {
  /// Emits cached timetable first (if any), then the fresh network value.
  /// Errors only if there was no cache AND the network failed.
  Stream<Timetable?> getTimetable({
    required String year,
    required String semester,
    required String schemeCode,
  });
}
