import '../../../pricing/domain/entities/quantity_pricing_tier.dart';
import '../../../pricing/domain/entities/price_rule.dart';
import '../../../returnable_containers/domain/entities/returnable_container.dart';

class Product {
  final String id;
  final String storeId; // RN07: pertenece a un solo establecimiento
  final String name;
  final String description;
  final double basePrice;
  final bool isAvailable;
  final String? imageUrl;
  final bool isReturnableContainer; // RN05
  final double containerDepositPrice;
  final List<QuantityPricingTier> quantityTiers; // RN04
  final List<PriceRule> priceRules;
  final ReturnableContainer? returnableContainer;

  const Product({
    required this.id,
    required this.storeId,
    required this.name,
    this.description = '',
    required this.basePrice,
    this.isAvailable = true,
    this.imageUrl,
    this.isReturnableContainer = false,
    this.containerDepositPrice = 0.0,
    this.quantityTiers = const [],
    this.priceRules = const [],
    this.returnableContainer,
  });

  /// Calculates the effective unit price for a given quantity (RN04)
  double getUnitPriceForQuantity(int quantity) {
    final tiers = <QuantityPricingTier>[
      ...quantityTiers,
      ...priceRules
          .where((rule) => rule.isActive)
          .map(
            (rule) => QuantityPricingTier(
              minQuantity: rule.minQuantity,
              unitPrice: rule.unitPrice,
            ),
          ),
    ];
    if (tiers.isEmpty) return basePrice;

    // Find the highest qualifying tier
    final sortedTiers = List<QuantityPricingTier>.from(tiers)
      ..sort((a, b) => b.minQuantity.compareTo(a.minQuantity));

    for (final tier in sortedTiers) {
      if (quantity >= tier.minQuantity) {
        return tier.unitPrice;
      }
    }

    return basePrice;
  }
}
