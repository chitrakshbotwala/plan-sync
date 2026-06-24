import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_native_splash/flutter_native_splash.dart';
import 'package:go_router/go_router.dart';
import 'package:plan_sync/app_initializer.dart';
import 'package:plan_sync/core/cache/cache_service.dart';
import 'package:plan_sync/core/cache/hive_cache_service.dart';
import 'package:plan_sync/core/services/analytics_service.dart';
import 'package:plan_sync/core/services/app_review_service.dart';
import 'package:plan_sync/core/services/app_tour_service.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository_impl.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository.dart';
import 'package:plan_sync/features/attendance/repository/attendance_credentials_repository_impl.dart';
import 'package:plan_sync/features/attendance/view/attendance_screen.dart';
import 'package:plan_sync/features/attendance/viewmodel/attendance_view_model.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/features/auth/repository/auth_repository_impl.dart';
import 'package:plan_sync/features/campus_navigator/repository/campus_navigator_repository.dart';
import 'package:plan_sync/features/campus_navigator/repository/campus_navigator_repository_impl.dart';
import 'package:plan_sync/features/campus_navigator/viewmodel/campus_navigator_view_model.dart';
import 'package:plan_sync/features/filters/viewmodel/filter_view_model.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/core/services/notification_service.dart';
import 'package:plan_sync/core/services/version_service.dart';
import 'package:plan_sync/features/electives/repository/electives_repository.dart';
import 'package:plan_sync/features/electives/repository/electives_repository_impl.dart';
import 'package:plan_sync/features/electives/viewmodel/electives_view_model.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository.dart';
import 'package:plan_sync/features/schedule/repository/schedule_repository_impl.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository.dart';
import 'package:plan_sync/features/schedule/repository/sections_repository_impl.dart';
import 'package:plan_sync/features/home/viewmodel/home_view_model.dart';
import 'package:plan_sync/features/schedule/viewmodel/schedule_view_model.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';
import 'package:plan_sync/core/services/remote_config_service_impl.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';
import 'package:plan_sync/router_refresh_stream.dart';
import 'package:plan_sync/features/campus_navigator/view/campus_navigator_view.dart';
import 'package:plan_sync/features/electives/view/electives_screen.dart';
import 'package:plan_sync/features/version/view/forced_update_screen.dart';
import 'package:plan_sync/features/home/view/home_screen.dart';
import 'package:plan_sync/features/auth/view/login_screen.dart';
import 'package:plan_sync/features/auth/viewmodel/login_view_model.dart';
import 'package:plan_sync/features/settings/view/settings_screen.dart';
import 'package:plan_sync/features/settings/viewmodel/settings_view_model.dart';
import 'package:plan_sync/widgets/scaffold_with_nav_bar.dart';
import 'package:provider/provider.dart';
import 'package:toastification/toastification.dart';
import 'firebase_options.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

Future<void> main() async {
  final widgetsBinding = WidgetsFlutterBinding.ensureInitialized();
  FlutterNativeSplash.preserve(widgetsBinding: widgetsBinding);

  await dotenv.load(fileName: 'env/.prod.env');
  await Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  );

  await Supabase.initialize(
    url: dotenv.env['SUPABASE_URL']!,
    anonKey: dotenv.env['SUPABASE_ANON_KEY']!,
  );

  if (kReleaseMode) {
    FlutterError.onError = FirebaseCrashlytics.instance.recordFlutterFatalError;
    FirebaseCrashlytics.instance
        .setCustomKey("env", kReleaseMode ? "release" : "debug");
    PlatformDispatcher.instance.onError = (error, stack) {
      FirebaseCrashlytics.instance.recordError(error, stack, fatal: true);
      return true;
    };
  }

  runApp(const AppProvider());
}

