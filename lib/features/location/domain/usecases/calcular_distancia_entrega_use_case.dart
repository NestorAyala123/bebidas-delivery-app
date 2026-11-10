import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/geo_coordinates.dart';

/// Resultado del cálculo de distancia y tiempo estimado de entrega.
class DeliveryEstimate {
  final double distanceKm;
  final int estimatedMinutes;
  final double suggestedFee;

  const DeliveryEstimate({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.suggestedFee,
  });

  String get formattedDistance {
    if (distanceKm < 1.0) {
      final meters = (distanceKm * 1000).round();
      return '$meters m';
    }
    return '${distanceKm.toStringAsFixed(2)} km';
  }
}

/// Caso de uso para calcular la distancia de entrega y estimar el tiempo
/// de traslado y tarifa referencial entre el comercio y el destino del cliente.
class CalcularDistanciaEntregaUseCase {
  const CalcularDistanciaEntregaUseCase();

  Result<DeliveryEstimate, Failure> call({
    required GeoCoordinates origin,
    required GeoCoordinates destination,
  }) {
    if (origin.latitude == 0.0 && origin.longitude == 0.0) {
      return const FailureResult(
        ValidationFailure('Las coordenadas de origen no son válidas'),
      );
    }

    if (destination.latitude == 0.0 && destination.longitude == 0.0) {
      return const FailureResult(
        ValidationFailure('Las coordenadas de destino no son válidas'),
      );
    }

    final distanceKm = origin.distanceToInKm(destination);

    // Estimación: 10 min de preparación + 3 minutos por kilómetro recorrido
    final estimatedMinutes = (10 + (distanceKm * 3)).round();

    // Tarifa base $1.50 + $0.50 por kilómetro adicional (tarifa referencial mínima $1.50)
    final suggestedFee = double.parse(
      (1.50 + (distanceKm * 0.50)).toStringAsFixed(2),
    );

    return Success(
      DeliveryEstimate(
        distanceKm: distanceKm,
        estimatedMinutes: estimatedMinutes,
        suggestedFee: suggestedFee,
      ),
    );
  }
}
