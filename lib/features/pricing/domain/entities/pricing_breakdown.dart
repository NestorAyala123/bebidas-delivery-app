/// Desglose de una compra antes de crear el pedido.
///
/// Mantiene separados productos y envío para que el cliente vea exactamente
/// qué está pagando y para que el total quede congelado en la orden (RN08).
class PricingBreakdown {
  final int totalUnits;
  final double unitPrice;
  final double subtotal;
  final double deliveryFee;
  final double total;
  final double distanceKm;

  const PricingBreakdown({
    required this.totalUnits,
    required this.unitPrice,
    required this.subtotal,
    required this.deliveryFee,
    required this.total,
    required this.distanceKm,
  });

  bool get hasDeliveryFee => deliveryFee > 0;

  String get formattedDeliveryFee => '\$${deliveryFee.toStringAsFixed(2)}';

  String get formattedTotal => '\$${total.toStringAsFixed(2)}';

  @override
  String toString() =>
      'PricingBreakdown(units: $totalUnits, subtotal: $subtotal, '
      'delivery: $deliveryFee, total: $total)';
}