class AppProvider extends StatelessWidget {
  const AppProvider({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        // Core infra — registered first; nothing depends on them in constructors
        Provider(create: (_) => ApiClient()),
        Provider<CacheService>(create: (_) => HiveCacheService()),
        Provider<AppPreferencesRepository>(
          create: (_) => AppPreferencesRepositoryImpl(),
        ),
        Provider<CampusNavigatorRepository>(
          create: (_) => CampusNavigatorRepositoryImpl(),
        ),
        // SectionsRepository needs ApiClient
        Provider<SectionsRepository>(
          create: (context) => SectionsRepositoryImpl(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        Provider(create: (_) => AppTourService()),
        // FilterViewModel needs SectionsRepository + AppPreferencesRepository + AppTourService
        ChangeNotifierProvider(
          create: (context) => FilterViewModel(
            sectionsRepository: context.read<SectionsRepository>(),
            preferences: context.read<AppPreferencesRepository>(),
            appTour: context.read<AppTourService>(),
          ),
        ),
        Provider<AuthRepository>(create: (_) => AuthRepositoryImpl()),
        Provider<RemoteConfigService>(
          create: (_) => RemoteConfigServiceImpl(),
        ),
        Provider(
          create: (context) => VersionService(
            apiClient: context.read<ApiClient>(),
          ),
        ),
        ChangeNotifierProvider(
          create: (context) => VersionViewModel(
            versionService: context.read<VersionService>(),
            remoteConfig: context.read<RemoteConfigService>(),
            preferences: context.read<AppPreferencesRepository>(),
          ),
        ),
        Provider(
          create: (context) => AnalyticsService(
            auth: context.read<AuthRepository>(),
            preferences: context.read<AppPreferencesRepository>(),
            versionService: context.read<VersionService>(),
          ),
        ),
        ChangeNotifierProvider(create: (_) => ThemeService()),
        Provider(create: (_) => NotificationService()),
        Provider(
          create: (context) {
            final service = AppReviewService(
              preferences: context.read<AppPreferencesRepository>(),
              version: context.read<VersionViewModel>(),
            );
            service.initialize();
            return service;
          },
          lazy: false,
        ),
        Provider<ScheduleRepository>(
          create: (context) => ScheduleRepositoryImpl(
            apiClient: context.read<ApiClient>(),
            cache: context.read<CacheService>(),
          ),
        ),
        Provider<ElectivesRepository>(
          create: (context) => ElectivesRepositoryImpl(
            apiClient: context.read<ApiClient>(),
            cache: context.read<CacheService>(),
          ),
        ),
        // Attendance: credentials repo + view-model are app-lifetime so both
        // the Attendance tab and the Settings screen can access them.
        Provider<AttendanceCredentialsRepository>(
          create: (_) => AttendanceCredentialsRepositoryImpl(),
        ),
        ChangeNotifierProvider<AttendanceViewModel>(
          create: (context) => AttendanceViewModel(
            credentialsRepository:
                context.read<AttendanceCredentialsRepository>(),
          ),
        ),
      ],
      child: const MainApp(),
    );
  }
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Future<void> _initializationFuture;

  @override
  void initState() {
    super.initState();
    _initializationFuture = _initialize();
  }

  Future<void> _initialize() async {
    try {
      await AppInitializer.initializeApp(context);
    } finally {
      // Remove splash screen once initialization is done, even if there's an error
      FlutterNativeSplash.remove();
    }
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<void>(
      future: _initializationFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Selector<ThemeService, ThemeMode>(
            selector: (context, controller) => controller.themeMode,
            builder: (context, mode, child) => MaterialApp(
              theme: ThemeService.lightTheme,
              darkTheme: ThemeService.darkTheme,
              themeMode: mode,
              home: const Scaffold(
                body: Center(
                  child: CircularProgressIndicator(),
                ),
              ),
            ),
          );
        }

        if (snapshot.hasError) {
          return Selector<ThemeService, ThemeMode>(
            selector: (context, controller) => controller.themeMode,
            builder: (context, mode, child) => MaterialApp(
              theme: ThemeService.lightTheme,
              darkTheme: ThemeService.darkTheme,
              themeMode: mode,
              home: Scaffold(
                body: Center(
                  child: Text('Error initializing app: ${snapshot.error}'),
                ),
              ),
            ),
          );
        }

        return ToastificationWrapper(
          config: ToastificationConfig(
            maxToastLimit: 2,
          ),
          child: Selector<ThemeService, ThemeMode>(
            builder: (context, mode, child) => MaterialApp.router(
              debugShowCheckedModeBanner: kDebugMode ? true : false,
              theme: ThemeService.lightTheme,
              darkTheme: ThemeService.darkTheme,
              themeMode: mode,
              routerDelegate: _router.routerDelegate,
              routeInformationParser: _router.routeInformationParser,
              routeInformationProvider: _router.routeInformationProvider,
            ),
            selector: (context, controller) => controller.themeMode,
          ),
        );
      },
    );
  }
}

