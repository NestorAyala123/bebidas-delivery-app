import '../../../users/domain/entities/app_user.dart';

class UserSession {
  final String userId;
  final String email;
  final String token;
  final UserRole role;

  const UserSession({
    required this.userId,
    required this.email,
    required this.token,
    this.role = UserRole.client,
  });
}

