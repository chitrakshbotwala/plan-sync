# Core infrastructure: CacheService, ApiClient, AuthRepository, wiring

The shared plumbing in `lib/core/`. These are app-lifetime singletons provided once at the
root. All examples match the app's real stack: `hive`, `dio`, `firebase_auth`, `provider`,
hand-written models, `Logger`.

---

## CacheService — `core/cache/`

One generic, Hive-backed cache abstraction. Repositories call into this instead of each
reinventing read/write/serialization. Stores JSON-encoded strings in a single Hive box; the
caller supplies `fromJson`/`toJson` so the store stays type-agnostic.

```dart
// core/cache/cache_service.dart
abstract class CacheService {
  Future<T?> get<T>(String key, {required T Function(Object json) fromJson});
  Future<void> set<T>(String key, T value, {required Object Function(T value) toJson});
  Future<void> clear(String key);
  Future<void> clearAll();
}
```

```dart
// core/cache/hive_cache_service.dart
import 'dart:convert';
import 'package:hive/hive.dart';

class HiveCacheService implements CacheService {
  HiveCacheService._(this._box);

  static const _boxName = 'plan_sync_cache';
  final Box<String> _box;

  /// Call once during app init (after Hive.init / path_provider setup).
  static Future<HiveCacheService> init() async {
    final box = await Hive.openBox<String>(_boxName);
    return HiveCacheService._(box);
  }

  @override
  Future<T?> get<T>(String key, {required T Function(Object json) fromJson}) async {
    final raw = _box.get(key);
    if (raw == null) return null;
    try {
      return fromJson(jsonDecode(raw) as Object);
    } catch (e) {
      Logger.w('CacheService.get failed to decode "$key": $e');
      await _box.delete(key); // poison value → drop it
      return null;
    }
  }

  @override
  Future<void> set<T>(String key, T value, {required Object Function(T value) toJson}) async {
    await _box.put(key, jsonEncode(toJson(value)));
  }

  @override
  Future<void> clear(String key) => _box.delete(key);

  @override
  Future<void> clearAll() => _box.clear();
}
```

> Migration note: today schedules are cached at the HTTP layer via
> `dio_cache_interceptor_hive_store` (ETag-based). That can keep working for endpoints that
> rely on it. New/migrated repositories use `CacheService` for explicit, model-level
> caching. Don't run both for the same data — when you migrate a method to `CacheService`,
> stop reading its Dio-interceptor cache for that method.

---

## ApiClient — `core/services/api_client.dart`

A Service (plumbing, no domain entity). Wraps Dio with the GitLab raw base URL and a single
interceptor that attaches auth tokens by reading from `AuthRepository`. **No repository
re-implements token attachment.**

```dart
// core/services/api_client.dart
import 'package:dio/dio.dart';

class ApiClient {
  ApiClient({required AuthRepository auth, String? branch})
      : _auth = auth {
    final resolvedBranch = branch ?? (kReleaseMode ? 'main' : 'dev');
    dio = Dio(
      BaseOptions(
        baseUrl: 'https://gitlab.com/delwinn/plan-sync/-/raw/$resolvedBranch/res',
        connectTimeout: const Duration(seconds: 15),
        contentType: 'application/json',
      ),
    );
    dio.interceptors.add(
      InterceptorsWrapper(
        onRequest: (options, handler) async {
          // Public GitLab raw files need no token; authenticated endpoints do.
          final token = await _auth.idToken();
          if (token != null) {
            options.headers['Authorization'] = 'Bearer $token';
          }
          handler.next(options);
        },
      ),
    );
  }

  final AuthRepository _auth;
  late final Dio dio;
}
```

Repositories receive the `ApiClient` and call `_api.dio.get('/<path>.json')` against the
shared base URL. (You can also attach the existing `DioCacheInterceptor` here if you want
HTTP-level caching alongside `CacheService`.)

---

## AuthRepository — `features/auth/`

Auth is a **Repository** (interface + impl): the session/user is real domain state with a
cache-or-network shape, and other repos depend on it for tokens, so it's wired early at the
app root. It exposes a `Stream<AuthState>` (like any repository) plus a synchronous
`current` snapshot and an `idToken()` for the `ApiClient`.

```dart
// features/auth/model/auth_state.dart
class AuthState {
  final bool isAuthenticated;
  final String? uid;
  final String? email;
  final String? displayName;

  const AuthState({
    required this.isAuthenticated,
    this.uid,
    this.email,
    this.displayName,
  });

  const AuthState.unauthenticated() : this(isAuthenticated: false);
}
```

