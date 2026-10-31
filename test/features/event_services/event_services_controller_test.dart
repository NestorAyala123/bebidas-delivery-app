import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/event_service.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/ficha_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/obtener_servicios_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/publicar_ficha_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_ficha_servicio_repository.dart';
import 'package:bebidas_delivery_app/features/event_services/presentation/controllers/event_services_controller.dart';

void main() {
  late InMemoryFichaServicioRepository repository;
  late EventServicesController controller;

  setUp(() {
    repository = InMemoryFichaServicioRepository();
    controller = EventServicesController(
      obtenerServiciosUseCase: ObtenerServiciosUseCase(repository),
      publicarFichaUseCase: PublicarFichaUseCase(repository),
    );
  });

  group('EventServicesController Tests', () {
    test('loadFichas carga las fichas y notifica listeners', () async {
      await controller.loadFichas();

      expect(controller.isLoading, isFalse);
      expect(controller.fichas.length, greaterThanOrEqualTo(5));
      expect(controller.errorMessage, isNull);
    });

    test('filterByType filtra por categoría y permite toggle para desmarcar', () async {
      await controller.filterByType(EventServiceType.bartender);
      expect(controller.selectedType, equals(EventServiceType.bartender));
      expect(controller.fichas.every((f) => f.serviceType == EventServiceType.bartender), isTrue);

      // Segundo tap toggle off
      await controller.filterByType(EventServiceType.bartender);
      expect(controller.selectedType, isNull);
      expect(controller.fichas.length, greaterThanOrEqualTo(5));
    });

    test('setSearchQuery filtra localmente las fichas por título o descripción', () async {
      await controller.loadFichas();

      controller.setSearchQuery('hielo');
      expect(controller.filteredFichas.every((f) => f.title.toLowerCase().contains('hielo') || f.description.toLowerCase().contains('hielo')), isTrue);
      expect(controller.filteredFichas.isNotEmpty, isTrue);
    });

    test('publishFicha publica una ficha y actualiza el listado activo', () async {
      await controller.loadFichas();
      final previousCount = controller.fichas.length;

      const nuevaFicha = FichaServicio(
        id: '',
        providerId: 'prov-controller-test',
        title: 'Servicio Nuevo Exclusivo',
        description: 'Descripción completa para prueba de integración de controller.',
        serviceType: EventServiceType.bartender,
        estimatedPrice: 190.0,
        locationLabel: 'Manta',
        contactPhone: '+593 99 000 1111',
        createdAt: '',
      );

      final result = await controller.publishFicha(nuevaFicha);

      expect(result.isSuccess, isTrue);
      expect(controller.fichas.length, equals(previousCount + 1));
      expect(controller.fichas.any((f) => f.title == 'Servicio Nuevo Exclusivo'), isTrue);
    });
  });
}

