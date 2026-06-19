import 'package:flutter/material.dart';
import 'package:mockito/mockito.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';

class MockVersionViewModel extends Mock
    with ChangeNotifier
    implements VersionViewModel {
  bool updateResult = true;

  @override
  bool isUpdateAvailable = false;

  @override
  Future<void> onReady(BuildContext context) async {}

  @override
  Future<bool> checkForUpdate() async {
    return updateResult;
  }
}
