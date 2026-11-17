import '../../../../core/errors/exceptions.dart';
import 'offer_status.dart';

/// Entidad de dominio que representa una oferta o contraoferta presentada por un
/// repartidor para una solicitud de delivery.
///
/// 100% pure Dart, independiente de Flutter y Firebase.
/// La representación canónica de los importes monetarios se gestiona en centavos
/// enteros (`referenceFareInCents` y `offeredFareInCents`) para garantizar exactitud
/// aritmética sin imprecisiones de punto flotante binario (IEEE 754).
class DeliveryOffer {
  /// Importe máximo permitido por tarifa en centavos ($100,000.00).
  static const int maxFareInCents = 10000000;

  /// Máximo número de unidades enteras permitidas ($100,000).
  static const int maxIntegerUnits = 100000;

  /// Representación textual del tope entero para validación previa de longitud.
  static const String maxIntegerString = '100000';

  final String id;
  final String deliveryRequestId;
  final String driverId;
  final String driverName;
  final int referenceFareInCents;
  final int offeredFareInCents;
  final String? comment;
  final OfferStatus status;
  final DateTime createdAt;
  final DateTime? respondedAt;

  DeliveryOffer({
    required this.id,
    required this.deliveryRequestId,
    required this.driverId,
    required this.driverName,
    required this.referenceFareInCents,
    required this.offeredFareInCents,
    this.comment,
    this.status = OfferStatus.pending,
    required this.createdAt,
    this.respondedAt,
  }) {
    if (id.trim().isEmpty) {
      throw const DomainException('El id de la oferta no puede estar vacío.');
    }
    if (deliveryRequestId.trim().isEmpty) {
      throw const DomainException(
        'El id de la solicitud de delivery no puede estar vacío.',
      );
    }
    if (driverId.trim().isEmpty) {
      throw const DomainException('El id del repartidor no puede estar vacío.');
    }
    if (driverName.trim().isEmpty) {
      throw const DomainException(
        'El nombre del repartidor no puede estar vacío.',
      );
    }
    if (referenceFareInCents <= 0) {
      throw const DomainException(
        'La tarifa referencial en centavos debe ser estrictamente mayor a 0.',
      );
    }
    if (referenceFareInCents > maxFareInCents) {
      throw const DomainException(
        'La tarifa referencial excede el importe máximo permitido.',
      );
    }
    if (offeredFareInCents <= 0) {
      throw const DomainException(
        'La tarifa ofertada en centavos debe ser estrictamente mayor a 0.',
      );
    }
    if (offeredFareInCents > maxFareInCents) {
      throw const DomainException(
        'La tarifa ofertada excede el importe máximo permitido.',
      );
    }
    if (respondedAt != null && respondedAt!.isBefore(createdAt)) {
      throw const DomainException(
        'La fecha de respuesta no puede ser anterior a la fecha de creación.',
      );
    }
  }

  /// Factory para construir una oferta a partir de valores double heredados,
  /// validando que no posean fracciones de centavo mediante reconstrucción exacta.
  factory DeliveryOffer.fromDoubles({
    required String id,
    required String deliveryRequestId,
    required String driverId,
    required String driverName,
    required double referenceFare,
    required double offeredFare,
    String? comment,
    OfferStatus status = OfferStatus.pending,
    required DateTime createdAt,
    DateTime? respondedAt,
  }) {
    return DeliveryOffer(
      id: id,
      deliveryRequestId: deliveryRequestId,
      driverId: driverId,
      driverName: driverName,
      referenceFareInCents: doubleToCents(
        referenceFare,
        'La tarifa referencial',
      ),
      offeredFareInCents: doubleToCents(offeredFare, 'La tarifa ofertada'),
      comment: comment,
      status: status,
      createdAt: createdAt,
      respondedAt: respondedAt,
    );
  }

  /// Factory para construir una oferta a partir de entradas textuales de usuario,
  /// procesando directamente la parte entera y decimal a centavos sin conversión previa a double.
  factory DeliveryOffer.fromText({
    required String id,
    required String deliveryRequestId,
    required String driverId,
    required String driverName,
    required int referenceFareInCents,
    required String offeredFareText,
    String? comment,
    OfferStatus status = OfferStatus.pending,
    required DateTime createdAt,
    DateTime? respondedAt,
  }) {
    final offeredCents = parseTextToCents(
      offeredFareText,
      'La tarifa ofertada',
    );
    return DeliveryOffer(
      id: id,
      deliveryRequestId: deliveryRequestId,
      driverId: driverId,
      driverName: driverName,
      referenceFareInCents: referenceFareInCents,
      offeredFareInCents: offeredCents,
      comment: comment,
      status: status,
      createdAt: createdAt,
      respondedAt: respondedAt,
    );
  }

