import 'package:firebase_auth/firebase_auth.dart';
import 'package:fitora/features/auth/domain/auth_repository.dart';
import 'package:fitora/features/auth/models/auth_user.dart';
import 'package:fitora/features/auth/services/firebase_auth_service.dart';

class FirebaseAuthRepository implements AuthRepository {
  final FirebaseAuthService _service;

  FirebaseAuthRepository(this._service);

  @override
  Stream<AuthUser?> authStateChanges() {
    return _service.authStateChanges().map(_mapUser);
  }

  @override
  Future<AuthUser?> signInWithGoogle() async {
    final credential = await _service.signInWithGoogle();
    return _mapUser(credential?.user);
  }

  @override
  Future<AuthUser?> signInAnonymously() async {
    final credential = await _service.signInAnonymously();
    return _mapUser(credential?.user);
  }

  @override
  Future<void> signOut() => _service.signOut();

  AuthUser? _mapUser(User? user) {
    if (user == null) {
      return null;
    }

    return AuthUser(
      id: user.uid,
      email: user.email,
      displayName: user.displayName,
      photoUrl: user.photoURL,
      isAnonymous: user.isAnonymous,
    );
  }
}
