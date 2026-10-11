import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';

class InMemoryStoreRepository implements StoreRepository {
  final Map<String, Store> _stores = {};

  @override
  Future<Result<List<Store>, Failure>> getStores() async {
    return Success(_stores.values.toList());
  }

  @override
  Future<Result<List<Store>, Failure>> getOpenStores() async {
    return Success(_stores.values.where((store) => store.isOpen).toList());
  }

  @override
  Future<Result<Store, Failure>> getStoreById(String id) async {
    final store = _stores[id];
    return store == null
        ? const FailureResult<Store, Failure>(
            NotFoundFailure('Comercio no encontrado'),
          )
        : Success(store);
  }

  @override
  Future<Result<Store, Failure>> createStore(Store store) async {
    if (_stores.containsKey(store.id)) {
      return const FailureResult<Store, Failure>(
        ValidationFailure('Ya existe un comercio con ese identificador'),
      );
    }
    _stores[store.id] = store;
    return Success(store);
  }

  @override
  Future<Result<Store, Failure>> updateStore(Store store) async {
    if (!_stores.containsKey(store.id)) {
      return const FailureResult<Store, Failure>(
        NotFoundFailure('Comercio no encontrado'),
      );
    }
    _stores[store.id] = store;
    return Success(store);
  }

  @override
  Future<Result<void, Failure>> updateStoreStatus(
    String storeId,
    bool isOpen,
  ) async {
    final store = _stores[storeId];
    if (store == null) {
      return const FailureResult<void, Failure>(
        NotFoundFailure('Comercio no encontrado'),
      );
    }
    _stores[storeId] = Store(
      id: store.id,
      ownerId: store.ownerId,
      name: store.name,
      description: store.description,
      address: store.address,
      latitude: store.latitude,
      longitude: store.longitude,
      openingHours: store.openingHours,
      phone: store.phone,
      imageUrl: store.imageUrl,
      isOpen: isOpen,
      hasOwnDelivery: store.hasOwnDelivery,
      allowsExternalDelivery: store.allowsExternalDelivery,
      allowsPickup: store.allowsPickup,
    );
    return const Success<void, Failure>(null);
  }

  @override
  Future<Result<List<Store>, Failure>> getNearbyStores({
    required double latitude,
    required double longitude,
    double radiusInKm = 10.0,
  }) async {
    return getOpenStores();
  }
}
