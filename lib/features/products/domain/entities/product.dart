import '../../../pricing/domain/entities/quantity_pricing_tier.dart';

class Product {
  final String id;
  final String storeId; // RN07: pertenece a un solo establecimiento
  final String name;
  final String description;
  final double basePrice;
  final bool isAvailable;
  final bool isReturnableContainer; // RN05
  final double containerDepositPrice;
  final List<QuantityPricingTier> quantityTiers; // RN04

  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    this.description = '',
    required this.basePrice,
    this.isAvailable = true,
    this.isReturnableContainer = false,
    this.containerDepositPrice = 0.0,
    this.quantityTiers = const [],
  });

  /// Calculates the effective unit price for a given quantity (RN04)
  double getUnitPriceForQuantity(int quantity) {
    if (quantityTiers.isEmpty) return basePrice;

    // Find the highest qualifying tier
    final sortedTiers = List<QuantityPricingTier>.from(quantityTiers)
      ..sort((a, b) => b.minQuantity.compareTo(a.minQuantity));

    for (final tier in sortedTiers) {
      if (quantity >= tier.minQuantity) {
        return tier.unitPrice;
      }
    }

    return basePrice;
  }
}
