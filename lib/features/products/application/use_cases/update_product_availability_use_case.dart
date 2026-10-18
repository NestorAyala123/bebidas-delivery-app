import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/product_repository.dart';

class UpdateProductAvailabilityUseCase {
  final ProductRepository repository;

  const UpdateProductAvailabilityUseCase(this.repository);

  Future<Result<void, Failure>> call({
    required String productId,
    required bool isAvailable,
  }) {
    if (productId.trim().isEmpty) {
      return Future.value(
        const FailureResult<void, Failure>(
          ValidationFailure('El identificador del producto es obligatorio'),
        ),
      );
    }
    return repository.updateStockStatus(productId, isAvailable);
  }
}
