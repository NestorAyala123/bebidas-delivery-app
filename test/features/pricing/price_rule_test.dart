import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/price_rule.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';

void main() {
  test('Applies the highest active minimum quantity rule', () {
    const product = Product(
      id: 'prod-1',
      storeId: 'store-1',
      name: 'Cerveza',
      basePrice: 10,
      priceRules: [
        PriceRule(
          id: 'rule-6',
          productId: 'prod-1',
          minQuantity: 6,
          unitPrice: 9,
        ),
        PriceRule(
          id: 'rule-12',
          productId: 'prod-1',
          minQuantity: 12,
          unitPrice: 8,
        ),
      ],
    );

    expect(product.getUnitPriceForQuantity(5), 10);
    expect(product.getUnitPriceForQuantity(6), 9);
    expect(product.getUnitPriceForQuantity(12), 8);
  });
}
