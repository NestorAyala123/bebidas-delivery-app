import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/event_service.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/ficha_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_ficha_servicio_repository.dart';

void main() {
  late InMemoryFichaServicioRepository repository;

  setUp(() {
    repository = InMemoryFichaServicioRepository();
  });

  group('InMemoryFichaServicioRepository Tests', () {
    test('getAllFichas retorna lista de semillas precargadas', () async {
      final result = await repository.getAllFichas();

      expect(result.isSuccess, isTrue);
      final list = result.dataOrNull!;
      expect(list.length, greaterThanOrEqualTo(5));
      expect(list.any((f) => f.serviceType == EventServiceType.bartender), isTrue);
      expect(list.any((f) => f.serviceType == EventServiceType.iceAndCoolers), isTrue);
    });

    test('getFichasByType filtra correctamente por tipo de servicio', () async {
      final result = await repository.getFichasByType(EventServiceType.soundAndDj);

      expect(result.isSuccess, isTrue);
      final list = result.dataOrNull!;
      expect(list.isNotEmpty, isTrue);
      expect(list.every((f) => f.serviceType == EventServiceType.soundAndDj), isTrue);
    });

    test('getFichaById retorna la ficha correspondiente o NotFoundFailure', () async {
      final foundResult = await repository.getFichaById('svc-001');
      expect(foundResult.isSuccess, isTrue);
      expect(foundResult.dataOrNull!.id, equals('svc-001'));

      final notFoundResult = await repository.getFichaById('inexistente');
      expect(notFoundResult.isFailure, isTrue);
      expect(notFoundResult.failureOrNull, isA<NotFoundFailure>());
    });

    test('publishFicha inserta una nueva ficha con ID y timestamp', () async {
      const nueva = FichaServicio(
        id: '',
        providerId: 'prov-test',
        title: 'Servicio Test Nuevo',
        description: 'Descripción de prueba para verificar persistencia.',
        serviceType: EventServiceType.customCocktailBar,
        estimatedPrice: 200.0,
        locationLabel: 'Manta',
        contactPhone: '+593 99 999 8888',
        createdAt: '',
      );

      final result = await repository.publishFicha(nueva);

      expect(result.isSuccess, isTrue);
      final saved = result.dataOrNull!;
      expect(saved.id, startsWith('svc-'));
      expect(saved.createdAt, isNotEmpty);

      // Verificamos que aparece en getAllFichas
      final all = await repository.getAllFichas();
      expect(all.dataOrNull!.any((f) => f.id == saved.id), isTrue);
    });
  });
}

