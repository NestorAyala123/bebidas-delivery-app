import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/returnable_containers/domain/entities/returnable_container.dart';

void main() {
  test('Stores the returnable container catalog configuration', () {
    const container = ReturnableContainer(
      id: 'container-1',
      productId: 'prod-1',
      isReturnable: true,
      depositPrice: 3,
    );

    expect(container.productId, 'prod-1');
    expect(container.isReturnable, isTrue);
    expect(container.depositPrice, 3);
  });
}
