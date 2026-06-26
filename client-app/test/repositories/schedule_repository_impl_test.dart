import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository_impl.dart';
import '../helpers/fake_api_client.dart';
import '../helpers/fake_cache_service.dart';

void main() {
  group('ScheduleRepositoryImpl', () {
    const year = '2024';
    const semester = 'SEM1';
    const section = 'A16';
    const cacheKey = 'schedule/$year/$semester/$section';

    test('cache miss + network success: emits one fresh item and stores in cache',
        () async {
      final cache = FakeCacheService();
      final repo = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );

      final items = await repo
          .getSchedule(year: year, semester: semester, section: section)
          .toList();

      expect(items.length, 1);
      expect(items.first!.isFresh, isTrue);
      expect(items.first!.meta.section, 'b16');
      expect(cache.store.containsKey(cacheKey), isTrue);
    });

    test('cache hit + network success: emits cached first then fresh', () async {
      final cache = FakeCacheService();
      final repo1 = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      // Populate cache
      await repo1
          .getSchedule(year: year, semester: semester, section: section)
          .toList();

      // Second call — should emit cached (isFresh=false) then fresh (isFresh=true)
      final repo2 = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      final items = await repo2
          .getSchedule(year: year, semester: semester, section: section)
          .toList();

      expect(items.length, 2);
      expect(items[0]!.isFresh, isFalse);
      expect(items[1]!.isFresh, isTrue);
    });

    test('cache miss + DioException: stream emits error', () async {
      final cache = FakeCacheService();
      final repo = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWithError(),
        cache: cache,
      );

      await expectLater(
        repo.getSchedule(year: year, semester: semester, section: section),
        emitsError(isA<Exception>()),
      );
    });

    test('cache hit + DioException: emits cached item, no error propagated',
        () async {
      final cache = FakeCacheService();
      // Populate cache first
      final repo1 = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      await repo1
          .getSchedule(year: year, semester: semester, section: section)
          .toList();

      // Second call with network error — should silently emit cached only
      final repo2 = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWithError(),
        cache: cache,
      );
      final items = await repo2
          .getSchedule(year: year, semester: semester, section: section)
          .toList();

      expect(items.length, 1);
      expect(items.first!.isFresh, isFalse);
    });

    test('cache miss + HTTP 4xx: stream emits error', () async {
      final cache = FakeCacheService();
      final repo = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: '', statusCode: 404),
        cache: cache,
      );

      await expectLater(
        repo.getSchedule(year: year, semester: semester, section: section),
        emitsError(isA<Exception>()),
      );
    });

    test('cache hit + HTTP 4xx: emits cached item, no error propagated',
        () async {
      final cache = FakeCacheService();
      final repo1 = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      await repo1
          .getSchedule(year: year, semester: semester, section: section)
          .toList();

      final repo2 = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: '', statusCode: 404),
        cache: cache,
      );
      final items = await repo2
          .getSchedule(year: year, semester: semester, section: section)
          .toList();

      expect(items.length, 1);
      expect(items.first!.isFresh, isFalse);
    });

    test('fetched data is round-tripped through cache correctly', () async {
      final cache = FakeCacheService();
      final repo1 = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWith(responseBody: encodeTimetableJson()),
        cache: cache,
      );
      await repo1
          .getSchedule(year: year, semester: semester, section: section)
          .toList();

      expect(cache.store.containsKey(cacheKey), isTrue);

      // A fresh repo using the same cache should recover the data
      final repo2 = ScheduleRepositoryImpl(
        apiClient: fakeApiClientWithError(),
        cache: cache,
      );
      final items = await repo2
          .getSchedule(year: year, semester: semester, section: section)
          .toList();
      expect(items.first!.meta.section, 'b16');
    });
  });
}
