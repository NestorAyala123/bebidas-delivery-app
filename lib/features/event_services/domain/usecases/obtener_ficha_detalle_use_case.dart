import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/ficha_servicio.dart';
import '../repositories/ficha_servicio_repository.dart';

/// Caso de uso para consultar el detalle de una ficha básica de proveedor por su ID.
class ObtenerFichaDetalleUseCase {
  final FichaServicioRepository _repository;

  const ObtenerFichaDetalleUseCase(this._repository);

  Future<Result<FichaServicio, Failure>> call(String id) {
    if (id.trim().isEmpty) {
      return Future.value(
        const FailureResult(ValidationFailure('El ID de la ficha es inválido')),
      );
    }
    return _repository.getFichaById(id);
  }
}

