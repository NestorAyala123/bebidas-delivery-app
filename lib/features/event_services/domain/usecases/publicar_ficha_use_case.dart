import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/ficha_servicio.dart';
import '../repositories/ficha_servicio_repository.dart';

/// Caso de uso para validar y publicar una ficha básica de proveedor de eventos.
///
/// Reglas de dominio puras:
/// - Título obligatorio (mínimo 3 caracteres).
/// - Descripción obligatoria (mínimo 10 caracteres).
/// - Teléfono de contacto obligatorio.
/// - Ubicación o zona de cobertura obligatoria.
/// - Precio estimado debe ser mayor o igual a 0.
class PublicarFichaUseCase {
  final FichaServicioRepository _repository;

  const PublicarFichaUseCase(this._repository);

  Future<Result<FichaServicio, Failure>> call(FichaServicio ficha) async {
    final title = ficha.title.trim();
    if (title.isEmpty || title.length < 3) {
      return const FailureResult(
        ValidationFailure('El título del servicio debe tener al menos 3 caracteres'),
      );
    }

    final description = ficha.description.trim();
    if (description.isEmpty || description.length < 10) {
      return const FailureResult(
        ValidationFailure(
          'La descripción del servicio debe contener al menos 10 caracteres',
        ),
      );
    }

    if (ficha.estimatedPrice < 0) {
      return const FailureResult(
        ValidationFailure('El precio estimado no puede ser negativo'),
      );
    }

    final contactPhone = ficha.contactPhone.trim();
    if (contactPhone.isEmpty) {
      return const FailureResult(
        ValidationFailure('El teléfono de contacto es obligatorio'),
      );
    }

    final locationLabel = ficha.locationLabel.trim();
    if (locationLabel.isEmpty) {
      return const FailureResult(
        ValidationFailure('La ubicación o zona de cobertura es obligatoria'),
      );
    }

    final sanitizedFicha = ficha.copyWith(
      title: title,
      description: description,
      contactPhone: contactPhone,
      locationLabel: locationLabel,
    );

    return _repository.publishFicha(sanitizedFicha);
  }
}

