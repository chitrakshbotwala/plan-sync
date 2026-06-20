import 'dart:io';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';
import 'package:plan_sync/core/services/version_service.dart';
import 'package:plan_sync/core/util/app_version.dart';
import 'package:plan_sync/core/util/external_links.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:plan_sync/core/util/logger.dart';
import 'package:plan_sync/widgets/popups/popups_wrapper.dart';

class VersionViewModel extends ChangeNotifier {
  VersionViewModel({
    required VersionService versionService,
    required RemoteConfigService remoteConfig,
    required AppPreferencesRepository preferences,
  })  : _versionService = versionService,
        _remoteConfig = remoteConfig,
        _preferences = preferences;

  final VersionService _versionService;
  final RemoteConfigService _remoteConfig;
  final AppPreferencesRepository _preferences;

  late PackageInfo _packageInfo;

  String? _clientVersion;
  String? get clientVersion => _clientVersion;
  set clientVersion(String? newVersion) {
    if (newVersion == null) return;
    _clientVersion = newVersion;
    notifyListeners();
  }

  String? _appBuild;
  String? get appBuild => _appBuild;
  set appBuild(String? newVersion) {
    if (newVersion == null) return;
    _appBuild = newVersion;
    notifyListeners();
  }

  bool _isError = false;
  bool get isError => _isError;
  set isError(bool newValue) {
    _isError = newValue;
    notifyListeners();
  }

  bool _isUpdateAvailable = false;
  bool get isUpdateAvailable => _isUpdateAvailable;
  set isUpdateAvailable(bool newValue) {
    _isUpdateAvailable = newValue;
    notifyListeners();
  }

  Future<void> onReady(BuildContext context) async {
    _packageInfo = await _versionService.getPackageInfo();
    _logCurrentVersion();

    checkForUpdate().then((value) => isUpdateAvailable = value);

    if (!kDebugMode) {
      triggerPlayUpdate(context: context);
    }
    // awaited so min-version flag is set before the router first renders
    await verifyMinimumVersion();
  }

  void _logCurrentVersion() {
    Logger.i("App version: v${_packageInfo.version}");
    clientVersion = _packageInfo.version;
    appBuild = _packageInfo.buildNumber;
  }

  void openStore(BuildContext context) async {
    try {
      await ExternalLinks.store();
    } catch (e) {
      if (!context.mounted) return;
      CustomSnackbar.error(
        'Failed to open store',
        'Could not open the app store. Please try again.',
        context,
      );
    }
  }

  Future<bool> checkIosUpdate() async {
    final latestValue = _remoteConfig.latestIosVersion();
    if (latestValue == null) return false;

    _clientVersion ??= (await _versionService.getPackageInfo()).version;

    final latestVersion = AppVersion(latestValue);
    final currentVersion = AppVersion(_clientVersion!);

    Logger.i('Latest Remote App version: ${latestVersion.parts}');
    Logger.i('Current Client App version: ${currentVersion.parts}');

    return latestVersion.isGreaterThan(currentVersion);
  }

  Future<bool> checkForUpdate() async {
    if (kIsWeb) return false;

    if (Platform.isIOS) return await checkIosUpdate();

    isError = false;
    try {
      final AppUpdateInfo result = await _versionService.checkAndroidUpdate();
      return result.updateAvailability == UpdateAvailability.updateAvailable;
    } on PlatformException catch (err) {
      if (err.message != null && err.message!.contains('ERROR_APP_NOT_OWNED')) {
        Logger.w('App Not Owned on this Device.');
        return false;
      } else {
        isError = true;
        throw Exception("VersionViewModel.checkForUpdate Exception, $err");
      }
    } catch (e) {
      isError = true;
      throw Exception("VersionViewModel.checkForUpdate Exception, $e");
    }
  }

  Future<void> triggerPlayUpdate({required BuildContext context}) async {
    if (Platform.isIOS) return;

    final updateAvail = await _versionService.checkAndroidUpdate();

    if (updateAvail.immediateUpdateAllowed &&
        _versionService.immediateUpdateCondition(
            updateAvail, _packageInfo.buildNumber)) {
      Logger.i('starting immediate update');
      await InAppUpdate.performImmediateUpdate();
      Logger.i('immediate update installed');
    } else if (updateAvail.flexibleUpdateAllowed) {
      Logger.i('starting flex update');
      final AppUpdateResult result = await InAppUpdate.startFlexibleUpdate();
      Logger.i('flex update package downloaded');

      if (result == AppUpdateResult.success) {
        await InAppUpdate.completeFlexibleUpdate().onError((err, trace) {
          FirebaseCrashlytics.instance.recordError(err, trace);
          PopupsWrapper.showInAppUpateFailedPopup(context: context);
          return;
        });
        Logger.i('flex update package installed');
      }
    }
  }

  Future<void> verifyMinimumVersion() async {
    if (kIsWeb) return;

    final minVersion = await _versionService.fetchMinVersion();
    if (minVersion == null) {
      _preferences.saveIsAppBelowMinVersion(false);
      return;
    }

    if (_clientVersion == null) {
      Logger.w('clientVersion is null, skipping min version check');
      _preferences.saveIsAppBelowMinVersion(false);
      return;
    }

    if (int.parse(_clientVersion!.split('.')[0]) <
        int.parse(minVersion.split('.')[0])) {
      Logger.e('Current App Version is unsupported with database!');
      _preferences.saveIsAppBelowMinVersion(true);
      return;
    }

    _preferences.saveIsAppBelowMinVersion(false);
  }
}
