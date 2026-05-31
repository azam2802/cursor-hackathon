import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:google_sign_in/google_sign_in.dart';

import 'auth_error_messages.dart';

/// Thrown when authentication fails with a user-facing message.
class AuthException implements Exception {
  AuthException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Thrown when the user cancels a sign-in flow (e.g. Google popup dismissed).
class AuthCancelledException implements Exception {}

/// Wraps Firebase Auth and Google Sign-In for the SummerDrift app.
class AuthService {
  AuthService({FirebaseAuth? firebaseAuth})
      : _firebaseAuth = firebaseAuth ?? FirebaseAuth.instance,
        _authStateChanges = null,
        _currentUserOverride = null;

  /// Test-only constructor that avoids touching [FirebaseAuth.instance].
  @visibleForTesting
  AuthService.testing({
    required Stream<User?> authStateChanges,
    User? currentUser,
  })  : _firebaseAuth = null,
        _authStateChanges = authStateChanges,
        _currentUserOverride = currentUser;

  final FirebaseAuth? _firebaseAuth;
  final Stream<User?>? _authStateChanges;
  final User? _currentUserOverride;
  bool _googleSignInInitialized = false;

  FirebaseAuth get _auth => _firebaseAuth ?? FirebaseAuth.instance;

  Stream<User?> get authStateChanges =>
      _authStateChanges ?? _auth.authStateChanges();

  User? get currentUser =>
      _authStateChanges != null ? _currentUserOverride : _auth.currentUser;

  Future<void> _ensureGoogleSignInInitialized() async {
    if (_googleSignInInitialized) {
      return;
    }

    // Platform setup (configure manually in Firebase / native projects):
    // TODO(Android): Add debug/release SHA-1 fingerprints in Firebase Console.
    // TODO(iOS): Add REVERSED_CLIENT_ID from GoogleService-Info.plist as a URL
    //   scheme in ios/Runner/Info.plist.
    // TODO(Web): Set authDomain meta tag or clientId in web/index.html if needed.
    await GoogleSignIn.instance.initialize();
    _googleSignInInitialized = true;
  }

  Future<UserCredential> signInWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(authErrorMessage(e));
    }
  }

  Future<UserCredential> signUpWithEmail({
    required String email,
    required String password,
  }) async {
    try {
      return await _auth.createUserWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );
    } on FirebaseAuthException catch (e) {
      throw AuthException(authErrorMessage(e));
    }
  }

  Future<UserCredential> signInWithGoogle() async {
    await _ensureGoogleSignInInitialized();

    try {
      final googleUser = await GoogleSignIn.instance.authenticate();
      final googleAuth = googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );
      return await _auth.signInWithCredential(credential);
    } on GoogleSignInException catch (e) {
      if (e.code == GoogleSignInExceptionCode.canceled) {
        throw AuthCancelledException();
      }
      throw AuthException('Не удалось войти через Google');
    } on FirebaseAuthException catch (e) {
      throw AuthException(authErrorMessage(e));
    }
  }

  Future<void> signOut() async {
    await Future.wait([
      _auth.signOut(),
      _signOutGoogleIfInitialized(),
    ]);
  }

  Future<void> _signOutGoogleIfInitialized() async {
    if (!_googleSignInInitialized) {
      return;
    }
    try {
      await GoogleSignIn.instance.signOut();
    } on GoogleSignInException {
      // Ignore Google sign-out errors; Firebase session is already cleared.
    }
  }
}
