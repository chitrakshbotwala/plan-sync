---
name: flutter-mvvm-repo
description: >-
  Apply this app's lightweight MVVM + Repository architecture when working on Flutter
  code in plan_sync. Trigger when: refactoring an existing screen/widget; adding a new
  feature; or whenever the request mentions Provider, "spaghetti", fat/god widgets,
  ChangeNotifier doing API calls, business logic in build(), or untangling a controller.
  Encodes the View / ViewModel / Repository(interface+impl) / Service / Model layering,
  the Stream-based cache-then-refresh data contract, the Repository-vs-Service decision
  rule, folder structure, naming, and the incremental migration recipe — tuned to this
  app's real stack (provider, dio, hive, firebase, GitLab raw-file API). NOT full Clean
  Architecture: no use-cases, no domain/data model split, no DI framework.
---

# Flutter MVVM + Repository (plan_sync)

This app is being migrated **off** "spaghetti widget + Provider" (fat `ChangeNotifier`
controllers that fetch, cache, hold UI state, and get poked at directly from widgets)
**toward** a disciplined, lightweight MVVM + Repository setup. The target is "modular and
maintainable enough", not textbook-pure. Keep using `provider` for both state and DI.

The reference exemplar of the *problem* is `lib/controllers/git_service.dart` — a
`ChangeNotifier` that owns Dio, owns the cache, owns selected-year/semester UI state,
talks to `FilterController`, shows snackbars, and exposes `Stream<Timetable?>` methods that
widgets call from `StreamBuilder`. The schedule feature is the running example throughout
this skill; everything is shown as "what `GitService` becomes".

> **Read the non-goals (bottom of this file) before proposing structure.** They are the
> guardrails that keep this from drifting into over-engineering. Most "should I add a
> layer / wrapper / framework?" questions are already answered there: **no.**

## When to use this skill

- Refactoring an existing screen, widget, or controller (the common case).
- Adding a brand-new feature that fetches/displays domain data.
- Any request mentioning: Provider, spaghetti, fat widget, god object, "logic in
  `build()`", "controller does too much", `ChangeNotifier` calling Dio/Firebase directly.

If the task is a pure UI tweak with no data/logic involved, you usually don't need this —
just keep the View clean.

## The app's real stack (verify before assuming)

These are facts about this codebase as of writing — re-check if it's been a while:

- **State + DI:** `provider` (`ChangeNotifier`, `MultiProvider`, `Consumer`, `Selector`,
  `context.read/watch`). No GetX-for-state, no get_it/riverpod/injectable. `get` is in
  pubspec but **not** used for state/DI — do not start using it for that.
- **HTTP:** `dio`. GitLab "API" = raw files at
  `https://gitlab.com/delwinn/plan-sync/-/raw/<branch>/...` (e.g. `res/sections.json`,
  `res/<year>/<sem>/<section>.json`).
- **Caching today:** `dio_cache_interceptor` + `dio_cache_interceptor_hive_store` (ETag,
  Hive-backed, at the HTTP layer). `hive`, `shared_preferences`, `path_provider` are all
  present. Going forward, repository-level caching standardizes on a generic
  **`CacheService`** (Hive-backed) — see `references/core-infra.md`. The existing Dio
  cache interceptor may stay for endpoints already relying on ETag behaviour; migrate
  opportunistically, don't rip it out in one go.
- **Models:** hand-written plain Dart classes with `fromJson` / `toJson` (e.g.
  `lib/backend/models/timetable.dart`). **No** `freezed`, **no** `json_serializable`. Do
  not introduce codegen unless the user asks — match the existing hand-written style.
- **Auth:** `firebase_auth` + Google/Apple sign-in (`lib/controllers/auth.dart`).
- **Remote config:** `firebase_remote_config`, read synchronously as flat key/values
  (`lib/controllers/remote_config_controller.dart`).
- **Notifications:** `firebase_messaging` + `flutter_local_notifications`.
- **Logging / UX:** use the existing `Logger.i/w/e` (`lib/util/logger.dart`) and
  `CustomSnackbar` (`lib/util/snackbar.dart`). Don't reinvent.

## The four layers (+ Model)

