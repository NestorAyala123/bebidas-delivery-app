import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';
import '../entities/delivery_offer.dart';
import '../entities/delivery_status.dart';
import '../entities/driver.dart';
import '../entities/driver_status.dart';
import '../entities/offer_status.dart';
import '../repositories/delivery_repository.dart';

/// Caso de uso para crear y registrar ofertas y contraofertas de repartidores.
/// Aplica RN-NEG-01 (solicitud en pendingOffer), RN-NEG-02 (repartidor available),
/// RN-NEG-03 (monto válido) y RN-NEG-04 (máximo 2 ofertas acumuladas por repartidor).
/// 100% pure Dart, independiente de Flutter y Firebase.
class SubmitDeliveryOfferUseCase {
  final DeliveryRepository repository;
  final String Function()? idGenerator;

  const SubmitDeliveryOfferUseCase({
    required this.repository,
    this.idGenerator,
  });

  Future<Result<DeliveryOffer, Failure>> call({
    required String deliveryRequestId,
    required String driverId,
    IdentityContract? driverIdentity,
    int? offeredFareInCents,
    String? offeredFareText,
    String? comment,
    DateTime? createdAt,
  }) async {
    // 1. Autorización obligatoria (Etapa 4 / 5):
    if (driverIdentity == null) {
      return const FailureResult(
        UnauthorizedFailure(
          'Se requiere la identidad autenticada del repartidor para enviar ofertas.',
        ),
      );
    }

    if (!driverIdentity.isActive) {
      return const FailureResult(
        UnauthorizedFailure('El repartidor autenticado se encuentra inactivo.'),
      );
    }

    if (driverIdentity.rbacRole != Role.driver) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-NEG-05: Solo usuarios con rol de repartidor pueden enviar ofertas.',
        ),
      );
    }

    if (driverIdentity.id != driverId) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-NEG-05: El identificador de la identidad autenticada no coincide con el repartidor indicado.',
        ),
      );
    }

    final effectiveDriverId = driverIdentity.id;

    // 2. Obtener la solicitud de delivery
    final requestResult = await repository.getDeliveryRequestById(
      deliveryRequestId,
    );
    if (requestResult.isFailure) {
      return FailureResult(requestResult.failureOrNull!);
    }
    final request = requestResult.dataOrNull!;

    if (request.status == DeliveryStatus.cancelled) {
      return const FailureResult(
        BusinessRuleFailure(
          'La solicitud ha sido cancelada y no admite nuevas ofertas.',
        ),
      );
    }

    // RN-NEG-01: Solo solicitudes en pendingOffer sin repartidor asignado
    if (request.status != DeliveryStatus.pendingOffer ||
        request.assignedDriverId != null) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-01: Solo se puede ofertar a solicitudes pendientes sin asignación previa.',
        ),
      );
    }

    // 2. Obtener datos del repartidor para verificar disponibilidad y capturar nombre
    final driversResult = await repository.getRegisteredDrivers();
    if (driversResult.isFailure) {
      return FailureResult(driversResult.failureOrNull!);
    }
    final drivers = driversResult.dataOrNull ?? [];
    final driver = drivers.cast<Driver?>().firstWhere(
      (d) => d?.id == effectiveDriverId,
      orElse: () => null,
    );

    if (driver == null) {
      return FailureResult(
        NotFoundFailure('Repartidor no encontrado con id: $effectiveDriverId'),
      );
    }

    // RN-NEG-02: Disponibilidad del repartidor
    if (driver.status != DriverStatus.available) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-02: El repartidor debe estar en estado disponible para ofertar.',
        ),
      );
    }

    // 3. RN-NEG-04: Límite de ofertas por repartidor para esta solicitud
    final existingOffersResult = await repository.getOffersByDriverAndRequest(
      deliveryRequestId: deliveryRequestId,
      driverId: effectiveDriverId,
    );
    if (existingOffersResult.isFailure) {
      return FailureResult(existingOffersResult.failureOrNull!);
    }
    final existingOffers = existingOffersResult.dataOrNull ?? [];

    if (existingOffers.any((o) => o.status == OfferStatus.pending)) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-04: El repartidor ya tiene una oferta pendiente para esta solicitud.',
        ),
      );
    }

    if (existingOffers.length >= 2) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-04: El repartidor ha alcanzado el límite máximo de 2 ofertas para esta solicitud.',
        ),
      );
    }

    if (existingOffers.length == 1 &&
        existingOffers.first.status != OfferStatus.rejected) {
      return const FailureResult(
        BusinessRuleFailure(
          'RN-NEG-04: La segunda oferta solo se permite si la primera fue rechazada.',
        ),
      );
    }

    // 4. Determinar tarifas canónicas en centavos
    final referenceFareCents = DeliveryOffer.doubleToCents(
      request.referenceFare,
      'Tarifa referencial',
    );

    int finalOfferedCents;
    if (offeredFareInCents != null) {
      if (offeredFareInCents <= 0 ||
          offeredFareInCents > DeliveryOffer.maxFareInCents) {
        return const FailureResult(
          ValidationFailure(
            'La tarifa ofertada en centavos debe ser mayor a 0 y no exceder el máximo permitido.',
          ),
        );
      }
      finalOfferedCents = offeredFareInCents;
    } else if (offeredFareText != null) {
      try {
        finalOfferedCents = DeliveryOffer.parseTextToCents(
          offeredFareText,
          'Tarifa ofertada',
        );
      } on Exception catch (e) {
        return FailureResult(ValidationFailure(e.toString()));
      }
    } else {
      // Oferta base directa: acepta la tarifa referencial exacta
      finalOfferedCents = referenceFareCents;
    }

    // 5. Construcción de entidad DeliveryOffer
    final offerId =
        idGenerator?.call() ??
        'off-$deliveryRequestId-$effectiveDriverId-${DateTime.now().millisecondsSinceEpoch}';

    final offer = DeliveryOffer(
      id: offerId,
      deliveryRequestId: deliveryRequestId,
      driverId: effectiveDriverId,
      driverName: driver.name,
      referenceFareInCents: referenceFareCents,
      offeredFareInCents: finalOfferedCents,
      comment: comment,
      status: OfferStatus.pending,
      createdAt: createdAt ?? DateTime.now(),
    );

    // 6. Persistir en el repositorio
    return repository.createDeliveryOffer(offer);
  }
}
