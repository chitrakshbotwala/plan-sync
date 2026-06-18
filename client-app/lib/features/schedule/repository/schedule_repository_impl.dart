import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:internet_connection_checker_plus/internet_connection_checker_plus.dart';
import 'package:plan_sync/backend/models/timetable.dart';
import 'package:plan_sync/controllers/git_service.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository.dart';
import 'package:plan_sync/util/logger.dart';

// Transitional: borrows Dio/cache from GitService until ApiClient + CacheService
// are extracted in a later pass.
class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({required GitService gitService})
      : _gitService = gitService;

  final GitService _gitService;

  @override
  Stream<Timetable?> getSchedule({
    required String year,
    required String semester,
    required String section,
  }) async* {
    final Dio dio = _gitService.dio;
    final CacheOptions? cacheOptions = _gitService.cacheOptions;
    final String branch = _gitService.branch;
    final url =
        'https://gitlab.com/delwinn/plan-sync/-/raw/$branch/res/$year/$semester/$section.json';

    bool emittedFromCache = false;

    try {
      final options = RequestOptions(path: url);
      final key = CacheOptions.defaultCacheKeyBuilder(options);
      final cache = await cacheOptions?.store?.get(key);

      if (cache != null) {
        emittedFromCache = true;
        yield Timetable.fromJson(
          json: jsonDecode(cache.toResponse(options).data),
          isFresh: false,
        );
      }

      final response = await dio.get(url);

      if ((response.statusCode ?? 0) >= 400) {
        if (!emittedFromCache) {
          yield* Stream.error(Exception('Server error ${response.statusCode}'));
        }
        return;
      }

      if (response.headers.map['etag']?.first != cache?.eTag) {
        Logger.i('ScheduleRepository: yield fresh (ETag changed)');
        yield Timetable.fromJson(
          json: jsonDecode(response.data),
          isFresh: true,
        );
      } else {
        Logger.i('ScheduleRepository: ETag matches, checking connectivity');
        final connectionAvailable =
            await InternetConnection().hasInternetAccess;
        if (cache != null) {
          yield Timetable.fromJson(
            json: jsonDecode(cache.toResponse(options).data),
            isFresh: connectionAvailable,
          );
        }
      }
    } on DioException catch (e) {
      Logger.e('ScheduleRepository.getSchedule DioException: $e');
      if (!emittedFromCache) {
        yield* Stream.error(Exception({
          'error': 'DioException',
          'type': e.type.toString(),
          'message': e.type == DioExceptionType.connectionError
              ? 'Please check your network connection.'
              : 'Could not fetch schedule. Please try again later.',
        }));
      }
    } catch (e) {
      Logger.e('ScheduleRepository.getSchedule exception: $e');
      if (!emittedFromCache) {
        yield* Stream.error(
          Exception('An error occurred while loading the schedule.'),
        );
      }
    }
  }
}
