import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:plan_sync/core/cache/cache_service.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/core/util/logger.dart';
import 'package:plan_sync/features/holidays/model/holiday.dart';
import 'package:plan_sync/features/holidays/repository/holidays_repository.dart';

class HolidaysRepositoryImpl implements HolidaysRepository {
  HolidaysRepositoryImpl({
    required ApiClient apiClient,
    required CacheService cache,
  })  : _apiClient = apiClient,
        _cache = cache;

  final ApiClient _apiClient;
  final CacheService _cache;

  @override
  Stream<List<Holiday>> getHolidays({required String year}) async* {
    final url =
        'https://gitlab.com/delwinn/plan-sync/-/raw/${_apiClient.branch}/res/$year/holiday.json';
    final cacheKey = 'holidays/$year';

    bool emittedFromCache = false;

    // CacheService is keyed on Map<String, dynamic>; the holiday payload is a
    // JSON array, so we wrap it under a single key for storage.
    final cached = await _cache.get<List<Holiday>>(
      cacheKey,
      fromJson: _fromCacheJson,
    );
    if (cached != null) {
      emittedFromCache = true;
      Logger.i('HolidaysRepository: yield from cache');
      yield cached;
    }

    try {
      final response = await _apiClient.dio.get(url);

      if ((response.statusCode ?? 0) >= 400) {
        if (!emittedFromCache) {
          yield* Stream.error(response.statusCode == 404
              ? const HolidaysNotPublishedException()
              : Exception('Server error ${response.statusCode}'));
        }
        return;
      }

      if (response.data == '' || response.data == null) return;

      final decoded = jsonDecode(response.data);
      final fresh = (decoded as List)
          .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
          .toList();

      await _cache.set<List<Holiday>>(
        cacheKey,
        fresh,
        toJson: _toCacheJson,
      );
      Logger.i('HolidaysRepository: yield fresh');
      yield fresh;
    } on DioException catch (e) {
      Logger.e('HolidaysRepository.getHolidays DioException: $e');
      if (!emittedFromCache) {
        if (e.response?.statusCode == 404) {
          yield* Stream.error(const HolidaysNotPublishedException());
          return;
        }
        yield* Stream.error(Exception({
          'error': 'DioException',
          'type': e.type.toString(),
          'message': e.type == DioExceptionType.connectionError
              ? 'Please check your network connection.'
              : 'Could not fetch holidays. Please try again later.',
        }));
      }
    } catch (e) {
      Logger.e('HolidaysRepository.getHolidays exception: $e');
      if (!emittedFromCache) {
        yield* Stream.error(
          Exception('An error occurred while loading holidays.'),
        );
      }
    }
  }

  static List<Holiday> _fromCacheJson(Map<String, dynamic> json) {
    final list = (json['holidays'] as List?) ?? const [];
    return list
        .map((e) => Holiday.fromJson(e as Map<String, dynamic>))
        .toList();
  }

  static Map<String, dynamic> _toCacheJson(List<Holiday> holidays) => {
        'holidays': holidays.map((h) => h.toJson()).toList(),
      };
}