  /// Parsea y valida una entrada textual directamente a centavos enteros.
  /// Normaliza ceros iniciales y valida longitud/valor textual antes de int.parse.
  static int parseTextToCents(String input, String fieldName) {
    final trimmed = input.trim();

    final regex = RegExp(r'^\d+(\.\d{1,2})?$');
    if (!regex.hasMatch(trimmed)) {
      throw DomainException(
        '$fieldName debe ser un importe numérico positivo con máximo dos decimales.',
      );
    }

    final parts = trimmed.split('.');
    final rawIntegerPart = parts[0];

    // Normalización de ceros iniciales (e.g. "0005" -> "5", "000" -> "0")
    final normalizedIntegerPart = rawIntegerPart.replaceFirst(
      RegExp(r'^0+(?!$)'),
      '',
    );

    // Validación textual previa frente al límite de 100,000 (6 caracteres numéricos)
    if (normalizedIntegerPart.length > maxIntegerString.length) {
      throw DomainException(
        '$fieldName excede el importe máximo permitido de ${(maxFareInCents / 100).toStringAsFixed(2)}.',
      );
    }

    if (normalizedIntegerPart.length == maxIntegerString.length &&
        normalizedIntegerPart.compareTo(maxIntegerString) > 0) {
      throw DomainException(
        '$fieldName excede el importe máximo permitido de ${(maxFareInCents / 100).toStringAsFixed(2)}.',
      );
    }

    final int integerPart = int.parse(normalizedIntegerPart);
    final int decimalPart = parts.length > 1
        ? int.parse(parts[1].padRight(2, '0'))
        : 0;

    final int totalCents = (integerPart * 100) + decimalPart;

    if (totalCents <= 0) {
      throw DomainException('$fieldName debe ser estrictamente mayor a 0.');
    }

    if (totalCents > maxFareInCents) {
      throw DomainException(
        '$fieldName excede el importe máximo permitido de ${(maxFareInCents / 100).toStringAsFixed(2)}.',
      );
    }

    return totalCents;
  }

  /// Valida y convierte un valor double heredado a centavos enteros mediante reconstrucción exacta.
  /// Rechaza NaN, infinitos, negativos, cero y fracciones de centavo.
  static int doubleToCents(double amount, String fieldName) {
    if (amount.isNaN || amount.isInfinite || amount <= 0) {
      throw DomainException(
        '$fieldName debe ser un número positivo finito mayor a 0.',
      );
    }

    final int cents = (amount * 100).round();
    final double reconstructed = cents / 100.0;

    if (reconstructed != amount) {
      throw DomainException(
        '$fieldName ($amount) contiene fracciones de centavo o más de dos decimales.',
      );
    }

    if (cents > maxFareInCents) {
      throw DomainException(
        '$fieldName excede el importe máximo permitido de ${(maxFareInCents / 100).toStringAsFixed(2)}.',
      );
    }

    return cents;
  }

  /// Determina si la oferta es una contraoferta comparando los centavos enteros.
  bool get isCounterOffer => offeredFareInCents != referenceFareInCents;

  /// Tarifa referencial expresada en unidades monetarias decimales (solo lectura).
  double get referenceFare => referenceFareInCents / 100.0;

  /// Tarifa ofertada expresada en unidades monetarias decimales (solo lectura).
  double get offeredFare => offeredFareInCents / 100.0;

  /// Indica si la oferta se encuentra en estado pendiente de respuesta.
  bool get isPending => status.isPending;

  /// Indica si la oferta fue aceptada.
  bool get isAccepted => status == OfferStatus.accepted;

  /// Indica si la oferta fue rechazada.
  bool get isRejected => status == OfferStatus.rejected;

  /// Indica si la oferta fue descartada.
  bool get isDiscarded => status == OfferStatus.discarded;

  /// Transiciona la oferta al estado [newStatus] validando las reglas terminales.
  DeliveryOffer transitionTo(OfferStatus newStatus, {DateTime? respondedAt}) {
    if (!status.canTransitionTo(newStatus)) {
      throw DomainException(
        'Transición de estado inválida para la oferta: de ${status.name} a ${newStatus.name}.',
      );
    }

    return copyWith(
      status: newStatus,
      respondedAt: respondedAt ?? DateTime.now(),
    );
  }

  /// Acepta la oferta marcándola como ganadora.
  DeliveryOffer accept({DateTime? respondedAt}) =>
      transitionTo(OfferStatus.accepted, respondedAt: respondedAt);

  /// Rechaza la oferta individualmente.
  DeliveryOffer reject({DateTime? respondedAt}) =>
      transitionTo(OfferStatus.rejected, respondedAt: respondedAt);

  /// Descarta la oferta (por descarte en cascada o cancelación de la solicitud).
  DeliveryOffer discard({DateTime? respondedAt}) =>
      transitionTo(OfferStatus.discarded, respondedAt: respondedAt);

  /// Crea una copia inmutable con campos modificados.
  DeliveryOffer copyWith({
    String? id,
    String? deliveryRequestId,
    String? driverId,
    String? driverName,
    int? referenceFareInCents,
    int? offeredFareInCents,
    String? comment,
    OfferStatus? status,
    DateTime? createdAt,
    DateTime? respondedAt,
  }) {
    return DeliveryOffer(
      id: id ?? this.id,
      deliveryRequestId: deliveryRequestId ?? this.deliveryRequestId,
      driverId: driverId ?? this.driverId,
      driverName: driverName ?? this.driverName,
      referenceFareInCents: referenceFareInCents ?? this.referenceFareInCents,
      offeredFareInCents: offeredFareInCents ?? this.offeredFareInCents,
      comment: comment ?? this.comment,
      status: status ?? this.status,
      createdAt: createdAt ?? this.createdAt,
      respondedAt: respondedAt ?? this.respondedAt,
    );
  }
}
