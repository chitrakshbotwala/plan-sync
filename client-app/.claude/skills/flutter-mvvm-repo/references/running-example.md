# Running example: migrating the schedule screen

End-to-end before/after for the schedule feature — the same scenario used throughout
`SKILL.md`. The "before" is a condensed but faithful version of today's
`lib/controllers/git_service.dart` + `lib/widgets/time_table.dart`. The "after" is the
target `features/schedule/` layout.

---

## BEFORE — spaghetti: fat `ChangeNotifier` + `StreamBuilder` in the widget

A controller that owns Dio, the cache, UI selection state, JSON decoding, snackbars, and
exposes a `Stream` the widget consumes directly.

```dart
// controllers/git_service.dart  (condensed — see the real file for the full mess)
class GitService extends ChangeNotifier {
  late final Dio dio;
  CacheOptions? cacheOptions;

  String? selectedYear;          // UI selection state living in the "service"
  String? selectedSemester;
  bool isWorking = false;        // loading flag
  Map? errorDetails;             // error state

  Future<void> startCachingService() async { /* builds Dio + Hive cache interceptor */ }

  // Returns a Stream the WIDGET subscribes to. Decodes JSON. Reads cache. Sets isWorking.
  Stream<Timetable?> getTimeTable(FilterController filterController) async* {
    final section = filterController.activeSectionCode;
    final semester = filterController.activeSemester;
    if (section == null || semester == null || selectedYear == null) { yield null; return; }

    isWorking = true; notifyListeners();
    final url = "https://gitlab.com/delwinn/plan-sync/-/raw/$branch/res/$selectedYear/$semester/$section.json";
    try {
      final cache = await cacheOptions?.store?.get(/* key */);
      if (cache != null) {
        yield Timetable.fromJson(json: jsonDecode(cache.toResponse(...).data), isFresh: false);
      }
      final response = await dio.get(url);
      isWorking = false; notifyListeners();
      yield Timetable.fromJson(json: jsonDecode(response.data), isFresh: true);
    } on DioException catch (e) {
      errorDetails = {'message': 'Could not fetch timetable'};
      isWorking = false; notifyListeners();
      yield* Stream.error(Exception(errorDetails));
    }
  }
}
```

```dart
// widgets/time_table.dart  (condensed)
@override
Widget build(BuildContext context) {
  final service = Provider.of<GitService>(context);
  final filterController = Provider.of<FilterController>(context);
  return StreamBuilder<Timetable?>(                       // ← View owns the Stream
    stream: service.getTimeTable(filterController),       // ← View calls the data method
    builder: (context, snapshot) {
      if (snapshot.connectionState == ConnectionState.waiting) return const CircularProgressIndicator();
      if (snapshot.hasError) return Text('${snapshot.error}');     // ← raw error in UI
      final timetable = snapshot.data;
      if (timetable == null) return const Text('Pick a section');
      // ...100+ lines building DataTable rows from timetable.data, sorting, dialogs...
    },
  );
}
```

Problems: the View owns the `Stream` and calls the fetch; the "service" holds UI selection
state *and* loading/error flags *and* Dio *and* the cache *and* JSON decoding; errors reach
the UI as raw exception strings; nothing is unit-testable without a widget tree.

---

## AFTER — View / ViewModel / Repository

### Model — `features/schedule/model/schedule_item.dart`

Plain Dart, hand-written `fromJson`/`toJson` (matches existing `Timetable` style; no
codegen). Keep an `isFresh`-style flag here if the UI must show "showing cached data".

```dart
class ScheduleItem {
  final String day;
  final String startTime;
  final String endTime;
  final String subject;
  final String? room;

  const ScheduleItem({
    required this.day,
    required this.startTime,
    required this.endTime,
    required this.subject,
    this.room,
  });

  factory ScheduleItem.fromJson(Map<String, dynamic> json) => ScheduleItem(
        day: json['day'] as String,
        startTime: json['start_time'] as String,
        endTime: json['end_time'] as String,
        subject: json['subject'] as String,
        room: json['room'] as String?,
      );

  Map<String, dynamic> toJson() => {
        'day': day,
        'start_time': startTime,
        'end_time': endTime,
        'subject': subject,
        'room': room,
      };
}

class ScheduleFetchException implements Exception {
  final String message;
  final Object cause;
  final StackTrace stackTrace;
  ScheduleFetchException(this.message, this.cause, this.stackTrace);
  @override
  String toString() => 'ScheduleFetchException: $message';
}
```

### Repository — `features/schedule/repository/schedule_repository.dart`

```dart
abstract class ScheduleRepository {
  /// Emits cached schedule first (if any), then the fresh network value.
  /// Errors only if there was no cache AND the network failed.
  Stream<List<ScheduleItem>> getSchedule({
    required String year,
    required String semester,
    required String section,
  });
}
```

### Repository impl — `features/schedule/repository/schedule_repository_impl.dart`

The cache-then-refresh contract. This is the *only* place that knows about both the GitLab
API (`ApiClient`) and the cache (`CacheService`).

