# MVVM Migration — Pending Items

Tracked per `.claude/skills/flutter-mvvm-repo/SKILL.md`. One item per pass — no big-bang.

## Done
- [x] `lib/controllers/auth.dart` → `AuthRepository` + `AuthRepositoryImpl`; slim `LoginViewModel` (no `BuildContext`); `DeleteAccountPopup`, `LogoutButton`, `SettingsViewModel`, `AnalyticsController` updated; old controller deleted

## Pending

### HIGH
- [ ] `lib/controllers/version_controller.dart` — fat controller: direct Dio call, UI state (`isUpdateAvailable`, `isError`), snackbars, static `forcedRedirectPath` side-channel → split into `VersionService` (fetch + parse) + `VersionViewModel` (UI state); move `forcedRedirectPath` into proper router state
- [ ] `lib/controllers/analytics_controller.dart` — `ChangeNotifier` with Firebase Analytics calls, `Provider.of(context)` in `onReady()` → plain `AnalyticsService` (no `ChangeNotifier`, no `BuildContext`); constructor-inject `AuthRepository` + `FilterViewModel` instead of reading from context
- [ ] `lib/controllers/app_review_controller.dart` — Firebase InAppReview + `BuildContext` in logic, `lazy: false` at root → plain `AppReviewService`
- [ ] `lib/backend/models/in_app_review_model.dart` — model contains date-logic, `Provider` access, `BuildContext` → strip to dumb data class; move business logic to `AppReviewService`

### MEDIUM
- [ ] `lib/features/home/viewmodel/home_view_model.dart` — `onReady(BuildContext)` calls `_appTour.startAppTour(context)` and `_notifications.initialize(context)` → trigger side-effects from View after VM init; drop `BuildContext` param
- [ ] `lib/core/services/notification_service.dart` — `initialize(BuildContext)` shows dialogs and navigates → decouple dialog/navigation; trigger from View, not service
- [ ] `lib/controllers/app_preferences_controller.dart` — JSON encode/decode in controller; `notifyListeners()` on pure persistence writes → minor cleanup; consider moving JSON handling to a dedicated cache helper

### LOW
- [ ] `lib/features/campus_navigator/viewmodel/campus_navigator_view_model.dart` — constructor fires async `fetchItems()` → move to explicit `load()` called from View's `create:` lambda
