import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:plan_sync/core/services/theme_service.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/features/auth/view/login_screen.dart';
import 'package:plan_sync/features/auth/viewmodel/login_view_model.dart';
import 'package:provider/provider.dart';

/// Configurable auth fake: succeed, throw [AuthException], or simulate the
/// user cancelling the OS auth sheet ([AuthCancelledByUser]).
class _FakeAuth implements AuthRepository {
  bool throwCancelled = false;
  bool throwAuthException = false;
  String message = 'Invalid credentials';
  Duration loginDelay = Duration.zero;
  int googleCalls = 0;
  int appleCalls = 0;

  @override
  User? get currentUser => null;

  @override
  Stream<User?> authStateChanges() => const Stream.empty();

  Future<void> _run() async {
    if (loginDelay > Duration.zero) await Future.delayed(loginDelay);
    if (throwCancelled) throw const AuthCancelledByUser();
    if (throwAuthException) throw AuthException(message);
  }

  @override
  Future<void> loginWithGoogle() async {
    googleCalls++;
    await _run();
  }

  @override
  Future<void> loginWithApple() async {
    appleCalls++;
    await _run();
  }

  @override
  Future<void> logout() async {}

  @override
  Future<void> deleteCurrentUser() async {}
}

void main() {
  late _FakeAuth auth;

  setUp(() {
    auth = _FakeAuth();
  });

  Future<void> pumpLogin(WidgetTester tester) async {
    await tester.pumpWidget(
      MultiProvider(
        providers: [
          ChangeNotifierProvider<ThemeService>(create: (_) => ThemeService()),
          ChangeNotifierProvider<LoginViewModel>(
            create: (_) => LoginViewModel(repository: auth),
          ),
        ],
        child: MaterialApp(
          theme: ThemeService.lightTheme,
          home: const LoginScreen(),
        ),
      ),
    );
    await tester.pumpAndSettle();
  }

  testWidgets('renders both auth buttons and the tagline', (tester) async {
    await pumpLogin(tester);

    expect(find.text('Continue with Google'), findsOneWidget);
    expect(find.text('Continue with Apple'), findsOneWidget);
    expect(find.textContaining('Synchronize'), findsOneWidget);
  });

  testWidgets('tapping Google logs in with no error snackbar', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(auth.googleCalls, 1);
    expect(find.text('Authentication Error'), findsNothing);
  });

  testWidgets('tapping Apple logs in with no error snackbar', (tester) async {
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Apple'));
    await tester.pumpAndSettle();

    expect(auth.appleCalls, 1);
    expect(find.text('Authentication Error'), findsNothing);
  });

  testWidgets('AuthException surfaces an error snackbar', (tester) async {
    auth.throwAuthException = true;
    auth.message = 'Account disabled';
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Authentication Error'), findsOneWidget);
    expect(find.text('Account disabled'), findsOneWidget);

    // Drain the snackbar auto-dismiss timer so none stays pending.
    await tester.pump(const Duration(seconds: 5));
    await tester.pumpAndSettle();
  });

  testWidgets('user-cancelled login shows no error snackbar', (tester) async {
    auth.throwCancelled = true;
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pumpAndSettle();

    expect(find.text('Authentication Error'), findsNothing);
  });

  testWidgets('shows loading indicator while a login is in flight',
      (tester) async {
    auth.loginDelay = const Duration(milliseconds: 500);
    await pumpLogin(tester);

    await tester.tap(find.text('Continue with Google'));
    await tester.pump(); // isLoading == true, label swapped for dots

    // isLoading is shared, so both buttons swap their label for the
    // Semantics(value: 'Loading') dots indicator.
    expect(
      find.byWidgetPredicate(
        (w) => w is Semantics && w.properties.value == 'Loading',
      ),
      findsNWidgets(2),
    );
    expect(find.text('Continue with Google'), findsNothing);

    await tester.pumpAndSettle(); // let the delayed login resolve
    expect(find.text('Continue with Google'), findsOneWidget);
  });
}
