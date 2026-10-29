import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/event_service.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/ficha_servicio.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/usecases/publicar_ficha_use_case.dart';
import 'package:bebidas_delivery_app/features/event_services/infrastructure/repositories/in_memory_ficha_servicio_repository.dart';

void main() {
  late InMemoryFichaServicioRepository repository;
  late PublicarFichaUseCase useCase;

  setUp(() {
    repository = InMemoryFichaServicioRepository(initialFichas: []);
    useCase = PublicarFichaUseCase(repository);
  });

  const validFicha = FichaServicio(
    id: '',
    providerId: 'prov-01',
    title: 'Bartender Profesional Premium',
    description: 'Servicio de coctelería de autor para bodas y eventos sociales.',
    serviceType: EventServiceType.bartender,
    estimatedPrice: 150.0,
    locationLabel: 'Manta, Manabí',
    contactPhone: '+593 99 123 4567',
    createdAt: '',
  );

  group('PublicarFichaUseCase Tests', () {
    test('publica exitosamente una ficha cuando cumple con todas las reglas de negocio', () async {
      final result = await useCase(validFicha);

      expect(result.isSuccess, isTrue);
      final published = result.dataOrNull;
      expect(published, isNotNull);
      expect(published!.id, isNotEmpty);
      expect(published.createdAt, isNotEmpty);
      expect(published.title, equals('Bartender Profesional Premium'));
    });

    test('falla con ValidationFailure si el título tiene menos de 3 caracteres', () async {
      final invalidFicha = validFicha.copyWith(title: 'Ab');

      final result = await useCase(invalidFicha);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('al menos 3 caracteres'));
    });

    test('falla con ValidationFailure si la descripción tiene menos de 10 caracteres', () async {
      final invalidFicha = validFicha.copyWith(description: 'Corta');

      final result = await useCase(invalidFicha);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('al menos 10 caracteres'));
    });

    test('falla con ValidationFailure si el precio estimado es negativo', () async {
      final invalidFicha = validFicha.copyWith(estimatedPrice: -10.0);

      final result = await useCase(invalidFicha);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('no puede ser negativo'));
    });

    test('falla con ValidationFailure si el teléfono de contacto está vacío', () async {
      final invalidFicha = validFicha.copyWith(contactPhone: '   ');

      final result = await useCase(invalidFicha);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('teléfono de contacto'));
    });

    test('falla con ValidationFailure si la ubicación está vacía', () async {
      final invalidFicha = validFicha.copyWith(locationLabel: '   ');

      final result = await useCase(invalidFicha);

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(result.failureOrNull!.message, contains('zona de cobertura'));
    });
  });
}
