import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/exceptions.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_delivery_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';

void main() {
  group('Order Business Rules Tests', () {
    test('RN01: Can only search driver when order status is confirmed', () {
      final order = Order(
        id: 'ord-1',
        customerId: 'usr-1',
        storeId: 'store-1',
        status: OrderStatus.created,
        deliveryMethod: OrderDeliveryMethod.externalDelivery,
        deliveryAddress: 'Av. Siempre Viva 123',
        createdAt: DateTime.now(),
        items: [
          const OrderItem(
            productId: 'prod-1',
            productName: 'Cerveza Lager 330ml',
            frozenUnitPrice: 5.0,
            quantity: 6,
          ),
        ],
      );

      // Initially created -> cannot search driver
      expect(order.canRequestDriver, isFalse);
      expect(order.status.canSearchDriver, isFalse);

      // Store confirms order -> now can search driver
      final confirmedOrder = order.copyWithStatus(OrderStatus.confirmed);
      expect(confirmedOrder.canRequestDriver, isTrue);
      expect(confirmedOrder.status.canSearchDriver, isTrue);
    });

    test('Only valid order status transitions are allowed', () {
      final order = Order(
        id: 'ord-2',
        customerId: 'usr-1',
        storeId: 'store-1',
        status: OrderStatus.created,
        deliveryMethod: OrderDeliveryMethod.externalDelivery,
        deliveryAddress: 'Av. Siempre Viva 123',
        createdAt: DateTime.now(),
        items: [
          const OrderItem(
            productId: 'prod-1',
            productName: 'Cerveza Lager 330ml',
            frozenUnitPrice: 5.0,
            quantity: 1,
          ),
        ],
      );

      expect(
        () => order.copyWithStatus(OrderStatus.delivered),
        throwsA(isA<DomainException>()),
      );
      expect(
        () => order.copyWithStatus(OrderStatus.rejected),
        throwsA(isA<DomainException>()),
      );
      final rejected = order.copyWithStatus(
        OrderStatus.rejected,
        rejectionReason: 'Producto agotado',
      );
      expect(rejected.rejectionReason, 'Producto agotado');
      expect(
        () => rejected.copyWithStatus(OrderStatus.confirmed),
        throwsA(isA<DomainException>()),
      );
    });

    test('Delivery paths and cancellation rules depend on the selected method', () {
      final pickupOrder = _order(OrderDeliveryMethod.pickup);
      expect(
        pickupOrder.copyWithStatus(OrderStatus.confirmed)
            .copyWithStatus(OrderStatus.preparing)
            .copyWithStatus(OrderStatus.readyForPickup)
            .copyWithStatus(OrderStatus.pickedUp)
            .copyWithStatus(OrderStatus.delivered)
            .status,
        OrderStatus.delivered,
      );

      final ownDeliveryOrder = _order(OrderDeliveryMethod.storeDelivery);
      expect(
        ownDeliveryOrder.copyWithStatus(OrderStatus.confirmed)
            .copyWithStatus(OrderStatus.preparing)
            .copyWithStatus(OrderStatus.readyForDelivery)
            .copyWithStatus(OrderStatus.inDelivery)
            .copyWithStatus(OrderStatus.delivered)
            .status,
        OrderStatus.delivered,
      );

      final confirmed = _order(
        OrderDeliveryMethod.externalDelivery,
      ).copyWithStatus(OrderStatus.confirmed);
      expect(confirmed.canRequestDriver, isTrue);
      expect(confirmed.timeline.map((change) => change.status), [
        OrderStatus.created,
        OrderStatus.confirmed,
      ]);
      expect(
        confirmed.copyWithStatus(OrderStatus.cancelled).canCancel,
        isFalse,
      );
      final assigned = confirmed.copyWithStatus(
        OrderStatus.lookingForDriver,
      ).copyWithStatus(OrderStatus.driverAssigned);
      expect(
        () => assigned.copyWithStatus(OrderStatus.cancelled),
        throwsA(isA<DomainException>()),
      );
    });

    test('RN07: Cart throws DomainException when adding items from a different store', () {
      var cart = const Cart();

      // Add item from store-1
      cart = cart.addItem(
        targetStoreId: 'store-1',
        item: const CartItem(
          productId: 'prod-1',
          productName: 'Cerveza Pilsen',
          unitPrice: 5.0,
          quantity: 2,
        ),
      );

      expect(cart.storeId, equals('store-1'));
      expect(cart.totalItemCount, equals(2));

      // Attempt to add item from store-2 should fail
      expect(
        () => cart.addItem(
          targetStoreId: 'store-2',
          item: const CartItem(
            productId: 'prod-99',
            productName: 'Vino Tinto',
            unitPrice: 25.0,
            quantity: 1,
          ),
        ),
        throwsA(isA<DomainException>()),
      );
    });

    test('RN08: Order preserves frozen unit price even if catalog changes', () {
      final order = Order(
        id: 'ord-100',
        customerId: 'usr-1',
        storeId: 'store-1',
        status: OrderStatus.created,
        deliveryMethod: OrderDeliveryMethod.externalDelivery,
        deliveryAddress: 'Calle Falsa 123',
        createdAt: DateTime.now(),
        items: [
          const OrderItem(
            productId: 'prod-1',
            productName: 'Vodka Especial',
            frozenUnitPrice: 40.0, // Historical frozen price
            quantity: 2,
          ),
        ],
      );

      // Total subtotal reflects 40.0 * 2 = 80.0
      expect(order.itemsSubtotal, equals(80.0));
      expect(order.total, equals(80.0));
    });
  });
}

Order _order(OrderDeliveryMethod deliveryMethod) => Order(
  id: 'ord-delivery-path',
  customerId: 'usr-1',
  storeId: 'store-1',
  status: OrderStatus.created,
  deliveryMethod: deliveryMethod,
  deliveryAddress: 'Av. Siempre Viva 123',
  createdAt: DateTime(2026, 11, 6),
  items: const [
    OrderItem(
      productId: 'prod-1',
      productName: 'Cerveza',
      frozenUnitPrice: 3,
      quantity: 1,
    ),
  ],
);
