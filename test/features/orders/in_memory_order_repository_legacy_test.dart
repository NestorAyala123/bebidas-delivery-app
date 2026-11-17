// Tests para lib/features/orders/infrastructure/repositories/in_memory_order_repository.dart
// (implementación legacy utilizada por la feature stores).
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_delivery_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/infrastructure/repositories/in_memory_order_repository.dart';

Order _externalOrder({
  String id = 'order-1',
  String customerId = 'customer-1',
  OrderStatus status = OrderStatus.created,
}) => Order(
  id: id,
  customerId: customerId,
  storeId: 'store-1',
  status: status,
  deliveryMethod: OrderDeliveryMethod.externalDelivery,
  deliveryAddress: 'Manta',
  createdAt: DateTime(2026, 11, 6),
  items: const [
    OrderItem(
      productId: 'p-1',
      productName: 'Bebida',
      frozenUnitPrice: 3,
      quantity: 1,
    ),
  ],
);

Order _noDriversOrder() {
  final base = _externalOrder();
  return base
      .copyWithStatus(OrderStatus.confirmed)
      .copyWithStatus(OrderStatus.lookingForDriver)
      .copyWithStatus(OrderStatus.noDriversAvailable);
}

void main() {
  group('InMemoryOrderRepository (repositories/) — changeDeliveryMethodAfterNoDrivers', () {
    late InMemoryOrderRepository repository;

    setUp(() {
      repository = InMemoryOrderRepository();
    });

    test(
      'cambia método a pickup cuando el pedido está en noDriversAvailable',
      () async {
        await repository.createOrder(_noDriversOrder());

        final result = await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: 'order-1',
          customerId: 'customer-1',
          deliveryMethod: OrderDeliveryMethod.pickup,
        );

        expect(result.dataOrNull?.status, OrderStatus.preparing);
        expect(result.dataOrNull?.deliveryMethod, OrderDeliveryMethod.pickup);
      },
    );

    test('cambia método a storeDelivery cuando el pedido está en noDriversAvailable', () async {
      await repository.createOrder(_noDriversOrder());

      final result = await repository.changeDeliveryMethodAfterNoDrivers(
        orderId: 'order-1',
        customerId: 'customer-1',
        deliveryMethod: OrderDeliveryMethod.storeDelivery,
      );

      expect(result.dataOrNull?.status, OrderStatus.preparing);
      expect(
        result.dataOrNull?.deliveryMethod,
        OrderDeliveryMethod.storeDelivery,
      );
    });

    test('falla con NotFoundFailure si el pedido no existe', () async {
      final result = await repository.changeDeliveryMethodAfterNoDrivers(
        orderId: 'no-existe',
        customerId: 'customer-1',
        deliveryMethod: OrderDeliveryMethod.pickup,
      );

      expect(result.failureOrNull, isA<NotFoundFailure>());
    });

    test(
      'falla con UnauthorizedFailure si el cliente no es el propietario',
      () async {
        await repository.createOrder(_noDriversOrder());

        final result = await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: 'order-1',
          customerId: 'otro-cliente',
          deliveryMethod: OrderDeliveryMethod.pickup,
        );

        expect(result.failureOrNull, isA<UnauthorizedFailure>());
      },
    );

    test(
      'falla con BusinessRuleFailure si el estado no es noDriversAvailable',
      () async {
        // Pedido confirmado — no está en noDriversAvailable
        final order = _externalOrder().copyWithStatus(OrderStatus.confirmed);
        await repository.createOrder(order);

        final result = await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: 'order-1',
          customerId: 'customer-1',
          deliveryMethod: OrderDeliveryMethod.pickup,
        );

        expect(result.failureOrNull, isA<BusinessRuleFailure>());
      },
    );

    test(
      'falla con BusinessRuleFailure si el nuevo método es externalDelivery',
      () async {
        await repository.createOrder(_noDriversOrder());

        final result = await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: 'order-1',
          customerId: 'customer-1',
          deliveryMethod: OrderDeliveryMethod.externalDelivery,
        );

        expect(result.failureOrNull, isA<BusinessRuleFailure>());
      },
    );

    test('el historial registra la transición a preparing', () async {
      await repository.createOrder(_noDriversOrder());

      final result = await repository.changeDeliveryMethodAfterNoDrivers(
        orderId: 'order-1',
        customerId: 'customer-1',
        deliveryMethod: OrderDeliveryMethod.pickup,
      );

      final statuses = result.dataOrNull!.timeline
          .map((c) => c.status)
          .toList();
      expect(statuses.last, OrderStatus.preparing);
      expect(statuses, contains(OrderStatus.noDriversAvailable));
    });
  });
}
