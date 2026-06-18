import 'package:plan_sync/features/campus_navigator/model/campus_navigation_model.dart';
import 'package:plan_sync/features/campus_navigator/repository/campus_navigator_repository.dart';
import 'package:plan_sync/util/logger.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class CampusNavigatorRepositoryImpl implements CampusNavigatorRepository {
  @override
  Future<List<CampusNavigationModel>> getLocations({
    required int page,
    required int limit,
    String search = '',
  }) async {
    try {
      final client = Supabase.instance.client;
      var query = client.from('campus_navigation').select();

      if (search.isNotEmpty) {
        query = query.ilike('title', '%$search%');
      }

      final data = await query
          .order('title', ascending: true)
          .range(page * limit, (page + 1) * limit - 1);

      return (data as List)
          .map((e) => CampusNavigationModel.fromJson(e as Map<String, dynamic>))
          .toList();
    } catch (e) {
      Logger.e('CampusNavigatorRepository.getLocations failed: $e');
      rethrow;
    }
  }
}
