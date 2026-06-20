import 'package:in_app_update/in_app_update.dart';
import 'package:package_info_plus/package_info_plus.dart';
import 'package:plan_sync/core/services/api_client.dart';
import 'package:plan_sync/core/util/logger.dart';

class VersionService {
  VersionService({required ApiClient apiClient}) : _apiClient = apiClient;

  final ApiClient _apiClient;

  Future<PackageInfo> getPackageInfo() => PackageInfo.fromPlatform();

  Future<String?> fetchMinVersion() async {
    try {
      final url =
          'https://gitlab.com/delwinn/plan-sync/-/raw/${_apiClient.branch}/min.version';
      final response = await _apiClient.dio.get(url);
      if ((response.statusCode ?? 0) >= 400 || response.data == '') {
        Logger.w('min.version from remote returned empty');
        return null;
      }
      return response.data as String;
    } catch (e) {
      Logger.w('min.version fetch failed: $e');
      return null;
    }
  }

  Future<AppUpdateInfo> checkAndroidUpdate() => InAppUpdate.checkForUpdate();

  bool immediateUpdateCondition(AppUpdateInfo info, String buildNumber) {
    // Perform immediate update when build gap > 5 (updatePriority API has been stale 4+ years)
    final difference = info.availableVersionCode! - int.parse(buildNumber);
    return difference > 5;
  }
}
