import '../../../users/domain/entities/app_user.dart';

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});
}

class RegisterRequest {
  final String email;
  final String password;
  final String name;
  final UserRole role;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
    this.role = UserRole.client,
  });
}
