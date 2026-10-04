import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../dtos/profile_dtos.dart';
import '../../domain/entities/identity_contract.dart';
import '../../domain/repositories/user_repository.dart';

class UpdateProfileUseCase {
  final UserRepository repository;

  const UpdateProfileUseCase(this.repository);

  Future<Result<IdentityContract, Failure>> call(
    String userId,
    UpdateProfileRequest request,
  ) async {
    if (userId.trim().isEmpty || request.displayName.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El id y el nombre son obligatorios'),
      );
    }
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
}
