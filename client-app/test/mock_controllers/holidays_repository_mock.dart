import 'package:plan_sync/features/holidays/model/holiday.dart';
import 'package:plan_sync/features/holidays/repository/holidays_repository.dart';

class MockHolidaysRepository implements HolidaysRepository {
  List<Holiday> holidays = const [];

  @override
  Stream<List<Holiday>> getHolidays({required String year}) async* {
    yield holidays;
  }
}
