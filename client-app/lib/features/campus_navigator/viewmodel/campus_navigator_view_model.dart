import 'package:easy_debounce/easy_debounce.dart';
import 'package:flutter/foundation.dart';
import 'package:plan_sync/features/campus_navigator/model/campus_navigation_model.dart';
import 'package:plan_sync/features/campus_navigator/repository/campus_navigator_repository.dart';
import 'package:plan_sync/util/logger.dart';

class CampusNavigatorViewModel extends ChangeNotifier {
  CampusNavigatorViewModel({required CampusNavigatorRepository repository})
      : _repository = repository;

  void load() => fetchItems(reset: true);

  final CampusNavigatorRepository _repository;
  final List<CampusNavigationModel> _items = [];
  List<CampusNavigationModel> get items => _items;

  bool isLoading = false;
  bool hasMore = true;
  String? errorMessage;
  int _page = 0;
  String _search = '';
  static const int _limit = 20;

  void onSearchChanged(String value) {
    EasyDebounce.debounce(
      'campusNavigatorSearch',
      const Duration(milliseconds: 400),
      () {
        _search = value;
        fetchItems(reset: true);
      },
    );
  }

  Future<void> fetchItems({bool reset = false}) async {
    if (isLoading) return;
    isLoading = true;
    if (reset) {
      _items.clear();
      _page = 0;
      hasMore = true;
    }
    errorMessage = null;
    notifyListeners();

    try {
      final fetched = await _repository.getLocations(
        page: _page,
        limit: _limit,
        search: _search,
      );
      if (fetched.length < _limit) hasMore = false;
      _items.addAll(fetched);
    } catch (e) {
      Logger.e('CampusNavigatorViewModel.fetchItems: $e');
      errorMessage = 'Could not load campus locations. Please try again.';
    } finally {
      isLoading = false;
      notifyListeners();
    }
  }

  void fetchNextPage() {
    if (!hasMore || isLoading) return;
    _page++;
    fetchItems();
  }
}
