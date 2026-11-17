import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/delivery_negotiation.dart';

/// Contrato de persistencia de las negociaciones de entrega.
abstract class DeliveryNegotiationRepository {
  Future<Result<DeliveryNegotiation, Failure>> getNegotiation(
    String negotiationId,
  );

  Future<Result<List<DeliveryNegotiation>, Failure>> getHistory(
    String customerId,
  );

  Future<Result<DeliveryNegotiation, Failure>> saveNegotiation(
    DeliveryNegotiation negotiation,
  );

  /// Selecciona una oferta y cierra el resto de forma atómica (RN06).
  ///
  /// La verificación y la escritura ocurren en la misma operación para evitar
  /// que dos aceptaciones simultáneas asignen dos repartidores.
  Future<Result<DeliveryNegotiation, Failure>> selectOffer({
    required String negotiationId,
    required String offerId,
  });
}
