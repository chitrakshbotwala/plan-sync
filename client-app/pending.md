## MVVM Pending Items

### Low priority / minor

**5. `lib/util/` not yet moved to `lib/core/util/`**
`logger.dart`, `snackbar.dart`, etc. — the skill says migrate opportunistically, no rush.

**6. `RequestFeaturesPopup` has inline `isLoading` state + `ExternalLinks` call**
`lib/widgets/popups/request_features_popup.dart:17-47` — it's a form that calls a URL launcher utility. This is borderline; the `isLoading` is pure local UI state and `ExternalLinks` isn't a repository. Lowest priority, arguably acceptable as-is.

---

### Completed

**1. `DeleteAccountPopup` calls `AuthRepository` directly** — fixed: moved to `lib/features/settings/view/widgets/`, now calls `context.read<SettingsViewModel>().deleteAccount()`.

**2. `AnalyticsService` depends on `FilterViewModel` and `VersionViewModel`** — fixed: replaced with `AppPreferencesRepository` (for primary prefs) and `VersionService` (for version string).

**3. Old models in `lib/backend/models/`** — moved: timetable models → `lib/features/schedule/model/`, review + HUD models → `lib/core/models/`.

**4. `lib/widgets/` bottom-sheets/dropdowns/popups** — graduated: schedule widgets → `lib/features/schedule/view/widgets/`, elective widgets → `lib/features/electives/view/widgets/`, home sheets → `lib/features/home/view/widgets/`, delete popup → `lib/features/settings/view/widgets/`.