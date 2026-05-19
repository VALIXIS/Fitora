class AuthUser {
  final String id;
  final String? email;
  final String? displayName;
  final String? photoUrl;
  final bool isAnonymous;

  const AuthUser({
    required this.id,
    this.email,
    this.displayName,
    this.photoUrl,
    this.isAnonymous = false,
  });
}
