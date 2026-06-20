import 'package:dio/dio.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository.dart';

enum MockScheduleRepositoryStage {
  success,
  noInternet,
  scheduleUpdating,
  noneSelected,
}

class MockScheduleRepository implements ScheduleRepository {
  MockScheduleRepositoryStage stage = MockScheduleRepositoryStage.success;

  @override
  Stream<Timetable?> getSchedule({
    required String year,
    required String semester,
    required String section,
  }) async* {
    switch (stage) {
      case MockScheduleRepositoryStage.noInternet:
        yield* Stream.error(
          DioException.connectionError(
            requestOptions: RequestOptions(),
            reason: 'No Internet',
          ),
        );
        return;

      case MockScheduleRepositoryStage.scheduleUpdating:
        yield Timetable.fromJson(json: _mockJson(isTimetableUpdating: true));
        return;

      case MockScheduleRepositoryStage.noneSelected:
        return;

      case MockScheduleRepositoryStage.success:
        yield Timetable.fromJson(json: _mockJson());
        return;
    }
  }

  Map<String, dynamic> _mockJson({bool isTimetableUpdating = false}) => {
        "meta": {
          "section": "b16",
          "type": "norm-class",
          "revision": "Revision 1.03",
          "effective-date": "Jan 15, 2024 (Saturdays' valid till Apr 13)",
          "contributor": "PlanSync Admin :)",
          "isTimetableUpdating": isTimetableUpdating,
        },
        "data": {
          "monday": [
            {"time": "08:00 - 09:00", "subject": "Electives", "room": "301"},
          ],
          "tuesday": [
            {"time": "08:00 - 09:00", "subject": "Electives", "room": "306"},
          ],
          "wednesday": [
            {"time": "08:00 - 09:00", "subject": "Electives", "room": "404"},
          ],
          "thursday": [
            {"time": "08:00 - 09:00", "subject": "Electives", "room": "402"},
          ],
          "friday": [
            {"time": "08:00 - 09:00", "subject": "Electives", "room": "403"},
          ],
          "saturday": [
            {"time": "08:00 - 09:00", "subject": "Electives", "room": "301"},
          ],
        },
      };
}
