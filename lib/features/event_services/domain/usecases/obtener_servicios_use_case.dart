import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/event_service.dart';
import '../entities/ficha_servicio.dart';
import '../repositories/ficha_servicio_repository.dart';

/// Use case: fetch all available event-service listings (fichas).
///
/// Optionally filters by [serviceType]. Returns a [Failure] on error.
class ObtenerServiciosUseCase {
  final FichaServicioRepository _repository;

  const ObtenerServiciosUseCase(this._repository);

  Future<Result<List<FichaServicio>, Failure>> call({
    EventServiceType? serviceType,
  }) async {
    if (serviceType != null) {
      return _repository.getFichasByType(serviceType);
    }
    return _repository.getAllFichas();
  }
}
