import '../../../users/domain/entities/app_user.dart';

class UserSession {
  final String userId;
  final String email;
  final String token;
  final AppUser user;

  const UserSession({
    required this.userId,
    required this.email,
    required this.token,
    required this.user,
  });

  UserRole get role => user.role;
}
