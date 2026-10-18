/// Value object responsible for calculating referential delivery fees.
/// 100% pure Dart, independent of Flutter and Firebase.
class DeliveryFee {
  final double baseFee;
  final double perKmRate;

  const DeliveryFee({
    this.baseFee = 1.50,
    this.perKmRate = 0.50,
  }) : assert(baseFee >= 0, 'La tarifa base no puede ser negativa'),
       assert(perKmRate >= 0, 'La tarifa por kilómetro no puede ser negativa');

  /// Calculates the referential fare based on the given [distanceInKm].
  double calculate(double distanceInKm) {
    assert(distanceInKm >= 0, 'La distancia no puede ser negativa');
    final total = baseFee + (distanceInKm * perKmRate);
    return double.parse(total.toStringAsFixed(2));
  }
}
