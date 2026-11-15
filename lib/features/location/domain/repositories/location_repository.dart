import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/geo_coordinates.dart';
import '../entities/location_fix.dart';
import '../entities/nearby_store.dart';

/// Contract for the location repository.
/// Implementations live in the data layer; the domain stays framework-free.
abstract class LocationRepository {
  /// Returns the current device position, or a [Failure] if the GPS is
  /// unavailable or the permission is denied.
  Future<Result<GeoCoordinates, Failure>> getCurrentPosition();

  /// Returns the current position with an approximate accuracy margin.
  ///
  /// Implementations using the real GPS plugin should override this method.
  Future<Result<LocationFix, Failure>> getCurrentFix() async {
    final result = await getCurrentPosition();
    return result.fold(
      onSuccess: (coordinates) =>
          Success(LocationFix(coordinates: coordinates, accuracyMeters: 100)),
      onFailure: (failure) => FailureResult(failure),
    );
  }

  /// Requests the location permission and returns [true] when granted.
  Future<bool> checkAndRequestPermission();

  /// Returns the list of stores within [radiusKm] from [origin],
  /// sorted by ascending distance.
  Future<Result<List<NearbyStore>, Failure>> getNearbyStores({
    required GeoCoordinates origin,
    double radiusKm = 5.0,
  });
}
