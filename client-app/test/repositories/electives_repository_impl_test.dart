import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/electives/repository/electives_repository_impl.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/fake_cache_service.dart';

void main() {
  group('ElectivesRepositoryImpl', () {
    const year = '2024';
    const semester = 'SEM1';
    const schemeCode = 'a';
    const cacheKey = 'electives/$year/$semester/$schemeCode';

    test('cache miss + network success: emits one fresh item and stores in cache',
        () async {
      final cache = FakeCacheService();
      final repo = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );

      final items = await repo
          .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
          .toList();

      expect(items.length, 1);
      expect(items.first!.isFresh, isTrue);
      expect(cache.store.containsKey(cacheKey), isTrue);
    });

    test('cache hit + network success: emits cached first then fresh', () async {
      final cache = FakeCacheService();
      final repo1 = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      await repo1
          .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
          .toList();

      final repo2 = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      final items = await repo2
          .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
          .toList();

      expect(items.length, 2);
      expect(items[0]!.isFresh, isFalse);
      expect(items[1]!.isFresh, isTrue);
    });

    test('cache miss + DioException: stream emits error', () async {
      final cache = FakeCacheService();
      final repo = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWithError(),
        cache: cache,
      );

      await expectLater(
        repo.getTimetable(year: year, semester: semester, schemeCode: schemeCode),
        emitsError(isA<Exception>()),
      );
    });

    test('cache hit + DioException: emits cached item, no error propagated',
        () async {
      final cache = FakeCacheService();
      final repo1 = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      await repo1
          .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
          .toList();

      final repo2 = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWithError(),
        cache: cache,
      );
      final items = await repo2
          .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
          .toList();

      expect(items.length, 1);
      expect(items.first!.isFresh, isFalse);
    });

    test('empty response.data with no cache: no yield, no error', () async {
      final cache = FakeCacheService();
      final repo = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: ''),
        cache: cache,
      );

      final items = await repo
          .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
          .toList();

      expect(items, isEmpty);
    });

    test('empty response.data with cache hit: yields cached only', () async {
      final cache = FakeCacheService();
      final repo1 = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      await repo1
          .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
          .toList();

      final repo2 = ElectivesRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: ''),
        cache: cache,
      );
      final items = await repo2
          .getTimetable(year: year, semester: semester, schemeCode: schemeCode)
          .toList();

      expect(items.length, 1);
      expect(items.first!.isFresh, isFalse);
    });
  });
}
