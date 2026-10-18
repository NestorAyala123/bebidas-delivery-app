import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/returnable_container.dart';
import '../../domain/repositories/returnable_container_repository.dart';

class SaveReturnableContainerUseCase {
  final ReturnableContainerRepository repository;

  const SaveReturnableContainerUseCase(this.repository);

  Future<Result<ReturnableContainer, Failure>> call({
    required String storeId,
    required ReturnableContainer container,
  }) {
    if (storeId.trim().isEmpty) {
      return Future.value(
        const FailureResult<ReturnableContainer, Failure>(
          ValidationFailure('El comercio del envase es obligatorio'),
        ),
      );
    }
    if (container.productId.trim().isEmpty) {
      return Future.value(
        const FailureResult<ReturnableContainer, Failure>(
          ValidationFailure('El producto del envase es obligatorio'),
        ),
      );
    }
    if (container.isReturnable && container.depositPrice <= 0) {
      return Future.value(
        const FailureResult<ReturnableContainer, Failure>(
          ValidationFailure(
            'El depósito debe ser mayor que cero para un envase retornable',
          ),
        ),
      );
    }
    return repository.save(storeId, container);
  }
}
