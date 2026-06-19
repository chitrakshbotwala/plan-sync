import 'package:plan_sync/backend/models/remote_config/hud_notices_model.dart';

abstract class RemoteConfigService {
  Future<void> onReady();
  List<HudNoticeModel> getNotices();
  String? latestIosVersion();
  bool canShowSigmaEmoji();
}
