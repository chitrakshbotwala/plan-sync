import 'package:plan_sync/features/campus_navigator/model/campus_navigation_model.dart';

abstract class CampusNavigatorRepository {
  Future<List<CampusNavigationModel>> getLocations({
    required int page,
    required int limit,
    String search,
  });
}
