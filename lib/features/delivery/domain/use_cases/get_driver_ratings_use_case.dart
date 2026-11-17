import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../ratings/domain/entities/rating.dart';
import '../../../ratings/domain/repositories/rating_repository.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../../users/domain/entities/role.dart';

/// Caso de uso para consultar las calificaciones recibidas por un repartidor.
/// 100% pure Dart, independiente de Flutter y Firebase.
class GetDriverRatingsUseCase {
  final RatingRepository ratingRepository;

  const GetDriverRatingsUseCase({required this.ratingRepository});

  Future<Result<List<Rating>, Failure>> call({
    required String driverId,
    IdentityContract? driverIdentity,
  }) async {
    // 1. Autorización: solo el repartidor autenticado consulta sus calificaciones.
    if (driverIdentity == null) {
      return const FailureResult(
        UnauthorizedFailure(
          'Se requiere la identidad autenticada del repartidor para consultar sus calificaciones.',
        ),
      );
    }

    if (!driverIdentity.isActive) {
      return const FailureResult(
        UnauthorizedFailure(
          'El usuario autenticado se encuentra inactivo.',
        ),
      );
    }

    if (driverIdentity.rbacRole != Role.driver) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-RATING: Solo usuarios con rol de repartidor pueden consultar sus calificaciones.',
        ),
      );
    }

    if (driverIdentity.id != driverId) {
      return const FailureResult(
        UnauthorizedFailure(
          'RN-RATING: El identificador de la identidad autenticada no coincide con el repartidor indicado.',
        ),
      );
    }

    // 2. Consultar las calificaciones recibidas por el repartidor.
    return ratingRepository.getRatingsForUser(driverId);
  }
}
