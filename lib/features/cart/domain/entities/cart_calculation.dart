/// Detailed calculation structure for a cart.
/// Enforces calculation rules including RN05 (Returnable containers fee).
class CartCalculation {
  final double itemsSubtotal;
  final int totalItemCount;
  final int totalContainersRequired;
  final int returnedContainers;
  final int missingContainers;
  final double missingContainersFee;
  final double deliveryFee;
  final double discount;
  final double total;

  const CartCalculation({
    required this.itemsSubtotal,
    required this.totalItemCount,
    required this.totalContainersRequired,
    required this.returnedContainers,
    required this.missingContainers,
    required this.missingContainersFee,
    this.deliveryFee = 0.0,
    this.discount = 0.0,
    required this.total,
  });

  /// Factory constructor that computes all derived fields automatically.
  factory CartCalculation.compute({
    required double itemsSubtotal,
    required int totalItemCount,
    required int totalContainersRequired,
    int returnedContainers = 0,
    required double missingContainersFee,
    double deliveryFee = 0.0,
    double discount = 0.0,
  }) {
    final safeReturned = returnedContainers < 0 ? 0 : returnedContainers;
    final safeDelivery = deliveryFee < 0 ? 0.0 : deliveryFee;
    final safeDiscount = discount < 0 ? 0.0 : discount;
    final missing = (totalContainersRequired - safeReturned).clamp(
      0,
      totalContainersRequired,
    );

    final grandTotal = (itemsSubtotal + missingContainersFee + safeDelivery - safeDiscount)
        .clamp(0.0, double.infinity);

    return CartCalculation(
      itemsSubtotal: itemsSubtotal,
      totalItemCount: totalItemCount,
      totalContainersRequired: totalContainersRequired,
      returnedContainers: safeReturned,
      missingContainers: missing,
      missingContainersFee: missingContainersFee,
      deliveryFee: safeDelivery,
      discount: safeDiscount,
      total: grandTotal,
    );
  }

  bool get hasReturnableContainers => totalContainersRequired > 0;
  bool get hasMissingContainersFee => missingContainersFee > 0;
  bool get isFullyReturned =>
      totalContainersRequired > 0 && missingContainers == 0;
  bool get isDeliveryFree => deliveryFee == 0.0;

  CartCalculation copyWith({
    double? itemsSubtotal,
    int? totalItemCount,
    int? totalContainersRequired,
    int? returnedContainers,
    int? missingContainers,
    double? missingContainersFee,
    double? deliveryFee,
    double? discount,
    double? total,
  }) {
    return CartCalculation(
      itemsSubtotal: itemsSubtotal ?? this.itemsSubtotal,
      totalItemCount: totalItemCount ?? this.totalItemCount,
      totalContainersRequired:
          totalContainersRequired ?? this.totalContainersRequired,
      returnedContainers: returnedContainers ?? this.returnedContainers,
      missingContainers: missingContainers ?? this.missingContainers,
      missingContainersFee: missingContainersFee ?? this.missingContainersFee,
      deliveryFee: deliveryFee ?? this.deliveryFee,
      discount: discount ?? this.discount,
      total: total ?? this.total,
    );
  }

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is CartCalculation &&
          runtimeType == other.runtimeType &&
          itemsSubtotal == other.itemsSubtotal &&
          totalItemCount == other.totalItemCount &&
          totalContainersRequired == other.totalContainersRequired &&
          returnedContainers == other.returnedContainers &&
          missingContainers == other.missingContainers &&
          missingContainersFee == other.missingContainersFee &&
          deliveryFee == other.deliveryFee &&
          discount == other.discount &&
          total == other.total;

  @override
  int get hashCode => Object.hash(
        itemsSubtotal,
        totalItemCount,
        totalContainersRequired,
        returnedContainers,
        missingContainers,
        missingContainersFee,
        deliveryFee,
        discount,
        total,
      );

  @override
  String toString() {
    return 'CartCalculation('
        'itemsSubtotal: \$$itemsSubtotal, '
        'totalItemCount: $totalItemCount, '
        'totalContainersRequired: $totalContainersRequired, '
        'returnedContainers: $returnedContainers, '
        'missingContainers: $missingContainers, '
        'missingContainersFee: \$$missingContainersFee, '
        'deliveryFee: \$$deliveryFee, '
        'discount: \$$discount, '
        'total: \$$total'
        ')';
  }
}

