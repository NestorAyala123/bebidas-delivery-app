import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/order_delivery_alternatives_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_delivery_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_payment_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/infrastructure/in_memory_order_repository.dart';
import 'package:bebidas_delivery_app/features/stores/domain/entities/store.dart';
import 'package:bebidas_delivery_app/features/stores/infrastructure/repositories/in_memory_store_repository.dart';

void main() {
  group('OrderDeliveryAlternativesUseCase', () {
    late InMemoryOrderRepository orderRepository;
    late InMemoryStoreRepository storeRepository;
    late OrderDeliveryAlternativesUseCase useCase;

    setUp(() async {
      orderRepository = InMemoryOrderRepository();
      storeRepository = InMemoryStoreRepository();
      useCase = OrderDeliveryAlternativesUseCase(
        orders: orderRepository,
        stores: storeRepository,
      );
      await storeRepository.createStore(
        const Store(
          id: 'store-1',
          name: 'Comercio',
          address: 'Manta',
          isOpen: true,
          allowsPickup: true,
          hasOwnDelivery: false,
        ),
      );
      await orderRepository.createOrder(_noDriversOrder());
    });

    test('only returns alternatives the open store supports', () async {
      final result = await useCase.availableFor(
        order: _noDriversOrder(),
        customerId: 'customer-1',
      );

      expect(result.dataOrNull, [OrderDeliveryMethod.pickup]);
    });

    test('closed stores do not advertise pickup or store delivery', () async {
      await storeRepository.updateStoreStatus('store-1', false);
      final result = await useCase.availableFor(
        order: _noDriversOrder(),
        customerId: 'customer-1',
      );

      expect(result.dataOrNull, isEmpty);
    });

    test('selecting pickup changes method and resumes preparation', () async {
      final result = await useCase.select(
        order: _noDriversOrder(),
        customerId: 'customer-1',
        deliveryMethod: OrderDeliveryMethod.pickup,
      );

      final order = result.dataOrNull!;
      expect(order.deliveryMethod, OrderDeliveryMethod.pickup);
      expect(order.status, OrderStatus.preparing);
      expect(order.paymentMethod.displayName, 'Transferencia');
      expect(order.timeline.last.status, OrderStatus.preparing);
    });

    test('rejects own delivery when the store does not offer it', () async {
      final result = await useCase.select(
        order: _noDriversOrder(),
        customerId: 'customer-1',
        deliveryMethod: OrderDeliveryMethod.storeDelivery,
      );

      expect(result.failureOrNull, isA<BusinessRuleFailure>());
    });

    test(
      'wait resumes the external driver search for the order customer',
      () async {
        final result = await useCase.waitForAvailableDrivers(
          order: _noDriversOrder(),
          customerId: 'customer-1',
        );

        expect(result.dataOrNull?.status, OrderStatus.lookingForDriver);
      },
    );
  });
}

Order _noDriversOrder() {
  final order = Order(
    id: 'order-1',
    customerId: 'customer-1',
    storeId: 'store-1',
    status: OrderStatus.created,
    deliveryMethod: OrderDeliveryMethod.externalDelivery,
    paymentMethod: OrderPaymentMethod.bankTransfer,
    deliveryAddress: 'Manta',
    createdAt: DateTime(2026, 11, 11),
    items: const [
      OrderItem(
        productId: 'product-1',
        productName: 'Bebida',
        frozenUnitPrice: 3,
        quantity: 1,
      ),
    ],
  );
  return order
      .copyWithStatus(OrderStatus.confirmed)
      .copyWithStatus(OrderStatus.lookingForDriver)
      .copyWithStatus(OrderStatus.noDriversAvailable);
}
