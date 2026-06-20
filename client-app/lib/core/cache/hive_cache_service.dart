import 'dart:convert';
import 'package:hive/hive.dart';
import 'package:path_provider/path_provider.dart';
import 'package:plan_sync/core/cache/cache_service.dart';
import 'package:plan_sync/core/util/logger.dart';

class HiveCacheService implements CacheService {
  static const _boxName = 'plan_sync_model_cache';
  late Box<String> _box;

  @override
  Future<void> initialize() async {
    final dir = await getApplicationDocumentsDirectory();
    _box = await Hive.openBox<String>(_boxName, path: dir.path);
  }

  @override
  Future<T?> get<T>(
    String key, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    try {
      final raw = _box.get(key);
      if (raw == null) return null;
      return fromJson(jsonDecode(raw) as Map<String, dynamic>);
    } catch (e) {
      Logger.e('HiveCacheService.get failed for key $key: $e');
      return null;
    }
  }

  @override
  Future<void> set<T>(
    String key,
    T value, {
    required Map<String, dynamic> Function(T value) toJson,
  }) async {
    try {
      await _box.put(key, jsonEncode(toJson(value)));
    } catch (e) {
      Logger.e('HiveCacheService.set failed for key $key: $e');
    }
  }

  @override
  Future<void> clear(String key) async {
    await _box.delete(key);
  }

  @override
  Future<void> clearAll() async {
    await _box.clear();
  }
}
