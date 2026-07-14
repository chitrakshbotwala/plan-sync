import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/util/snackbar.dart';
import 'package:toastification/toastification.dart';

enum _Type { info, error }

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  Future<void> pumpBaseWidget(
    WidgetTester tester,
    _Type type,
  ) async {
    return tester.pumpWidget(
      MaterialApp(
        home: ToastificationWrapper(
          child: Scaffold(
            body: Builder(
              builder: (ctx) => ElevatedButton(
                child: const Text('Open Snackbar'),
                onPressed: () => type == _Type.info
                    ? CustomSnackbar.info('foo title', 'foo message', ctx)
                    : CustomSnackbar.error(
                        'foo error title', 'foo error message', ctx),
              ),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets(
    'CustomSnackbar.info dispatches a toast without throwing',
    (WidgetTester tester) async {
      await pumpBaseWidget(tester, _Type.info);
      await tester.pump();

      await tester.tap(find.text('Open Snackbar'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
    },
  );

  testWidgets(
    'CustomSnackbar.error dispatches a toast without throwing',
    (WidgetTester tester) async {
      await pumpBaseWidget(tester, _Type.error);
      await tester.pump();

      await tester.tap(find.text('Open Snackbar'));
      await tester.pump(const Duration(milliseconds: 500));
      await tester.pumpAndSettle(const Duration(seconds: 6));
      expect(tester.takeException(), isNull);
    },
  );
}
