import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/quantity_pricing_tier.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';

void main() {
  group('Pricing and Volume Tier Rules (RN04)', () {
    test('Calculates base price when quantity does not reach any tier', () {
      const product = Product(
        id: 'prod-1',
        storeId: 'store-1',
        name: 'Six-pack Cerveza',
        basePrice: 10.0,
        quantityTiers: [
          QuantityPricingTier(minQuantity: 6, unitPrice: 9.0),
          QuantityPricingTier(minQuantity: 12, unitPrice: 8.0),
        ],
      );

      expect(product.getUnitPriceForQuantity(1), equals(10.0));
      expect(product.getUnitPriceForQuantity(5), equals(10.0));
    });

    test('Calculates tier price when quantity meets or exceeds threshold', () {
      const product = Product(
        id: 'prod-1',
        storeId: 'store-1',
        name: 'Six-pack Cerveza',
        basePrice: 10.0,
        quantityTiers: [
          QuantityPricingTier(minQuantity: 6, unitPrice: 9.0),
          QuantityPricingTier(minQuantity: 12, unitPrice: 8.0),
        ],
      );

      // Reaches tier 1 (>= 6)
      expect(product.getUnitPriceForQuantity(6), equals(9.0));
      expect(product.getUnitPriceForQuantity(10), equals(9.0));

      // Reaches tier 2 (>= 12)
      expect(product.getUnitPriceForQuantity(12), equals(8.0));
      expect(product.getUnitPriceForQuantity(24), equals(8.0));
    });
  });
}
