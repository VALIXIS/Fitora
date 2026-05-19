import 'package:fitora/features/auth/models/auth_status.dart';
import 'package:fitora/features/auth/models/auth_user.dart';

class AuthSession {
  final AuthStatus status;
  final AuthUser? user;
  final String? message;

  const AuthSession._({
    required this.status,
    this.user,
    this.message,
  });

  factory AuthSession.loading() => const AuthSession._(
        status: AuthStatus.loading,
      );

  factory AuthSession.unauthenticated() => const AuthSession._(
        status: AuthStatus.unauthenticated,
      );

  factory AuthSession.guest(AuthUser? user) => AuthSession._(
        status: AuthStatus.guest,
        user: user,
      );

  factory AuthSession.authenticated(AuthUser user) => AuthSession._(
        status: AuthStatus.authenticated,
        user: user,
      );

  factory AuthSession.error(String message) => AuthSession._(
        status: AuthStatus.error,
        message: message,
      );

  bool get isAuthenticated => status == AuthStatus.authenticated;
  bool get isGuest => status == AuthStatus.guest;
  bool get isLoading => status == AuthStatus.loading;
}
