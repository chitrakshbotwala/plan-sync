import 'dart:convert';
import 'package:plan_sync/core/cache/cache_service.dart';

class FakeCacheService implements CacheService {
  final Map<String, String> _store = {};

  Map<String, String> get store => Map.unmodifiable(_store);

  @override
  Future<void> initialize() async {}

  @override
  Future<T?> get<T>(
    String key, {
    required T Function(Map<String, dynamic> json) fromJson,
  }) async {
    final raw = _store[key];
    if (raw == null) return null;
    return fromJson(jsonDecode(raw) as Map<String, dynamic>);
  }

  @override
  Future<void> set<T>(
    String key,
    T value, {
    required Map<String, dynamic> Function(T value) toJson,
  }) async {
    _store[key] = jsonEncode(toJson(value));
  }

  @override
  Future<void> clear(String key) async => _store.remove(key);

  @override
  Future<void> clearAll() async => _store.clear();
}
