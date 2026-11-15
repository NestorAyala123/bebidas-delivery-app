import '../../../../core/errors/exceptions.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../delivery/domain/entities/delivery_request.dart';
import '../../../delivery/domain/entities/delivery_status.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/entities/delivery_negotiation_event.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/entities/delivery_rating.dart';
import '../../domain/repositories/delivery_negotiation_repository.dart';
import '../../domain/services/offer_negotiation_service.dart';

/// Repositorio en memoria con escenarios de demostración de la Semana 5.
class InMemoryDeliveryNegotiationRepository
    implements DeliveryNegotiationRepository {
  final Map<String, DeliveryNegotiation> _negotiations;
  final OfferNegotiationService selectionService;

  InMemoryDeliveryNegotiationRepository({
    List<DeliveryNegotiation>? initialNegotiations,
    this.selectionService = const OfferNegotiationService(),
  }) : _negotiations = {
         for (final negotiation in initialNegotiations ?? _seedNegotiations())
           negotiation.id: negotiation,
       };

  static DateTime get _baseDate => DateTime(2026, 11, 15, 10);

  static List<DeliveryNegotiation> _seedNegotiations() {
    final base = _baseDate;

    final pendingRequest = DeliveryRequest(
      id: 'req-demo-01',
      orderId: 'ord-demo-03',
      customerId: 'customer-demo',
      storeId: 'store-001',
      originAddress: 'Licorera El Barril · Av. Flavio Reyes y Calle 24',
      destinationAddress: 'Av. Malecón Jaime Chávez, Manta',
      distanceInKm: 2.4,
      referenceFare: 3.50,
      initialCustomerOffer: 3.00,
      isOrderConfirmedByStore: true,
      createdAt: base,
    );

    final deliveredRequest =
        DeliveryRequest(
              id: 'req-demo-02',
              orderId: 'ord-demo-02',
              customerId: 'customer-demo',
              storeId: 'store-002',
              originAddress: 'Distribuidora La Copa · Calle 13 y Av. 24',
              destinationAddress: 'Barrio Santa Martha, Manta',
              distanceInKm: 1.8,
              referenceFare: 3.00,
              initialCustomerOffer: 2.20,
              isOrderConfirmedByStore: true,
              createdAt: base.subtract(const Duration(days: 2)),
            )
            .copyWithAssignedDriver(driverId: 'drv-701')
            .copyWithStatus(DeliveryStatus.delivered);

    final unratedRequest =
        DeliveryRequest(
              id: 'req-demo-03',
              orderId: 'ord-demo-01',
              customerId: 'customer-demo',
              storeId: 'store-001',
              originAddress: 'Licorera El Barril · Av. Flavio Reyes y Calle 24',
              destinationAddress: 'Av. Universitaria, Manta',
              distanceInKm: 3.1,
              referenceFare: 4.20,
              initialCustomerOffer: 4.00,
              isOrderConfirmedByStore: true,
              createdAt: base.subtract(const Duration(days: 5)),
            )
            .copyWithAssignedDriver(driverId: 'drv-702')
            .copyWithStatus(DeliveryStatus.delivered);

    final deliveredAt = base.subtract(const Duration(days: 2, hours: 1));
    final unratedDeliveredAt = base.subtract(const Duration(days: 5, hours: 1));

    return [
      DeliveryNegotiation(
        request: pendingRequest,
        history: [
          DeliveryNegotiationEvent(
            id: 'evt-demo-01-created',
            type: DeliveryNegotiationEventType.requestCreated,
            description: 'Solicitud de entrega creada para ord-demo-03',
            createdAt: base,
          ),
          DeliveryNegotiationEvent(
            id: 'evt-demo-01-offer',
            type: DeliveryNegotiationEventType.clientOfferUpdated,
            description: 'Propuesta del cliente: \$3.00 (referencia \$3.50)',
            amount: 3.00,
            createdAt: base.add(const Duration(minutes: 1)),
          ),
        ],
      ),
      DeliveryNegotiation(
        request: deliveredRequest,
        offers: [
          DeliveryOffer(
            id: 'offer-demo-02',
            deliveryRequestId: 'req-demo-02',
            driverId: 'drv-701',
            driverName: 'Carlos Mendoza',
            offeredAmount: 2.75,
            status: DeliveryOfferStatus.accepted,
            createdAt: deliveredAt.subtract(const Duration(minutes: 20)),
          ),
        ],
        assignedOfferId: 'offer-demo-02',
        agreedFare: 2.75,
        rating: DeliveryRating(
          stars: 5,
          comment: 'Llegó rápido y el pedido estaba completo.',
          driverId: 'drv-701',
          createdAt: deliveredAt.add(const Duration(minutes: 10)),
        ),
        history: [
          DeliveryNegotiationEvent(
            id: 'evt-demo-02-selected',
            type: DeliveryNegotiationEventType.offerSelected,
            description: 'Carlos Mendoza seleccionado por \$2.75',
            amount: 2.75,
            driverId: 'drv-701',
            createdAt: deliveredAt.subtract(const Duration(minutes: 20)),
          ),
          DeliveryNegotiationEvent(
            id: 'evt-demo-02-delivered',
            type: DeliveryNegotiationEventType.statusChanged,
            description: 'Entrega completada',
            createdAt: deliveredAt,
          ),
          DeliveryNegotiationEvent(
            id: 'evt-demo-02-rated',
            type: DeliveryNegotiationEventType.deliveryRated,
            description: 'Calificación del cliente: 5/5',
            driverId: 'drv-701',
            createdAt: deliveredAt.add(const Duration(minutes: 10)),
          ),
        ],
      ),
      DeliveryNegotiation(
        request: unratedRequest,
        offers: [
          DeliveryOffer(
            id: 'offer-demo-03',
            deliveryRequestId: 'req-demo-03',
            driverId: 'drv-702',
            driverName: 'Marcos Vera',
            offeredAmount: 4.25,
            status: DeliveryOfferStatus.accepted,
            createdAt: unratedDeliveredAt.subtract(const Duration(minutes: 30)),
          ),
        ],
        assignedOfferId: 'offer-demo-03',
        agreedFare: 4.25,
        history: [
          DeliveryNegotiationEvent(
            id: 'evt-demo-03-selected',
            type: DeliveryNegotiationEventType.offerSelected,
            description: 'Marcos Vera seleccionado por \$4.25',
            amount: 4.25,
            driverId: 'drv-702',
            createdAt: unratedDeliveredAt.subtract(const Duration(minutes: 30)),
          ),
          DeliveryNegotiationEvent(
            id: 'evt-demo-03-delivered',
            type: DeliveryNegotiationEventType.statusChanged,
            description: 'Entrega completada, pendiente de calificación',
            createdAt: unratedDeliveredAt,
          ),
        ],
      ),
    ];
  }

  @override
  Future<Result<DeliveryNegotiation, Failure>> getNegotiation(
    String negotiationId,
  ) async {
    final negotiation = _negotiations[negotiationId];
    if (negotiation == null) {
      return const FailureResult(
        NotFoundFailure('La negociación de entrega indicada no existe'),
      );
    }
    return Success(negotiation);
  }

  @override
  Future<Result<List<DeliveryNegotiation>, Failure>> getHistory(
    String customerId,
  ) async {
    final items =
        _negotiations.values
            .where(
              (negotiation) => negotiation.request.customerId == customerId,
            )
            .toList()
          ..sort((a, b) => b.request.createdAt.compareTo(a.request.createdAt));
    return Success(List.unmodifiable(items));
  }

  @override
  Future<Result<DeliveryNegotiation, Failure>> saveNegotiation(
    DeliveryNegotiation negotiation,
  ) async {
    if (!_negotiations.containsKey(negotiation.id)) {
      return const FailureResult(
        NotFoundFailure('La negociación de entrega indicada no existe'),
      );
    }
    _negotiations[negotiation.id] = negotiation;
    return Success(negotiation);
  }

  @override
  Future<Result<DeliveryNegotiation, Failure>> selectOffer({
    required String negotiationId,
    required String offerId,
  }) async {
    final current = _negotiations[negotiationId];
    if (current == null) {
      return const FailureResult(
        NotFoundFailure('La negociación de entrega indicada no existe'),
      );
    }

    try {
      final updatedOffers = selectionService.selectDriverOffer(
        currentOffers: current.offers,
        selectedOfferId: offerId,
      );
      final selected = updatedOffers.firstWhere((offer) => offer.id == offerId);
      final closedOffers = updatedOffers.where(
        (offer) =>
            offer.status == DeliveryOfferStatus.closedByAnotherAcceptance,
      );
      final now = DateTime.now();

      final events = <DeliveryNegotiationEvent>[
        DeliveryNegotiationEvent(
          id: 'evt-${now.microsecondsSinceEpoch}-selected',
          type: DeliveryNegotiationEventType.offerSelected,
          description:
              '${selected.driverName} seleccionado por ${selected.amountLabel}',
          amount: selected.offeredAmount,
          driverId: selected.driverId,
          createdAt: now,
        ),
        for (final closed in closedOffers)
          DeliveryNegotiationEvent(
            id: 'evt-${now.microsecondsSinceEpoch}-closed-${closed.id}',
            type: DeliveryNegotiationEventType.offerClosed,
            description:
                'Oferta de ${closed.driverName} cerrada automáticamente',
            amount: closed.offeredAmount,
            driverId: closed.driverId,
            createdAt: now,
          ),
      ];

      final updated = current.copyWith(
        request: current.request.copyWithAssignedDriver(
          driverId: selected.driverId,
        ),
        offers: updatedOffers,
        assignedOfferId: selected.id,
        agreedFare: selected.offeredAmount,
        history: [...current.history, ...events],
      );

      // La operación no contiene awaits: la verificación y la escritura son
      // atómicas dentro del mismo microtask de Dart.
      _negotiations[negotiationId] = updated;
      return Success(updated);
    } on DomainException catch (error) {
      return FailureResult(BusinessRuleFailure(error.message));
    }
  }
}
