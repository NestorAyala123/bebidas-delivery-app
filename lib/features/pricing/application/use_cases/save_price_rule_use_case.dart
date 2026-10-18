import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../products/domain/entities/product.dart';
import '../../../products/domain/repositories/product_repository.dart';
import '../../domain/entities/price_rule.dart';

class SavePriceRuleUseCase {
  final ProductRepository productRepository;

  const SavePriceRuleUseCase(this.productRepository);

  Future<Result<Product, Failure>> call({
    required Product product,
    required PriceRule rule,
  }) async {
    if (rule.productId != product.id) {
      return const FailureResult<Product, Failure>(
        ValidationFailure('La regla debe pertenecer al producto'),
      );
    }
    if (rule.minQuantity <= 1) {
      return const FailureResult<Product, Failure>(
        ValidationFailure('La cantidad mínima debe ser mayor que 1'),
      );
    }
    if (rule.unitPrice < 0) {
      return const FailureResult<Product, Failure>(
        ValidationFailure('El precio escalonado no puede ser negativo'),
      );
    }

    final rules = [
      ...product.priceRules.where((item) => item.id != rule.id),
      rule,
    ];
    return productRepository.updateProduct(
      Product(
        id: product.id,
        storeId: product.storeId,
        name: product.name,
        description: product.description,
        basePrice: product.basePrice,
        isAvailable: product.isAvailable,
        imageUrl: product.imageUrl,
        isReturnableContainer: product.isReturnableContainer,
        containerDepositPrice: product.containerDepositPrice,
        quantityTiers: product.quantityTiers,
        priceRules: rules,
        returnableContainer: product.returnableContainer,
      ),
    );
  }
}
