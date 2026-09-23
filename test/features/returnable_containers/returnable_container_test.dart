import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/returnable_containers/domain/services/container_fee_calculator.dart';

void main() {
  group('Returnable Container Fee Rules (RN05)', () {
    const calculator = ContainerFeeCalculator();

    test('Charges nothing when customer returns all required containers', () {
      final fee = calculator.calculateMissingFee(
        requiredContainers: 4,
        returnedContainers: 4,
        depositPerContainer: 1.5,
      );

      expect(fee, equals(0.0));
    });

    test('Charges nothing when customer returns more containers than required', () {
      final fee = calculator.calculateMissingFee(
        requiredContainers: 3,
        returnedContainers: 5,
        depositPerContainer: 2.0,
      );

      expect(fee, equals(0.0));
    });

    test('Charges only the difference when customer has missing containers', () {
      final fee = calculator.calculateMissingFee(
        requiredContainers: 5,
        returnedContainers: 2,
        depositPerContainer: 2.0,
      );

      // Missing = 5 - 2 = 3 containers -> 3 * 2.0 = 6.0
      expect(fee, equals(6.0));
    });

    test('Charges all containers when customer returns zero', () {
      final fee = calculator.calculateMissingFee(
        requiredContainers: 6,
        returnedContainers: 0,
        depositPerContainer: 1.0,
      );

      expect(fee, equals(6.0));
    });
  });
}
