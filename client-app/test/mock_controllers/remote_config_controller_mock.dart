import 'package:mockito/mockito.dart';
import 'package:plan_sync/core/models/hud_notices_model.dart';
import 'package:plan_sync/core/services/remote_config_service.dart';

class MockRemoteConfigController extends Mock implements RemoteConfigService {
  @override
  Future<void> onReady() async {}

  @override
  List<HudNoticeModel> getNotices() => [];

  @override
  String? latestIosVersion() => null;

  @override
  bool canShowSigmaEmoji() => false;
}
