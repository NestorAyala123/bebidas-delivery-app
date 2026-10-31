import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/consulta_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/crear_consulta_servicio_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_consulta_servicio_repository.dart';

void main() {
  late InMemoryConsultaServicioRepository repository;
  late CrearConsultaServicioUseCase useCase;

  String formatDate(DateTime date) {
    final month = date.month.toString().padLeft(2, '0');
    final day = date.day.toString().padLeft(2, '0');
    return '${date.year}-$month-$day';
  }

  final futureDate = formatDate(DateTime.now().add(const Duration(days: 30)));
  final pastDate = formatDate(DateTime.now().subtract(const Duration(days: 2)));

  ConsultaServicio buildConsulta({String eventDate = ''}) {
    return ConsultaServicio(
      id: '',
      serviceId: 'svc-001',
      serviceTitle: 'Bartender Profesional',
      providerId: 'prov-001',
      customerId: 'customer-001',
      customerName: '  David Vera  ',
      customerPhone: '  +593 99 123 4567  ',
      eventDate: eventDate.isEmpty ? futureDate : eventDate,
      guestCount: 80,
      location: '  Manta, Manabí  ',
      notes: '  Barra frente a la piscina  ',
      budgetOffered: 250.0,
      createdAt: '',
    );
  }

  setUp(() {
    repository = InMemoryConsultaServicioRepository(initialConsultas: []);
    useCase = CrearConsultaServicioUseCase(repository);
  });

  group('CrearConsultaServicioUseCase Tests', () {
    test('crea la consulta, asigna ID/fecha y normaliza los campos', () async {
      final result = await useCase(buildConsulta());

      expect(result.isSuccess, isTrue);
      final created = result.dataOrNull!;
      expect(created.id, isNotEmpty);
      expect(created.createdAt, isNotEmpty);
      expect(created.status, equals(ConsultaServicioStatus.pendiente));
      expect(created.customerName, equals('David Vera'));
      expect(created.customerPhone, equals('+593 99 123 4567'));
      expect(created.location, equals('Manta, Manabí'));
      expect(created.notes, equals('Barra frente a la piscina'));
      expect(repository.consultas, hasLength(1));
    });

    test('falla si no hay servicio asociado', () async {
      final result = await useCase(buildConsulta().copyWith(serviceId: '  '));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('servicio'));
    });

    test('falla si no hay proveedor asociado', () async {
      final result = await useCase(buildConsulta().copyWith(providerId: ''));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('proveedor'));
    });

    test('falla si no hay cliente asociado', () async {
      final result = await useCase(buildConsulta().copyWith(customerId: ''));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('cliente'));
    });

    test('falla si el nombre del cliente es demasiado corto', () async {
      final result = await useCase(
        buildConsulta().copyWith(customerName: 'Al'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('nombre'));
    });

    test('falla con teléfonos inválidos', () async {
      final result = await useCase(
        buildConsulta().copyWith(customerPhone: 'abc'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('teléfono'));
    });

    test('falla si la fecha tentativa no se puede interpretar', () async {
      final result = await useCase(
        buildConsulta().copyWith(eventDate: 'fecha-invalida'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('fecha'));
    });

    test('falla si la fecha tentativa es anterior a hoy', () async {
      final result = await useCase(buildConsulta(eventDate: pastDate));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('anterior a hoy'));
    });

    test('falla si la cantidad de invitados es cero', () async {
      final result = await useCase(buildConsulta().copyWith(guestCount: 0));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('invitados'));
    });

    test('falla si la ubicación está vacía', () async {
      final result = await useCase(buildConsulta().copyWith(location: '   '));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('ubicación'));
    });

    test('falla si el presupuesto es negativo', () async {
      final result = await useCase(buildConsulta().copyWith(budgetOffered: -1));

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull!.message, contains('presupuesto'));
    });
  });
}
