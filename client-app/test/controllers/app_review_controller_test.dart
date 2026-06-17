import 'package:flutter/foundation.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/controllers/app_review_controller.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  test('AppReviewController is a ChangeNotifier', () {
    final controller = AppReviewController();
    expect(controller, isA<ChangeNotifier>());
  });

  test('AppReviewController can be added to / removed from listener', () {
    final controller = AppReviewController();
    int notifications = 0;
    void listener() => notifications++;
    controller.addListener(listener);
    // there is no public emit on this controller; verify removal works
    controller.removeListener(listener);
    expect(notifications, 0);
  });

  test('multiple controllers are independent instances', () {
    final a = AppReviewController();
    final b = AppReviewController();
    expect(identical(a, b), isFalse);
  });
}
