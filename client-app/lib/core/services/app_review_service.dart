import 'dart:developer';

import 'package:in_app_review/in_app_review.dart';
import 'package:plan_sync/backend/models/in_app_review_model.dart';
import 'package:plan_sync/core/repositories/app_preferences_repository.dart';
import 'package:plan_sync/features/version/viewmodel/version_view_model.dart';

class AppReviewService {
  AppReviewService({
    required AppPreferencesRepository preferences,
    required VersionViewModel version,
  })  : _preferences = preferences,
        _version = version;

  final AppPreferencesRepository _preferences;
  final VersionViewModel _version;

  void initialize() async {
    final available = await InAppReview.instance.isAvailable();
    if (!available) {
      log('InAppReview not available');
      return;
    }
    log('InAppReview is available');
    Future.delayed(const Duration(seconds: 5), _showRatingsRequest);
  }

  Future<void> _showRatingsRequest() async {
    final isAvailable = await InAppReview.instance.isAvailable();
    if (!isAvailable) return;

    final reviewModel = _preferences.getAppReviewRequest();

    if (reviewModel == null) {
      log('No review model found');
      final cacheModel = InAppReviewCacheModel(
        firstOpen: DateTime.now().millisecondsSinceEpoch,
      );
      await _preferences.saveAppReviewRequest(cacheModel);
      return;
    }

    if (!shouldRequestReview(reviewModel)) {
      log('Review request conditions not met');
      return;
    }

    try {
      await InAppReview.instance.requestReview();
      log('Review requested successfully');
    } catch (e) {
      log('Error requesting review: $e');
    }
  }

  bool shouldRequestReview(InAppReviewCacheModel model) {
    final now = DateTime.now();
    final firstOpenDate = DateTime.fromMillisecondsSinceEpoch(model.firstOpen);
    final currentVersion = _version.clientVersion;

    // If app version has changed, allow prompt again
    if (model.lastAppVersion != null && model.lastAppVersion != currentVersion) {
      model.lastRequested = null;
      model.firstOpen = now.millisecondsSinceEpoch;
    }

    if (model.lastRequested == null) {
      // Only prompt if at least 7 days since first open
      if (now.difference(firstOpenDate).inDays >= 7) {
        _updateLastRequested(model);
        return true;
      }
      return false;
    }

    // Re-prompt every 30 days
    final lastRequestedDate =
        DateTime.fromMillisecondsSinceEpoch(model.lastRequested!);
    if (now.difference(lastRequestedDate).inDays >= 30) {
      _updateLastRequested(model);
      return true;
    }
    return false;
  }

  void _updateLastRequested(InAppReviewCacheModel model) {
    model.lastRequested = DateTime.now().millisecondsSinceEpoch;
    model.lastAppVersion = _version.clientVersion;
    _preferences.saveAppReviewRequest(model);
  }
}
