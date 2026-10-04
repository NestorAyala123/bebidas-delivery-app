import '../../../users/domain/entities/app_user.dart';

class RegisterRequest {
  final String email;
  final String password;
  final String name;
  final String? phoneNumber;
  final UserRole role;

  const RegisterRequest({
    required this.email,
    required this.password,
    required this.name,
    required this.role,
    this.phoneNumber,
  });
}

class LoginRequest {
  final String email;
  final String password;

  const LoginRequest({required this.email, required this.password});
}

class TokenResponse {
  final String accessToken;
  final String refreshToken;
  final int expiresInSeconds;
  final String tokenType;

  const TokenResponse({
    required this.accessToken,
    required this.refreshToken,
    required this.expiresInSeconds,
    this.tokenType = 'Bearer',
  });

  Map<String, Object> toJson() => {
    'accessToken': accessToken,
    'refreshToken': refreshToken,
    'expiresIn': expiresInSeconds,
    'tokenType': tokenType,
  };
}
