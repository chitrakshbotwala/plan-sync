import 'package:plan_sync/features/electives/repository/electives_repository.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';

class MockElectivesRepository implements ElectivesRepository {
  @override
  Stream<Timetable?> getTimetable({
    required String year,
    required String semester,
    required String schemeCode,
  }) => const Stream.empty();
}
