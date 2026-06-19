import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/widgets/buttons/logout_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../main.dart';

void main() {
  Future<void> pumpBaseWidget(
    WidgetTester tester,
  ) async {
    return tester.pumpWidget(testApp(child: Scaffold(
        body: Center(
          child: LogoutButton(),
        ),
      ),
    ));
  }

  setUp(() async {
    SharedPreferences.setMockInitialValues({});
    await injectMockDependencies();
  });

  testWidgets('LogoutButton loads with icon', (WidgetTester tester) async {
    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    expect(find.text('Logout'), findsOneWidget);
    expect(find.byIcon(Icons.logout), findsOneWidget);
  });

  testWidgets('LogoutButton logs out user', (WidgetTester tester) async {
    await pumpBaseWidget(tester);
    await tester.pumpAndSettle();

    await mockAuth.loginWithGoogle();

    expect(mockAuth.currentUser, isNotNull);

    // start logout
    await tester.tap(find.text('Logout'));
    expect(mockAuth.currentUser, isNull);
  });
}