```dart
// features/auth/repository/auth_repository.dart
abstract class AuthRepository {
  /// Emits whenever the session changes (login, logout, token refresh boundaries).
  Stream<AuthState> authStateChanges();

  /// Synchronous current snapshot — for guards/redirects that can't await.
  AuthState get current;

  /// Used by ApiClient to attach tokens. Null when signed out.
  Future<String?> idToken();

  Future<void> signInWithGoogle();
  Future<void> signInWithApple();
  Future<void> signOut();
}
```

```dart
// features/auth/repository/auth_repository_impl.dart
import 'package:firebase_auth/firebase_auth.dart';

class AuthRepositoryImpl implements AuthRepository {
  AuthRepositoryImpl({FirebaseAuth? firebaseAuth})
      : _auth = firebaseAuth ?? FirebaseAuth.instance;

  final FirebaseAuth _auth;

  AuthState _map(User? user) => user == null
      ? const AuthState.unauthenticated()
      : AuthState(
          isAuthenticated: true,
          uid: user.uid,
          email: user.email,
          displayName: user.displayName,
        );

  @override
  Stream<AuthState> authStateChanges() => _auth.authStateChanges().map(_map);

  @override
  AuthState get current => _map(_auth.currentUser);

  @override
  Future<String?> idToken() => _auth.currentUser?.getIdToken() ?? Future.value(null);

  @override
  Future<void> signInWithGoogle() async {
    // move the existing Google flow from controllers/auth.dart here.
    // Repository surfaces failures by throwing; the ViewModel maps them to UI messages.
  }

  @override
  Future<void> signInWithApple() async {
    // move the existing Apple flow from controllers/auth.dart here.
  }

  @override
  Future<void> signOut() => _auth.signOut();
}
```

A `LoginViewModel` then subscribes to `authStateChanges()` (or just calls
`signInWithGoogle()` and reflects loading/error), exactly like `ScheduleViewModel`
subscribes to `getSchedule()`. Snackbars/dialogs stay in the View — the repository never
imports widgets or takes a `BuildContext`.

---

## RemoteConfigService & NotificationService — `core/services/` (Services, not Repositories)

Per the decision rule: cross-cutting capability / side-effect, no domain entity a VM
subscribes to. Concrete classes, no interface.

```dart
// core/services/remote_config_service.dart
class RemoteConfigService {
  final _rc = FirebaseRemoteConfig.instance;

  Future<void> init() async { /* setDefaults + fetchAndActivate (as today) */ }

  // Read synchronously wherever needed — this is why it's NOT a stream/repository.
  bool isFeatureEnabled(String key) => _rc.getBool(key);
  String stringValue(String key) => _rc.getString(key);
  List<HudNoticeModel> notices() { /* decode 'hud_notice' as today */ }
}
```

`NotificationService` similarly owns FCM permission prompts, token registration, and tap
payload routing. It may *call into* a repository to trigger a refresh, but it is not one.

---

## Wiring it all up — `main.dart`

App-lifetime singletons at the root, in dependency order. Plain `Provider` for
repos/services (not `ChangeNotifier`); `ChangeNotifierProvider` only for things that notify.
Per-screen ViewModels are provided locally at their routes (see
`running-example.md`), **not** here.

```dart
Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp(options: DefaultFirebaseOptions.currentPlatform);
  await Hive.initFlutter();

  final cache = await HiveCacheService.init();
  final authRepository = AuthRepositoryImpl();
  final apiClient = ApiClient(auth: authRepository);
  final remoteConfig = RemoteConfigService();
  await remoteConfig.init();

  runApp(MyApp(
    cache: cache,
    authRepository: authRepository,
    apiClient: apiClient,
    remoteConfig: remoteConfig,
  ));
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.cache,
    required this.authRepository,
    required this.apiClient,
    required this.remoteConfig,
  });

  final CacheService cache;
  final AuthRepository authRepository;
  final ApiClient apiClient;
  final RemoteConfigService remoteConfig;

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // order matters: cache + auth + apiClient before repos that need them
        Provider<CacheService>.value(value: cache),
        Provider<AuthRepository>.value(value: authRepository),
        Provider<ApiClient>.value(value: apiClient),
        Provider<RemoteConfigService>.value(value: remoteConfig),

        // feature repositories (plain Provider — not ChangeNotifier)
        Provider<ScheduleRepository>(
          create: (context) => ScheduleRepositoryImpl(
            api: context.read<ApiClient>(),
            cache: context.read<CacheService>(),
          ),
        ),

        // legacy controllers stay here until their screens are migrated:
        // ChangeNotifierProvider(create: (_) => FilterController()), ...
      ],
      child: const AppRouter(),
    );
  }
}
```

### Transition state of the global provider tree

- Add the new app-lifetime repos/services to this list **immediately**, even before all
  consumers are migrated.
- Keep old `controllers/*` entries in the list while any unmigrated screen still reads them.
- As each screen is migrated, move its ViewModel out of this list into its route, and
  delete the old controller entry once nothing references it.
