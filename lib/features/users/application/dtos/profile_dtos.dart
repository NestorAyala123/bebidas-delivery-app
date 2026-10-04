import '../../domain/entities/app_user.dart';
import '../../domain/entities/identity_contract.dart';

class UpdateProfileRequest {
  final String displayName;
  final String? phoneNumber;

  const UpdateProfileRequest({required this.displayName, this.phoneNumber});
}

class IdentityResponse {
  final IdentityContract identity;

  const IdentityResponse(this.identity);

  Map<String, Object?> toJson() => {'data': identity.toJson()};
}

AppUser applyProfileUpdate(AppUser user, UpdateProfileRequest request) =>
    AppUser(
      id: user.id,
      email: user.email,
      name: request.displayName.trim(),
      phoneNumber: request.phoneNumber?.trim(),
      role: user.role,
      createdAt: user.createdAt,
    );
