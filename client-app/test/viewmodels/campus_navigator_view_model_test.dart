import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/features/campus_navigator/model/campus_navigation_model.dart';
import 'package:plan_sync/features/campus_navigator/repository/campus_navigator_repository.dart';
import 'package:plan_sync/features/campus_navigator/viewmodel/campus_navigator_view_model.dart';

class FakeCampusNavigatorRepository implements CampusNavigatorRepository {
  int lastPage = -1;
  int itemsToReturn = 20;
  bool shouldThrow = false;

  @override
  Future<List<CampusNavigationModel>> getLocations({
    required int page,
    required int limit,
    String search = '',
  }) async {
    lastPage = page;
    if (shouldThrow) throw Exception('Network error');
    return List.generate(
      itemsToReturn,
      (i) => CampusNavigationModel(id: page * 100 + i, title: 'Location $i'),
    );
  }
}

void main() {
  late CampusNavigatorViewModel vm;
  late FakeCampusNavigatorRepository repository;

  setUp(() {
    repository = FakeCampusNavigatorRepository();
    vm = CampusNavigatorViewModel(repository: repository);
  });

  tearDown(() => vm.dispose());

  group('fetchItems', () {
    test('appends items to the list', () async {
      repository.itemsToReturn = 5;
      await vm.fetchItems();
      expect(vm.items.length, 5);
    });

    test('reset: true clears existing items and resets page', () async {
      repository.itemsToReturn = 20;
      await vm.fetchItems(); // page 0 → 20 items

      repository.itemsToReturn = 3;
      await vm.fetchItems(reset: true);

      expect(vm.items.length, 3);
    });

    test('isLoading is false after fetch completes', () async {
      await vm.fetchItems();
      expect(vm.isLoading, isFalse);
    });

    test('hasMore is false when fetched.length < limit (20)', () async {
      repository.itemsToReturn = 10;
      await vm.fetchItems();
      expect(vm.hasMore, isFalse);
    });

    test('hasMore stays true when fetched.length == limit', () async {
      repository.itemsToReturn = 20;
      await vm.fetchItems();
      expect(vm.hasMore, isTrue);
    });

    test('errorMessage is set when repository throws', () async {
      repository.shouldThrow = true;
      await vm.fetchItems();
      expect(vm.errorMessage, isNotNull);
      expect(vm.isLoading, isFalse);
    });

    test('errorMessage is null on successful fetch', () async {
      await vm.fetchItems();
      expect(vm.errorMessage, isNull);
    });
  });

  group('fetchNextPage', () {
    test('increments page and appends more items', () async {
      repository.itemsToReturn = 20;
      await vm.fetchItems(reset: true); // page 0
      final countAfterPage0 = vm.items.length;

      vm.fetchNextPage(); // page 1
      await Future.delayed(Duration.zero);

      expect(vm.items.length, greaterThan(countAfterPage0));
      expect(repository.lastPage, 1);
    });

    test('is no-op when hasMore is false', () async {
      repository.itemsToReturn = 5;
      await vm.fetchItems(reset: true);
      expect(vm.hasMore, isFalse);

      final countBefore = vm.items.length;
      vm.fetchNextPage();
      await Future.delayed(Duration.zero);

      expect(vm.items.length, countBefore);
    });
  });

  group('load', () {
    test('load() calls fetchItems with reset', () async {
      repository.itemsToReturn = 20;
      await vm.fetchItems(); // load page 0

      repository.itemsToReturn = 3;
      vm.load();
      await Future.delayed(Duration.zero);

      expect(vm.items.length, 3);
    });
  });
}
