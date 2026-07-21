import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:plan_sync/core/util/logger.dart';

/// Thin wrapper over Crashlytics. firebase_crashlytics has no web
/// implementation, so on web every call degrades to a debug-only log.
class CrashReporter {
  const CrashReporter._();

  static Future<void> recordError(
    Object? error,
    StackTrace? stack, {
    String? reason,
    bool fatal = false,
  }) async {
    if (kIsWeb) {
      Logger.e('${reason == null ? '' : '$reason: '}$error');
      return;
    }
    try {
      await FirebaseCrashlytics.instance
          .recordError(error, stack, reason: reason, fatal: fatal);
    } catch (_) {/* telemetry must never throw */}
  }

  static Future<void> recordFlutterError(FlutterErrorDetails details) async {
    if (kIsWeb) {
      Logger.e(details.exceptionAsString());
      return;
    }
    try {
      await FirebaseCrashlytics.instance.recordFlutterError(details);
    } catch (_) {/* telemetry must never throw */}
  }

  static Future<void> setUserIdentifier(String identifier) async {
    if (kIsWeb) return;
    try {
      await FirebaseCrashlytics.instance.setUserIdentifier(identifier);
    } catch (_) {/* telemetry must never throw */}
  }
}
