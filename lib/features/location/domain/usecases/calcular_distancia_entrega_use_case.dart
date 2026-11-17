import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/geo_coordinates.dart';

/// Resultado del cálculo de distancia y tiempo estimado de entrega.
class DeliveryEstimate {
  final double distanceKm;
  final int estimatedMinutes;
  final double suggestedFee;
  final double accuracyMeters;

  const DeliveryEstimate({
    required this.distanceKm,
    required this.estimatedMinutes,
    required this.suggestedFee,
    this.accuracyMeters = 0,
  });

  bool get isApproximate => accuracyMeters > 150;

  String get accuracyLabel {
    if (accuracyMeters <= 0) return 'Precisión no reportada';
    return 'Precisión aproximada ±${accuracyMeters.round()} m';
  }

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
    double accuracyMeters = 0,
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
    return fromDistance(distanceKm, accuracyMeters: accuracyMeters);
  }

  /// Calcula tiempo y tarifa referencial a partir de una distancia conocida.
  /// La usan el checkout y la negociación de repartidores.
  Result<DeliveryEstimate, Failure> fromDistance(
    double distanceKm, {
    double accuracyMeters = 0,
  }) {
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

    if (distanceKm > 50) {
      return const FailureResult(
        ValidationFailure('La distancia supera el máximo soportado (50 km)'),
      );
    }

    if (accuracyMeters < 0 || accuracyMeters > 5000) {
      return const FailureResult(
        ValidationFailure('La precisión de la ubicación no es válida'),
      );
    }

    // Estimación: 10 min de preparación + 3 minutos por kilómetro recorrido
    final estimatedMinutes = (10 + (distanceKm * 3)).round();

    // Tarifa base $1.50 + $0.50 por kilómetro adicional (mínimo $1.50)
    final suggestedFee = double.parse(
      (1.50 + (distanceKm * 0.50)).toStringAsFixed(2),
    );

    return Success(
      DeliveryEstimate(
        distanceKm: distanceKm,
        estimatedMinutes: estimatedMinutes,
        suggestedFee: suggestedFee,
        accuracyMeters: accuracyMeters,
      ),
    );
  }
}
