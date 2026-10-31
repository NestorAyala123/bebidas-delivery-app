import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class GetStoreCatalogUseCase {
  final ProductRepository repository;

  const GetStoreCatalogUseCase(this.repository);

  Future<Result<List<Product>, Failure>> call({
    required String storeId,
    bool availableOnly = true,
  }) {
    if (storeId.trim().isEmpty) {
      return Future.value(
        const FailureResult<List<Product>, Failure>(
          ValidationFailure('El comercio del catálogo es obligatorio'),
        ),
      );
    }

    return availableOnly
        ? repository.getAvailableProducts(storeId)
        : repository.getProductsByStore(storeId);
  }
}
