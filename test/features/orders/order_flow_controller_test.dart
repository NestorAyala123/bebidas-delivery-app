import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_mode.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/payment_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/services/order_flow_service.dart';
import 'package:bebidas_delivery_app/features/orders/infrastructure/repositories/in_memory_order_repository.dart';
import 'package:bebidas_delivery_app/features/orders/presentation/controllers/order_flow_controller.dart';

void main() {
  late InMemoryOrderRepository repository;
  late OrderFlowController controller;

  setUp(() {
    repository = InMemoryOrderRepository();
    controller = OrderFlowController(orderRepository: repository);
  });

  tearDown(() => controller.dispose());

  test('carga pedidos del cliente con distintos estados', () async {
    await controller.loadOrders('customer-demo');

    expect(controller.orders, isNotEmpty);
    expect(controller.orders.map((o) => o.id), contains('ord-demo-03'));
  });

  test('selecciona modalidad, registra pago y confirma checkout', () async {
    await controller.loadOrder('ord-demo-04');

    expect(
      controller.selectDeliveryMode(
        DeliveryMode.externalDriver,
        deliveryFee: 3.5,
      ),
      isTrue,
    );
    expect(controller.registerPayment(PaymentMethod.transfer), isTrue);
    expect(controller.activeOrder!.isCheckoutReady, isTrue);

    final confirmed = await controller.confirmCheckout();

    expect(confirmed, isTrue);
    final persisted = await repository.getOrderById('ord-demo-04');
    expect(persisted.dataOrNull!.paymentMethod, PaymentMethod.transfer);
    expect(persisted.dataOrNull!.deliveryFee, 3.5);
  });

  test('confirma checkout sin pago falla con mensaje', () async {
    await controller.loadOrder('ord-demo-04');

    final confirmed = await controller.confirmCheckout();

    expect(confirmed, isFalse);
    expect(controller.errorMessage, contains('método de pago'));
  });

  test('avanza estados y resuelve ausencia de repartidores', () async {
    await controller.loadOrder('ord-demo-04');
    controller.registerPayment(PaymentMethod.cash);

    expect(await controller.advanceTo(OrderStatus.confirmed), isTrue);
    expect(
      await controller.advanceTo(OrderStatus.lookingForDriver),
      isTrue,
    );

    expect(
      await controller.resolveNoDrivers(
        OrderNoDriversAction.pickupAtStore,
      ),
      isTrue,
    );
    expect(controller.activeOrder!.isPickup, isTrue);
    expect(controller.activeOrder!.deliveryFee, 0);
  });

  test('no ofrece delivery propio si el comercio no lo tiene', () async {
    controller.dispose();
    controller = OrderFlowController(
      orderRepository: repository,
      storeHasOwnDelivery: false,
      storeAllowsPickup: true,
    );
    await controller.loadOrder('ord-demo-03');

    expect(
      controller.noDriverActions.contains(
        OrderNoDriversAction.useStoreOwnDelivery,
      ),
      isFalse,
    );
    expect(
      controller.noDriverActions.contains(OrderNoDriversAction.pickupAtStore),
      isTrue,
    );
  });
}