| Layer | Type | Owns | Must NOT |
|-------|------|------|----------|
| **View** | `StatelessWidget` / `StatefulWidget` | layout, reading VM state via `watch`/`Consumer`/`Selector`, calling VM methods on user actions | hold business logic, call repos/Dio/Firebase, touch a `Stream` directly, decode JSON |
| **ViewModel** | `extends ChangeNotifier` | UI state for ONE screen (loading / error / data / form), subscribing to repo streams internally, `notifyListeners()` | import widgets, take `BuildContext` for logic, know about Dio/Hive/JSON, know about the cache |
| **Repository** | abstract `XRepository` + `XRepositoryImpl` | combining ONE domain's remote API + local cache; the cache-then-refresh policy; returning `Stream<T>` / `Future<T>` of **models** | hold UI state, call `notifyListeners`, import Flutter widgets, know about `BuildContext` |
| **Service** | concrete `XService` (no interface unless a real reason to swap) | a cross-cutting capability / side-effect (config, notifications, the `ApiClient`) | be forced into interface+impl just for symmetry |
| **Model** | plain Dart class + `fromJson`/`toJson` | one concept, one class | be split into separate "domain" vs "data" classes |

Rules that bite if ignored:

- **The View never touches a `Stream`.** Today widgets do `StreamBuilder(stream:
  service.getTimeTable(...))`. After migration the **ViewModel** owns the subscription and
  exposes plain getters (`schedule`, `isLoading`, `errorMessage`); the View reads those.
- **The ViewModel never knows about the cache or the network.** It calls
  `repository.getSchedule(...)` and reacts to emissions. Cache-then-refresh lives entirely
  in the repository.
- **The Repository never calls `notifyListeners()`** and isn't a `ChangeNotifier`. It's a
  plain object returning streams/futures of models.

## Repository vs Service — the decision rule (not just a table)

Ask: **"Is this domain data with a real fetch/cache lifecycle that a screen displays or
reacts to?"**

- **Yes → Repository** (abstract interface + `…Impl`). It has an entity, it's fetched,
  it's cached, a ViewModel subscribes to it and rebuilds UI from it.
  - `ScheduleRepository` — schedules are *the* domain data, fetched from GitLab, cached,
    streamed into the schedule screen. Textbook repository.
  - `AuthRepository` — the current session/user is genuine domain state with a
    cache-or-network shape (Firebase persists it, you read it on launch, it changes over
    time), **and** other repositories depend on it for auth tokens. So it's a repository,
    and it's wired early in the dependency graph (app root) so token-needing repos can
    depend on it.

- **No → Service** (concrete class, no interface unless you genuinely need to swap impls).
  Cross-cutting capability or side-effect with no domain entity of its own that a
  ViewModel would "subscribe to":
  - `RemoteConfigService` — a flat key/value snapshot from the Firebase SDK, read
    *synchronously* in many places (`isFeatureXEnabled()`). Nobody subscribes to it like a
    data stream; there's no `RemoteConfig` entity a screen renders a list of. Service.
  - `NotificationService` — permission prompts, FCM token registration, handling tap
    payloads. Mostly side effects. It may *call into* a repository to trigger a refresh,
    but it isn't one. Service.
  - `ApiClient` — the Dio wrapper + auth-token interceptor. Pure plumbing. Service.

Why this matters: forcing `RemoteConfigService` or `NotificationService` into an
interface+impl+Stream repository shape adds ceremony with zero payoff and makes the
codebase *harder* to read. The lifecycle test keeps each new addition classified
consistently. **When you add something new, write down which side of this rule it falls on
and why** (a one-line comment at the class is enough).

## Stream vs Future — picking the right return type

**The rule:** use `Stream<T>` only when you intend to emit **two values** — cached data
first, fresh network data second. If a method will ever only return one value, use
`Future<T>`.

| Use `Stream<T>` when… | Use `Future<T>` when… |
|---|---|
| Showing stale content immediately improves perceived performance (timetables, campus maps, long lists the user stares at) | Data is metadata / lookup values that the user never directly stares at (years list, semesters list, available sections) |
| The screen should re-render twice: once with cache, once with fresh | One result is all that's needed — either fresh (first load) or cached-fallback (network failure) |
| A stale → fresh transition is invisible or welcome (schedule updates silently in the background) | A stale → fresh transition would cause visible flicker or reset the user's current selection |

