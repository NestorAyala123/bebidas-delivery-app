import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/identity_contract.dart';
import '../../domain/entities/role.dart';
import '../../domain/repositories/user_repository.dart';

/// Returns the full identity to its owner and the public identity (no email or
/// phone) to any other authenticated user.
class GetProfileUseCase {
  final UserRepository repository;

  const GetProfileUseCase(this.repository);

  Future<Result<IdentityContract, Failure>> call(
    String userId, {
    required IdentityContract requester,
  }) async {
    if (userId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El id de usuario es obligatorio'),
      );
    }
    final isOwner = requester.id == userId;
    if (isOwner &&
        !hasPermission(requester.rbacRole, Permission.readOwnProfile)) {
      return const FailureResult(
        UnauthorizedFailure('No tienes permiso para ver este perfil'),
      );
    }
    final result = await repository.getUserById(userId);
    return result.fold(
      onSuccess: (user) {
        final identity = IdentityContract.fromUser(user);
        return Success(isOwner ? identity : identity.toPublic());
      },
      onFailure: FailureResult.new,
    );
  }
}
