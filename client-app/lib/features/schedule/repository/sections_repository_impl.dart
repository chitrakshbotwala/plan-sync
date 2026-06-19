import 'dart:convert';
import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository.dart';
import 'package:plan_sync/util/logger.dart';

class SectionsRepositoryImpl implements SectionsRepository {
  SectionsRepositoryImpl({required ApiClient apiClient})
      : _apiClient = apiClient;

  final ApiClient _apiClient;

  String get _sectionsUrl =>
      'https://gitlab.com/delwinn/plan-sync/-/raw/${_apiClient.branch}/res/sections.json';

  String get _electivesUrl =>
      'https://gitlab.com/delwinn/plan-sync/-/raw/${_apiClient.branch}/res/electives.json';

  // Fetches the raw JSON map for a given URL using the same cache-then-refresh
  // pattern as ScheduleRepositoryImpl: emit cached data first (fast first
  // paint), then the fresh network value if the ETag has changed.
  Stream<Map<String, dynamic>> _fetchJsonData(String url) async* {
    final reqOptions = RequestOptions(path: url);
    final cacheKey = CacheOptions.defaultCacheKeyBuilder(reqOptions);
    final cache = await _apiClient.cacheOptions?.store?.get(cacheKey);

    bool emittedFromCache = false;

    if (cache != null) {
      emittedFromCache = true;
      yield jsonDecode(cache.toResponse(reqOptions).data)
          as Map<String, dynamic>;
    }

    try {
      final response = await _apiClient.dio.get(url);

      if ((response.statusCode ?? 0) >= 400) {
        if (!emittedFromCache) {
          yield* Stream.error(
              Exception('Server error ${response.statusCode}'));
        }
        return;
      }

      if (response.headers.map['etag']?.first != cache?.eTag) {
        Logger.i('SectionsRepository: yield fresh for $url (ETag changed)');
        yield jsonDecode(response.data) as Map<String, dynamic>;
      }
      // ETag unchanged → cached data is still current; no second yield.
    } on DioException catch (e) {
      Logger.e('SectionsRepository._fetchJsonData DioException: $e');
      if (!emittedFromCache) yield* Stream.error(e);
    } catch (e) {
      Logger.e('SectionsRepository._fetchJsonData failed: $e');
      if (!emittedFromCache) yield* Stream.error(e);
    }
  }

  @override
  Stream<List<String>> getYears() =>
      _fetchJsonData(_sectionsUrl).map((data) => List<String>.from(data.keys));

  @override
  Stream<List<String>> getSemesters(String year) =>
      _fetchJsonData(_sectionsUrl).map((data) {
        final yearData = data[year] as Map<String, dynamic>?;
        return yearData == null ? [] : List<String>.from(yearData.keys);
      });

  @override
  Stream<Map<String, String>> getSections(String year, String semester) =>
      _fetchJsonData(_sectionsUrl).map((data) {
        final semData = (data[year] as Map<String, dynamic>?)?[semester];
        return semData == null ? {} : Map<String, String>.from(semData as Map);
      });

  @override
  Stream<List<String>> getElectiveYears() =>
      _fetchJsonData(_electivesUrl)
          .map((data) => List<String>.from(data.keys));

  @override
  Stream<List<String>> getElectiveSemesters(String year) =>
      _fetchJsonData(_electivesUrl).map((data) {
        final yearData = data[year] as Map<String, dynamic>?;
        return yearData == null ? [] : List<String>.from(yearData.keys);
      });

  @override
  Stream<Map<String, String>?> getElectiveSchemes(
          String year, String semester) =>
      _fetchJsonData(_electivesUrl).map((data) {
        final semData = (data[year] as Map<String, dynamic>?)?[semester];
        return semData == null ? null : Map<String, String>.from(semData as Map);
      });
}
