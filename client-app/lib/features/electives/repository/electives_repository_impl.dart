import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:plan_sync/core/cache/cache_service.dart';
import 'package:plan_sync/features/schedule/model/timetable.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/features/electives/repository/electives_repository.dart';
import 'package:plan_sync/core/util/logger.dart';

class ElectivesRepositoryImpl implements ElectivesRepository {
  ElectivesRepositoryImpl({
    required ApiClient apiClient,
    required CacheService cache,
  })  : _apiClient = apiClient,
        _cache = cache;

  final ApiClient _apiClient;
  final CacheService _cache;

  @override
  Stream<Timetable?> getTimetable({
    required String year,
    required String semester,
    required String schemeCode,
  }) async* {
    final url =
        '${ApiClient.baseUrl}/api/v1/electives-scheme/$year/$semester/$schemeCode';
    final cacheKey = 'electives/$year/$semester/$schemeCode';

    bool emittedFromCache = false;

    final cached = await _cache.get<Timetable>(
      cacheKey,
      fromJson: (json) => Timetable.fromJson(json: json, isFresh: false),
    );
    if (cached != null) {
      emittedFromCache = true;
      Logger.i('ElectivesRepository: yield from cache');
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

      if (response.data == '') return;

      final fresh = Timetable.fromJson(
        json: jsonDecode(response.data),
        isFresh: true,
      );
      await _cache.set<Timetable>(
        cacheKey,
        fresh,
        toJson: (t) => t.toJson(),
      );
      Logger.i('ElectivesRepository: yield fresh');
      yield fresh;
    } on DioException catch (e) {
      Logger.e('ElectivesRepository.getTimetable DioException: $e');
      if (!emittedFromCache) {
        yield* Stream.error(Exception({
          'error': 'DioException',
          'type': e.type.toString(),
          'message': e.type == DioExceptionType.connectionError
              ? 'Please check your network connection.'
              : 'Could not fetch electives. Please try again later.',
        }));
      }
    } catch (e) {
      Logger.e('ElectivesRepository.getTimetable exception: $e');
      if (!emittedFromCache) {
        yield* Stream.error(
          Exception('An error occurred while loading electives.'),
        );
      }
    }
  }
}
