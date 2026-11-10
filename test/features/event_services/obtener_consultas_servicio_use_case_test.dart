import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/consulta_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/obtener_consultas_servicio_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_consulta_servicio_repository.dart';

void main() {
  const consultaA = ConsultaServicio(
    id: 'consulta-a',
    serviceId: 'svc-001',
    serviceTitle: 'Bartender',
    providerId: 'prov-x',
    customerId: 'customer-a',
    customerName: 'Cliente A',
    customerPhone: '0991111111',
    eventDate: '2026-12-15',
    guestCount: 50,
    location: 'Manta',
    createdAt: '2026-11-01T10:00:00Z',
  );

  const consultaB = ConsultaServicio(
    id: 'consulta-b',
    serviceId: 'svc-002',
    serviceTitle: 'DJ',
    providerId: 'prov-y',
    customerId: 'customer-b',
    customerName: 'Cliente B',
    customerPhone: '0992222222',
    eventDate: '2026-12-20',
    guestCount: 120,
    location: 'Portoviejo',
    createdAt: '2026-11-02T10:00:00Z',
  );

  late ObtenerConsultasServicioUseCase useCase;

  setUp(() {
    final repository = InMemoryConsultaServicioRepository(
      initialConsultas: [consultaA, consultaB],
    );
    useCase = ObtenerConsultasServicioUseCase(repository);
  });

  group('ObtenerConsultasServicioUseCase Tests', () {
    test('exige al menos un criterio de consulta', () async {
      final result = await useCase();

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('cliente'));
    });

    test('filtra por cliente', () async {
      final result = await useCase(customerId: 'customer-a');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull!.first.id, equals('consulta-a'));
    });

    test('filtra por proveedor', () async {
      final result = await useCase(providerId: 'prov-y');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull!.first.id, equals('consulta-b'));
    });

    test('filtra por servicio', () async {
      final result = await useCase(serviceId: 'svc-001');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, hasLength(1));
      expect(result.dataOrNull!.first.id, equals('consulta-a'));
    });

    test('devuelve lista vacía cuando no hay coincidencias', () async {
      final result = await useCase(customerId: 'customer-desconocido');

      expect(result.isSuccess, isTrue);
      expect(result.dataOrNull, isEmpty);
    });
  });
}
