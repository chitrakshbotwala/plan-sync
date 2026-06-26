import 'package:dio/dio.dart';
import 'package:plan_sync/features/electives/repository/electives_repository.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';

enum MockElectivesRepositoryStage {
  empty,
  success,
  error,
}

class MockElectivesRepository implements ElectivesRepository {
  MockElectivesRepositoryStage stage = MockElectivesRepositoryStage.empty;

  @override
  Stream<Timetable?> getTimetable({
    required String year,
    required String semester,
    required String schemeCode,
  }) async* {
    switch (stage) {
      case MockElectivesRepositoryStage.empty:
        return;
      case MockElectivesRepositoryStage.error:
        yield* Stream.error(
          DioException.connectionError(
            requestOptions: RequestOptions(),
            reason: 'No Internet',
          ),
        );
        return;
      case MockElectivesRepositoryStage.success:
        yield Timetable.fromJson(json: _mockJson());
        return;
    }
  }

  Map<String, dynamic> _mockJson() => {
        'meta': {
          'section': 'electives-a',
          'type': 'elective',
          'revision': 'Rev 1',
          'effective-date': 'Jan 2024',
          'contributor': 'Admin',
          'isTimetableUpdating': false,
        },
        'data': {
          'monday': [
            {'time': '08:00 - 09:00', 'subject': 'Machine Learning', 'room': '101'},
          ],
          'tuesday': [
            {'time': '08:00 - 09:00', 'subject': 'Machine Learning', 'room': '101'},
            {'time': '09:00 - 10:00', 'subject': 'Data Structures', 'room': '102'},
          ],
          'wednesday': [
            {'time': '08:00 - 09:00', 'subject': 'Operating Systems', 'room': '103'},
          ],
        },
      };
}
