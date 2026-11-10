import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';
import 'package:bebidas_delivery_app/features/products/infrastructure/repositories/in_memory_product_repository.dart';
import 'package:bebidas_delivery_app/features/stores/application/use_cases/validate_purchase_availability_use_case.dart';
import 'package:bebidas_delivery_app/features/stores/domain/entities/store.dart';
import 'package:bebidas_delivery_app/features/stores/infrastructure/repositories/in_memory_store_repository.dart';

void main() {
  late InMemoryStoreRepository storeRepository;
  late InMemoryProductRepository productRepository;
  late ValidatePurchaseAvailabilityUseCase validatePurchase;

  setUp(() {
    storeRepository = InMemoryStoreRepository();
    productRepository = InMemoryProductRepository();
    validatePurchase = ValidatePurchaseAvailabilityUseCase(
      storeRepository: storeRepository,
      productRepository: productRepository,
    );
  });

  test('allows a purchase when store and products are available', () async {
    await storeRepository.createStore(
      const Store(
        id: 'store-1',
        name: 'La Esquina',
        address: 'Av. Central',
        isOpen: true,
      ),
    );
    await productRepository.createProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua',
        basePrice: 1.5,
      ),
    );

    final result = await validatePurchase(
      storeId: 'store-1',
      quantitiesByProductId: {'product-1': 2},
    );

    expect(result.isSuccess, isTrue);
  });

  test('rejects a purchase when the store is closed', () async {
    await storeRepository.createStore(
      const Store(
        id: 'store-1',
        name: 'La Esquina',
        address: 'Av. Central',
        isOpen: false,
      ),
    );

    final result = await validatePurchase(
      storeId: 'store-1',
      quantitiesByProductId: {'product-1': 1},
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull?.message, contains('cerrado'));
  });

  test('rejects a product that became unavailable before buying', () async {
    await storeRepository.createStore(
      const Store(
        id: 'store-1',
        name: 'La Esquina',
        address: 'Av. Central',
        isOpen: true,
      ),
    );
    await productRepository.createProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua',
        basePrice: 1.5,
        isAvailable: false,
      ),
    );

    final result = await validatePurchase(
      storeId: 'store-1',
      quantitiesByProductId: {'product-1': 1},
    );

    expect(result.isFailure, isTrue);
    expect(result.failureOrNull?.message, contains('disponible'));
  });
}
