import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../products/domain/entities/product.dart';
import '../entities/pricing_breakdown.dart';
import 'delivery_fee_policy.dart';

/// Calcula el precio de compra aplicando escalones por volumen (RN04)
/// y la tarifa de envío por distancia.
///
/// Reglas corregidas en la integración de la Semana 5:
/// - Cantidades fuera de rango (0 o más de 999) se rechazan.
/// - Los escalones debe tener cantidades mínimas únicas.
/// - El precio de un escalón no puede superar el precio base ni ser negativo.
/// - La distancia de envío debe estar entre 0 y 50 km.
class QuantityPricingService {
  final DeliveryFeePolicy deliveryFeePolicy;

  const QuantityPricingService({
    this.deliveryFeePolicy = const DeliveryFeePolicy(),
  });

  Result<void, Failure> validateTiers(Product product) {
    final seenMinQuantities = <int>{};

    for (final tier in product.quantityTiers) {
      if (!seenMinQuantities.add(tier.minQuantity)) {
        return FailureResult(
          ValidationFailure(
            'El escalón de ${tier.minQuantity} unidades está duplicado',
          ),
        );
      }

      if (tier.unitPrice <= 0) {
        return const FailureResult(
          ValidationFailure(
            'El precio de un escalón por volumen debe ser mayor a 0',
          ),
        );
      }

      if (tier.unitPrice > product.basePrice) {
        return FailureResult(
          ValidationFailure(
            'El precio del escalón de ${tier.minQuantity} unidades no puede '
            'ser mayor que el precio base',
          ),
        );
      }
    }

    return const Success(null);
  }

  Result<PricingBreakdown, Failure> calculate({
    required Product product,
    required int quantity,
    double deliveryDistanceKm = 0,
  }) {
    if (quantity <= 0) {
      return const FailureResult(
        ValidationFailure('La cantidad debe ser mayor a 0'),
      );
    }

    if (quantity > 999) {
      return const FailureResult(
        ValidationFailure('La cantidad máxima por compra es 999 unidades'),
      );
    }

    if (product.basePrice < 0) {
      return const FailureResult(
        ValidationFailure('El precio base del producto no es válido'),
      );
    }

    final tiersResult = validateTiers(product);
    if (tiersResult.isFailure) {
      return FailureResult(tiersResult.failureOrNull!);
    }

    final feeResult = deliveryFeePolicy.calculate(deliveryDistanceKm);
    if (feeResult.isFailure) {
      return FailureResult(feeResult.failureOrNull!);
    }

    final unitPrice = product.getUnitPriceForQuantity(quantity);
    final subtotal = double.parse((unitPrice * quantity).toStringAsFixed(2));
    final deliveryFee = feeResult.dataOrNull!;
    final total = double.parse((subtotal + deliveryFee).toStringAsFixed(2));

    return Success(
      PricingBreakdown(
        totalUnits: quantity,
        unitPrice: unitPrice,
        subtotal: subtotal,
        deliveryFee: deliveryFee,
        total: total,
        distanceKm: deliveryDistanceKm,
      ),
    );
  }
}
