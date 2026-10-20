/// Domain service that enforces Business Rule RN05:
/// In products with returnable containers, only missing containers are charged.
class ContainerFeeCalculator {
  const ContainerFeeCalculator();

  /// Calculates the total fee for missing containers.
  /// [requiredContainers]: Amount of containers the current order requires.
  /// [returnedContainers]: Amount of empty containers the customer is handing in.
  /// [depositPerContainer]: Unit deposit fee for the container.
  double calculateMissingFee({
    required int requiredContainers,
    required int returnedContainers,
    required double depositPerContainer,
  }) {
    assert(
      returnedContainers >= 0,
      'La cantidad de envases devueltos no puede ser negativa',
    );

    if (requiredContainers <= 0 || depositPerContainer <= 0) {
      return 0.0;
    }

    final int missingContainers = requiredContainers - returnedContainers;
    if (missingContainers <= 0) {
      return 0.0;
    }

    return missingContainers * depositPerContainer;
  }
}
