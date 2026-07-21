import 'package:dio/dio.dart';
import 'package:dio_cache_interceptor/dio_cache_interceptor.dart';
import 'package:dio_cache_interceptor_hive_store/dio_cache_interceptor_hive_store.dart';
import 'package:flutter/foundation.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plan_sync/core/util/logger.dart';

class ApiClient {
  late final Dio dio;
  CacheOptions? cacheOptions;

  // Base URL of the relay API that fronts the plan-sync data repo. Override
  // with --dart-define=RELAY_BASE_URL=... for staging/prod builds.
  static const String baseUrl =
      String.fromEnvironment('RELAY_BASE_URL', defaultValue: 'http://localhost:8080');

  ApiClient() {
    dio = Dio(
      BaseOptions(
        connectTimeout: const Duration(seconds: 15),
        headers: {'Cache-Control': 'no-cache'},
        contentType: 'application/json',
        // The relay returns real `application/json` Content-Type headers
        // (unlike GitLab's raw files, served as text/plain), which would
        // make Dio auto-decode the body. Force plain-string responses so
        // the existing manual `jsonDecode(response.data)` call sites keep
        // working unchanged.
        responseType: ResponseType.plain,
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
