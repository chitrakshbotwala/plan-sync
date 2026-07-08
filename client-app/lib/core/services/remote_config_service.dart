import 'package:plan_sync/core/models/hud_notices_model.dart';

abstract class RemoteConfigService {
  Future<void> onReady();
  List<HudNoticeModel> getNotices();
  String? latestIosVersion();
  bool canShowSigmaEmoji();

  /// The KIIT attendance scraper agent script, served from Remote Config so it
  /// can be patched without shipping an app update when the SAP portal's DOM
  /// changes. Returns an empty string when unset/unfetched — callers must then
  /// fall back to the script baked into the app binary.
  String sapAgentScript();
}
