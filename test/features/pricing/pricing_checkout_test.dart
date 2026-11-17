import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/entities/quantity_pricing_tier.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/services/delivery_fee_policy.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/services/quantity_pricing_service.dart';
import 'package:bebidas_delivery_app/features/pricing/domain/usecases/calcular_precio_compra_use_case.dart';
import 'package:bebidas_delivery_app/features/products/domain/entities/product.dart';

void main() {
  const product = Product(
    id: 'prod-1',
    storeId: 'store-1',
    name: 'Cerveza artesanal',
    basePrice: 10.0,
    quantityTiers: [
      QuantityPricingTier(minQuantity: 6, unitPrice: 9.0),
      QuantityPricingTier(minQuantity: 12, unitPrice: 8.0),
    ],
  );

  group('DeliveryFeePolicy (envíos)', () {
    const policy = DeliveryFeePolicy();

    test('calcula tarifa base más costo por kilómetro', () {
      final fee = policy.calculate(4);

      expect(fee.isSuccess, isTrue);
      expect(fee.dataOrNull, 3.5);
    });

    test('rechaza distancias negativas o fuera de rango', () {
      expect(policy.calculate(-1).isFailure, isTrue);
      expect(policy.calculate(51).isFailure, isTrue);
      expect(policy.calculate(double.nan).isFailure, isTrue);
    });
  });

  group('QuantityPricingService (precio/rango)', () {
    const service = QuantityPricingService();
    const useCase = CalcularPrecioCompraUseCase();

    test('aplica escalón por volumen y suma envío', () {
      final result = useCase(
        product: product,
        quantity: 12,
        deliveryDistanceKm: 4,
      );

      final breakdown = result.dataOrNull!;
      expect(breakdown.unitPrice, 8.0);
      expect(breakdown.subtotal, 96.0);
      expect(breakdown.deliveryFee, 3.5);
      expect(breakdown.total, 99.5);
      expect(breakdown.totalUnits, 12);
    });

    test('cobra la tarifa base mínima para distancia cero', () {
      final result = service.calculate(
        product: product,
        quantity: 1,
        deliveryDistanceKm: 0,
      );

      expect(result.dataOrNull!.deliveryFee, 1.5);
      expect(result.dataOrNull!.subtotal, 10.0);
    });

    test('rechaza cantidades fuera de rango', () {
      expect(
        service.calculate(product: product, quantity: 0).failureOrNull,
        isNotNull,
      );
      expect(
        service.calculate(product: product, quantity: 1000).failureOrNull,
        isNotNull,
      );
    });

    test('rechaza escalones duplicados', () {
      const invalid = Product(
        id: 'prod-2',
        storeId: 'store-1',
        name: 'Vino',
        basePrice: 20,
        quantityTiers: [
          QuantityPricingTier(minQuantity: 6, unitPrice: 18),
          QuantityPricingTier(minQuantity: 6, unitPrice: 17),
        ],
      );

      expect(service.validateTiers(invalid).isFailure, isTrue);
      expect(
        service.calculate(product: invalid, quantity: 6).isFailure,
        isTrue,
      );
    });

    test('rechaza un escalón más caro que el precio base', () {
      const invalid = Product(
        id: 'prod-3',
        storeId: 'store-1',
        name: 'Ron',
        basePrice: 15,
        quantityTiers: [QuantityPricingTier(minQuantity: 3, unitPrice: 16)],
      );

      final failure = service.validateTiers(invalid).failureOrNull;
      expect(failure, isNotNull);
      expect(failure!.message, contains('mayor que el precio base'));
    });

    test('rechaza un precio de escalón en cero', () {
      const invalid = Product(
        id: 'prod-4',
        storeId: 'store-1',
        name: 'Tequila',
        basePrice: 30,
        quantityTiers: [QuantityPricingTier(minQuantity: 2, unitPrice: 0)],
      );

      expect(service.validateTiers(invalid).isFailure, isTrue);
    });
  });
}
