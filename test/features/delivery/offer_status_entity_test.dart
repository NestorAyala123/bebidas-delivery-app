import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/offer_status.dart';

void main() {
  group('OfferStatus Domain Tests', () {
    test('Contiene exactamente los cuatro estados requeridos', () {
      expect(OfferStatus.values, hasLength(4));
      expect(
        OfferStatus.values,
        containsAll([
          OfferStatus.pending,
          OfferStatus.accepted,
          OfferStatus.rejected,
          OfferStatus.discarded,
        ]),
      );
    });

    test('Propiedad isTerminal es true para estados terminales y false para pending', () {
      expect(OfferStatus.pending.isTerminal, isFalse);
      expect(OfferStatus.accepted.isTerminal, isTrue);
      expect(OfferStatus.rejected.isTerminal, isTrue);
      expect(OfferStatus.discarded.isTerminal, isTrue);
    });

    test('Propiedad isPending es true solo para OfferStatus.pending', () {
      expect(OfferStatus.pending.isPending, isTrue);
      expect(OfferStatus.accepted.isPending, isFalse);
      expect(OfferStatus.rejected.isPending, isFalse);
      expect(OfferStatus.discarded.isPending, isFalse);
    });

    group('Transiciones válidas desde OfferStatus.pending', () {
      test('pending puede transicionar a accepted', () {
        expect(OfferStatus.pending.canTransitionTo(OfferStatus.accepted), isTrue);
      });

      test('pending puede transicionar a rejected', () {
        expect(OfferStatus.pending.canTransitionTo(OfferStatus.rejected), isTrue);
      });

      test('pending puede transicionar a discarded', () {
        expect(OfferStatus.pending.canTransitionTo(OfferStatus.discarded), isTrue);
      });

      test('pending no puede transicionar a sí mismo', () {
        expect(OfferStatus.pending.canTransitionTo(OfferStatus.pending), isFalse);
      });
    });

    group('Transiciones prohibidas desde estados terminales', () {
      for (final terminalStatus in [
        OfferStatus.accepted,
        OfferStatus.rejected,
        OfferStatus.discarded,
      ]) {
        test('${terminalStatus.name} no puede transicionar a ningún otro estado', () {
          for (final targetStatus in OfferStatus.values) {
            expect(
              terminalStatus.canTransitionTo(targetStatus),
              isFalse,
              reason:
                  '${terminalStatus.name} no debe poder transicionar a ${targetStatus.name}',
            );
          }
        });
      }
    });
  });
}
