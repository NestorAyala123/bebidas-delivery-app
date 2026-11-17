import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';

/// Política única de tarifa de envío por distancia.
///
/// Se comparte con el cálculo de la pantalla de ubicación para evitar
/// discrepancias entre el mapa y el total mostrado al pagar.
class DeliveryFeePolicy {
  static const double baseFee = 1.50;
  static const double feePerKm = 0.50;
  static const double maxSupportedDistanceKm = 50.0;

  const DeliveryFeePolicy();

  /// Valida el rango de distancia y devuelve la tarifa referencial.
  Result<double, Failure> calculate(double distanceKm) {
    if (distanceKm.isNaN || distanceKm.isInfinite) {
      return const FailureResult(
        ValidationFailure('La distancia de entrega no es válida'),
      );
    }

    if (distanceKm < 0) {
      return const FailureResult(
        ValidationFailure('La distancia de entrega no puede ser negativa'),
      );
    }

    if (distanceKm > maxSupportedDistanceKm) {
      return const FailureResult(
        ValidationFailure(
          'La distancia supera el máximo soportado de 50 km. '
          'Selecciona otra dirección de entrega.',
        ),
      );
    }

    final fee = double.parse(
      (baseFee + (distanceKm * feePerKm)).toStringAsFixed(2),
    );
    return Success(fee);
  }

  String labelFor(double distanceKm) {
    if (distanceKm <= 0) return 'Retiro en local: sin costo de envío';
    return 'Envío aproximado para ${distanceKm.toStringAsFixed(2)} km';
  }
}
