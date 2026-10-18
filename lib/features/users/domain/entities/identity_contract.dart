import 'app_user.dart';
import 'role.dart';

/// Contrato de identidad compartido entre módulos.
class IdentityContract {
  final String id;
  final String email;
  final String displayName;
  final String? phoneNumber;
  final UserRole role;
  final bool isActive;
  final DateTime createdAt;

  const IdentityContract({
    required this.id,
    required this.email,
    required this.displayName,
    required this.phoneNumber,
    required this.role,
    required this.isActive,
    required this.createdAt,
  });

  factory IdentityContract.fromUser(AppUser user) {
    return IdentityContract(
      id: user.id,
      email: user.email,
      displayName: user.name,
      phoneNumber: user.phoneNumber,
      role: user.role,
      isActive: true,
      createdAt: user.createdAt,
    );
  }

  Map<String, Object?> toJson() => {
    'id': id,
    'email': email,
    'displayName': displayName,
    'phoneNumber': phoneNumber,
    'role': role.name,
    'isActive': isActive,
    'createdAt': createdAt.toUtc().toIso8601String(),
  };

  Role get rbacRole => switch (role) {
    UserRole.client => Role.client,
    UserRole.store => Role.store,
    UserRole.driver => Role.driver,
    UserRole.eventProvider => Role.eventProvider,
  };
}
