/// Price applied when a product reaches a minimum quantity.
class PriceRule {
  final String id;
  final String productId;
  final int minQuantity;
  final double unitPrice;
  final bool isActive;

  const PriceRule({
    required this.id,
    required this.productId,
    required this.minQuantity,
    required this.unitPrice,
    this.isActive = true,
  }) : assert(minQuantity > 0, 'La cantidad mínima debe ser mayor a 0'),
       assert(unitPrice >= 0, 'El precio no puede ser negativo');
}
