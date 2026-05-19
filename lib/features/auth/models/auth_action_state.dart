enum AuthActionType {
  google,
  guest,
  email,
}

class AuthActionState {
  final bool isLoading;
  final String? error;
  final AuthActionType? action;

  const AuthActionState({
    required this.isLoading,
    this.error,
    this.action,
  });

  factory AuthActionState.idle() {
    return const AuthActionState(isLoading: false);
  }

  AuthActionState copyWith({
    bool? isLoading,
    String? error,
    bool clearError = false,
    AuthActionType? action,
  }) {
    return AuthActionState(
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      action: action ?? this.action,
    );
  }
}
