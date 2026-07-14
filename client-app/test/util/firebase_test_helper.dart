import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_core_platform_interface/src/pigeon/messages.pigeon.dart';
import 'package:firebase_core_platform_interface/src/pigeon/test_api.dart';
import 'package:flutter_test/flutter_test.dart';

class _MockCoreHostApi implements TestFirebaseCoreHostApi {
  @override
  Future<CoreInitializeResponse> initializeApp(
    String appName,
    CoreFirebaseOptions initializeAppRequest,
  ) async {
    return CoreInitializeResponse(
      name: appName,
      options: initializeAppRequest,
      pluginConstants: <String?, Object?>{},
    );
  }

  @override
  Future<List<CoreInitializeResponse>> initializeCore() async {
    return [
      CoreInitializeResponse(
        name: '[DEFAULT]',
        options: _defaultOptions,
        pluginConstants: <String?, Object?>{},
      ),
    ];
  }

  @override
  Future<CoreFirebaseOptions> optionsFromResource() async => _defaultOptions;
}

CoreFirebaseOptions get _defaultOptions => CoreFirebaseOptions(
      apiKey: 'test-key',
      appId: 'test-app',
      messagingSenderId: '123',
      projectId: 'test-project',
    );

void setupFirebaseCoreMocks() {
  TestWidgetsFlutterBinding.ensureInitialized();
  TestFirebaseCoreHostApi.setUp(_MockCoreHostApi());
}

Future<void> ensureFirebaseInitialized() async {
  setupFirebaseCoreMocks();
  try {
    await Firebase.initializeApp(
      options: const FirebaseOptions(
        apiKey: 'test-key',
        appId: 'test-app',
        messagingSenderId: '123',
        projectId: 'test-project',
      ),
    );
  } catch (_) {
    // already initialized — ignore.
  }
}
