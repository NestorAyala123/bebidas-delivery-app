import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_fee.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_mode.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver_status.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/services/delivery_order_policy.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/create_delivery_request_from_order_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_available_drivers_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/orders/domain/contracts/order_delivery_contract.dart';

void main() {
  group('Semana 4 - Implementación del Módulo Delivery', () {
    late MockDeliveryRepository repository;
    late CreateDeliveryRequestFromOrderUseCase createFromOrderUseCase;
    late GetAvailableDriversUseCase getAvailableDriversUseCase;
    const feeCalculator = DeliveryFee(baseFee: 1.50, perKmRate: 0.50);

    final fixedDate = DateTime(2026, 11, 2, 12, 0);

    setUp(() {
      repository = MockDeliveryRepository(
        latency: Duration.zero,
        seedTime: fixedDate,
      );
      createFromOrderUseCase = CreateDeliveryRequestFromOrderUseCase(
        repository: repository,
        feeCalculator: feeCalculator,
        policy: const DeliveryOrderPolicy(),
        idGenerator: () => 'req-test-w4-01',
      );
      getAvailableDriversUseCase = GetAvailableDriversUseCase(repository);
    });

    OrderDeliveryInfo makeOrderInfo({
      String orderId = 'ord-201',
      String storeId = 'store-manta-01',
      String customerId = 'cust-505',
      String pickupAddress = 'Calle 13 y Av. 24, Manta',
      String deliveryAddress = 'Barrio Cordova, Manta',
      bool isConfirmedByStore = true,
      OrderDeliveryMethod deliveryMethod = OrderDeliveryMethod.externalDelivery,
      double? distanceInKm = 4.0,
      int totalItemsCount = 3,
      double orderTotal = 25.50,
    }) {
      return OrderDeliveryInfo(
        orderId: orderId,
        storeId: storeId,
        customerId: customerId,
        pickupAddress: pickupAddress,
        deliveryAddress: deliveryAddress,
        isConfirmedByStore: isConfirmedByStore,
        deliveryMethod: deliveryMethod,
        distanceInKm: distanceInKm,
        totalItemsCount: totalItemsCount,
        orderTotal: orderTotal,
      );
    }

    // =========================================================================
    // Requisito A: Crear solicitudes después de la confirmación (RN01)
    // =========================================================================
    group('A. Solicitudes condicionadas a la confirmación del comercio (RN01)', () {
      test('1. Un pedido confirmado puede generar una solicitud externa', () async {
        final orderInfo = makeOrderInfo(isConfirmedByStore: true);

        final result = await createFromOrderUseCase(orderInfo: orderInfo);

        expect(result.isSuccess, isTrue);
        final request = result.dataOrNull!;
        expect(request.orderId, equals('ord-201'));
        expect(request.status, equals(DeliveryStatus.pendingOffer));
        expect(request.deliveryMode, equals(DeliveryMode.externalDriver));

        // Verificar que fue persistida en el repositorio
        final persisted = await repository.getDeliveryRequestById(request.id);
        expect(persisted.isSuccess, isTrue);
        expect(persisted.dataOrNull!.orderId, equals('ord-201'));
      });

      test('2. Un pedido pendiente no puede generar una solicitud (RN01)', () async {
        // Pedido no confirmado por el comercio (estado pendiente)
        final pendingOrder = makeOrderInfo(
          orderId: 'ord-pending-01',
          isConfirmedByStore: false,
        );

        final result = await createFromOrderUseCase(orderInfo: pendingOrder);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<BusinessRuleFailure>());
        expect(
          result.failureOrNull!.message,
          contains('RN01: El pedido debe estar confirmado'),
        );

        // Verificar que no se persistió ninguna solicitud
        final activeCheck = await repository.getActiveDeliveryRequestByOrderId('ord-pending-01');
        expect(activeCheck.dataOrNull, isNull);
      });

      test('3. Un pedido rechazado no puede generar una solicitud (RN01)', () async {
        // Pedido rechazado por el comercio (isConfirmedByStore = false)
        final rejectedOrder = makeOrderInfo(
          orderId: 'ord-rejected-01',
          isConfirmedByStore: false,
        );

        final result = await createFromOrderUseCase(orderInfo: rejectedOrder);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<BusinessRuleFailure>());
        final activeCheck = await repository.getActiveDeliveryRequestByOrderId('ord-rejected-01');
        expect(activeCheck.dataOrNull, isNull);
      });

      test('4. Un pedido cancelado no puede generar una solicitud (RN01)', () async {
        // Pedido cancelado previo a confirmación (isConfirmedByStore = false)
        final cancelledOrder = makeOrderInfo(
          orderId: 'ord-cancelled-01',
          isConfirmedByStore: false,
        );

        final result = await createFromOrderUseCase(orderInfo: cancelledOrder);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<BusinessRuleFailure>());
        final activeCheck = await repository.getActiveDeliveryRequestByOrderId('ord-cancelled-01');
        expect(activeCheck.dataOrNull, isNull);
      });

      test('Pedido confirmado con método pickup o storeDelivery es rechazado por la política', () async {
        final pickupOrder = makeOrderInfo(
          isConfirmedByStore: true,
          deliveryMethod: OrderDeliveryMethod.pickup,
        );
        final storeDeliveryOrder = makeOrderInfo(
          isConfirmedByStore: true,
          deliveryMethod: OrderDeliveryMethod.storeDelivery,
        );

        final pickupResult = await createFromOrderUseCase(orderInfo: pickupOrder);
        final storeResult = await createFromOrderUseCase(orderInfo: storeDeliveryOrder);

        expect(pickupResult.isFailure, isTrue);
        expect(storeResult.isFailure, isTrue);
      });
    });

    // =========================================================================
    // Prevención de duplicados
    // =========================================================================
    group('Prevención de solicitudes duplicadas', () {
      test('5. No se pueden generar solicitudes duplicadas para el mismo pedido', () async {
        final orderInfo = makeOrderInfo(orderId: 'ord-unique-01');

        // Primera creación: exitosa
        final firstResult = await createFromOrderUseCase(orderInfo: orderInfo);
        expect(firstResult.isSuccess, isTrue);

        // Segunda creación para el mismo pedido: bloqueada
        final duplicateResult = await createFromOrderUseCase(orderInfo: orderInfo);
        expect(duplicateResult.isFailure, isTrue);
        expect(duplicateResult.failureOrNull, isA<BusinessRuleFailure>());
        expect(
          duplicateResult.failureOrNull!.message,
          contains('Ya existe una solicitud de delivery activa para el pedido ord-unique-01'),
        );
      });

      test('Solicitudes anteriores canceladas permiten generar una nueva', () async {
        final orderInfo = makeOrderInfo(orderId: 'ord-retry-01');

        // 1. Crear primera solicitud
        final firstResult = await createFromOrderUseCase(orderInfo: orderInfo);
        expect(firstResult.isSuccess, isTrue);
        final firstRequest = firstResult.dataOrNull!;

        // 2. Cancelar la primera solicitud (pasa a estado terminal)
        await repository.updateStatus(firstRequest.id, DeliveryStatus.cancelled.name);

        // 3. Crear una nueva solicitud para el mismo pedido debe ser permitida
        final customUseCase = CreateDeliveryRequestFromOrderUseCase(
          repository: repository,
          feeCalculator: feeCalculator,
          idGenerator: () => 'req-test-w4-02',
        );
        final secondResult = await customUseCase(orderInfo: orderInfo);
        expect(secondResult.isSuccess, isTrue);
        expect(secondResult.dataOrNull!.id, equals('req-test-w4-02'));
        expect(secondResult.dataOrNull!.status, equals(DeliveryStatus.pendingOffer));
      });

      test('Solicitudes anteriores entregadas (delivered) permiten generar una nueva', () async {
        final orderInfo = makeOrderInfo(orderId: 'ord-delivered-01');

        // 1. Crear primera solicitud
        final firstResult = await createFromOrderUseCase(orderInfo: orderInfo);
        expect(firstResult.isSuccess, isTrue);
        final firstRequest = firstResult.dataOrNull!;

        // 2. Marcar como entregada (pasa a estado terminal)
        await repository.updateStatus(firstRequest.id, DeliveryStatus.delivered.name);

        // 3. Crear una nueva solicitud para el mismo pedido debe ser permitida
        final customUseCase = CreateDeliveryRequestFromOrderUseCase(
          repository: repository,
          feeCalculator: feeCalculator,
          idGenerator: () => 'req-test-w4-03',
        );
        final secondResult = await customUseCase(orderInfo: orderInfo);
        expect(secondResult.isSuccess, isTrue);
        expect(secondResult.dataOrNull!.id, equals('req-test-w4-03'));
        expect(secondResult.dataOrNull!.status, equals(DeliveryStatus.pendingOffer));
      });

      test('Protección a nivel de repositorio mock impide duplicados directos', () async {
        final request1 = DeliveryRequest(
          id: 'direct-req-1',
          orderId: 'ord-direct-dup',
          customerId: 'c1',
          storeId: 's1',
          originAddress: 'Origen',
          destinationAddress: 'Destino',
          distanceInKm: 2.0,
          referenceFare: 2.50,
          isOrderConfirmedByStore: true,
          status: DeliveryStatus.pendingOffer,
          createdAt: DateTime.now(),
        );
        final request2 = DeliveryRequest(
          id: 'direct-req-2',
          orderId: 'ord-direct-dup',
          customerId: 'c1',
          storeId: 's1',
          originAddress: 'Origen',
          destinationAddress: 'Destino',
          distanceInKm: 2.0,
          referenceFare: 2.50,
          isOrderConfirmedByStore: true,
          status: DeliveryStatus.pendingOffer,
          createdAt: DateTime.now(),
        );

        final res1 = await repository.createDeliveryRequest(request1);
        final res2 = await repository.createDeliveryRequest(request2);

        expect(res1.isSuccess, isTrue);
        expect(res2.isFailure, isTrue);
        expect(res2.failureOrNull, isA<BusinessRuleFailure>());
      });
    });

    // =========================================================================
    // Requisito B: Filtrar repartidores disponibles
    // =========================================================================
    group('B. Filtrado de repartidores disponibles', () {
      test('6 y 7. Solo se consideran repartidores disponibles; busy y offline quedan excluidos', () async {
        // En MockDeliveryRepository se inicializan por defecto:
        // - driver-1: available
        // - driver-2: busy
        // - driver-3: offline
        final result = await getAvailableDriversUseCase();

        expect(result.isSuccess, isTrue);
        final availableDrivers = result.dataOrNull!;

        // Debe contener únicamente al driver disponible
        expect(availableDrivers.length, equals(1));
        expect(availableDrivers.first.id, equals('driver-1'));
        expect(availableDrivers.first.status, equals(DriverStatus.available));
        expect(availableDrivers.first.canAcceptDeliveries, isTrue);

        // Exclusión explícita de busy y offline
        final hasBusy = availableDrivers.any((d) => d.status == DriverStatus.busy);
        final hasOffline = availableDrivers.any((d) => d.status == DriverStatus.offline);
        expect(hasBusy, isFalse);
        expect(hasOffline, isFalse);
      });

      test('Cambio dinámico de disponibilidad refleja inmediatamente en el filtrado', () async {
        // Cambiar driver-2 de busy a available
        await repository.setDriverAvailability('driver-2', DriverStatus.available);

        final result = await getAvailableDriversUseCase();
        expect(result.isSuccess, isTrue);
        final drivers = result.dataOrNull!;

        expect(drivers.length, equals(2));
        final ids = drivers.map((d) => d.id).toSet();
        expect(ids, containsAll(['driver-1', 'driver-2']));
        expect(ids.contains('driver-3'), isFalse);
      });

      test('Si todos los repartidores están desconectados u ocupados, retorna lista vacía exitosamente', () async {
        await repository.setDriverAvailability('driver-1', DriverStatus.offline);
        await repository.setDriverAvailability('driver-2', DriverStatus.busy);
        await repository.setDriverAvailability('driver-3', DriverStatus.offline);

        final result = await getAvailableDriversUseCase();
        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!, isEmpty);
      });
    });

    // =========================================================================
    // Requisito C: Conservación de datos y cálculo de tarifa referencial
    // =========================================================================
    group('C. Asociación de solicitud, pedido, ubicación y tarifa', () {
      test('8. La solicitud conserva correctamente el orderId, las direcciones y la distancia', () async {
        final orderInfo = makeOrderInfo(
          orderId: 'ord-preserve-99',
          customerId: 'cust-special',
          storeId: 'store-central',
          pickupAddress: 'Av. Flavio Reyes 100',
          deliveryAddress: 'Av. Malecón 200',
          distanceInKm: 7.25,
        );

        final result = await createFromOrderUseCase(orderInfo: orderInfo);

        expect(result.isSuccess, isTrue);
        final req = result.dataOrNull!;

        expect(req.orderId, equals('ord-preserve-99'));
        expect(req.customerId, equals('cust-special'));
        expect(req.storeId, equals('store-central'));
        expect(req.originAddress, equals('Av. Flavio Reyes 100'));
        expect(req.destinationAddress, equals('Av. Malecón 200'));
        expect(req.distanceInKm, equals(7.25));
        expect(req.status, equals(DeliveryStatus.pendingOffer));
        expect(req.createdAt, isNotNull);
      });

      test('9. La tarifa referencial se mantiene correctamente calculada', () async {
        // Distancia = 5.0 km
        // Tarifa base = 1.50, Tarifa por km = 0.50
        // Esperado = 1.50 + (5.0 * 0.50) = 4.00
        final orderInfo = makeOrderInfo(
          orderId: 'ord-fare-calc',
          distanceInKm: 5.0,
        );

        final result = await createFromOrderUseCase(orderInfo: orderInfo);

        expect(result.isSuccess, isTrue);
        final req = result.dataOrNull!;
        expect(req.referenceFare, equals(4.00));
        expect(req.suggestedFee, equals(4.00));
      });

      test('Falla de validación si no se proporciona distancia en la solicitud', () async {
        final orderInfoWithoutDistance = makeOrderInfo(
          orderId: 'ord-no-dist',
          distanceInKm: null,
        );

        final result = await createFromOrderUseCase(
          orderInfo: orderInfoWithoutDistance,
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull!.message,
          contains('La distancia en kilómetros es obligatoria'),
        );
      });
    });
  });
}
