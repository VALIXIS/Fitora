import 'dart:async';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:fitora/core/utils/app_logger.dart';
import 'package:fitora/features/auth/data/firebase_auth_repository.dart';
import 'package:fitora/features/auth/domain/auth_repository.dart';
import 'package:fitora/features/auth/models/auth_action_state.dart';
import 'package:fitora/features/auth/models/auth_session.dart';
import 'package:fitora/features/auth/models/auth_status.dart';
import 'package:fitora/features/auth/models/auth_user.dart';
import 'package:fitora/features/auth/services/firebase_auth_service.dart';

final firebaseAuthServiceProvider = Provider<FirebaseAuthService>((ref) {
  return FirebaseAuthService(GoogleSignIn());
});

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return FirebaseAuthRepository(ref.read(firebaseAuthServiceProvider));
});

final authStateProvider =
    StateNotifierProvider<AuthController, AuthSession>((ref) {
  return AuthController(ref.read(authRepositoryProvider), ref);
});

final authActionProvider =
    StateNotifierProvider<AuthActionController, AuthActionState>((ref) {
  return AuthActionController(ref.read(authRepositoryProvider));
});

class AuthController extends StateNotifier<AuthSession> {
  final AuthRepository _repository;
  final Ref _ref;
  StreamSubscription<AuthUser?>? _subscription;

  AuthController(this._repository, this._ref) : super(AuthSession.loading()) {
    _subscription = _repository.authStateChanges().listen(
      _handleAuthChange,
      onError: _handleAuthError,
    );
    _ref.onDispose(() => _subscription?.cancel());
  }

  void _handleAuthChange(AuthUser? user) {
    if (user == null) {
      state = AuthSession.unauthenticated();
      return;
    }

    if (user.isAnonymous) {
      state = AuthSession.guest(user);
      return;
    }

    state = AuthSession.authenticated(user);
  }

  void _handleAuthError(Object error, StackTrace stackTrace) {
    AppLogger.error(error, stackTrace);
    state = AuthSession.error('Unable to read auth state');
  }
}

class AuthActionController extends StateNotifier<AuthActionState> {
  final AuthRepository _repository;

  AuthActionController(this._repository) : super(AuthActionState.idle());

  Future<void> signInWithGoogle() async {
    await _runAction(
      action: AuthActionType.google,
      task: _repository.signInWithGoogle,
      canceledMessage: 'Google sign-in was canceled.',
    );
  }

  Future<void> signInAnonymously() async {
    await _runAction(
      action: AuthActionType.guest,
      task: _repository.signInAnonymously,
      canceledMessage: 'Guest sign-in was canceled.',
    );
  }

  void clearError() {
    state = state.copyWith(clearError: true);
  }

  Future<void> _runAction({
    required AuthActionType action,
    required Future<AuthUser?> Function() task,
    required String canceledMessage,
  }) async {
    if (state.isLoading) {
      return;
    }

    state = state.copyWith(
      isLoading: true,
      action: action,
      clearError: true,
    );

    try {
      final user = await task();
      if (user == null) {
        state = state.copyWith(
          isLoading: false,
          error: canceledMessage,
          action: null,
        );
        return;
      }

      state = state.copyWith(isLoading: false, action: null);
    } on FirebaseAuthException catch (error, stackTrace) {
      AppLogger.error(error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: error.message ?? 'Unable to sign in.',
        action: null,
      );
    } on PlatformException catch (error, stackTrace) {
      AppLogger.error(error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: error.message ?? 'Sign-in is unavailable right now.',
        action: null,
      );
    } catch (error, stackTrace) {
      AppLogger.error(error, stackTrace);
      state = state.copyWith(
        isLoading: false,
        error: 'Something went wrong. Please try again.',
        action: null,
      );
    }
  }
}
