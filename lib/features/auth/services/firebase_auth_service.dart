import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fitora/core/services/firebase_initializer.dart';
import 'package:fitora/core/utils/app_logger.dart';

class FirebaseAuthService {
  final GoogleSignIn _googleSignIn;

  FirebaseAuthService(this._googleSignIn);

  Future<bool> _ensureInitialized() async {
    await FirebaseInitializer.initialize();
    return FirebaseInitializer.isInitialized;
  }

  Stream<User?> authStateChanges() async* {
    final ready = await _ensureInitialized();
    if (!ready) {
      yield null;
      return;
    }
    yield* FirebaseAuth.instance.authStateChanges();
  }

  Future<UserCredential?> signInWithGoogle() async {
    final ready = await _ensureInitialized();
    if (!ready) {
      AppLogger.info('Firebase not initialized. Skipping Google sign-in.');
      return null;
    }

    try {
      if (await _googleSignIn.isSignedIn()) {
        await _googleSignIn.signOut();
      }
    } catch (e) {
      AppLogger.info('Google sign-in pre-cleanup warning: $e');
    }

    final account = await _googleSignIn.signIn();
    if (account == null) {
      return null;
    }

    final authentication = await account.authentication;
    if (authentication.idToken == null && authentication.accessToken == null) {
      throw FirebaseAuthException(
        code: 'missing-google-token',
        message: 'Could not obtain authentication tokens from Google.',
      );
    }

    final credential = GoogleAuthProvider.credential(
      accessToken: authentication.accessToken,
      idToken: authentication.idToken,
    );

    return FirebaseAuth.instance.signInWithCredential(credential);
  }

  Future<UserCredential?> signInAnonymously() async {
    final ready = await _ensureInitialized();
    if (!ready) {
      AppLogger.info('Firebase not initialized. Skipping anonymous sign-in.');
      return null;
    }

    return FirebaseAuth.instance.signInAnonymously();
  }

  Future<void> signOut() async {
    final ready = await _ensureInitialized();
    if (!ready) {
      return;
    }

    try {
      await FirebaseAuth.instance.signOut();
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
    }

    try {
      await _googleSignIn.signOut();
    } catch (e, stackTrace) {
      AppLogger.error(e, stackTrace);
    }
  }
}
