import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/pricing/application/use_cases/save_price_rule_use_case.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/price_rule.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';
import 'package:bebidas_delivery_app/features/products/infrastructure/repositories/in_memory_product_repository.dart';

void main() {
  test('adds a valid quantity price rule to a product', () async {
    final repository = InMemoryProductRepository();
    const product = Product(
      id: 'product-1',
      storeId: 'store-1',
      name: 'Cerveza',
      basePrice: 10,
    );
    await repository.createProduct(product);

    final result = await SavePriceRuleUseCase(repository)(
      product: product,
      rule: const PriceRule(
        id: 'rule-6',
        productId: 'product-1',
        minQuantity: 6,
        unitPrice: 9,
      ),
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.getUnitPriceForQuantity(6), 9);
  });

  test('rejects a rule for another product', () async {
    final repository = InMemoryProductRepository();
    const product = Product(
      id: 'product-1',
      storeId: 'store-1',
      name: 'Cerveza',
      basePrice: 10,
    );
    await repository.createProduct(product);

    final result = await SavePriceRuleUseCase(repository)(
      product: product,
      rule: const PriceRule(
        id: 'rule-6',
        productId: 'product-2',
        minQuantity: 6,
        unitPrice: 9,
      ),
    );

    expect(result.isFailure, isTrue);
  });
}
