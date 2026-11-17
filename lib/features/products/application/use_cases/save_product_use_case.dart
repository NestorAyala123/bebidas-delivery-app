import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/product.dart';
import '../../domain/repositories/product_repository.dart';

class SaveProductUseCase {
  final ProductRepository repository;

  const SaveProductUseCase(this.repository);

  Future<Result<Product, Failure>> call(Product product) async {
    if (product.storeId.trim().isEmpty) {
      return Future.value(
        const FailureResult<Product, Failure>(
          ValidationFailure('El comercio del producto es obligatorio'),
        ),
      );
    }
    if (product.name.trim().isEmpty) {
      return Future.value(
        const FailureResult<Product, Failure>(
          ValidationFailure('El nombre del producto es obligatorio'),
        ),
      );
    }
    if (!product.basePrice.isFinite || product.basePrice < 0) {
      return Future.value(
        const FailureResult<Product, Failure>(
          ValidationFailure('El precio no puede ser negativo'),
        ),
      );
    }

    final tierMinimums = <int>{};
    for (final tier in product.quantityTiers) {
      if (tier.minQuantity <= 1) {
        return Future.value(
          const FailureResult<Product, Failure>(
            ValidationFailure(
              'La cantidad mínima escalonada debe ser mayor que 1',
            ),
          ),
        );
      }
      if (!tierMinimums.add(tier.minQuantity)) {
        return Future.value(
          const FailureResult<Product, Failure>(
            ValidationFailure(
              'No puede haber dos precios para el mismo rango de cantidad',
            ),
          ),
        );
      }
      if (!tier.unitPrice.isFinite || tier.unitPrice < 0) {
        return Future.value(
          const FailureResult<Product, Failure>(
            ValidationFailure('El precio escalonado no puede ser negativo'),
          ),
        );
      }
    }

    if (product.id.trim().isEmpty) return repository.createProduct(product);

    final existing = await repository.getProductById(product.id);
    if (existing.failureOrNull is NotFoundFailure) {
      return repository.createProduct(product);
    }
    if (existing.isFailure) {
      return FailureResult<Product, Failure>(existing.failureOrNull!);
    }
    return repository.updateProduct(product);
  }
}
