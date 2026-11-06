import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_delivery_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/infrastructure/in_memory_order_repository.dart';

void main() {
  group('Order lifecycle', () {
    final now = DateTime(2026, 11, 6, 12);

    test('pickup follows confirmation, preparation, pickup, and delivery', () async {
      final repository = InMemoryOrderRepository(null, () => now);
      await repository.createOrder(_order(OrderDeliveryMethod.pickup));

      final confirmed = await repository.confirmOrder(
        orderId: 'order-1',
        storeId: 'store-1',
      );
      expect(confirmed.dataOrNull?.status, OrderStatus.confirmed);

      final preparing = await repository.updateOrderStatus(
        orderId: 'order-1',
        storeId: 'store-1',
        status: OrderStatus.preparing,
      );
      expect(preparing.dataOrNull?.status, OrderStatus.preparing);

      final ready = await repository.updateOrderStatus(
        orderId: 'order-1',
        storeId: 'store-1',
        status: OrderStatus.readyForPickup,
      );
      expect(ready.dataOrNull?.status, OrderStatus.readyForPickup);

      final pickedUp = await repository.updateOrderStatus(
        orderId: 'order-1',
        storeId: 'store-1',
        status: OrderStatus.pickedUp,
      );
      expect(pickedUp.dataOrNull?.status, OrderStatus.pickedUp);

      final delivered = await repository.updateOrderStatus(
        orderId: 'order-1',
        storeId: 'store-1',
        status: OrderStatus.delivered,
      );
      final order = delivered.dataOrNull!;
      expect(order.status, OrderStatus.delivered);
      expect(order.timeline.map((change) => change.status), [
        OrderStatus.created,
        OrderStatus.confirmed,
        OrderStatus.preparing,
        OrderStatus.readyForPickup,
        OrderStatus.pickedUp,
        OrderStatus.delivered,
      ]);
    });

    test('own delivery cannot start before confirmation and can be tracked', () async {
      final repository = InMemoryOrderRepository(null, () => now);
      await repository.createOrder(_order(OrderDeliveryMethod.storeDelivery));

      final prematureDispatch = await repository.updateOrderStatus(
        orderId: 'order-1',
        storeId: 'store-1',
        status: OrderStatus.inDelivery,
      );
      expect(prematureDispatch.failureOrNull, isA<BusinessRuleFailure>());

      await repository.confirmOrder(orderId: 'order-1', storeId: 'store-1');
      await repository.updateOrderStatus(
        orderId: 'order-1',
        storeId: 'store-1',
        status: OrderStatus.preparing,
      );
      await repository.updateOrderStatus(
        orderId: 'order-1',
        storeId: 'store-1',
        status: OrderStatus.readyForDelivery,
      );
      final inDelivery = await repository.updateOrderStatus(
        orderId: 'order-1',
        storeId: 'store-1',
        status: OrderStatus.inDelivery,
      );
      expect(inDelivery.dataOrNull?.status, OrderStatus.inDelivery);
    });

    test('reject, cancellation, and store ownership are enforced', () async {
      final repository = InMemoryOrderRepository(null, () => now);
      await repository.createOrder(_order(OrderDeliveryMethod.externalDelivery));

      final wrongStore = await repository.confirmOrder(
        orderId: 'order-1',
        storeId: 'another-store',
      );
      expect(wrongStore.failureOrNull, isA<UnauthorizedFailure>());

      final rejected = await repository.rejectOrder(
        orderId: 'order-1',
        storeId: 'store-1',
        reason: 'Sin inventario',
      );
      expect(rejected.dataOrNull?.status, OrderStatus.rejected);
      expect(rejected.dataOrNull?.canRequestDriver, isFalse);
      expect(rejected.dataOrNull?.rejectionReason, 'Sin inventario');

      final cancelRepository = InMemoryOrderRepository(null, () => now);
      await cancelRepository.createOrder(
        _order(OrderDeliveryMethod.externalDelivery),
      );
      final cancelled = await cancelRepository.cancelOrder(
        orderId: 'order-1',
        customerId: 'customer-1',
      );
      expect(cancelled.dataOrNull?.status, OrderStatus.cancelled);

      final unauthorizedCancel = await cancelRepository.cancelOrder(
        orderId: 'order-1',
        customerId: 'another-customer',
      );
      expect(unauthorizedCancel.failureOrNull, isA<UnauthorizedFailure>());
    });
  });
}

Order _order(OrderDeliveryMethod method) => Order(
  id: 'order-1',
  customerId: 'customer-1',
  storeId: 'store-1',
  status: OrderStatus.created,
  deliveryMethod: method,
  deliveryAddress: 'Manta',
  createdAt: DateTime(2026, 11, 6, 11),
  items: const [
    OrderItem(
      productId: 'product-1',
      productName: 'Bebida',
      frozenUnitPrice: 3,
      quantity: 1,
    ),
  ],
);
