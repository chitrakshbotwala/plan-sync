import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository_impl.dart';
import '../helpers/fake_api_client.dart';

void main() {
  SectionsRepositoryImpl buildRepo() {
    return SectionsRepositoryImpl(
      apiClient: fakeApiClientByUrl({
        '/api/v1/sections': encodeSectionsJson(),
        '/api/v1/electives-index': encodeElectivesJson(),
      }),
    );
  }

  group('SectionsRepositoryImpl', () {
    group('getYears', () {
      test('returns top-level keys from sections JSON', () async {
        final years = await buildRepo().getYears();
        expect(years, containsAll(['2024', '2023']));
      });
    });

    group('getSemesters', () {
      test('returns semester keys for a known year', () async {
        final semesters = await buildRepo().getSemesters('2024');
        expect(semesters, containsAll(['SEM1', 'SEM2']));
      });

      test('returns empty list for unknown year', () async {
        final semesters = await buildRepo().getSemesters('1999');
        expect(semesters, isEmpty);
      });
    });

    group('getSections', () {
      test('returns section code→name map for known year+semester', () async {
        final sections = await buildRepo().getSections('2024', 'SEM1');
        expect(sections, {'A16': 'A-16', 'B16': 'B-16'});
      });

      test('returns empty map for missing semester', () async {
        final sections = await buildRepo().getSections('2024', 'SEM9');
        expect(sections, isEmpty);
      });

      test('returns empty map for missing year', () async {
        final sections = await buildRepo().getSections('1999', 'SEM1');
        expect(sections, isEmpty);
      });
    });

    group('getElectiveSchemes', () {
      test('returns scheme map for known year+semester', () async {
        final schemes = await buildRepo().getElectiveSchemes('2024', 'SEM1');
        expect(schemes, {'a': 'Scheme A', 'b': 'Scheme B'});
      });

      test('returns null for missing year', () async {
        final schemes = await buildRepo().getElectiveSchemes('1999', 'SEM1');
        expect(schemes, isNull);
      });

      test('returns null for missing semester', () async {
        final schemes = await buildRepo().getElectiveSchemes('2024', 'SEM9');
        expect(schemes, isNull);
      });
    });

    group('error propagation', () {
      test('DioException from _fetchJsonData is rethrown as a Future error',
          () async {
        final repo = SectionsRepositoryImpl(apiClient: fakeApiClientWithError());
        expect(repo.getYears(), throwsA(isA<Exception>()));
      });
    });
  });
}
