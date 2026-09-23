import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/geo_coordinates.dart';

abstract class LocationServiceContract {
  Future<Result<GeoCoordinates, Failure>> getCurrentPosition();
  Stream<GeoCoordinates> trackPositionStream();
  Future<bool> checkAndRequestPermissions();
}
