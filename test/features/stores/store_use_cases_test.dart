import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/stores/application/use_cases/save_store_use_case.dart';
import 'package:bebidas_delivery_app/features/stores/application/use_cases/update_store_status_use_case.dart';
import 'package:bebidas_delivery_app/features/stores/domain/entities/store.dart';
import 'package:bebidas_delivery_app/features/stores/infrastructure/repositories/in_memory_store_repository.dart';

void main() {
  late InMemoryStoreRepository repository;
  late SaveStoreUseCase saveStore;

  setUp(() {
    repository = InMemoryStoreRepository();
    saveStore = SaveStoreUseCase(repository);
  });

  test('registers and edits a store with delivery modes', () async {
    final created = await saveStore(
      const Store(
        id: 'store-1',
        name: 'La Esquina',
        address: 'Av. Central',
        isOpen: true,
        openingHours: {'monday': '09:00-22:00', 'saturday': '10:00-20:00'},
        hasOwnDelivery: true,
        allowsExternalDelivery: false,
        allowsPickup: true,
      ),
    );

    expect(created, isA<Success<Store, Failure>>());
    expect(created.dataOrNull?.openingHours['monday'], '09:00-22:00');
    expect(created.dataOrNull?.openingHours['saturday'], '10:00-20:00');

    final edited = await saveStore(
      const Store(
        id: 'store-1',
        name: 'La Esquina Express',
        address: 'Av. Central',
        isOpen: false,
        hasOwnDelivery: true,
        allowsExternalDelivery: true,
        allowsPickup: false,
      ),
    );
    expect(edited.dataOrNull?.name, 'La Esquina Express');
    expect(edited.dataOrNull?.allowsExternalDelivery, isTrue);
  });

  test('rejects invalid coordinates', () async {
    final result = await saveStore(
      const Store(
        id: 'store-1',
        name: 'La Esquina',
        address: 'Av. Central',
        isOpen: true,
        latitude: 91,
      ),
    );

    expect(result.isFailure, isTrue);
  });

  test('changes the open status', () async {
    await saveStore(
      const Store(
        id: 'store-1',
        name: 'La Esquina',
        address: 'Av. Central',
        isOpen: true,
      ),
    );

    final result = await UpdateStoreStatusUseCase(repository)(
      storeId: 'store-1',
      isOpen: false,
    );
    final store = await repository.getStoreById('store-1');

    expect(result.isSuccess, isTrue);
    expect(store.dataOrNull?.isOpen, isFalse);
  });
}
