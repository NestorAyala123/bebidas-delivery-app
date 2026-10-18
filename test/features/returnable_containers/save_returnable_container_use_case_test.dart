import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/returnable_containers/application/use_cases/save_returnable_container_use_case.dart';
import 'package:bebidas_delivery_app/features/returnable_containers/domain/entities/returnable_container.dart';
import 'package:bebidas_delivery_app/features/returnable_containers/infrastructure/repositories/in_memory_returnable_container_repository.dart';

void main() {
  test('saves a returnable container configuration', () async {
    final repository = InMemoryReturnableContainerRepository();
    final result = await SaveReturnableContainerUseCase(repository)(
      storeId: 'store-1',
      container: const ReturnableContainer(
        id: 'container-1',
        productId: 'product-1',
        isReturnable: true,
        depositPrice: 3,
      ),
    );

    final saved = await repository.getByProduct('store-1', 'product-1');
    expect(result.isSuccess, isTrue);
    expect(saved.dataOrNull?.depositPrice, 3);
  });

  test('requires a deposit for returnable containers', () async {
    final result =
        await SaveReturnableContainerUseCase(
          InMemoryReturnableContainerRepository(),
        )(
          storeId: 'store-1',
          container: const ReturnableContainer(
            id: 'container-1',
            productId: 'product-1',
            isReturnable: true,
            depositPrice: 0,
          ),
        );

    expect(result.isFailure, isTrue);
  });
}
