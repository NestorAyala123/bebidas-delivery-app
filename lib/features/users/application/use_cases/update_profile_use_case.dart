import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../dtos/profile_dtos.dart';
import '../../domain/entities/identity_contract.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/user_repository.dart';

class UpdateProfileUseCase {
  static const int minNameLength = 2;
  static const int maxNameLength = 60;
  static final RegExp _phonePattern = RegExp(r'^\+?[0-9]{7,15}$');

  final UserRepository repository;

  const UpdateProfileUseCase(this.repository);

  Future<Result<IdentityContract, Failure>> call(
    String userId,
    UpdateProfileRequest request, {
    required IdentityContract requester,
  }) async {
    if (userId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El id de usuario es obligatorio'),
      );
    }
    if (requester.id != userId ||
        !hasPermission(requester.rbacRole, Permission.updateOwnProfile)) {
      return const FailureResult(
        UnauthorizedFailure('Solo puedes editar tu propio perfil'),
      );
    }
    final invalid = _validate(request);
    if (invalid != null) return FailureResult(invalid);

    final current = await repository.getUserById(userId);
    return current.fold(
      onFailure: FailureResult.new,
      onSuccess: (user) async {
        final updated = applyProfileUpdate(user, request);
        final saveResult = await repository.updateProfile(updated);
        return saveResult.fold(
          onSuccess: (_) => Success(IdentityContract.fromUser(updated)),
          onFailure: FailureResult.new,
        );
      },
    );
  }

  ValidationFailure? _validate(UpdateProfileRequest request) {
    final name = request.displayName.trim();
    if (name.length < minNameLength || name.length > maxNameLength) {
      return const ValidationFailure(
        'El nombre debe tener entre $minNameLength y $maxNameLength caracteres',
      );
    }
    final phone = request.phoneNumber?.trim() ?? '';
    if (phone.isNotEmpty && !_phonePattern.hasMatch(phone)) {
      return const ValidationFailure(
        'El teléfono debe tener entre 7 y 15 dígitos (puede iniciar con +)',
      );
    }
    return null;
  }
}
