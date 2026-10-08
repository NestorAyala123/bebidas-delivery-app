import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/core/errors/failures.dart';
import 'package:bebidas_delivery_app/core/result/result.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/confirm_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/application/use_cases/reject_order_use_case.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_item.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';
import 'package:bebidas_delivery_app/features/orders/domain/repositories/order_repository.dart';

void main() {
  late _MockOrderRepository repository;
  late ConfirmOrderUseCase confirmUseCase;
  late RejectOrderUseCase rejectUseCase;

  setUp(() {
    repository = _MockOrderRepository();
    confirmUseCase = ConfirmOrderUseCase(repository);
    rejectUseCase = RejectOrderUseCase(repository);
  });

  group('ConfirmOrderUseCase', () {
    test('confirms order successfully when inputs are valid', () async {
      final result = await confirmUseCase(
        const ConfirmOrderInput(orderId: 'ord-123', storeId: 'store-abc'),
      );

      expect(result.isSuccess, isTrue);
      final confirmed = result.dataOrNull!;
      expect(confirmed.status, equals(OrderStatus.confirmed));
      expect(confirmed.confirmedAt, isNotNull);
      expect(confirmed.canRequestDriver, isTrue);
      expect(repository.lastConfirmedOrderId, equals('ord-123'));
      expect(repository.lastConfirmedStoreId, equals('store-abc'));
    });

    test('fails with ValidationFailure when orderId is empty', () async {
      final result = await confirmUseCase(
        const ConfirmOrderInput(orderId: '   ', storeId: 'store-abc'),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });

    test('fails with ValidationFailure when storeId is empty', () async {
      final result = await confirmUseCase(
        const ConfirmOrderInput(orderId: 'ord-123', storeId: ''),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
    });
  });

  group('RejectOrderUseCase', () {
    test(
      'rejects order successfully when inputs and reason are valid',
      () async {
        final result = await rejectUseCase(
          const RejectOrderInput(
            orderId: 'ord-123',
            storeId: 'store-abc',
            reason: 'Sin inventario de cerveza',
          ),
        );

        expect(result.isSuccess, isTrue);
        final rejected = result.dataOrNull!;
        expect(rejected.status, equals(OrderStatus.rejected));
        expect(rejected.rejectionReason, equals('Sin inventario de cerveza'));
        expect(repository.lastRejectedOrderId, equals('ord-123'));
        expect(
          repository.lastRejectedReason,
          equals('Sin inventario de cerveza'),
        );
      },
    );

    test('fails with ValidationFailure when reason is empty', () async {
      final result = await rejectUseCase(
        const RejectOrderInput(
          orderId: 'ord-123',
          storeId: 'store-abc',
          reason: '   ',
        ),
      );

      expect(result.isFailure, isTrue);
      expect(result.failureOrNull, isA<ValidationFailure>());
      expect(repository.lastRejectedOrderId, isNull);
    });

    test(
      'fails with ValidationFailure when orderId or storeId is blank',
      () async {
        final result = await rejectUseCase(
          const RejectOrderInput(
            orderId: '',
            storeId: 'store-abc',
            reason: 'Cerrado por hoy',
          ),
        );

        expect(result.isFailure, isTrue);
        expect(result.failureOrNull, isA<ValidationFailure>());
      },
    );
  });
}

class _MockOrderRepository implements OrderRepository {
  String? lastConfirmedOrderId;
  String? lastConfirmedStoreId;
  String? lastRejectedOrderId;
  String? lastRejectedReason;

  Order _buildBaseOrder(String orderId, String storeId) {
    return Order(
      id: orderId,
      customerId: 'cust-1',
      storeId: storeId,
      status: OrderStatus.created,
      deliveryAddress: 'Av. Flavio Reyes',
      createdAt: DateTime.now(),
      items: const [
        OrderItem(
          productId: 'prod-1',
          productName: 'Pilsener 600ml',
          frozenUnitPrice: 2.0,
          quantity: 2,
        ),
      ],
    );
  }

  @override
  Future<Result<Order, Failure>> confirmOrder({
    required String orderId,
    required String storeId,
  }) async {
    lastConfirmedOrderId = orderId;
    lastConfirmedStoreId = storeId;
    final order = _buildBaseOrder(orderId, storeId);
    final confirmed = order.copyWithStatus(
      OrderStatus.confirmed,
      confirmedAt: DateTime.now(),
    );
    return Success(confirmed);
  }

  @override
  Future<Result<Order, Failure>> rejectOrder({
    required String orderId,
    required String storeId,
    required String reason,
  }) async {
    lastRejectedOrderId = orderId;
    lastRejectedReason = reason;
    final order = _buildBaseOrder(orderId, storeId);
    final rejected = order.copyWithStatus(
      OrderStatus.rejected,
      rejectionReason: reason,
    );
    return Success(rejected);
  }

  @override
  Future<Result<Order, Failure>> createOrder(Order order) =>
      throw UnimplementedError();

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
