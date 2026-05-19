import 'package:fitora/features/auth/models/auth_user.dart';

abstract class AuthRepository {
  Stream<AuthUser?> authStateChanges();
  Future<AuthUser?> signInWithGoogle();
  Future<AuthUser?> signInAnonymously();
  Future<void> signOut();
}
