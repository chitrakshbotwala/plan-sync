## MVVM Pending Items — all resolved ✓

### Completed

**1. `DeleteAccountPopup` calls `AuthRepository` directly** — fixed: moved to `lib/features/settings/view/widgets/`, now calls `context.read<SettingsViewModel>().deleteAccount()`.

**2. `AnalyticsService` depends on `FilterViewModel` and `VersionViewModel`** — fixed: replaced with `AppPreferencesRepository` (for primary prefs) and `VersionService` (for version string).

**3. Old models in `lib/backend/models/`** — moved: timetable models → `lib/features/schedule/model/`, review + HUD models → `lib/core/models/`.

**4. `lib/widgets/` bottom-sheets/dropdowns/popups** — graduated: schedule widgets → `lib/features/schedule/view/widgets/`, elective widgets → `lib/features/electives/view/widgets/`, home sheets → `lib/features/home/view/widgets/`, delete popup → `lib/features/settings/view/widgets/`.