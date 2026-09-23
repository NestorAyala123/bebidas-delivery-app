class UserSession {
  final String userId;
  final String email;
  final String token;

  const UserSession({
    required this.userId,
    required this.email,
    required this.token,
  });
}
