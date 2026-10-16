import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/di/service_locator.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/cart/application/use_cases/add_to_cart_use_case.dart';
import 'package:bebidas_delivery_app/features/cart/application/use_cases/calculate_cart_totals_use_case.dart';
import 'package:bebidas_delivery_app/features/cart/application/use_cases/clear_cart_use_case.dart';
import 'package:bebidas_delivery_app/features/cart/application/use_cases/remove_from_cart_use_case.dart';
import 'package:bebidas_delivery_app/features/cart/application/use_cases/update_cart_quantity_use_case.dart';
import 'package:bebidas_delivery_app/features/cart/di/cart_di.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';
import 'package:bebidas_delivery_app/features/cart/domain/repositories/cart_repository.dart';
import 'package:bebidas_delivery_app/features/cart/infrastructure/in_memory_cart_repository.dart';

void main() {
  group('Cart Use Cases & DI Integration Tests', () {
    late CartRepository repository;
    late AddToCartUseCase addToCartUseCase;
    late UpdateCartQuantityUseCase updateCartQuantityUseCase;
    late RemoveFromCartUseCase removeFromCartUseCase;
    late ClearCartUseCase clearCartUseCase;
    late CalculateCartTotalsUseCase calculateCartTotalsUseCase;

    const storeId = 'store-test';
    const item1 = CartItem(
      productId: 'p-1',
      productName: 'Cerveza Artesanal 500ml',
      unitPrice: 3.50,
      quantity: 2,
      isReturnable: true,
      containerDeposit: 0.50,
    );
    const item2 = CartItem(
      productId: 'p-2',
      productName: 'Refresco 1.5L',
      unitPrice: 2.00,
      quantity: 1,
    );

    setUp(() {
      repository = InMemoryCartRepository();
      addToCartUseCase = AddToCartUseCase(repository);
      updateCartQuantityUseCase = UpdateCartQuantityUseCase(repository);
      removeFromCartUseCase = RemoveFromCartUseCase(repository);
      clearCartUseCase = ClearCartUseCase(repository);
      calculateCartTotalsUseCase = const CalculateCartTotalsUseCase();
    });

    test('Full shopping cart user flow through use cases', () async {
      // 1. Add item 1
      final addResult1 = await addToCartUseCase(
        const AddToCartInput(targetStoreId: storeId, item: item1),
      );
      expect(addResult1.isSuccess, isTrue);
      expect(addResult1.dataOrNull?.totalItemCount, equals(2));

      // 2. Add item 2
      final addResult2 = await addToCartUseCase(
        const AddToCartInput(targetStoreId: storeId, item: item2),
      );
      expect(addResult2.isSuccess, isTrue);
      expect(addResult2.dataOrNull?.totalItemCount, equals(3));
      expect(addResult2.dataOrNull?.subtotal, equals(9.00)); // (2 * 3.50) + (1 * 2.00)

      // 3. Increment item 1 quantity via UpdateCartQuantityUseCase
      final incResult = await updateCartQuantityUseCase(
        const UpdateCartQuantityInput.increment('p-1', 2),
      );
      expect(incResult.isSuccess, isTrue);
      expect(incResult.dataOrNull?.getItem('p-1')?.quantity, equals(4));

      // 4. Decrement item 2 quantity by 1 (removes it since it was 1)
      final decResult = await updateCartQuantityUseCase(
        const UpdateCartQuantityInput.decrement('p-2', 1),
      );
      expect(decResult.isSuccess, isTrue);
      expect(decResult.dataOrNull?.hasProduct('p-2'), isFalse);

      // 5. Calculate totals with returned container
      final calcResult = await calculateCartTotalsUseCase(
        CalculateCartTotalsInput(
          cart: decResult.dataOrNull!,
          returnedContainers: 2, // 4 required, 2 returned -> 2 missing * 0.50 = 1.00 fee
          deliveryFee: 2.50,
          discount: 1.00,
        ),
      );
      expect(calcResult.isSuccess, isTrue);
      final calc = calcResult.dataOrNull!;
      expect(calc.itemsSubtotal, equals(14.00)); // 4 * 3.50
      expect(calc.missingContainersFee, equals(1.00));
      expect(calc.deliveryFee, equals(2.50));
      expect(calc.discount, equals(1.00));
      expect(calc.total, equals(16.50)); // 14.00 + 1.00 + 2.50 - 1.00

      // 6. Remove remaining item
      final remResult = await removeFromCartUseCase('p-1');
      expect(remResult.isSuccess, isTrue);
      expect(remResult.dataOrNull?.isEmpty, isTrue);
      expect(remResult.dataOrNull?.storeId, isNull);

      // 7. Clear cart
      final clearResult = await clearCartUseCase();
      expect(clearResult.isSuccess, isTrue);
    });

    test('UpdateCartQuantityUseCase returns NotFoundFailure for non-existent product', () async {
      await addToCartUseCase(
        const AddToCartInput(targetStoreId: storeId, item: item1),
      );

      final result = await updateCartQuantityUseCase(
        const UpdateCartQuantityInput.set('p-non-existent', 5),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test('UpdateCartQuantityUseCase rejects empty productId with ValidationFailure', () async {
      final result = await updateCartQuantityUseCase(
        const UpdateCartQuantityInput.set('', 5),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('RemoveFromCartUseCase rejects empty productId with ValidationFailure', () async {
      final result = await removeFromCartUseCase('');
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('CartDi registers all dependencies properly in ServiceLocator', () {
      final locator = ServiceLocator.instance;
      locator.reset();

      final cartDi = CartDi();
      cartDi.registerDependencies(locator);

      expect(locator.isRegistered<CartRepository>(), isTrue);
      expect(locator.isRegistered<AddToCartUseCase>(), isTrue);
      expect(locator.isRegistered<UpdateCartQuantityUseCase>(), isTrue);
      expect(locator.isRegistered<RemoveFromCartUseCase>(), isTrue);
      expect(locator.isRegistered<ClearCartUseCase>(), isTrue);
      expect(locator.isRegistered<CalculateCartTotalsUseCase>(), isTrue);

      final repo = locator.get<CartRepository>();
      expect(repo, isA<InMemoryCartRepository>());
    });
  });
}

