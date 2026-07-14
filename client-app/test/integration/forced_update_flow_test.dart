import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/version/view/forced_update_screen.dart';

void main() {
  Future<void> pumpForcedUpdate(WidgetTester tester) async {
    await tester.pumpWidget(
      MaterialApp(
        theme: ThemeService.lightTheme,
        home: const ForcedUpdateScreen(),
      ),
    );
    await tester.pump(); // Lottie schedules a frame; avoid pumpAndSettle.
  }

  testWidgets('renders the update message and the Update Now button',
      (tester) async {
    await pumpForcedUpdate(tester);

    expect(find.text('Important System Update Available'), findsOneWidget);
    expect(find.textContaining('new'), findsWidgets);
    expect(find.text('Update Now'), findsOneWidget);
    expect(find.byType(FilledButton), findsOneWidget);
  });
}
