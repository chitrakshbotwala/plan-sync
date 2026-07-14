import 'dart:io';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:firebase_crashlytics/firebase_crashlytics.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:plan_sync/features/auth/repository/auth_repository.dart';
import 'package:plan_sync/core/util/logger.dart';

class AuthRepositoryImpl implements AuthRepository {
  final _auth = FirebaseAuth.instance;

  // google_sign_in v7 exposes a singleton that must be initialized once
  // before any authenticate/signOut call.
  static Future<void>? _googleInit;
  Future<void> _ensureGoogleInitialized() {
    return _googleInit ??= GoogleSignIn.instance.initialize(
      serverClientId: dotenv.env['GOOGLE_SIGN_IN_SERVER_CLIENT_ID'] ??
          dotenv.env['WEB_FIREBASE_OPTIONS_CLIENT_ID'],
    );
  }

  @override
  User? get currentUser => _auth.currentUser;

  @override
  Stream<User?> authStateChanges() => _auth.authStateChanges();

  @override
  Future<void> loginWithGoogle() async {
    Logger.i('login using google');
    if (kIsWeb) {
      await FirebaseAuth.instance.signInWithPopup(GoogleAuthProvider());
      return;
    }

    try {
      await _ensureGoogleInitialized();
      final googleUser = await GoogleSignIn.instance.authenticate(
        scopeHint: ['profile', 'email'],
      );

      final credential = GoogleAuthProvider.credential(
        idToken: googleUser.authentication.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (currentUser != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(currentUser!.uid);
      }
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        Logger.e('google sign-in cancelled by the user');
        throw const AuthCancelledByUser();
      }
      FirebaseCrashlytics.instance.recordError(e, StackTrace.current);
      throw const AuthException('Team has been notified, try again later');
    } on AuthCancelledByUser {
      rethrow;
    } on FirebaseAuthException catch (e) {
      throw AuthException('${e.code} : ${e.message}');
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
      throw const AuthException('Team has been notified, try again later');
    }
  }

  @override
  Future<void> loginWithApple() async {
    final appleAuth = AppleAuthProvider()
      ..addScope('email')
      ..addScope('name');

    try {
      await FirebaseAuth.instance.signInWithProvider(appleAuth);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'web-context-canceled' || e.code == 'canceled') {
        throw const AuthCancelledByUser();
      }
      throw AuthException('${e.code} : ${e.message}');
    } catch (e, st) {
      FirebaseCrashlytics.instance.recordError(e, st);
      throw const AuthException('Team has been notified, try again later');
    }

    if (currentUser != null) {
      await FirebaseCrashlytics.instance.setUserIdentifier(currentUser!.uid);
    }
  }

  @override
  Future<void> logout() async {
    Logger.i('logout sequence');
    await _auth.signOut();
    await _ensureGoogleInitialized();
    await GoogleSignIn.instance.signOut();
    await FirebaseCrashlytics.instance.setUserIdentifier('');
  }

  @override
  Future<void> deleteCurrentUser() async {
    final provider =
        Platform.isAndroid ? GoogleAuthProvider() : AppleAuthProvider();

    UserCredential? authenticatedUser;
    try {
      authenticatedUser =
          await _auth.currentUser?.reauthenticateWithProvider(provider);
    } on FirebaseAuthException catch (e) {
      if (e.code == 'user-mismatch') {
        throw const DeleteAccountException(
          "We weren't able to verify your account, contact us to continue deletion.",
        );
      }
    }

    if (authenticatedUser == null) {
      throw const DeleteAccountException(
        "We weren't able to verify your account, try again.",
      );
    }

    try {
      await _auth.currentUser?.delete();
    } catch (err, trace) {
      if (kReleaseMode) {
        await FirebaseCrashlytics.instance.recordFlutterError(
          FlutterErrorDetails(
            exception: err,
            stack: trace,
          ),
        );
      }
      throw const DeleteAccountException(
          'We faced some error. Please try again later.');
    }
  }
}
