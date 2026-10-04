import 'app_user.dart';
import 'role.dart';

/// Stable, module-agnostic representation of an authenticated identity.
///
/// Other features should depend on this contract rather than importing a
/// users repository or infrastructure implementation.
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

  factory IdentityContract.fromUser(AppUser user) => IdentityContract(
    id: user.id,
    email: user.email,
    displayName: user.name,
    phoneNumber: user.phoneNumber,
    role: user.role,
    isActive: true,
    createdAt: user.createdAt,
  );

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