**In practice for this app:**
- `ScheduleRepository.getSchedule()` → `Stream<T>` — the timetable renders immediately
  from cache, then quietly updates if fresh data differs.
- `SectionsRepository.getYears/Semesters/Sections()` → `Future<T>` — these are dropdowns
  driven by user selection; the Dio `refreshForceCache` interceptor already handles
  cache-or-network, so a plain `Future` that returns one result is correct.

**Don't reach for `Stream<T>` just because data is cached.** The Dio interceptor's
`refreshForceCache` policy already provides cache-fallback behaviour for `Future`-based
methods: it hits the network and falls back to cache on failure. A `Stream` on top of
that adds a second emission and `StreamSubscription` lifecycle overhead for no UX gain.

## The cache-then-refresh contract (`Stream<T>` methods)

For repository methods that genuinely need dual-emission, use `async*` generators.
The contract:

1. Check local cache. If present → **emit it immediately** (fast first paint).
2. Call the network in the background.
3. On success → **update cache, emit fresh value** (second emission).
4. If cache was empty, the network result is the **first and only** emission.

**Error handling:**
- Cached value already emitted → swallow the network error (log it, don't re-emit).
  The View keeps showing cached data; it must never flash an error after rendering content.
- No cache + network fails → emit an error so the ViewModel can surface it.

```dart
// schedule_repository.dart
abstract class ScheduleRepository {
  Stream<List<ScheduleItem>> getSchedule({
    required String year,
    required String semester,
    required String section,
  });
}
```

```dart
// schedule_repository_impl.dart
@override
Stream<List<ScheduleItem>> getSchedule({
  required String year,
  required String semester,
  required String section,
}) async* {
  final cacheKey = 'schedule/$year/$semester/$section';
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

  try {
    final res = await _api.dio.get('/$year/$semester/$section.json');
    final fresh = (jsonDecode(res.data) as List)
        .map((e) => ScheduleItem.fromJson(e as Map<String, dynamic>))
        .toList();
    await _cache.set<List<ScheduleItem>>(
      cacheKey,
      fresh,
      toJson: (value) => value.map((e) => e.toJson()).toList(),
    );
    yield fresh;
  } catch (e, st) {
    Logger.e('ScheduleRepository.getSchedule failed: $e');
    if (!emittedFromCache) throw ScheduleFetchException('Could not load schedule', e, st);
  }
}
```

The ViewModel holds a `StreamSubscription`, subscribes internally, and exposes plain
getters. **Always cancel in `dispose()`.**

```dart
class ScheduleViewModel extends ChangeNotifier {
  final ScheduleRepository _repository;
  StreamSubscription<List<ScheduleItem>>? _sub;

  List<ScheduleItem> schedule = [];
  bool isLoading = false;
  String? errorMessage;

  void load({required String year, required String semester, required String section}) {
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
        notifyListeners();              // fires on cache emit AND on fresh emit
      },
      onError: (e) {
        isLoading = false;
        errorMessage = 'Could not load your schedule. Pull to retry.';
        notifyListeners();
      },
    );
  }

  @override
  void dispose() {
    _sub?.cancel();
    super.dispose();
  }
}
```

## Future-based repository methods

When the return type is `Future<T>`, the implementation is a straightforward async fetch.
The Dio `refreshForceCache` interceptor handles cache-fallback automatically — no manual
cache check needed in the repository.

```dart
// sections_repository.dart
abstract class SectionsRepository {
  Future<List<String>> getYears();
  Future<List<String>> getSemesters(String year);
  Future<Map<String, String>> getSections(String year, String semester);
}
```

```dart
// sections_repository_impl.dart
Future<Map<String, dynamic>> _fetchJsonData(String url) async {
  try {
    final response = await _apiClient.dio.get(url);
    return jsonDecode(response.data) as Map<String, dynamic>;
  } on DioException catch (e) {
    Logger.e('SectionsRepository._fetchJsonData DioException: $e');
    rethrow;
  }
}

@override
Future<List<String>> getYears() async {
  final data = await _fetchJsonData(_sectionsUrl);
  return List<String>.from(data.keys);
}
```

The ViewModel uses plain `async/await` + try-catch — **no `StreamSubscription` fields,
no `dispose()` override needed.**

```dart
Future<void> _loadYears() async {
  try {
    years = await _repository.getYears();
    _applyPrimaryYear();
    notifyListeners();
  } catch (e) {
    Logger.e('FilterViewModel._loadYears error: $e');
  }
}
```

Fire-and-forget from setters is fine — discard the returned `Future`:

```dart
set selectedYear(String? newYear) {
  if (newYear == null || _selectedYear == newYear) return;
  _selectedYear = newYear;
  _semesters = null;
  notifyListeners();
  _loadSemesters(); // fire-and-forget: Future discarded intentionally
}
```

## Caching: one generic `CacheService`

Repositories must not each reinvent read/write/serialize logic. They depend on a single
generic, Hive-backed abstraction:

```dart
abstract class CacheService {
  Future<T?> get<T>(String key, {required T Function(Object json) fromJson});
  Future<void> set<T>(String key, T value, {required Object Function(T value) toJson});
  Future<void> clear(String key);
  Future<void> clearAll();
}
```

Full Hive-backed impl, the `ApiClient` + auth-token interceptor, and the `AuthRepository`
sketch are in **`references/core-infra.md`**.

## Auth specifics

- `AuthRepository` (interface + impl) owns current session/user state and exposes it as a
  `Stream<AuthState>` (wrapping `FirebaseAuth.authStateChanges()`) plus a synchronous
  `AuthState get current`. ViewModels react to the stream like any other repository.
- A lower-level **`ApiClient`** (Dio + interceptor) attaches auth tokens to outgoing
  requests by reading from `AuthRepository`. **Token attachment lives in exactly one
  place** — no repository re-implements it. (Today's GitLab raw-file endpoints are public,
  but authenticated endpoints go through this interceptor.)

## Folder structure (feature-first)

Migrate toward this. New features go here from day one; old `lib/controllers` +
`lib/views` + `lib/backend/models` shrink as features move over.

```
lib/
  features/
    schedule/
      view/                 schedule_screen.dart, widgets/
      viewmodel/            schedule_view_model.dart
      repository/           schedule_repository.dart, schedule_repository_impl.dart
      model/                schedule_item.dart
    auth/
      view/
      viewmodel/
      repository/           auth_repository.dart, auth_repository_impl.dart
      model/                auth_state.dart
  core/
    services/               api_client.dart, remote_config_service.dart, notification_service.dart
    cache/                  cache_service.dart, hive_cache_service.dart
    models/                 shared models used by >1 feature (keep this small)
    util/                   logger.dart, snackbar.dart, ... (existing lib/util moves here over time)
```

- One feature folder per domain area; each is self-contained (`view`/`viewmodel`/
  `repository`/`model`).
- `core/` holds cross-cutting Services, the cache, the ApiClient, and truly shared models.
- The existing `lib/views/campus_navigator/` (already has its own `models/` + `widgets/`)
  is the closest thing to this today — model new features on it, then graduate it into
  `lib/features/campus_navigator/`.

## Naming conventions

- ViewModel: `XViewModel` (e.g. `ScheduleViewModel`).
- Repository: abstract `XRepository` + concrete `XRepositoryImpl`.
- Service: `XService`, **no** `Impl` suffix (unless it also gets an interface for a real
  swap reason, then mirror the repository convention).
- Model: noun for the concept (`ScheduleItem`, `AuthState`).

## Providing dependencies (where each thing is registered)

- **App-lifetime singletons → app root** (`main.dart`'s `MultiProvider`): `CacheService`,
  `ApiClient`, `AuthRepository`, `RemoteConfigService`, `NotificationService`. Order
  matters — register `CacheService`/`ApiClient` before `AuthRepository`, and
  `AuthRepository` before anything that needs tokens. Use plain `Provider` for
  repos/services (they're **not** `ChangeNotifier`); use `ChangeNotifierProvider` only for
  things that actually notify.
- **Per-screen ViewModels → at the point of use** (the route/screen), NOT globally:

  ```dart
  ChangeNotifierProvider(
    create: (context) => ScheduleViewModel(
      repository: context.read<ScheduleRepository>(),
    )..load(year: y, semester: s, section: sec),
    child: const ScheduleScreen(),
  )
  ```

- A feature repository that's used by one feature can also be provided at that feature's
  subtree rather than globally — keep global registration for genuinely app-wide things.

## Incremental migration recipe (this is a refactor, not greenfield)

Do **one screen/feature at a time**. Never attempt a big-bang rewrite. Untouched screens
keep working off the old `controllers/` exactly as-is until their turn.

**Step 0 — Classify.** Walk the existing fat `ChangeNotifier`/`StatefulWidget` and label
each piece:

| Smells like… | …goes to |
|---|---|
| `setState`, layout, `showDialog`, snackbars, reading state to render, `onTap` handlers | **View** |
| holding `isLoading`/error/data/selected-filter fields, deciding *when* to fetch, mapping repo data into display state | **ViewModel** |
| `dio.get`, JSON decode, cache read/write, ETag checks, combining remote+local, Firebase calls | **Repository** (or a **Service** if it's cross-cutting per the decision rule) |

**Step 1 — Extract the Repository first.** Pull data-fetching + caching out into a new (or
existing) `XRepository` + `XRepositoryImpl`, returning `Stream<T>`/`Future<T>` of models
using the cache-then-refresh contract above. This is where `GitService`'s `dio` + cache +
`Timetable.fromJson` logic lands as `ScheduleRepositoryImpl`.

**Step 2 — Slim the controller into a ViewModel.** Reduce the old `ChangeNotifier` to UI
state + calls into the repository + `notifyListeners()`. It subscribes to repo streams in
its `load()`/constructor and cancels in `dispose()`. Drop all Dio/JSON/cache knowledge and
all `BuildContext` business logic.

**Step 3 — Strip the View.** Reduce the widget to layout + reading VM getters via
`watch`/`Consumer`/`Selector` + calling VM methods. Delete `StreamBuilder(stream: repo...)`
— the VM holds the data now. No JSON, no Dio, no cache, no logic in `build()`.

**Step 4 — Wire providers.** App-lifetime repos/services to root; the new ViewModel
provided locally at that screen's route.

**Step 5 — Leave the rest alone.** Other screens still using the old controllers are fine.
Migrate them in later passes.

**Handling the global `MultiProvider` in `main.dart` during transition:** it currently
registers every controller globally. That's OK temporarily. As you migrate:
- App-lifetime repositories/services (`AuthRepository`, `CacheService`, `ApiClient`,
  `RemoteConfigService`, `NotificationService`) can be added to the root provider list
  immediately — even before all their consumers are migrated.
- Each per-screen ViewModel moves **out** of the global list and **into** its screen's
  route as that screen is migrated. Remove the old controller from the global list only
  once nothing reads it anymore.

See **`references/running-example.md`** for the concrete before/after of the schedule
screen end to end, and **`references/core-infra.md`** for `CacheService`, `ApiClient`, and
`AuthRepository` implementations.

## Non-goals (read this — it's the anti-over-engineering guardrail)

- **No use-case / interactor layer** between ViewModel and Repository. The ViewModel calls
  the repository directly.
- **No separate domain-entity vs data-model split.** One model class per concept, with
  `fromJson`/`toJson`. (`Timetable` is `Timetable` everywhere.)
- **No DI framework** — no get_it, riverpod, injectable, etc. `provider` does both state
  and DI. (`get` exists in pubspec but is not the DI tool — don't adopt it as one.)
- **No `freezed`/`json_serializable`** unless the user explicitly asks — match the
  existing hand-written model style.
- **No `Resource<T>` / sealed state wrapper** around stream emissions. Plain `Stream<T>`.
  (Use a model flag like `Timetable.isFresh` if a screen must distinguish cached vs fresh —
  that's already the app's pattern.)
- **Don't force cross-cutting concerns into the Repository interface+impl shape.** Remote
  config and notifications are Services. Only domain data with a real fetch/cache lifecycle
  gets the repository treatment.
- **Don't big-bang.** One feature per pass; leave the rest on the old controllers.
