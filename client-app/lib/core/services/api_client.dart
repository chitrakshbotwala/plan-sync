import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plan_sync/core/util/logger.dart';

class ApiClient {
  late final Dio dio;
  CacheOptions? cacheOptions;
  late final String branch;

  ApiClient() {
    // Timetable/section data (sections.json, per-section schedules) is served
    // from the GitLab data repo's `main` branch — that's where the live years
    // live (e.g. 2026-2027). Read `main` in every build so debug runs see the
    // same data as release instead of a stale `dev` snapshot missing newer
    // years.
    branch = 'main';
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        headers: {'Cache-Control': 'no-cache'},
        contentType: 'application/json',
      ),
    );
  }

  Future<void> initialize() async {
    if (kIsWeb) return;
    try {
      final dir = await getApplicationCacheDirectory();
      cacheOptions = CacheOptions(
        store: HiveCacheStore(dir.path, hiveBoxName: 'plan_sync'),
        policy: CachePolicy.refreshForceCache,
        hitCacheOnErrorExcept: [401, 403],
        maxStale: const Duration(days: 7),
        priority: CachePriority.high,
        keyBuilder: CacheOptions.defaultCacheKeyBuilder,
        allowPostMethod: false,
      );
      dio.interceptors.add(DioCacheInterceptor(options: cacheOptions!));
    } catch (e) {
      Logger.e('ApiClient.initialize failed: $e');
      rethrow;
    }
  }
}
