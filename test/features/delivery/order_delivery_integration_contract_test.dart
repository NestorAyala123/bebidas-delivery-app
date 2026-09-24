import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/events/order_confirmed_notification.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/services/delivery_order_policy.dart';
import 'package:bebidas_delivery_app/features/orders/domain/contracts/order_delivery_contract.dart';

/// Fake test implementation of OrderDeliveryContract to prove complete decoupling from Orders infrastructure
class FakeOrderDeliveryContract implements OrderDeliveryContract {
  final Map<String, OrderDeliveryInfo> _orders = {};

  void addOrder(OrderDeliveryInfo order) {
    _orders[order.orderId] = order;
  }

  @override
  Future<Result<OrderDeliveryInfo, Failure>> getOrderDeliveryInfo(
    String orderId,
  ) async {
    final order = _orders[orderId];
    if (order != null) {
      return Success(order);
    }
    return const FailureResult(NotFoundFailure('Pedido no encontrado'));
  }
}

void main() {
  group('Order & Delivery Integration Contract Tests (Etapa 1.4.1)', () {
    const policy = DeliveryOrderPolicy();
    late FakeOrderDeliveryContract fakeContract;

    setUp(() {
      fakeContract = FakeOrderDeliveryContract();
    });

    test('1. Pedido no confirmado NO inicia búsqueda externa', () {
      const orderInfo = OrderDeliveryInfo(
        orderId: 'ord-unconfirmed-001',
        storeId: 'store-1',
        customerId: 'usr-1',
        pickupAddress: 'Av. Larco 100',
        deliveryAddress: 'Calle Berlin 200',
        isConfirmedByStore: false, // NO confirmado
        deliveryMethod: OrderDeliveryMethod.externalDelivery,
        totalItemsCount: 3,
        orderTotal: 45.0,
      );

      expect(orderInfo.requiresExternalDelivery, isTrue);
      expect(orderInfo.canInitiateExternalDelivery, isFalse);
      expect(policy.canCreateDeliveryRequest(orderInfo), isFalse);
    });

    test(
      '2. Pedido confirmado con retiro en tienda NO inicia delivery externo',
      () {
        const orderInfo = OrderDeliveryInfo(
          orderId: 'ord-pickup-002',
          storeId: 'store-1',
          customerId: 'usr-1',
          pickupAddress: 'Av. Larco 100',
          deliveryAddress: 'Av. Larco 100', // Retiro en tienda
          isConfirmedByStore: true,
          deliveryMethod: OrderDeliveryMethod.pickup, // Retiro explícito
          totalItemsCount: 2,
          orderTotal: 30.0,
        );

        expect(orderInfo.requiresExternalDelivery, isFalse);
        expect(orderInfo.canInitiateExternalDelivery, isFalse);
        expect(policy.canCreateDeliveryRequest(orderInfo), isFalse);
      },
    );

    test('3. Pedido confirmado con delivery propio del comercio NO inicia delivery externo', () {
      const orderInfo = OrderDeliveryInfo(
        orderId: 'ord-own-delivery-003',
        storeId: 'store-1',
        customerId: 'usr-1',
        pickupAddress: 'Av. Larco 100',
        deliveryAddress: 'Calle Schell 300',
        isConfirmedByStore: true,
        deliveryMethod: OrderDeliveryMethod.storeDelivery, // Delivery propio
        totalItemsCount: 5,
        orderTotal: 80.0,
      );

      expect(orderInfo.requiresExternalDelivery, isFalse);
      expect(orderInfo.canInitiateExternalDelivery, isFalse);
      expect(policy.canCreateDeliveryRequest(orderInfo), isFalse);
    });

    test('4. Pedido confirmado con delivery externo PUEDE iniciar creación de solicitud', () {
      const orderInfo = OrderDeliveryInfo(
        orderId: 'ord-external-004',
        storeId: 'store-1',
        customerId: 'usr-1',
        pickupAddress: 'Av. Larco 100',
        deliveryAddress: 'Calle Alcanfores 400',
        isConfirmedByStore: true,
        deliveryMethod: OrderDeliveryMethod
            .externalDelivery, // Requiere repartidor de la app
        distanceInKm: 2.1,
        totalItemsCount: 4,
        orderTotal: 65.0,
      );

      expect(orderInfo.requiresExternalDelivery, isTrue);
      expect(orderInfo.canInitiateExternalDelivery, isTrue);
      expect(policy.canCreateDeliveryRequest(orderInfo), isTrue);
    });

    test('5. Modalidad requerida explícitamente: pickup y storeDelivery derivan requiresExternalDelivery en false', () {
      const pickup = OrderDeliveryMethod.pickup;
      const storeDelivery = OrderDeliveryMethod.storeDelivery;
      const externalDelivery = OrderDeliveryMethod.externalDelivery;

      expect(pickup.isExternal, isFalse);
      expect(storeDelivery.isExternal, isFalse);
      expect(externalDelivery.isExternal, isTrue);
    });

    test('6. Contrato es independiente de implementaciones concretas de orders mediante Fake', () async {
      fakeContract.addOrder(
        const OrderDeliveryInfo(
          orderId: 'ord-fake-100',
          storeId: 'store-fake',
          customerId: 'usr-fake',
          pickupAddress: 'Av. Benavides 1000',
          deliveryAddress: 'Calle Mercaderes 500',
          isConfirmedByStore: true,
          deliveryMethod: OrderDeliveryMethod.externalDelivery,
          distanceInKm: 4.2,
          totalItemsCount: 2,
          orderTotal: 50.0,
        ),
      );

      final result = await fakeContract.getOrderDeliveryInfo('ord-fake-100');
      expect(result.isSuccess, isTrue);

      final retrieved = result.dataOrNull!;
      expect(retrieved.orderId, equals('ord-fake-100'));
      expect(retrieved.requiresExternalDelivery, isTrue);
      expect(retrieved.canInitiateExternalDelivery, isTrue);
      expect(policy.canCreateDeliveryRequest(retrieved), isTrue);

      final notFoundResult = await fakeContract.getOrderDeliveryInfo(
        'ord-nonexistent',
      );
      expect(notFoundResult.isFailure, isTrue);
    });

    test('7. Evento conceptual OrderConfirmedNotification refleja la intención de despacho', () {
      final now = DateTime.now();
      final notification = OrderConfirmedNotification(
        orderId: 'ord-event-01',
        storeId: 'store-1',
        customerId: 'usr-1',
        pickupAddress: 'Av. Pardo 500',
        deliveryAddress: 'Calle Porta 200',
        requiresExternalDelivery: true,
        orderTotal: 100.0,
        confirmedAt: now,
      );

      expect(notification.shouldDispatchExternalDriver, isTrue);
      expect(notification.orderId, equals('ord-event-01'));
      expect(notification.confirmedAt, equals(now));
    });
  });
}