// GoRouter configuration
final _router = GoRouter(
  refreshListenable: GoRouterRefreshStream(),
  redirect: (context, state) => redirectHandler(context, state),
  routes: [
    StatefulShellRoute.indexedStack(
      builder: (context, state, navigationShell) => ScaffoldWithNavBar(
        navigationShell: navigationShell,
      ),
      branches: [
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/',
              name: 'home_screen',
              builder: (context, state) => MultiProvider(
                providers: [
                  ChangeNotifierProvider<ScheduleViewModel>(
                    create: (ctx) => ScheduleViewModel(
                      repository: ctx.read<ScheduleRepository>(),
                      filterViewModel: ctx.read<FilterViewModel>(),
                      remoteConfig: ctx.read<RemoteConfigService>(),
                    ),
                  ),
                  ChangeNotifierProvider<HomeViewModel>(
                    create: (ctx) => HomeViewModel(
                      appTour: ctx.read<AppTourService>(),
                      appPreferences: ctx.read<AppPreferencesRepository>(),
                      remoteConfig: ctx.read<RemoteConfigService>(),
                      notifications: ctx.read<NotificationService>(),
                    ),
                  ),
                ],
                child: const HomeScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/attendance',
              name: 'attendance_screen',
              builder: (context, state) => const AttendanceScreen(),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/electives',
              name: 'electives_screen',
              builder: (context, state) => ChangeNotifierProvider<ElectivesViewModel>(
                create: (ctx) => ElectivesViewModel(
                  repository: ctx.read<ElectivesRepository>(),
                  filterViewModel: ctx.read<FilterViewModel>(),
                  preferences: ctx.read<AppPreferencesRepository>(),
                  remoteConfig: ctx.read<RemoteConfigService>(),
                ),
                child: const ElectiveScreen(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/navigator',
              name: 'navigator',
              builder: (context, state) => ChangeNotifierProvider(
                create: (ctx) => CampusNavigatorViewModel(
                  repository: ctx.read<CampusNavigatorRepository>(),
                )..load(),
                child: const CampusNavigatorView(),
              ),
            ),
          ],
        ),
        StatefulShellBranch(
          routes: <RouteBase>[
            GoRoute(
              path: '/settings',
              name: 'settings_screen',
              builder: (context, state) => ChangeNotifierProvider(
                create: (context) => SettingsViewModel(
                  auth: context.read<AuthRepository>(),
                  version: context.read<VersionViewModel>(),
                  analytics: context.read<AnalyticsService>(),
                ),
                child: const SettingsPage(),
              ),
            ),
          ],
        ),
      ],
    ),
    GoRoute(
      path: '/login',
      name: 'login_screen',
      builder: (context, state) => ChangeNotifierProvider(
        create: (context) =>
            LoginViewModel(repository: context.read<AuthRepository>()),
        child: const LoginScreen(),
      ),
    ),
    GoRoute(
      path: '/forced_update',
      name: 'forced_update',
      builder: (context, state) => const ForcedUpdateScreen(),
    ),
  ],
);

String? redirectHandler(BuildContext context, GoRouterState state) {
  // Handle notification route from terminated state
  final notifRoute = NotificationService.initialNotificationRoute;
  if (notifRoute != null && notifRoute != state.matchedLocation) {
    NotificationService.initialNotificationRoute = null; // Clear after use
    return notifRoute;
  }

  final auth = Provider.of<AuthRepository>(context, listen: false);

  if (auth.currentUser != null && state.matchedLocation == '/login') {
    return '/';
  }
  if (auth.currentUser == null) {
    return '/login';
  }

  AppPreferencesRepository perfs =
      Provider.of<AppPreferencesRepository>(context, listen: false);
  if (perfs.isAppBelowMinVersion() &&
      state.matchedLocation != '/forced_update') {
    return '/forced_update';
  }
  return null;
}
