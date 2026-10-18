import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';

class SaveStoreUseCase {
  final StoreRepository repository;

  const SaveStoreUseCase(this.repository);

  Future<Result<Store, Failure>> call(Store store) async {
    final validation = _validate(store);
    if (validation != null) {
      return Future.value(FailureResult<Store, Failure>(validation));
    }

    if (store.id.trim().isEmpty) return repository.createStore(store);

    final existing = await repository.getStoreById(store.id);
    if (existing.failureOrNull is NotFoundFailure) {
      return repository.createStore(store);
    }
    if (existing.isFailure) {
      return FailureResult<Store, Failure>(existing.failureOrNull!);
    }
    return repository.updateStore(store);
  }

  ValidationFailure? _validate(Store store) {
    if (store.name.trim().isEmpty) {
      return const ValidationFailure('El nombre del comercio es obligatorio');
    }
    if (store.address.trim().isEmpty) {
      return const ValidationFailure(
        'La dirección del comercio es obligatoria',
      );
    }
    if (store.latitude != null &&
        (store.latitude! < -90 || store.latitude! > 90)) {
      return const ValidationFailure('La latitud debe estar entre -90 y 90');
    }
    if (store.longitude != null &&
        (store.longitude! < -180 || store.longitude! > 180)) {
      return const ValidationFailure('La longitud debe estar entre -180 y 180');
    }
    return null;
  }
}
