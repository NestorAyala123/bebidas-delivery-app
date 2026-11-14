import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_mode.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/payment_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/services/order_flow_service.dart';

void main() {
  const service = OrderFlowService();
  final base = DateTime(2026, 11, 15, 10);

  Order buildOrder({
    OrderStatus status = OrderStatus.created,
    DeliveryMode mode = DeliveryMode.externalDriver,
    PaymentMethod? payment,
    double fee = 0,
  }) {
    return Order(
      id: 'ord-1',
      customerId: 'customer-demo',
      storeId: 'store-1',
      items: const [
        OrderItem(
          productId: 'prod-1',
          productName: 'Cerveza',
          frozenUnitPrice: 2.5,
          quantity: 4,
        ),
      ],
      status: status,
      deliveryAddress: 'Av. Malecón',
      deliveryMode: mode,
      paymentMethod: payment,
      deliveryFee: fee,
      createdAt: base,
    );
  }

  group('Modalidad de entrega (RN02)', () {
    test('permite las modalidades soportadas por el comercio', () {
      final order = buildOrder();

      expect(
        service
            .selectDeliveryMode(
              order: order,
              mode: DeliveryMode.ownDelivery,
              storeHasOwnDelivery: true,
              storeAllowsExternalDelivery: true,
              storeAllowsPickup: true,
            )
            .isSuccess,
        isTrue,
      );
    });

    test('rechaza delivery propio si el comercio no lo ofrece', () {
      final result = service.selectDeliveryMode(
        order: buildOrder(),
        mode: DeliveryMode.ownDelivery,
        storeHasOwnDelivery: false,
        storeAllowsExternalDelivery: true,
        storeAllowsPickup: true,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('RN02'));
    });

    test('retiro en local deja el envío en cero', () {
      final result = service.selectDeliveryMode(
        order: buildOrder(fee: 5),
        mode: DeliveryMode.pickupAtStore,
        storeHasOwnDelivery: true,
        storeAllowsExternalDelivery: true,
        storeAllowsPickup: true,
        deliveryFee: 5,
      );

      expect(result.dataOrNull!.deliveryMode, DeliveryMode.pickupAtStore);
      expect(result.dataOrNull!.deliveryFee, 0);
      expect(result.dataOrNull!.total, 10);
    });
  });

  group('Método de pago', () {
    test('registra efectivo o transferencia', () {
      final cash = service.registerPaymentMethod(
        order: buildOrder(),
        method: PaymentMethod.cash,
      );

      expect(cash.dataOrNull!.isPaymentRegistered, isTrue);
      expect(cash.dataOrNull!.paymentMethod, PaymentMethod.cash);

      final transfer = service.registerPaymentMethod(
        order: cash.dataOrNull!,
        method: PaymentMethod.transfer,
      );

      expect(transfer.dataOrNull!.paymentMethod, PaymentMethod.transfer);
    });

    test('exige pago registrado para confirmar el checkout', () {
      expect(
        service.validatePaymentReady(buildOrder()).isFailure,
        isTrue,
      );
      expect(
        service
            .validatePaymentReady(buildOrder(payment: PaymentMethod.cash))
            .isSuccess,
        isTrue,
      );
    });
  });

  group('Transiciones de estado', () {
    test('permite created -> confirmed -> lookingForDriver con checkout', () {
      final created = buildOrder(payment: PaymentMethod.cash);
      final confirmed = service.transition(created, OrderStatus.confirmed);
      expect(confirmed.isSuccess, isTrue);

      final looking = service.transition(
        confirmed.dataOrNull!,
        OrderStatus.lookingForDriver,
      );
      expect(looking.isSuccess, isTrue);
    });

    test('rechaza saltos inválidos', () {
      final result = service.transition(
        buildOrder(payment: PaymentMethod.cash),
        OrderStatus.delivered,
      );
      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('no permitida'));
    });

    test('no busca repartidor sin pago registrado (RN01)', () {
      final confirmed = buildOrder(status: OrderStatus.confirmed);
      final result = service.transition(
        confirmed,
        OrderStatus.lookingForDriver,
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('RN01'));
    });
  });

  group('Alternativas sin repartidores (RN03)', () {
    Order looking({double fee = 2}) => buildOrder(
          status: OrderStatus.lookingForDriver,
          payment: PaymentMethod.transfer,
          fee: fee,
        );

    test('esperar mantiene el pedido buscando repartidor', () {
      final result = service.resolveNoDrivers(
        order: looking(),
        action: OrderNoDriversAction.wait,
        storeHasOwnDelivery: false,
        storeAllowsPickup: true,
      );

      expect(result.dataOrNull!.order.deliveryFee, 2);
      expect(result.dataOrNull!.message, contains('buscando'));
    });

    test('aumentar oferta exige una tarifa mayor', () {
      final rejected = service.resolveNoDrivers(
        order: looking(),
        action: OrderNoDriversAction.increaseOffer,
        storeHasOwnDelivery: false,
        storeAllowsPickup: true,
        increasedFee: 2,
      );
      expect(rejected.isFailure, isTrue);

      final accepted = service.resolveNoDrivers(
        order: looking(),
        action: OrderNoDriversAction.increaseOffer,
        storeHasOwnDelivery: false,
        storeAllowsPickup: true,
        increasedFee: 3.5,
      );
      expect(accepted.dataOrNull!.order.deliveryFee, 3.5);
    });

    test('retiro en local aplica solo si el comercio lo permite', () {
      final rejected = service.resolveNoDrivers(
        order: looking(),
        action: OrderNoDriversAction.pickupAtStore,
        storeHasOwnDelivery: false,
        storeAllowsPickup: false,
      );
      expect(rejected.isFailure, isTrue);

      final accepted = service.resolveNoDrivers(
        order: looking(),
        action: OrderNoDriversAction.pickupAtStore,
        storeHasOwnDelivery: false,
        storeAllowsPickup: true,
      );
      expect(
        accepted.dataOrNull!.order.deliveryMode,
        DeliveryMode.pickupAtStore,
      );
      expect(accepted.dataOrNull!.order.deliveryFee, 0);
    });

    test('delivery propio y cancelación respetan reglas del comercio', () {
      final rejected = service.resolveNoDrivers(
        order: looking(),
        action: OrderNoDriversAction.useStoreOwnDelivery,
        storeHasOwnDelivery: false,
        storeAllowsPickup: true,
      );
      expect(rejected.isFailure, isTrue);

      final own = service.resolveNoDrivers(
        order: looking(),
        action: OrderNoDriversAction.useStoreOwnDelivery,
        storeHasOwnDelivery: true,
        storeAllowsPickup: true,
      );
      expect(own.dataOrNull!.order.deliveryMode, DeliveryMode.ownDelivery);

      final cancel = service.resolveNoDrivers(
        order: looking(),
        action: OrderNoDriversAction.cancelOrder,
        storeHasOwnDelivery: true,
        storeAllowsPickup: true,
      );
      expect(cancel.dataOrNull!.order.status, OrderStatus.cancelled);
    });
  });
}
