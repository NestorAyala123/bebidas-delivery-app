/// Represents a tier for quantity-based pricing (RN04)
class QuantityPricingTier {
  final int minQuantity;
  final double unitPrice;

  const QuantityPricingTier({
    required this.minQuantity,
    required this.unitPrice,
  }) : assert(minQuantity > 0, 'La cantidad mínima debe ser mayor a 0'),
       assert(unitPrice >= 0, 'El precio no puede ser negativo');
}
