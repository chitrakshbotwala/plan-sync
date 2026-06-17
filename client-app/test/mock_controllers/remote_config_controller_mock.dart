import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/backend/models/remote_config/hud_notices_model.dart';
import 'package:plan_sync/controllers/remote_config_controller.dart';

class MockRemoteConfigController extends Mock
    with ChangeNotifier
    implements RemoteConfigController {
  @override
  Future<void> onReady() async {}

  @override
  List<HudNoticeModel> getNotices() => [];

  @override
  String? latestIosVersion() => null;

  @override
  bool canShowSigmaEmoji() => false;
}
