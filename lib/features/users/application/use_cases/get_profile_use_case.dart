import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/identity_contract.dart';
import '../../domain/repositories/user_repository.dart';

class GetProfileUseCase {
  final UserRepository repository;

  const GetProfileUseCase(this.repository);

  Future<Result<IdentityContract, Failure>> call(String userId) async {
    if (userId.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El id de usuario es obligatorio'),
      );
    }
    final result = await repository.getUserById(userId);
    return result.fold(
      onSuccess: (user) => Success(IdentityContract.fromUser(user)),
      onFailure: FailureResult.new,
    );
  }
}
