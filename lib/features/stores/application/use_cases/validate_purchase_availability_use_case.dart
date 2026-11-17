import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../domain/repositories/store_repository.dart';

/// Validates the catalog state immediately before creating a purchase.
class ValidatePurchaseAvailabilityUseCase {
  final StoreRepository storeRepository;
  final ProductRepository productRepository;

  const ValidatePurchaseAvailabilityUseCase({
    required this.storeRepository,
    required this.productRepository,
  });

  Future<Result<void, Failure>> call({
    required String storeId,
    required Map<String, int> quantitiesByProductId,
  }) async {
    if (storeId.trim().isEmpty) {
      return const FailureResult<void, Failure>(
        ValidationFailure('El comercio de la compra es obligatorio'),
      );
    }
    if (quantitiesByProductId.isEmpty) {
      return const FailureResult<void, Failure>(
        ValidationFailure('La compra debe contener al menos un producto'),
      );
    }
    if (quantitiesByProductId.entries.any(
      (entry) => entry.key.trim().isEmpty || entry.value <= 0,
    )) {
      return const FailureResult<void, Failure>(
        ValidationFailure(
          'Cada producto debe tener un identificador y una cantidad válida',
        ),
      );
    }

    final storeResult = await storeRepository.getStoreById(storeId);
    if (storeResult.isFailure) {
      return FailureResult<void, Failure>(storeResult.failureOrNull!);
    }
    final store = storeResult.dataOrNull!;
    if (!store.canAcceptOrders()) {
      return const FailureResult<void, Failure>(
        BusinessRuleFailure(
          'El comercio está cerrado y no puede aceptar compras',
        ),
      );
    }

    for (final entry in quantitiesByProductId.entries) {
      final productResult = await productRepository.getProductById(entry.key);
      if (productResult.isFailure) {
        return FailureResult<void, Failure>(productResult.failureOrNull!);
      }
      final product = productResult.dataOrNull!;
      if (product.storeId != storeId) {
        return const FailureResult<void, Failure>(
          BusinessRuleFailure(
            'El producto no pertenece al comercio de la compra',
          ),
        );
      }
      if (!product.isAvailable) {
        return const FailureResult<void, Failure>(
          BusinessRuleFailure('Uno de los productos ya no está disponible'),
        );
      }
    }

    return const Success<void, Failure>(null);
  }
}
