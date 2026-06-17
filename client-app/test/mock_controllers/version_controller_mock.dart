import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/controllers/version_controller.dart';

class MockVersionController extends Mock
    with ChangeNotifier
    implements VersionController {
  bool updateResult = true;

  @override
  bool isUpdateAvailable = false;

  @override
  Future<void> onReady(BuildContext context) async {}

  @override
  Future<bool> checkForUpdate({required BuildContext context}) async {
    return updateResult;
  }
}
