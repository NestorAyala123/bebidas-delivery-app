import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/store_repository.dart';

class UpdateStoreStatusUseCase {
  final StoreRepository repository;

  const UpdateStoreStatusUseCase(this.repository);

  Future<Result<void, Failure>> call({
    required String storeId,
    required bool isOpen,
  }) {
    if (storeId.trim().isEmpty) {
      return Future.value(
        const FailureResult<void, Failure>(
          ValidationFailure('El identificador del comercio es obligatorio'),
        ),
      );
    }
    return repository.updateStoreStatus(storeId, isOpen);
  }
}
