/// Catalog configuration for a product that uses returnable containers.
class ReturnableContainer {
  final String id;
  final String productId;
  final bool isReturnable;
  final double depositPrice;
  final bool isActive;

  const ReturnableContainer({
    required this.id,
    required this.productId,
    required this.isReturnable,
    required this.depositPrice,
    this.isActive = true,
  }) : assert(depositPrice >= 0, 'La garantía no puede ser negativa');
}
