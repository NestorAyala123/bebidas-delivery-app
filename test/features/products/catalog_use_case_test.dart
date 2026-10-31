import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/products/application/use_cases/get_store_catalog_use_case.dart';
import 'package:bebidas_delivery_app/features/products/application/use_cases/save_product_use_case.dart';
import 'package:bebidas_delivery_app/features/products/application/use_cases/update_product_availability_use_case.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';
import 'package:bebidas_delivery_app/features/products/infrastructure/repositories/in_memory_product_repository.dart';

void main() {
  late InMemoryProductRepository repository;
  late SaveProductUseCase saveProduct;
  late GetStoreCatalogUseCase getCatalog;

  setUp(() {
    repository = InMemoryProductRepository();
    saveProduct = SaveProductUseCase(repository);
    getCatalog = GetStoreCatalogUseCase(repository);
  });

  test(
    'persists products and returns only the selected store catalog',
    () async {
      await saveProduct(
        const Product(
          id: 'product-1',
          storeId: 'store-1',
          name: 'Agua',
          basePrice: 1.5,
        ),
      );
      await saveProduct(
        const Product(
          id: 'product-2',
          storeId: 'store-2',
          name: 'Gaseosa',
          basePrice: 2.5,
        ),
      );

      final result = await getCatalog(storeId: 'store-1');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull!.single.id, 'product-1');
    },
  );

  test('separates available and complete catalog queries', () async {
    await saveProduct(
      const Product(
        id: 'product-1',
        storeId: 'store-1',
        name: 'Agua',
        basePrice: 1.5,
      ),
    );
    await saveProduct(
      const Product(
        id: 'product-2',
        storeId: 'store-1',
        name: 'Gaseosa',
        basePrice: 2.5,
        isAvailable: false,
      ),
    );
    await UpdateProductAvailabilityUseCase(repository)(
      productId: 'product-1',
      isAvailable: false,
    );

    final available = await getCatalog(storeId: 'store-1');
    final complete = await getCatalog(storeId: 'store-1', availableOnly: false);

    expect(available.dataOrNull, isEmpty);
    expect(complete.dataOrNull, hasLength(2));
  });

  test('requires a store when querying the catalog', () async {
    final result = await getCatalog(storeId: '  ');

    expect(result.isFailure, isTrue);
  });
}
