import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/event_service.dart';
import '../entities/ficha_servicio.dart';

/// Extended repository contract for the event-services module.
///
/// Inherits read operations and adds publish/update/delete for providers.
/// Domain-only: no Firebase or Flutter imports.
abstract class FichaServicioRepository {
  /// Returns all available [FichaServicio] listings.
  Future<Result<List<FichaServicio>, Failure>> getAllFichas();

  /// Returns fichas filtered by [serviceType].
  Future<Result<List<FichaServicio>, Failure>> getFichasByType(
    EventServiceType serviceType,
  );

  /// Returns all fichas published by [providerId].
  Future<Result<List<FichaServicio>, Failure>> getFichasByProvider(
    String providerId,
  );

  /// Returns a single ficha by [id].
  Future<Result<FichaServicio, Failure>> getFichaById(String id);

  /// Persists a new [ficha] and returns the saved copy (with server-assigned id).
  Future<Result<FichaServicio, Failure>> publishFicha(FichaServicio ficha);

  /// Removes the ficha identified by [id].
  Future<Result<void, Failure>> deleteFicha(String id);
}
