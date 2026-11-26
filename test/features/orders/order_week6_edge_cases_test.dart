import 'package:bebidas_delivery_app/core/errors/exceptions.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/cancel_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/confirm_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/create_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/reject_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/update_order_status_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_delivery_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_payment_method.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/infrastructure/in_memory_order_repository.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/quantity_pricing_tier.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  final baseTime = DateTime(2026, 11, 25, 19);
  final actionTime = DateTime(2026, 11, 25, 20);

  group('Importes y precios históricos', () {
    test(
      'calcula subtotales por rango, envases faltantes y total congelado',
      () async {
        final repository = InMemoryOrderRepository(null, () => actionTime);
        final createOrder = CreateOrderUseCase(
          repository: repository,
          generateOrderId: () => 'ORD-AMOUNT-1',
          now: () => baseTime,
        );

        const beer = Product(
          id: 'prod-beer',
          storeId: 'store-1',
          name: 'Cerveza Retornable',
          basePrice: 3.00,
          isReturnableContainer: true,
          containerDepositPrice: 0.50,
          quantityTiers: [QuantityPricingTier(minQuantity: 6, unitPrice: 2.40)],
        );
        const snack = Product(
          id: 'prod-snack',
          storeId: 'store-1',
          name: 'Snack',
          basePrice: 1.75,
        );

        var cart = const Cart();
        cart = cart.addItem(
          targetStoreId: 'store-1',
          item: CartItem.fromProduct(beer, quantity: 6),
        );
        cart = cart.addItem(
          targetStoreId: 'store-1',
          item: CartItem.fromProduct(snack, quantity: 2),
        );

        final result = await createOrder(
          CreateOrderInput.fromCart(
            customerId: ' customer-1 ',
            deliveryAddress: ' Av. Flavio Reyes ',
            cart: cart,
            deliveryMethod: OrderDeliveryMethod.externalDelivery,
            paymentMethod: OrderPaymentMethod.bankTransfer,
            returnedContainers: 4, // 6 requeridos - 4 devueltos = 2 * 0.50
          ),
        );

        final order = result.dataOrNull!;
        expect(order.customerId, 'customer-1');
        expect(order.deliveryAddress, 'Av. Flavio Reyes');
        expect(order.items.first.frozenUnitPrice, 2.40);
        expect(order.itemsSubtotal, closeTo(17.90, 0.0001));
        expect(order.missingContainersFee, closeTo(1.00, 0.0001));
        expect(order.total, closeTo(18.90, 0.0001));
      },
    );

    test('rechaza importes inválidos y pedidos con id duplicado', () async {
      final repository = InMemoryOrderRepository([_order()], () => actionTime);
      final createOrder = CreateOrderUseCase(
        repository: repository,
        generateOrderId: () => 'order-1',
        now: () => baseTime,
      );
      final validCart = const Cart().addItem(
        targetStoreId: 'store-1',
        item: const CartItem(
          productId: 'p-1',
          productName: 'Agua',
          unitPrice: 1.5,
          quantity: 1,
        ),
      );

      for (final invalidFee in [-0.01, double.nan, double.infinity]) {
        final invalid = await createOrder(
          CreateOrderInput(
            customerId: 'customer-1',
            deliveryAddress: 'Manta',
            cart: validCart,
            deliveryMethod: OrderDeliveryMethod.pickup,
            paymentMethod: OrderPaymentMethod.cash,
            missingContainersFee: invalidFee,
          ),
        );
        expect(invalid.failureOrNull, isA<ValidationFailure>());
      }

      final blankIdUseCase = CreateOrderUseCase(
        repository: repository,
        generateOrderId: () => '   ',
      );
      final blankId = await blankIdUseCase(
        CreateOrderInput(
          customerId: 'customer-1',
          deliveryAddress: 'Manta',
          cart: validCart,
          deliveryMethod: OrderDeliveryMethod.pickup,
          paymentMethod: OrderPaymentMethod.cash,
        ),
      );
      expect(blankId.failureOrNull, isA<ValidationFailure>());

      final duplicate = await createOrder(
        CreateOrderInput(
          customerId: 'customer-1',
          deliveryAddress: 'Manta',
          cart: validCart,
          deliveryMethod: OrderDeliveryMethod.pickup,
          paymentMethod: OrderPaymentMethod.cash,
        ),
      );
      expect(duplicate.failureOrNull, isA<BusinessRuleFailure>());
      expect((await repository.getOrderById('order-1')).dataOrNull?.total, 2.0);
    });

    test(
      'mantiene precios históricos congelados a través de cambios de estado y modalidad',
      () async {
        final repository = InMemoryOrderRepository(null, () => actionTime);
        final createOrder = CreateOrderUseCase(
          repository: repository,
          generateOrderId: () => 'ORD-HIST',
          now: () => baseTime,
        );

        var catalogProduct = const Product(
          id: 'whisky',
          storeId: 'store-1',
          name: 'Whisky',
          basePrice: 12.00,
          isReturnableContainer: true,
          containerDepositPrice: 1.00,
          quantityTiers: [QuantityPricingTier(minQuantity: 3, unitPrice: 9.50)],
        );
        final cart = const Cart().addItem(
          targetStoreId: 'store-1',
          item: CartItem.fromProduct(catalogProduct, quantity: 3),
        );

        final created = (await createOrder(
          CreateOrderInput.fromCart(
            customerId: 'customer-1',
            deliveryAddress: 'Manta',
            cart: cart,
            deliveryMethod: OrderDeliveryMethod.externalDelivery,
            paymentMethod: OrderPaymentMethod.cash,
            returnedContainers: 1,
          ),
        )).dataOrNull!;

        catalogProduct = const Product(
          id: 'whisky',
          storeId: 'store-1',
          name: 'Whisky',
          basePrice: 40.00,
          isReturnableContainer: true,
          containerDepositPrice: 5.00,
          quantityTiers: [QuantityPricingTier(minQuantity: 3, unitPrice: 35.00)],
        );
        expect(catalogProduct.getUnitPriceForQuantity(3), 35.00);

        await repository.confirmOrder(orderId: created.id, storeId: 'store-1');
        await repository.updateOrderStatus(
          orderId: created.id,
          storeId: 'store-1',
          status: OrderStatus.lookingForDriver,
        );
        await repository.updateOrderStatus(
          orderId: created.id,
          storeId: 'store-1',
          status: OrderStatus.noDriversAvailable,
        );
        final switched = (await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: created.id,
          customerId: 'customer-1',
          deliveryMethod: OrderDeliveryMethod.pickup,
        )).dataOrNull!;

        expect(switched.items.single.frozenUnitPrice, 9.50);
        expect(switched.items.single.containerDepositPrice, 1.00);
        expect(switched.itemsSubtotal, 28.50);
        expect(switched.missingContainersFee, 2.00);
        expect(switched.total, 30.50);
      },
    );
  });

  group('Estados, confirmación y rechazo', () {
    test(
      'confirmación fija confirmedAt, respeta comercio y no permite reconfirmar',
      () async {
        final repository = InMemoryOrderRepository([_order()], () => actionTime);
        final confirm = ConfirmOrderUseCase(repository);

        final wrongStore = await confirm(
          const ConfirmOrderInput(orderId: 'order-1', storeId: 'store-2'),
        );
        expect(wrongStore.failureOrNull, isA<UnauthorizedFailure>());

        final missingOrder = await confirm(
          const ConfirmOrderInput(orderId: 'missing', storeId: 'store-1'),
        );
        expect(missingOrder.failureOrNull, isA<NotFoundFailure>());

        final confirmed = (await confirm(
          const ConfirmOrderInput(orderId: ' order-1 ', storeId: ' store-1 '),
        )).dataOrNull!;
        expect(confirmed.status, OrderStatus.confirmed);
        expect(confirmed.confirmedAt, actionTime);
        expect(confirmed.canRequestDriver, isTrue);
        expect(confirmed.timeline.map((e) => e.status), [
          OrderStatus.created,
          OrderStatus.confirmed,
        ]);

        final secondConfirm = await confirm(
          const ConfirmOrderInput(orderId: 'order-1', storeId: 'store-1'),
        );
        expect(secondConfirm.failureOrNull, isA<BusinessRuleFailure>());
      },
    );

    test(
      'copyWithStatus(confirmed) asigna confirmedAt por defecto si no se envía',
      () {
        final confirmed = _order().copyWithStatus(
          OrderStatus.confirmed,
          changedAt: actionTime,
        );
        expect(confirmed.confirmedAt, actionTime);
      },
    );

    test('rechazo exige motivo no vacío y bloquea transiciones posteriores', () async {
      final repository = InMemoryOrderRepository([_order()], () => actionTime);
      final reject = RejectOrderUseCase(repository);

      final blankUseCase = await reject(
        const RejectOrderInput(
          orderId: 'order-1',
          storeId: 'store-1',
          reason: '   ',
        ),
      );
      expect(blankUseCase.failureOrNull, isA<ValidationFailure>());

      final blankRepo = await repository.rejectOrder(
        orderId: 'order-1',
        storeId: 'store-1',
        reason: '   ',
      );
      expect(blankRepo.failureOrNull, isA<ValidationFailure>());

      final wrongStore = await reject(
        const RejectOrderInput(
          orderId: 'order-1',
          storeId: 'other-store',
          reason: 'Sin stock',
        ),
      );
      expect(wrongStore.failureOrNull, isA<UnauthorizedFailure>());

      final rejected = (await reject(
        const RejectOrderInput(
          orderId: 'order-1',
          storeId: 'store-1',
          reason: '  Producto agotado  ',
        ),
      )).dataOrNull!;
      expect(rejected.status, OrderStatus.rejected);
      expect(rejected.status.isTerminal, isTrue);
      expect(rejected.canRequestDriver, isFalse);
      expect(rejected.canCancel, isFalse);
      expect(rejected.rejectionReason, 'Producto agotado');

      final confirmAfterReject = await repository.confirmOrder(
        orderId: 'order-1',
        storeId: 'store-1',
      );
      expect(confirmAfterReject.failureOrNull, isA<BusinessRuleFailure>());
    });
  });

  group('Cancelaciones y límites de autorización', () {
    test(
      'permite cancelar en todos los estados declarados como cancelables',
      () async {
        final cancellableOrders = <String, Order>{
          'created': _order(id: 'created'),
          'confirmed': _order(id: 'confirmed').copyWithStatus(OrderStatus.confirmed),
          'preparing': _order(id: 'preparing')
              .copyWithStatus(OrderStatus.confirmed)
              .copyWithStatus(OrderStatus.preparing),
          'readyForPickup': _order(
            id: 'readyForPickup',
            method: OrderDeliveryMethod.pickup,
          )
              .copyWithStatus(OrderStatus.confirmed)
              .copyWithStatus(OrderStatus.preparing)
              .copyWithStatus(OrderStatus.readyForPickup),
          'readyForDelivery': _order(
            id: 'readyForDelivery',
            method: OrderDeliveryMethod.storeDelivery,
          )
              .copyWithStatus(OrderStatus.confirmed)
              .copyWithStatus(OrderStatus.preparing)
              .copyWithStatus(OrderStatus.readyForDelivery),
          'lookingForDriver': _order(id: 'lookingForDriver')
              .copyWithStatus(OrderStatus.confirmed)
              .copyWithStatus(OrderStatus.lookingForDriver),
          'noDriversAvailable': _order(id: 'noDriversAvailable')
              .copyWithStatus(OrderStatus.confirmed)
              .copyWithStatus(OrderStatus.lookingForDriver)
              .copyWithStatus(OrderStatus.noDriversAvailable),
        };

        final repository = InMemoryOrderRepository(
          cancellableOrders.values.toList(),
          () => actionTime,
        );
        final cancelUseCase = CancelOrderUseCase(repository);

        for (final entry in cancellableOrders.entries) {
          expect(entry.value.canCancel, isTrue, reason: entry.key);
          final res = await cancelUseCase(
            orderId: entry.key,
            customerId: 'customer-1',
          );
          expect(res.dataOrNull?.status, OrderStatus.cancelled, reason: entry.key);
          expect(res.dataOrNull?.canCancel, isFalse, reason: entry.key);
        }
      },
    );

    test(
      'impide cancelar fuera de tiempo, por otro usuario o dos veces',
      () async {
        final nonCancellableOrders = <Order>[
          _order(id: 'pickedUp', method: OrderDeliveryMethod.pickup)
              .copyWithStatus(OrderStatus.confirmed)
              .copyWithStatus(OrderStatus.preparing)
              .copyWithStatus(OrderStatus.readyForPickup)
              .copyWithStatus(OrderStatus.pickedUp),
          _order(id: 'driverAssigned')
              .copyWithStatus(OrderStatus.confirmed)
              .copyWithStatus(OrderStatus.lookingForDriver)
              .copyWithStatus(OrderStatus.driverAssigned),
          _order(id: 'inDelivery', method: OrderDeliveryMethod.storeDelivery)
              .copyWithStatus(OrderStatus.confirmed)
              .copyWithStatus(OrderStatus.preparing)
              .copyWithStatus(OrderStatus.readyForDelivery)
              .copyWithStatus(OrderStatus.inDelivery),
          _deliveredOrder(id: 'delivered'),
          _order(id: 'rejected').copyWithStatus(
            OrderStatus.rejected,
            rejectionReason: 'Cerrado',
          ),
          _order(id: 'cancelled').copyWithStatus(OrderStatus.cancelled),
        ];

        final repository = InMemoryOrderRepository(
          nonCancellableOrders,
          () => actionTime,
        );

        for (final order in nonCancellableOrders) {
          expect(order.canCancel, isFalse, reason: order.id);
          final res = await repository.cancelOrder(
            orderId: order.id,
            customerId: 'customer-1',
          );
          expect(
            res.failureOrNull,
            isA<BusinessRuleFailure>(),
            reason: order.id,
          );
        }

        final wrongCustomer = await repository.cancelOrder(
          orderId: 'pickedUp',
          customerId: 'store-1',
        );
        expect(wrongCustomer.failureOrNull, isA<UnauthorizedFailure>());
      },
    );
  });

  group('Transiciones y casos límite', () {
    test(
      'valida rutas por modalidad y bloquea saltos o cambios directos prohibidos',
      () async {
        final repository = InMemoryOrderRepository([
          _order(id: 'pickup', method: OrderDeliveryMethod.pickup),
          _order(id: 'own', method: OrderDeliveryMethod.storeDelivery),
          _order(id: 'ext', method: OrderDeliveryMethod.externalDelivery),
        ], () => actionTime);
        final updateStatus = UpdateOrderStatusUseCase(repository);

        // Despacho prematuro sin confirmación
        final premature = await updateStatus(
          const UpdateOrderStatusInput(
            orderId: 'ext',
            storeId: 'store-1',
            status: OrderStatus.inDelivery,
          ),
        );
        expect(premature.failureOrNull, isA<BusinessRuleFailure>());

        // updateOrderStatus no debe permitir estados con operación dedicada
        for (final restricted in [
          OrderStatus.created,
          OrderStatus.confirmed,
          OrderStatus.rejected,
          OrderStatus.cancelled,
        ]) {
          final res = await updateStatus(
            UpdateOrderStatusInput(
              orderId: 'ext',
              storeId: 'store-1',
              status: restricted,
            ),
          );
          expect(res.failureOrNull, isA<ValidationFailure>());
        }

        await repository.confirmOrder(orderId: 'pickup', storeId: 'store-1');
        final invalidPickupDriver = await updateStatus(
          const UpdateOrderStatusInput(
            orderId: 'pickup',
            storeId: 'store-1',
            status: OrderStatus.lookingForDriver,
          ),
        );
        expect(invalidPickupDriver.failureOrNull, isA<BusinessRuleFailure>());

        await repository.confirmOrder(orderId: 'own', storeId: 'store-1');
        await repository.updateOrderStatus(
          orderId: 'own',
          storeId: 'store-1',
          status: OrderStatus.preparing,
        );
        final invalidOwnPickup = await updateStatus(
          const UpdateOrderStatusInput(
            orderId: 'own',
            storeId: 'store-1',
            status: OrderStatus.readyForPickup,
          ),
        );
        expect(invalidOwnPickup.failureOrNull, isA<BusinessRuleFailure>());

        // Ciclo completo externalDelivery con reintento tras noDriversAvailable
        await repository.confirmOrder(orderId: 'ext', storeId: 'store-1');
        await repository.updateOrderStatus(
          orderId: 'ext',
          storeId: 'store-1',
          status: OrderStatus.lookingForDriver,
        );
        await repository.updateOrderStatus(
          orderId: 'ext',
          storeId: 'store-1',
          status: OrderStatus.noDriversAvailable,
        );
        await repository.updateOrderStatus(
          orderId: 'ext',
          storeId: 'store-1',
          status: OrderStatus.lookingForDriver,
        );
        await repository.updateOrderStatus(
          orderId: 'ext',
          storeId: 'store-1',
          status: OrderStatus.driverAssigned,
        );
        await repository.updateOrderStatus(
          orderId: 'ext',
          storeId: 'store-1',
          status: OrderStatus.inDelivery,
        );
        final delivered = (await repository.updateOrderStatus(
          orderId: 'ext',
          storeId: 'store-1',
          status: OrderStatus.delivered,
        )).dataOrNull!;

        expect(delivered.status.isTerminal, isTrue);
        expect(
          () => delivered.copyWithStatus(OrderStatus.preparing),
          throwsA(isA<DomainException>()),
        );
      },
    );

    test(
      'alternativa de entrega rechaza opciones inválidas y conserva historial',
      () async {
        final noDrivers = _order(id: 'alt-1')
            .copyWithStatus(OrderStatus.confirmed)
            .copyWithStatus(OrderStatus.lookingForDriver)
            .copyWithStatus(OrderStatus.noDriversAvailable);
        final repository = InMemoryOrderRepository([noDrivers], () => actionTime);

        final invalidMethod = await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: 'alt-1',
          customerId: 'customer-1',
          deliveryMethod: OrderDeliveryMethod.externalDelivery,
        );
        expect(invalidMethod.failureOrNull, isA<BusinessRuleFailure>());

        final wrongCustomer = await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: 'alt-1',
          customerId: 'customer-2',
          deliveryMethod: OrderDeliveryMethod.storeDelivery,
        );
        expect(wrongCustomer.failureOrNull, isA<UnauthorizedFailure>());

        final changed = (await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: 'alt-1',
          customerId: 'customer-1',
          deliveryMethod: OrderDeliveryMethod.storeDelivery,
        )).dataOrNull!;
        expect(changed.status, OrderStatus.preparing);
        expect(changed.deliveryMethod, OrderDeliveryMethod.storeDelivery);

        // No puede volver a cambiar de alternativa una vez en preparación
        final repeatedChange = await repository.changeDeliveryMethodAfterNoDrivers(
          orderId: 'alt-1',
          customerId: 'customer-1',
          deliveryMethod: OrderDeliveryMethod.pickup,
        );
        expect(repeatedChange.failureOrNull, isA<BusinessRuleFailure>());
      },
    );
  });
}

Order _order({
  String id = 'order-1',
  OrderDeliveryMethod method = OrderDeliveryMethod.externalDelivery,
  double price = 2,
  int quantity = 1,
  double missingContainersFee = 0,
}) => Order(
  id: id,
  customerId: 'customer-1',
  storeId: 'store-1',
  status: OrderStatus.created,
  deliveryMethod: method,
  paymentMethod: OrderPaymentMethod.cash,
  deliveryAddress: 'Manta',
  missingContainersFee: missingContainersFee,
  createdAt: DateTime(2026, 11, 25, 19),
  items: [
    OrderItem(
      productId: 'product-1',
      productName: 'Bebida',
      frozenUnitPrice: price,
      quantity: quantity,
    ),
  ],
);

Order _deliveredOrder({String id = 'order-1'}) {
  return _order(id: id)
      .copyWithStatus(OrderStatus.confirmed)
      .copyWithStatus(OrderStatus.preparing)
      .copyWithStatus(OrderStatus.lookingForDriver)
      .copyWithStatus(OrderStatus.driverAssigned)
      .copyWithStatus(OrderStatus.inDelivery)
      .copyWithStatus(OrderStatus.delivered);
}
