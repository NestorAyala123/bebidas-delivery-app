import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../products/domain/entities/product.dart';
import '../entities/pricing_breakdown.dart';
import '../services/quantity_pricing_service.dart';

/// Caso de uso para calcular el total de una compra antes del checkout.
class CalcularPrecioCompraUseCase {
  final QuantityPricingService service;

  const CalcularPrecioCompraUseCase({
    this.service = const QuantityPricingService(),
  });

  Result<PricingBreakdown, Failure> call({
    required Product product,
    required int quantity,
    double deliveryDistanceKm = 0,
  }) {
    return service.calculate(
      product: product,
      quantity: quantity,
      deliveryDistanceKm: deliveryDistanceKm,
    );
  }
}
