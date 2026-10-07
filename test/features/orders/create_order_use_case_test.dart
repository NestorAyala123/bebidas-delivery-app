import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart.dart';
import 'package:bebidas_delivery_app/features/cart/domain/entities/cart_item.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/create_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/domain/repositories/order_repository.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  group('CreateOrderUseCase', () {
    test('creates an order with immutable historical item prices', () async {
      final repository = _FakeOrderRepository();
      final createdAt = DateTime(2026, 10, 4);
      final useCase = CreateOrderUseCase(
        repository: repository,
        generateOrderId: () => 'order-1',
        now: () => createdAt,
      );
      const cart = Cart(
        storeId: 'store-1',
        items: [
          CartItem(
            productId: 'product-1',
            productName: 'Bebida',
            unitPrice: 2.5,
            quantity: 3,
            isReturnable: true,
            containerDeposit: 0.5,
          ),
        ],
      );

      final result = await useCase(
        const CreateOrderInput(
          customerId: 'customer-1',
          deliveryAddress: 'Manta',
          cart: cart,
          missingContainersFee: 1.25,
        ),
      );
      final order = result.dataOrNull!;

      expect(repository.savedOrder, same(order));
      expect(order.status, OrderStatus.created);
      expect(order.createdAt, createdAt);
      expect(order.items.single.frozenUnitPrice, 2.5);
      expect(order.items.single.containerDepositPrice, 0.5);
      expect(order.itemsSubtotal, 7.5);
      expect(order.total, 8.75);
    });

    test('rejects an empty cart without calling the repository', () async {
      final repository = _FakeOrderRepository();
      final useCase = CreateOrderUseCase(
        repository: repository,
        generateOrderId: () => 'order-1',
      );

      final result = await useCase(
        const CreateOrderInput(
          customerId: 'customer-1',
          deliveryAddress: 'Manta',
          cart: Cart(),
        ),
      );

      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.savedOrder, isNull);
    });
  });
}

class _FakeOrderRepository implements OrderRepository {
  Order? savedOrder;

  @override
  Future<Result<Order, Failure>> createOrder(Order order) async {
    savedOrder = order;
    return Success(order);
  }

  @override
  Future<Result<Order, Failure>> confirmOrder({
    required String orderId,
    required String storeId,
  }) => throw UnimplementedError();

  @override
  Future<Result<Order, Failure>> rejectOrder({
    required String orderId,
    required String storeId,
    required String reason,
  }) => throw UnimplementedError();

  @override
  Future<Result<Order, Failure>> getOrderById(String orderId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Order>, Failure>> getOrdersByCustomer(String customerId) =>
      throw UnimplementedError();

  @override
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId) =>
      throw UnimplementedError();
}
