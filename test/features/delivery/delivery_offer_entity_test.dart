import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/exceptions.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/delivery_offer.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/offer_status.dart';

void main() {
  group('DeliveryOffer Domain Entity Tests', () {
    final fixedCreatedAt = DateTime(2026, 11, 2, 10, 0);

    DeliveryOffer createSampleOffer({
      String id = 'off-001',
      String deliveryRequestId = 'req-101',
      String driverId = 'drv-001',
      String driverName = 'Carlos Mendoza',
      int referenceFareInCents = 350, // $3.50
      int offeredFareInCents = 350, // $3.50
      String? comment,
      OfferStatus status = OfferStatus.pending,
      DateTime? createdAt,
      DateTime? respondedAt,
    }) {
      return DeliveryOffer(
        id: id,
        deliveryRequestId: deliveryRequestId,
        driverId: driverId,
        driverName: driverName,
        referenceFareInCents: referenceFareInCents,
        offeredFareInCents: offeredFareInCents,
        comment: comment,
        status: status,
        createdAt: createdAt ?? fixedCreatedAt,
        respondedAt: respondedAt,
      );
    }

    group('Construcción y validaciones básicas de la entidad', () {
      test('Crea una oferta válida con representación canónica en centavos', () {
        final offer = createSampleOffer(
          offeredFareInCents: 400,
          comment: 'Ruta con congestión',
        );

        expect(offer.id, equals('off-001'));
        expect(offer.deliveryRequestId, equals('req-101'));
        expect(offer.driverId, equals('drv-001'));
        expect(offer.driverName, equals('Carlos Mendoza'));
        expect(offer.referenceFareInCents, equals(350));
        expect(offer.offeredFareInCents, equals(400));
        expect(offer.comment, equals('Ruta con congestión'));
        expect(offer.status, equals(OfferStatus.pending));
        expect(offer.isPending, isTrue);
        expect(offer.referenceFare, equals(3.50));
        expect(offer.offeredFare, equals(4.00));
        expect(offer.isCounterOffer, isTrue);
      });

      test('Rechaza identificadores vacíos con DomainException', () {
        expect(
          () => createSampleOffer(id: '   '),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleOffer(deliveryRequestId: ''),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleOffer(driverId: ' '),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleOffer(driverName: '  '),
          throwsA(isA<DomainException>()),
        );
      });

      test('Rechaza tarifas en centavos menores o iguales a 0', () {
        expect(
          () => createSampleOffer(referenceFareInCents: 0),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleOffer(referenceFareInCents: -100),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleOffer(offeredFareInCents: 0),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleOffer(offeredFareInCents: -50),
          throwsA(isA<DomainException>()),
        );
      });

      test('Rechaza tarifas en centavos superiores al límite máximo de 10.000.000', () {
        expect(
          () => createSampleOffer(referenceFareInCents: 10000001),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => createSampleOffer(offeredFareInCents: 10000001),
          throwsA(isA<DomainException>()),
        );
      });

      test('Rechaza fecha de respuesta anterior a la fecha de creación', () {
        expect(
          () => createSampleOffer(
            createdAt: DateTime(2026, 11, 2, 12, 0),
            respondedAt: DateTime(2026, 11, 2, 11, 0),
          ),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('Detección estricta de oferta base vs. contraoferta', () {
      test('isCounterOffer es false cuando la tarifa ofertada coincide con la referencial', () {
        final directOffer = createSampleOffer(
          referenceFareInCents: 350,
          offeredFareInCents: 350,
        );

        expect(directOffer.isCounterOffer, isFalse);
      });

      test('isCounterOffer es true cuando la tarifa ofertada difiere de la referencial', () {
        final higherOffer = createSampleOffer(
          referenceFareInCents: 350,
          offeredFareInCents: 450,
        );
        final lowerOffer = createSampleOffer(
          referenceFareInCents: 350,
          offeredFareInCents: 300,
        );

        expect(higherOffer.isCounterOffer, isTrue);
        expect(lowerOffer.isCounterOffer, isTrue);
      });
    });

    group('Transiciones de estado de la oferta', () {
      test('Aceptación de oferta transiciona a accepted y registra respondedAt', () {
        final offer = createSampleOffer();
        final responseTime = DateTime(2026, 11, 2, 10, 15);

        final acceptedOffer = offer.accept(respondedAt: responseTime);

        expect(acceptedOffer.status, equals(OfferStatus.accepted));
        expect(acceptedOffer.isAccepted, isTrue);
        expect(acceptedOffer.respondedAt, equals(responseTime));
      });

      test('Rechazo de oferta transiciona a rejected y registra respondedAt', () {
        final offer = createSampleOffer();
        final responseTime = DateTime(2026, 11, 2, 10, 20);

        final rejectedOffer = offer.reject(respondedAt: responseTime);

        expect(rejectedOffer.status, equals(OfferStatus.rejected));
        expect(rejectedOffer.isRejected, isTrue);
        expect(rejectedOffer.respondedAt, equals(responseTime));
      });

      test('Descarte de oferta transiciona a discarded y registra respondedAt', () {
        final offer = createSampleOffer();
        final responseTime = DateTime(2026, 11, 2, 10, 25);

        final discardedOffer = offer.discard(respondedAt: responseTime);

        expect(discardedOffer.status, equals(OfferStatus.discarded));
        expect(discardedOffer.isDiscarded, isTrue);
        expect(discardedOffer.respondedAt, equals(responseTime));
      });

      test('Intentar transicionar una oferta en estado terminal lanza DomainException', () {
        final accepted = createSampleOffer().accept();
        final rejected = createSampleOffer().reject();
        final discarded = createSampleOffer().discard();

        expect(() => accepted.accept(), throwsA(isA<DomainException>()));
        expect(() => accepted.reject(), throwsA(isA<DomainException>()));
        expect(() => accepted.discard(), throwsA(isA<DomainException>()));

        expect(() => rejected.accept(), throwsA(isA<DomainException>()));
        expect(() => rejected.discard(), throwsA(isA<DomainException>()));

        expect(() => discarded.accept(), throwsA(isA<DomainException>()));
        expect(() => discarded.reject(), throwsA(isA<DomainException>()));
      });
    });

    group('Parsing textual a centavos (parseTextToCents)', () {
      test('Parsea correctamente importes válidos enteros y decimales', () {
        expect(DeliveryOffer.parseTextToCents('10', 'monto'), equals(1000));
        expect(DeliveryOffer.parseTextToCents('10.5', 'monto'), equals(1050));
        expect(DeliveryOffer.parseTextToCents('10.50', 'monto'), equals(1050));
        expect(DeliveryOffer.parseTextToCents('0.05', 'monto'), equals(5));
        expect(DeliveryOffer.parseTextToCents('3.25', 'monto'), equals(325));
        expect(
          DeliveryOffer.parseTextToCents('100000', 'monto'),
          equals(10000000),
        );
        expect(
          DeliveryOffer.parseTextToCents('100000.00', 'monto'),
          equals(10000000),
        );
      });

      test('Normaliza espacios y ceros iniciales', () {
        expect(DeliveryOffer.parseTextToCents('  15.50  ', 'monto'), equals(1550));
        expect(DeliveryOffer.parseTextToCents('0005.50', 'monto'), equals(550));
        expect(DeliveryOffer.parseTextToCents('00010', 'monto'), equals(1000));
        expect(DeliveryOffer.parseTextToCents('000000.75', 'monto'), equals(75));
      });

      test('Rechaza cero y valores negativos', () {
        expect(
          () => DeliveryOffer.parseTextToCents('0', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('0.0', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('0.00', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('-5.50', 'monto'),
          throwsA(isA<DomainException>()),
        );
      });

      test('Rechaza entradas no numéricas o con formato inválido', () {
        expect(
          () => DeliveryOffer.parseTextToCents('', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('abc', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('12.a5', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('12.3.4', 'monto'),
          throwsA(isA<DomainException>()),
        );
      });

      test('Rechaza importes con más de dos decimales (sin redondeo silencioso)', () {
        expect(
          () => DeliveryOffer.parseTextToCents('3.555', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('10.123', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('0.001', 'monto'),
          throwsA(isA<DomainException>()),
        );
      });

      test('Rechaza cadenas excesivamente largas antes de cualquier conversión numérica', () {
        expect(
          () => DeliveryOffer.parseTextToCents('99999999999999999999', 'monto'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('1000000', 'monto'), // 7 dígitos
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('100001', 'monto'), // 6 dígitos > 100000
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.parseTextToCents('100000.01', 'monto'), // excede maxFareInCents
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('Conversión y adaptación de valores double heredados (doubleToCents)', () {
      test('Convierte double exactos válidos a centavos enteros', () {
        expect(DeliveryOffer.doubleToCents(3.50, 'tarifa'), equals(350));
        expect(DeliveryOffer.doubleToCents(15.0, 'tarifa'), equals(1500));
        expect(DeliveryOffer.doubleToCents(0.01, 'tarifa'), equals(1));
        expect(DeliveryOffer.doubleToCents(100000.0, 'tarifa'), equals(10000000));
      });

      test('Rechaza mediante reconstrucción exacta valores double con fracciones de centavo', () {
        expect(
          () => DeliveryOffer.doubleToCents(1.2300001, 'tarifa'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.doubleToCents(1.235, 'tarifa'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.doubleToCents(0.001, 'tarifa'),
          throwsA(isA<DomainException>()),
        );
      });

      test('Rechaza NaN, infinitos, cero y negativos', () {
        expect(
          () => DeliveryOffer.doubleToCents(double.nan, 'tarifa'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.doubleToCents(double.infinity, 'tarifa'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.doubleToCents(0.0, 'tarifa'),
          throwsA(isA<DomainException>()),
        );
        expect(
          () => DeliveryOffer.doubleToCents(-5.0, 'tarifa'),
          throwsA(isA<DomainException>()),
        );
      });

      test('Rechaza double superiores al importe máximo permitido', () {
        expect(
          () => DeliveryOffer.doubleToCents(100000.01, 'tarifa'),
          throwsA(isA<DomainException>()),
        );
      });
    });

    group('Factories fromDoubles y fromText', () {
      test('Factory fromDoubles crea oferta válida con centavos canónicos', () {
        final offer = DeliveryOffer.fromDoubles(
          id: 'off-d1',
          deliveryRequestId: 'req-01',
          driverId: 'drv-01',
          driverName: 'Juan',
          referenceFare: 3.50,
          offeredFare: 4.25,
          createdAt: fixedCreatedAt,
        );

        expect(offer.referenceFareInCents, equals(350));
        expect(offer.offeredFareInCents, equals(425));
        expect(offer.isCounterOffer, isTrue);
      });

      test('Factory fromText crea oferta válida a partir de texto de usuario', () {
        final offer = DeliveryOffer.fromText(
          id: 'off-t1',
          deliveryRequestId: 'req-01',
          driverId: 'drv-01',
          driverName: 'Juan',
          referenceFareInCents: 350,
          offeredFareText: '4.50',
          createdAt: fixedCreatedAt,
        );

        expect(offer.offeredFareInCents, equals(450));
        expect(offer.isCounterOffer, isTrue);
      });
    });

    group('Inmutabilidad y copyWith', () {
      test('copyWith preserva campos no modificados', () {
        final original = createSampleOffer(comment: 'Original');
        final copy = original.copyWith(comment: 'Modificado');

        expect(copy.id, equals(original.id));
        expect(copy.comment, equals('Modificado'));
        expect(copy.offeredFareInCents, equals(original.offeredFareInCents));
        expect(original.comment, equals('Original'));
      });
    });
  });
}
