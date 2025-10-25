import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

final authServiceProvider = Provider((ref) => AuthService());

class AuthService {
  final FirebaseAuth _auth = FirebaseAuth.instance;

  User? get currentUser => _auth.currentUser;
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  Future<UserCredential> signInWithEmail(String email, String password) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Create Account
  Future<UserCredential> createAccount(String email, String password) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email,
        password: password,
      );
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Magic Link (Email Link)
  Future<void> sendMagicLink(String email) async {
    try {
      final acs = ActionCodeSettings(
        url: 'https://truelimbsmobileapp.page.link/auth',
        handleCodeInApp: true,
        androidPackageName: 'com.truelimbs.app.truelimbs',
        androidInstallApp: true,
        androidMinimumVersion: '1',
        // iOSBundleId: 'com.yourapp.ios',
      );

      await _auth.sendSignInLinkToEmail(email: email, actionCodeSettings: acs);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  Future<UserCredential> signInWithMagicLink(String email, String link) async {
    try {
      return await _auth.signInWithEmailLink(email: email, emailLink: link);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Reset Password
  Future<void> resetPassword(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
    } catch (e) {
      throw _handleAuthException(e);
    }
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
  }

  String _handleAuthException(dynamic e) {
    if (e is FirebaseAuthException) {
      switch (e.code) {
        case 'user-not-found':
          return 'No user found with this email';
        case 'wrong-password':
          return 'Wrong password';
        case 'email-already-in-use':
          return 'Email already in use';
        case 'weak-password':
          return 'Password is too weak';
        case 'invalid-email':
          return 'Invalid email address';
        default:
          return e.message ?? 'Authentication error';
      }
    }
    return e.toString();
  }
}