```dart
class ScheduleRepositoryImpl implements ScheduleRepository {
  ScheduleRepositoryImpl({required ApiClient api, required CacheService cache})
      : _api = api,
        _cache = cache;

  final ApiClient _api;
  final CacheService _cache;

  @override
  Stream<List<ScheduleItem>> getSchedule({
    required String year,
    required String semester,
    required String section,
  }) async* {
    final cacheKey = 'schedule/$year/$semester/$section';

    // 1. cache → emit immediately
    var emittedFromCache = false;
    final cached = await _cache.get<List<ScheduleItem>>(
      cacheKey,
      fromJson: (json) => (json as List)
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList(),
    );
    if (cached != null) {
      emittedFromCache = true;
      yield cached;
    }

    // 2 + 3. background refresh → update cache → emit fresh
    try {
      final res = await _api.dio.get('/$year/$semester/$section.json');
      final decoded = res.data is String ? jsonDecode(res.data) : res.data;
      final fresh = (decoded as List)
          .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
          .toList();

      await _cache.set<List<ScheduleItem>>(
        cacheKey,
        fresh,
        toJson: (value) => value.map((e) => e.toJson()).toList(),
      );
      yield fresh; // 4. first & only emission if cache was empty
    } catch (e, st) {
      Logger.e('ScheduleRepository.getSchedule failed: $e');
      if (!emittedFromCache) {
        throw ScheduleFetchException('Could not load schedule', e, st);
      }
      // had cache → swallow; the View keeps showing cached data, no error flash
    }
  }
}
```

### ViewModel — `features/schedule/viewmodel/schedule_view_model.dart`

Subscribes internally, exposes plain getters, notifies on every emission and on error,
cancels in `dispose()`. No widget imports, no `BuildContext` logic, no cache/Dio.

```dart
class ScheduleViewModel extends ChangeNotifier {
  ScheduleViewModel({required ScheduleRepository repository})
      : _repository = repository;

  final ScheduleRepository _repository;
  StreamSubscription<List<ScheduleItem>>? _sub;

  List<ScheduleItem> schedule = [];
  bool isLoading = false;
  String? errorMessage;

  bool get hasData => schedule.isNotEmpty;

  void load({
    required String year,
    required String semester,
    required String section,
  }) {
    _sub?.cancel();
    isLoading = true;
    errorMessage = null;
    notifyListeners();

    _sub = _repository
        .getSchedule(year: year, semester: semester, section: section)
        .listen(
      (items) {
        schedule = items;
        isLoading = false;
        errorMessage = null;
        notifyListeners(); // fires on cache emit AND fresh emit
      },
      onError: (Object e) {
        isLoading = false;
        errorMessage = 'Could not load your schedule. Pull to retry.';
        notifyListeners(); // notify on error too
      },
    );
  }

  void retry({
    required String year,
    required String semester,
    required String section,
  }) =>
      load(year: year, semester: semester, section: section);

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

### View — `features/schedule/view/schedule_screen.dart`

Layout + delegation only. Reads VM state via `Selector`/`Consumer`; calls VM methods. No
`Stream`, no Dio, no JSON, no logic in `build()`.

```dart
class ScheduleScreen extends StatelessWidget {
  const ScheduleScreen({
    super.key,
    required this.year,
    required this.semester,
    required this.section,
  });

  final String year;
  final String semester;
  final String section;

  @override
  Widget build(BuildContext context) {
    // ViewModel provided locally at the screen, fed the repository from the root.
    return ChangeNotifierProvider(
      create: (context) => ScheduleViewModel(
        repository: context.read<ScheduleRepository>(),
      )..load(year: year, semester: semester, section: section),
      child: const _ScheduleView(),
    );
  }
}

class _ScheduleView extends StatelessWidget {
  const _ScheduleView();

  @override
  Widget build(BuildContext context) {
    final vm = context.watch<ScheduleViewModel>();

    if (vm.isLoading && !vm.hasData) {
      return const Center(child: CircularProgressIndicator());
    }
    if (vm.errorMessage != null && !vm.hasData) {
      return _ErrorState(message: vm.errorMessage!, onRetry: () {
        // call back into the VM; screen-level args could come from a parent VM/route
        context.read<ScheduleViewModel>().retry(year: '2026', semester: 'sem1', section: 'A');
      });
    }
    return ListView.builder(
      itemCount: vm.schedule.length,
      itemBuilder: (context, i) => _ScheduleTile(item: vm.schedule[i]),
    );
  }
}
```

Note how the loading/error states key off `!vm.hasData` — that's the contract in action:
once cached data is showing, a failed refresh does **not** replace it with an error screen.

---

## What moved where (checklist applied)

| Old (`GitService` / `time_table.dart`) | New home |
|---|---|
| `dio.get`, `jsonDecode`, cache read/write, ETag check | `ScheduleRepositoryImpl` |
| `Timetable.fromJson` / model shape | `model/schedule_item.dart` |
| `isWorking`, `errorDetails`, selected year/semester | `ScheduleViewModel` fields |
| `StreamBuilder(stream: service.getTimeTable(...))` | VM subscribes; View reads `vm.schedule` |
| `CustomSnackbar.error(...)` from inside the service | View decides UX from `vm.errorMessage` |
| `notifyListeners()` scattered in the data method | only in the VM, on each emission/error |

`FilterController` (which holds the active year/semester/section selection) can be migrated
in its own later pass — e.g. into a `ScheduleFilterViewModel` or folded into
`ScheduleViewModel`. Until then it can stay a global controller and feed `load(...)` args.
