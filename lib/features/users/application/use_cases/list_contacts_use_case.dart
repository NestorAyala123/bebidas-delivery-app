import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/identity_contract.dart';
import '../../domain/repositories/user_repository.dart';

/// Public identities the requester can start a conversation with.
class ListContactsUseCase {
  final UserRepository repository;

  const ListContactsUseCase(this.repository);

  Future<Result<List<IdentityContract>, Failure>> call({
    required IdentityContract requester,
  }) async {
    final result = await repository.listUsers();
    return result.fold(
      onSuccess: (users) => Success(
        users
            .where((user) => user.id != requester.id)
            .map((user) => IdentityContract.fromUser(user).toPublic())
            .toList(),
      ),
      onFailure: FailureResult.new,
    );
  }
}
