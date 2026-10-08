import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/exceptions.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';

void main() {
  group('Cart and CartItem Domain Entity Tests', () {
    const item1 = CartItem(
      productId: 'p-1',
      productName: 'Cerveza Club 330ml',
      unitPrice: 2.0,
      quantity: 3,
      isReturnable: true,
      containerDeposit: 0.5,
    );

    const item2 = CartItem(
      productId: 'p-2',
      productName: 'Agua Mineral 500ml',
      unitPrice: 1.0,
      quantity: 2,
    );

    test('CartItem calculates subtotal correctly', () {
      expect(item1.subtotal, equals(6.0));
      expect(item2.subtotal, equals(2.0));
    });

    test('CartItem throws assertion error if quantity <= 0', () {
      expect(
        () => CartItem(
          productId: 'p-3',
          productName: 'Item Invalido',
          unitPrice: 1.0,
          quantity: 0,
        ),
        throwsA(isA<AssertionError>()),
      );
    });

    test('Cart starts empty with zero total item count and zero subtotal', () {
      const cart = Cart();
      expect(cart.isEmpty, isTrue);
      expect(cart.totalItemCount, equals(0));
      expect(cart.subtotal, equals(0.0));
      expect(cart.storeId, isNull);
    });

    test('Adding items from the same store accumulates quantities and updates subtotal', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: 'store-1', item: item1);
      expect(cart.isEmpty, isFalse);
      expect(cart.storeId, equals('store-1'));
      expect(cart.totalItemCount, equals(3));
      expect(cart.subtotal, equals(6.0));

      // Add more of the same item
      cart = cart.addItem(
        targetStoreId: 'store-1',
        item: const CartItem(
          productId: 'p-1',
          productName: 'Cerveza Club 330ml',
          unitPrice: 2.0,
          quantity: 2,
        ),
      );
      expect(cart.items.length, equals(1));
      expect(cart.items.first.quantity, equals(5));
      expect(cart.totalItemCount, equals(5));
      expect(cart.subtotal, equals(10.0));

      // Add different item from same store
      cart = cart.addItem(targetStoreId: 'store-1', item: item2);
      expect(cart.items.length, equals(2));
      expect(cart.totalItemCount, equals(7));
      expect(cart.subtotal, equals(12.0));
    });

    test('RN07: Adding item from another store throws DomainException', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: 'store-1', item: item1);

      expect(
        () => cart.addItem(targetStoreId: 'store-2', item: item2),
        throwsA(isA<DomainException>()),
      );
    });

    test(
      'updateQuantity modifies quantity or removes item if quantity <= 0',
      () {
        var cart = const Cart();
        cart = cart.addItem(targetStoreId: 'store-1', item: item1);
        cart = cart.addItem(targetStoreId: 'store-1', item: item2);

        cart = cart.updateQuantity('p-1', 10);
        expect(
          cart.items.firstWhere((i) => i.productId == 'p-1').quantity,
          equals(10),
        );
        expect(cart.subtotal, equals(22.0)); // (10 * 2.0) + (2 * 1.0)

        // Setting quantity to 0 removes the item
        cart = cart.updateQuantity('p-1', 0);
        expect(cart.items.any((i) => i.productId == 'p-1'), isFalse);
        expect(cart.items.length, equals(1));
        expect(cart.subtotal, equals(2.0));
      },
    );

    test('removeItem removes item and resets storeId if cart is emptied', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: 'store-1', item: item1);

      cart = cart.removeItem('p-1');
      expect(cart.isEmpty, isTrue);
      expect(cart.storeId, isNull);

      // Now cart can accept items from another store since it was emptied
      cart = cart.addItem(targetStoreId: 'store-2', item: item2);
      expect(cart.storeId, equals('store-2'));
      expect(cart.items.length, equals(1));
    });

    test('clear empties the cart and resets storeId', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: 'store-1', item: item1);
      cart = cart.clear();

      expect(cart.isEmpty, isTrue);
      expect(cart.storeId, isNull);
    });
  });
}
