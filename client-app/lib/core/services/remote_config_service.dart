import 'package:plan_sync/core/models/hud_notices_model.dart';

abstract class RemoteConfigService {
  Future<void> onReady();
  List<HudNoticeModel> getNotices();
  String? latestIosVersion();
  bool canShowSigmaEmoji();
}
