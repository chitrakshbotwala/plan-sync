import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:plan_sync/core/util/crash_reporter.dart';
import 'package:firebase_remote_config/firebase_remote_config.dart';
import 'package:plan_sync/core/models/hud_notices_model.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';
import 'package:plan_sync/core/util/logger.dart';

class RemoteConfigServiceImpl implements RemoteConfigService {
  final remoteConfig = FirebaseRemoteConfig.instance;

  @override
  Future<void> onReady() async {
    await remoteConfig.setConfigSettings(
      RemoteConfigSettings(
        fetchTimeout: const Duration(seconds: 30),
        minimumFetchInterval: const Duration(minutes: kReleaseMode ? 60 : 1),
      ),
    );
    await remoteConfig.setDefaults({
      'hud_notice': '[]',
      'latest_ios_version': '',
      // TODO: Remove this temporary easter egg
      // ( The Sigma Male Loading Indicator )
      'can_show_sigma_status_indicator': false,
      // Empty by default → the attendance scraper uses the script baked into
      // the binary. Set this in the Firebase console to hot-patch the scraper.
      'sap_agent_script': '',
    });

    try {
      await remoteConfig.activate();
    } catch (exception, stack) {
      CrashReporter.recordError(exception, stack);
      Logger.w("Error activating remoteConfig.");
    }
    unawaited(
      remoteConfig
          .fetchAndActivate()
          .catchError((Object exception, StackTrace stack) {
        CrashReporter.recordError(exception, stack);
        Logger.w("Error fetching remoteConfig.");
        return false;
      }),
    );
  }

  @override
  List<HudNoticeModel> getNotices() {
    final val = remoteConfig.getString('hud_notice');

    if (val == '[]') {
      Logger.i('No HUD notices');
      return [];
    }

    List<HudNoticeModel> result = [];
    List data = jsonDecode(val) ?? [];

    for (Map instance in data) {
      result.add(HudNoticeModel.fromMap(instance));
    }

    return result;
  }

  @override
  String? latestIosVersion() {
    final value = remoteConfig.getString('latest_ios_version');
    return value == '' ? null : value;
  }

  // TODO: Remove this temporary easter egg
  // ( The Sigma Male Loading Indicator )
  @override
  bool canShowSigmaEmoji() {
    return remoteConfig.getBool('can_show_sigma_status_indicator');
  }

  @override
  String sapAgentScript() => remoteConfig.getString('sap_agent_script');
}
