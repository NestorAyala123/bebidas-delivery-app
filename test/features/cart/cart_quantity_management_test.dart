import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';
import 'package:bebidas_delivery_app/features/cart/domain/exceptions/cart_exceptions.dart';

void main() {
  group('Cart Quantity Management Tests (Cantidades y Manipulación de Ítems)', () {
    const storeId = 'store-test-quantities';

    const itemA = CartItem(
      productId: 'p-a',
      productName: 'Cerveza Corona 355ml',
      unitPrice: 2.50,
      quantity: 2,
    );

    const itemB = CartItem(
      productId: 'p-b',
      productName: 'Tónica 200ml',
      unitPrice: 1.25,
      quantity: 3,
    );

    test('Adding the same product multiple times accumulates its quantity', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);
      expect(cart.items.length, equals(1));
      expect(cart.totalItemCount, equals(2));
      expect(cart.subtotal, equals(5.00));

      // Add 3 more of itemA
      cart = cart.addItem(
        targetStoreId: storeId,
        item: itemA.copyWith(quantity: 3),
      );

      expect(cart.items.length, equals(1)); // Still 1 unique item
      expect(cart.items.first.quantity, equals(5));
      expect(cart.totalItemCount, equals(5));
      expect(cart.subtotal, equals(12.50));
    });

    test('uniqueProductCount reflects unique items, totalItemCount reflects total units', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA); // 2 units
      cart = cart.addItem(targetStoreId: storeId, item: itemB); // 3 units

      expect(cart.uniqueProductCount, equals(2));
      expect(cart.totalItemCount, equals(5));
      expect(cart.hasProduct('p-a'), isTrue);
      expect(cart.hasProduct('p-b'), isTrue);
      expect(cart.hasProduct('p-unknown'), isFalse);
    });

    test('getItem returns item if present, null otherwise', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);

      final found = cart.getItem('p-a');
      expect(found, isNotNull);
      expect(found?.productName, equals('Cerveza Corona 355ml'));

      final notFound = cart.getItem('p-non-existent');
      expect(notFound, isNull);
    });

    test('updateQuantity directly modifies quantity and subtotal', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);

      cart = cart.updateQuantity('p-a', 10);
      expect(cart.getItem('p-a')?.quantity, equals(10));
      expect(cart.totalItemCount, equals(10));
      expect(cart.subtotal, equals(25.00));
    });

    test('updateQuantity with 0 or negative quantity removes item', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);
      cart = cart.addItem(targetStoreId: storeId, item: itemB);

      // Setting p-a to 0 removes it
      cart = cart.updateQuantity('p-a', 0);
      expect(cart.hasProduct('p-a'), isFalse);
      expect(cart.uniqueProductCount, equals(1));
      expect(cart.totalItemCount, equals(3));

      // Setting p-b to -1 removes it, emptying cart and resetting storeId
      cart = cart.updateQuantity('p-b', -1);
      expect(cart.isEmpty, isTrue);
      expect(cart.storeId, isNull);
    });

    test('incrementQuantity increases quantity by default amount 1', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA); // quantity: 2

      cart = cart.incrementQuantity('p-a');
      expect(cart.getItem('p-a')?.quantity, equals(3));
      expect(cart.totalItemCount, equals(3));
    });

    test('incrementQuantity with custom amount increases accordingly', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);

      cart = cart.incrementQuantity('p-a', 5);
      expect(cart.getItem('p-a')?.quantity, equals(7));
      expect(cart.totalItemCount, equals(7));
    });

    test('incrementQuantity on non-existent product throws CartItemNotFoundException', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);

      expect(
        () => cart.incrementQuantity('p-non-existent'),
        throwsA(isA<CartItemNotFoundException>()),
      );
    });

    test('incrementQuantity with amount <= 0 throws InvalidCartQuantityException', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);

      expect(
        () => cart.incrementQuantity('p-a', 0),
        throwsA(isA<InvalidCartQuantityException>()),
      );
      expect(
        () => cart.incrementQuantity('p-a', -2),
        throwsA(isA<InvalidCartQuantityException>()),
      );
    });

    test('decrementQuantity decreases quantity by 1 by default', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA); // quantity: 2

      cart = cart.decrementQuantity('p-a');
      expect(cart.getItem('p-a')?.quantity, equals(1));
      expect(cart.totalItemCount, equals(1));
    });

    test('decrementQuantity removes item when resulting quantity is <= 0', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA); // quantity: 2

      // Decrement by 2 -> reaches 0 -> removes item
      cart = cart.decrementQuantity('p-a', 2);
      expect(cart.hasProduct('p-a'), isFalse);
      expect(cart.isEmpty, isTrue);
      expect(cart.storeId, isNull);
    });

    test('decrementQuantity on non-existent product throws CartItemNotFoundException', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);

      expect(
        () => cart.decrementQuantity('p-non-existent'),
        throwsA(isA<CartItemNotFoundException>()),
      );
    });

    test('decrementQuantity with amount <= 0 throws InvalidCartQuantityException', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: itemA);

      expect(
        () => cart.decrementQuantity('p-a', 0),
        throwsA(isA<InvalidCartQuantityException>()),
      );
      expect(
        () => cart.decrementQuantity('p-a', -3),
        throwsA(isA<InvalidCartQuantityException>()),
      );
    });

    test('CartItem helper methods increment and decrement', () {
      const item = CartItem(
        productId: 'p-1',
        productName: 'Vino',
        unitPrice: 10.0,
        quantity: 3,
      );

      final inc = item.increment(2);
      expect(inc.quantity, equals(5));

      final dec = inc.decrement(3);
      expect(dec.quantity, equals(2));

      expect(() => dec.decrement(2), throwsA(isA<AssertionError>()));
    });
  });
}

