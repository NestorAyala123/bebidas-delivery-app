import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/cart/application/use_cases/calculate_cart_totals_use_case.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';

void main() {
  group('Cart Calculation Structure Tests (Estructura de Cálculo y RN05)', () {
    const storeId = 'store-test-1';

    const nonReturnableItem = CartItem(
      productId: 'prod-chips',
      productName: 'Snack Papas 150g',
      unitPrice: 2.50,
      quantity: 4,
      isReturnable: false,
    );

    const returnableBeer330 = CartItem(
      productId: 'prod-beer-330',
      productName: 'Cerveza Retornable 330ml',
      unitPrice: 1.50,
      quantity: 6,
      isReturnable: true,
      containerDeposit: 0.25,
    );

    const returnableBottle1L = CartItem(
      productId: 'prod-cider-1l',
      productName: 'Sidra Familiar 1L Retornable',
      unitPrice: 5.00,
      quantity: 2,
      isReturnable: true,
      containerDeposit: 1.00,
    );

    test('Empty cart calculation returns zero for all fields', () {
      const cart = Cart();
      final calc = cart.calculateTotals();

      expect(calc.itemsSubtotal, equals(0.0));
      expect(calc.totalItemCount, equals(0));
      expect(calc.totalContainersRequired, equals(0));
      expect(calc.returnedContainers, equals(0));
      expect(calc.missingContainers, equals(0));
      expect(calc.missingContainersFee, equals(0.0));
      expect(calc.deliveryFee, equals(0.0));
      expect(calc.discount, equals(0.0));
      expect(calc.total, equals(0.0));
      expect(calc.hasReturnableContainers, isFalse);
      expect(calc.hasMissingContainersFee, isFalse);
      expect(calc.isDeliveryFree, isTrue);
    });

    test('Cart with only non-returnable items calculates subtotal and zero container fees', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: nonReturnableItem);

      final calc = cart.calculateTotals(deliveryFee: 2.00);

      expect(calc.itemsSubtotal, equals(10.00)); // 4 * 2.50
      expect(calc.totalItemCount, equals(4));
      expect(calc.totalContainersRequired, equals(0));
      expect(calc.missingContainersFee, equals(0.0));
      expect(calc.deliveryFee, equals(2.00));
      expect(calc.total, equals(12.00));
      expect(calc.hasReturnableContainers, isFalse);
    });

    test('RN05: Charges full deposit when customer returns 0 empty containers', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330);

      final calc = cart.calculateTotals(returnedContainers: 0);

      expect(calc.itemsSubtotal, equals(9.00)); // 6 * 1.50
      expect(calc.totalContainersRequired, equals(6));
      expect(calc.returnedContainers, equals(0));
      expect(calc.missingContainers, equals(6));
      expect(calc.missingContainersFee, equals(1.50)); // 6 * 0.25
      expect(calc.total, equals(10.50)); // 9.00 + 1.50
      expect(calc.hasMissingContainersFee, isTrue);
      expect(calc.isFullyReturned, isFalse);
    });

    test('RN05: Charges 0 container fee when customer returns all required containers', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330);

      final calc = cart.calculateTotals(returnedContainers: 6);

      expect(calc.totalContainersRequired, equals(6));
      expect(calc.returnedContainers, equals(6));
      expect(calc.missingContainers, equals(0));
      expect(calc.missingContainersFee, equals(0.0));
      expect(calc.total, equals(9.00));
      expect(calc.hasMissingContainersFee, isFalse);
      expect(calc.isFullyReturned, isTrue);
    });

    test('RN05: Charges 0 container fee when customer returns more containers than required', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330);

      final calc = cart.calculateTotals(returnedContainers: 10);

      expect(calc.totalContainersRequired, equals(6));
      expect(calc.missingContainers, equals(0));
      expect(calc.missingContainersFee, equals(0.0));
      expect(calc.total, equals(9.00));
      expect(calc.isFullyReturned, isTrue);
    });

    test('RN05: Charges only the difference when customer partially returns containers', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330);

      // Customer returns 4 out of 6 containers -> 2 missing
      final calc = cart.calculateTotals(returnedContainers: 4);

      expect(calc.totalContainersRequired, equals(6));
      expect(calc.returnedContainers, equals(4));
      expect(calc.missingContainers, equals(2));
      expect(calc.missingContainersFee, equals(0.50)); // 2 * 0.25
      expect(calc.total, equals(9.50)); // 9.00 + 0.50
    });

    test('Multiple returnable items with different deposit values prioritize customer savings', () {
      var cart = const Cart();
      // 2 bottles of 1L ($1.00 deposit each) = 2 containers, $2.00 total deposit
      cart = cart.addItem(targetStoreId: storeId, item: returnableBottle1L);
      // 6 beers ($0.25 deposit each) = 6 containers, $1.50 total deposit
      cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330);

      expect(cart.totalReturnableContainers, equals(8));

      // If customer returns 2 containers:
      // The system waives the highest deposit units first ($1.00 each),
      // leaving 6 beers ($0.25 each) to be charged -> $1.50 missing fee
      final calc = cart.calculateTotals(returnedContainers: 2);
      expect(calc.totalContainersRequired, equals(8));
      expect(calc.returnedContainers, equals(2));
      expect(calc.missingContainers, equals(6));
      expect(calc.missingContainersFee, equals(1.50));
    });

    test('Complete calculation structure combines subtotal, container fees, delivery and discounts', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330); // Subtotal: 9.00, Req: 6 @ 0.25
      cart = cart.addItem(targetStoreId: storeId, item: nonReturnableItem); // Subtotal: 10.00

      // Returned 2 containers -> missing 4 -> missing fee: 4 * 0.25 = 1.00
      // Subtotal = 19.00
      // Delivery = 3.50
      // Discount = 2.00
      // Grand total = 19.00 + 1.00 + 3.50 - 2.00 = 21.50
      final calc = cart.calculateTotals(
        returnedContainers: 2,
        deliveryFee: 3.50,
        discount: 2.00,
      );

      expect(calc.itemsSubtotal, equals(19.00));
      expect(calc.totalItemCount, equals(10));
      expect(calc.totalContainersRequired, equals(6));
      expect(calc.returnedContainers, equals(2));
      expect(calc.missingContainers, equals(4));
      expect(calc.missingContainersFee, equals(1.00));
      expect(calc.deliveryFee, equals(3.50));
      expect(calc.discount, equals(2.00));
      expect(calc.total, equals(21.50));
    });

    test('Grand total does not go below zero when discount exceeds total cost', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: nonReturnableItem); // 10.00

      final calc = cart.calculateTotals(discount: 50.00);
      expect(calc.total, equals(0.0));
    });

    test('Negative arguments in calculateTotals are safely clamped', () {
      var cart = const Cart();
      cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330);

      final calc = cart.calculateTotals(
        returnedContainers: -5,
        deliveryFee: -10.0,
        discount: -2.0,
      );

      expect(calc.returnedContainers, equals(0));
      expect(calc.deliveryFee, equals(0.0));
      expect(calc.discount, equals(0.0));
      expect(calc.missingContainersFee, equals(1.50));
    });

    group('CalculateCartTotalsUseCase', () {
      const useCase = CalculateCartTotalsUseCase();

      test('Computes totals successfully with valid inputs', () async {
        var cart = const Cart();
        cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330);

        final result = await useCase(
          CalculateCartTotalsInput(
            cart: cart,
            returnedContainers: 3,
            deliveryFee: 1.50,
            discount: 0.50,
          ),
        );

        expect(result.isSuccess, isTrue);
        final calc = result.dataOrNull!;
        expect(calc.itemsSubtotal, equals(9.00));
        expect(calc.missingContainersFee, equals(0.75)); // (6 - 3) * 0.25
        expect(calc.deliveryFee, equals(1.50));
        expect(calc.discount, equals(0.50));
        expect(calc.total, equals(10.75)); // 9.00 + 0.75 + 1.50 - 0.50
      });

      test('Rejects negative parameters with ValidationFailure', () async {
        var cart = const Cart();
        cart = cart.addItem(targetStoreId: storeId, item: returnableBeer330);

        final res1 = await useCase(
          CalculateCartTotalsInput(cart: cart, returnedContainers: -1),
        );
        expect(res1.isFailure, isTrue);
        expect(res1.failureOrNull, isA<ValidationFailure>());

        final res2 = await useCase(
          CalculateCartTotalsInput(cart: cart, deliveryFee: -1.0),
        );
        expect(res2.isFailure, isTrue);
        expect(res2.failureOrNull, isA<ValidationFailure>());

        final res3 = await useCase(
          CalculateCartTotalsInput(cart: cart, discount: -1.0),
        );
        expect(res3.isFailure, isTrue);
        expect(res3.failureOrNull, isA<ValidationFailure>());
      });
    });
  });
}

