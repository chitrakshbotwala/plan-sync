import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/core/cache/cache_service.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository.dart';
import 'package:plan_sync/util/logger.dart';

class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({
    required ApiClient apiClient,
    required CacheService cache,
  })  : _apiClient = apiClient,
        _cache = cache;

  final ApiClient _apiClient;
  final CacheService _cache;

  @override
  Stream<Timetable?> getSchedule({
    required String year,
    required String semester,
    required String section,
  }) async* {
    final url =
        'https://gitlab.com/delwinn/plan-sync/-/raw/${_apiClient.branch}/res/$year/$semester/$section.json';
    final cacheKey = 'schedule/$year/$semester/$section';

    bool emittedFromCache = false;

    final cached = await _cache.get<Timetable>(
      cacheKey,
      fromJson: (json) => Timetable.fromJson(json: json, isFresh: false),
    );
    if (cached != null) {
      emittedFromCache = true;
      yield cached;
    }

    try {
      final response = await _apiClient.dio.get(url);

      if ((response.statusCode ?? 0) >= 400) {
        if (!emittedFromCache) {
          yield* Stream.error(Exception('Server error ${response.statusCode}'));
        }
        return;
      }

      final fresh = Timetable.fromJson(
        json: jsonDecode(response.data),
        isFresh: true,
      );
      await _cache.set<Timetable>(
        cacheKey,
        fresh,
        toJson: (t) => t.toJson(),
      );
      yield fresh;
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
