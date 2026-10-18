import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/exceptions.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/cart/application/use_cases/add_to_cart_use_case.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';
import 'package:bebidas_delivery_app/features/cart/domain/exceptions/cart_exceptions.dart';
import 'package:bebidas_delivery_app/features/cart/infrastructure/in_memory_cart_repository.dart';

void main() {
  group('RN07 - Single Store Constraint Tests (Restricción de Comercio Único)', () {
    const storeA = 'store-licoreria-centro';
    const storeB = 'store-bodega-norte';

    const itemStoreA1 = CartItem(
      productId: 'p-beer-pilsen',
      productName: 'Cerveza Pilsener 330ml',
      unitPrice: 1.50,
      quantity: 6,
      isReturnable: true,
      containerDeposit: 0.25,
    );

    const itemStoreA2 = CartItem(
      productId: 'p-snack-chips',
      productName: 'Papas Fritas 150g',
      unitPrice: 2.00,
      quantity: 2,
    );

    const itemStoreB1 = CartItem(
      productId: 'p-whisky-red',
      productName: 'Whisky Red Label 750ml',
      unitPrice: 28.00,
      quantity: 1,
    );

    test('Initial cart is empty and has no assigned storeId', () {
      const cart = Cart();
      expect(cart.isEmpty, isTrue);
      expect(cart.storeId, isNull);
      expect(cart.items, isEmpty);
      expect(cart.canAddItemFromStore(storeA), isTrue);
      expect(cart.canAddItemFromStore(storeB), isTrue);
    });

    test('Adding first item assigns targetStoreId to the cart', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);

      expect(cart.storeId, equals(storeA));
      expect(cart.isEmpty, isFalse);
      expect(cart.items.length, equals(1));
      expect(cart.totalItemCount, equals(6));
    });

    test('Adding multiple items from the same store succeeds', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA2);

      expect(cart.storeId, equals(storeA));
      expect(cart.items.length, equals(2));
      expect(cart.totalItemCount, equals(8));
      expect(cart.subtotal, equals(13.00)); // (6 * 1.50) + (2 * 2.00)
    });

    test('canAddItemFromStore returns true for same store, false for different store', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);

      expect(cart.canAddItemFromStore(storeA), isTrue);
      expect(cart.canAddItemFromStore('  $storeA  '), isTrue);
      expect(cart.canAddItemFromStore(storeB), isFalse);
      expect(cart.canAddItemFromStore(''), isFalse);
    });

    test('RN07: Adding item from different store throws SingleStoreViolationException and DomainException', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);

      expect(
        () => cart.addItem(targetStoreId: storeB, item: itemStoreB1),
        throwsA(isA<SingleStoreViolationException>()),
      );

      // Must also be catchable as DomainException for system consistency
      expect(
        () => cart.addItem(targetStoreId: storeB, item: itemStoreB1),
        throwsA(isA<DomainException>()),
      );
    });

    test('SingleStoreViolationException carries code RN07 and informative message', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);

      try {
        cart.addItem(targetStoreId: storeB, item: itemStoreB1);
        fail('Should have thrown SingleStoreViolationException');
      } on SingleStoreViolationException catch (e) {
        expect(e.code, equals('RN07'));
        expect(
          e.message,
          contains('RN07: No se pueden agregar productos de diferentes comercios'),
        );
      }
    });

    test('Cart state is immutable and untouched when store mismatch occurs', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);

      expect(
        () => cart.addItem(targetStoreId: storeB, item: itemStoreB1),
        throwsA(isA<SingleStoreViolationException>()),
      );

      // Verify cart still only has items from Store A
      expect(cart.storeId, equals(storeA));
      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals('p-beer-pilsen'));
      expect(cart.totalItemCount, equals(6));
    });

    test('Removing all items resets storeId to null and allows adding from another store', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);
      expect(cart.storeId, equals(storeA));

      // Remove the only item
      cart = cart.removeItem(itemStoreA1.productId);
      expect(cart.isEmpty, isTrue);
      expect(cart.storeId, isNull);

      // Now adding from Store B should succeed without error
      cart = cart.addItem(targetStoreId: storeB, item: itemStoreB1);
      expect(cart.storeId, equals(storeB));
      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals('p-whisky-red'));
    });

    test('Calling clear() resets storeId to null and allows adding from another store', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA2);
      expect(cart.storeId, equals(storeA));

      cart = cart.clear();
      expect(cart.isEmpty, isTrue);
      expect(cart.storeId, isNull);

      // Adding from Store B succeeds
      cart = cart.addItem(targetStoreId: storeB, item: itemStoreB1);
      expect(cart.storeId, equals(storeB));
      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals(itemStoreB1.productId));
    });

    test('replaceStoreAndSetItem discards previous store items and initiates cart with new store', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA1);
      cart = cart.addItem(targetStoreId: storeA, item: itemStoreA2);
      expect(cart.storeId, equals(storeA));
      expect(cart.items.length, equals(2));

      // User confirms switching to Store B
      cart = cart.replaceStoreAndSetItem(targetStoreId: storeB, item: itemStoreB1);
      expect(cart.storeId, equals(storeB));
      expect(cart.items.length, equals(1));
      expect(cart.items.first.productId, equals(itemStoreB1.productId));
      expect(cart.subtotal, equals(28.00));
    });

    test('Empty or blank targetStoreId is rejected with DomainException', () {
      var cart = const Cart();
      expect(
        () => cart.addItem(targetStoreId: '', item: itemStoreA1),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => cart.addItem(targetStoreId: '   ', item: itemStoreA1),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => cart.replaceStoreAndSetItem(targetStoreId: '', item: itemStoreA1),
        throwsA(isA<DomainException>()),
      );
    });

    group('AddToCartUseCase RN07 Integration', () {
      late InMemoryCartRepository repository;
      late AddToCartUseCase useCase;

      setUp(() {
        repository = InMemoryCartRepository();
        useCase = AddToCartUseCase(repository);
      });

      test('UseCase adds item to empty cart successfully', () async {
        final result = await useCase(
          const AddToCartInput(targetStoreId: storeA, item: itemStoreA1),
        );

        expect(result.isSuccess, isTrue);
        final cart = result.dataOrNull!;
        expect(cart.storeId, equals(storeA));
        expect(cart.totalItemCount, equals(6));
      });

      test('UseCase returns BusinessRuleFailure(RN07) when adding item from different store without force', () async {
        // Initial item in Store A
        await useCase(const AddToCartInput(targetStoreId: storeA, item: itemStoreA1));

        // Try to add from Store B without forceReplaceStore
        final result = await useCase(
          const AddToCartInput(targetStoreId: storeB, item: itemStoreB1),
        );

        expect(result.isFailure, isTrue);
        final failure = result.failureOrNull;
        expect(failure, isA<BusinessRuleFailure>());
        expect(failure?.code, equals('RN07'));
        expect(failure?.message, contains('RN07: No se pueden agregar productos'));

        // Verify repository still contains Store A cart
        final repoCart = (await repository.getCart()).dataOrNull!;
        expect(repoCart.storeId, equals(storeA));
        expect(repoCart.items.length, equals(1));
      });

      test('UseCase replaces store when forceReplaceStore is true', () async {
        // Initial item in Store A
        await useCase(const AddToCartInput(targetStoreId: storeA, item: itemStoreA1));

        // Switch to Store B with forceReplaceStore = true
        final result = await useCase(
          const AddToCartInput(
            targetStoreId: storeB,
            item: itemStoreB1,
            forceReplaceStore: true,
          ),
        );

        expect(result.isSuccess, isTrue);
        final cart = result.dataOrNull!;
        expect(cart.storeId, equals(storeB));
        expect(cart.items.length, equals(1));
        expect(cart.items.first.productId, equals(itemStoreB1.productId));
      });

      test('UseCase rejects empty targetStoreId with ValidationFailure', () async {
        final result = await useCase(
          const AddToCartInput(targetStoreId: '  ', item: itemStoreA1),
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
      });
    });
  });
}

