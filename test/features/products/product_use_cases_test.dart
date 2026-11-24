import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/price_rule.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/quantity_pricing_tier.dart';
import 'package:bebidas_delivery_app/features/products/application/use_cases/save_product_use_case.dart';
import 'package:bebidas_delivery_app/features/products/application/use_cases/update_product_availability_use_case.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';
import 'package:bebidas_delivery_app/features/products/infrastructure/repositories/in_memory_product_repository.dart';

void main() {
  late InMemoryProductRepository repository;
  late SaveProductUseCase saveProduct;

  setUp(() {
    repository = InMemoryProductRepository();
    saveProduct = SaveProductUseCase(repository);
  });

  test('registers a basic product and filters it by store', () async {
    final result = await saveProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua',
        basePrice: 1.5,
        imageUrl: 'https://example.com/agua.png',
      ),
    );
    final products = await repository.getProductsByStore('store-1');

    expect(result.isSuccess, isTrue);
    expect(products.dataOrNull, hasLength(1));
    expect(products.dataOrNull!.single.imageUrl, contains('agua.png'));
  });

  test('edits product data and changes availability', () async {
    await saveProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua',
        basePrice: 1.5,
      ),
    );
    final edited = await saveProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua grande',
        basePrice: 2.0,
      ),
    );
    final availability = await UpdateProductAvailabilityUseCase(repository)(
      productId: 'product-1',
      isAvailable: false,
    );
    final availableProducts = await repository.getAvailableProducts('store-1');

    expect(edited.dataOrNull?.name, 'Agua grande');
    expect(availability.isSuccess, isTrue);
    expect(availableProducts.dataOrNull, isEmpty);
  });

  test('rejects a negative price', () async {
    final result = await saveProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua',
        basePrice: -1,
      ),
    );

    expect(result.isFailure, isTrue);
  });

  test('rejects quantity rules that conflict with product tiers', () async {
    final result = await saveProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua',
        basePrice: 1.5,
        quantityTiers: [QuantityPricingTier(minQuantity: 6, unitPrice: 1.2)],
        priceRules: [
          PriceRule(
            id: 'rule-1',
            productId: 'product-1',
            minQuantity: 6,
            unitPrice: 1.1,
          ),
        ],
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull?.message, contains('mismo rango'));
  });

  test('rejects a quantity rule that does not belong to the product', () async {
    final result = await saveProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua',
        basePrice: 1.5,
        priceRules: [
          PriceRule(
            id: 'rule-1',
            productId: 'another-product',
            minQuantity: 6,
            unitPrice: 1.1,
          ),
        ],
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull?.message, contains('pertenecer'));
  });

  test('requires a positive deposit for returnable products', () async {
    final result = await saveProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Botella retornable',
        basePrice: 1.5,
        isReturnableContainer: true,
      ),
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull?.message, contains('depósito'));
  });
}
