import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/store.dart';

abstract class StoreRepository {
  Future<Result<Store, Failure>> getStoreById(String id);
  Future<Result<List<Store>, Failure>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
  });
  Future<Result<void, Failure>> updateStoreStatus(String storeId, bool isOpen);
}
