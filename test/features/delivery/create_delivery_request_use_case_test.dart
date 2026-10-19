import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_fee.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_request.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/create_delivery_request_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';

void main() {
  group('CreateDeliveryRequestUseCase Tests (Semana 3 - Entregable A)', () {
    late MockDeliveryRepository repository;
    late CreateDeliveryRequestUseCase useCase;

    setUp(() {
      repository = MockDeliveryRepository(latency: Duration.zero);
      useCase = CreateDeliveryRequestUseCase(
        repository,
        feeCalculator: const DeliveryFee(baseFee: 1.50, perKmRate: 0.50),
      );
    });

    DeliveryRequest makeSampleRequest({
      String id = 'req-test-1',
      String originAddress = 'Av. 4 de Noviembre',
      String destinationAddress = 'Calle 12 y Av. 24',
      double? distanceInKm = 3.5,
      double referenceFare = 0.0,
    }) {
      return DeliveryRequest(
        id: id,
        orderId: 'order-101',
        customerId: 'customer-1',
        storeId: 'store-1',
        originAddress: originAddress,
        destinationAddress: destinationAddress,
        distanceInKm: distanceInKm,
        referenceFare: referenceFare,
        isOrderConfirmedByStore: true,
        createdAt: DateTime(2026, 10, 18),
      );
    }

    test(
      '1. Caso exitoso: calcula referenceFare = 1.50 + (3.5 * 0.50) = 3.25 y persiste con la tarifa calculada',
      () async {
        final request = makeSampleRequest(distanceInKm: 3.5, referenceFare: 0.0);

        final result = await useCase(request);

        expect(result.isSuccess, isTrue);
        final created = result.dataOrNull!;
        expect(created.referenceFare, equals(3.25));

        // Verificar que el repositorio persistió la solicitud con la tarifa calculada
        final fromRepoResult = await repository.getDeliveryRequestById(request.id);
        expect(fromRepoResult.isSuccess, isTrue);
        expect(fromRepoResult.dataOrNull!.referenceFare, equals(3.25));
      },
    );

    test(
      '2. Caso borde inferior válido (0.0 km): calcula referenceFare = 1.50 + (0 * 0.50) = 1.50 y persiste con la tarifa calculada',
      () async {
        final request = makeSampleRequest(distanceInKm: 0.0, referenceFare: 0.0);

        final result = await useCase(request);

        expect(result.isSuccess, isTrue);
        final created = result.dataOrNull!;
        expect(created.referenceFare, equals(1.50));

        // Verificar que el repositorio persistió la solicitud con la tarifa calculada
        final fromRepoResult = await repository.getDeliveryRequestById(request.id);
        expect(fromRepoResult.isSuccess, isTrue);
        expect(fromRepoResult.dataOrNull!.referenceFare, equals(1.50));
      },
    );

    test(
      '3. Caso distanceInKm es null: retorna ValidationFailure sin tocar repositorio',
      () async {
        final request = makeSampleRequest(distanceInKm: null);

        final result = await useCase(request);

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
        expect(
          result.failureOrNull!.message,
          equals(
            'La distancia en kilómetros es obligatoria y debe ser mayor o igual a 0',
          ),
        );

        // Verificación de que el repositorio no fue llamado
        final repoCheck = await repository.getDeliveryRequestById(request.id);
        expect(repoCheck.failureOrNull, isA<NotFoundFailure>());
      },
    );

    test(
      '4. Regla A1: sobrescribe tarifa manipulada (999.0) con la tarifa calculada correcta',
      () async {
        final request = makeSampleRequest(
          distanceInKm: 3.5,
          referenceFare: 999.0, // tarifa manipulada arbitraria
        );

        final result = await useCase(request);

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull!.referenceFare, equals(3.25));

        final persisted = (await repository.getDeliveryRequestById(request.id))
            .dataOrNull!;
        expect(persisted.referenceFare, equals(3.25));
      },
    );
  });
}
