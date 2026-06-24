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
      final googleUser = await GoogleSignIn(
        scopes: ['profile', 'email'],
        clientId: dotenv.env['WEB_FIREBASE_OPTIONS_CLIENT_ID'],
      ).signIn();

      final googleAuth = await googleUser?.authentication;
      if (googleAuth == null) {
        Logger.e('googleAuth was null, login potentially cancelled by the user');
        throw const AuthCancelledByUser();
      }

      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
      if (currentUser != null) {
        await FirebaseCrashlytics.instance.setUserIdentifier(currentUser!.uid);
      }
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
    await GoogleSignIn().signOut();
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
