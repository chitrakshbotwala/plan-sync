abstract class CacheService {
  Future<void> initialize();
  Future<T?> get<T>(
    String key, {
    required T Function(Map<String, dynamic> json) fromJson,
  });
  Future<void> set<T>(
    String key,
    T value, {
    required Map<String, dynamic> Function(T value) toJson,
  });
  Future<void> clear(String key);
  Future<void> clearAll();
}
