import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_item.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/entities/payment_method.dart';
import '../../domain/repositories/order_repository.dart';
import '../../../delivery/domain/entities/delivery_mode.dart';

/// Repositorio en memoria de pedidos con datos de demostración de la Semana 5.
class InMemoryOrderRepository implements OrderRepository {
  final List<Order> _orders;

  InMemoryOrderRepository({List<Order>? initialOrders})
      : _orders = initialOrders ?? _seedOrders();

  static List<Order> _seedOrders() {
    final base = DateTime(2026, 11, 15, 9);
    const items = [
      OrderItem(
        productId: 'prod-1',
        productName: 'Cerveza Pilsen 330 ml',
        frozenUnitPrice: 2.50,
        quantity: 6,
      ),
      OrderItem(
        productId: 'prod-2',
        productName: 'Vino tinto Reserva',
        frozenUnitPrice: 18.00,
        quantity: 1,
      ),
    ];

    return [
      Order(
        id: 'ord-demo-01',
        customerId: 'customer-demo',
        storeId: 'store-001',
        items: items,
        status: OrderStatus.confirmed,
        deliveryAddress: 'Av. Malecón Jaime Chávez, Manta',
        deliveryMode: DeliveryMode.externalDriver,
        deliveryFee: 3.50,
        createdAt: base,
        confirmedAt: base.add(const Duration(minutes: 3)),
      ),
      Order(
        id: 'ord-demo-02',
        customerId: 'customer-demo',
        storeId: 'store-001',
        items: items,
        status: OrderStatus.delivered,
        deliveryAddress: 'Barrio Santa Martha, Manta',
        deliveryMode: DeliveryMode.pickupAtStore,
        paymentMethod: PaymentMethod.cash,
        deliveryFee: 0,
        createdAt: base.subtract(const Duration(days: 3)),
        confirmedAt: base.subtract(const Duration(days: 3)),
      ),
      Order(
        id: 'ord-demo-03',
        customerId: 'customer-demo',
        storeId: 'store-002',
        items: items,
        status: OrderStatus.lookingForDriver,
        deliveryAddress: 'Av. Flavio Reyes, Manta',
        deliveryMode: DeliveryMode.externalDriver,
        paymentMethod: PaymentMethod.transfer,
        deliveryFee: 2.00,
        createdAt: base.add(const Duration(hours: 1)),
        confirmedAt: base.add(const Duration(hours: 1)),
      ),
      Order(
        id: 'ord-demo-04',
        customerId: 'customer-demo',
        storeId: 'store-001',
        items: items,
        status: OrderStatus.created,
        deliveryAddress: 'Calle 13 y Av. 24, Manta',
        deliveryMode: DeliveryMode.externalDriver,
        createdAt: base.add(const Duration(hours: 2)),
      ),
    ];
  }

  @override
  Future<Result<Order, Failure>> createOrder(Order order) async {
    final index = _orders.indexWhere((o) => o.id == order.id);
    if (index >= 0) {
      _orders[index] = order;
    } else {
      _orders.add(order);
    }
    return Success(order);
  }

  @override
  Future<Result<Order, Failure>> getOrderById(String orderId) async {
    for (final order in _orders) {
      if (order.id == orderId) return Success(order);
    }
    return FailureResult(
      NotFoundFailure('No se encontró el pedido $orderId'),
    );
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByCustomer(
    String customerId,
  ) async {
    final found = _orders.where((o) => o.customerId == customerId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(found);
  }

  @override
  Future<Result<List<Order>, Failure>> getOrdersByStore(String storeId) async {
    final found = _orders.where((o) => o.storeId == storeId).toList()
      ..sort((a, b) => b.createdAt.compareTo(a.createdAt));
    return Success(found);
  }

  @override
  Future<Result<void, Failure>> updateOrderStatus(
    String orderId,
    OrderStatus status,
  ) async {
    final index = _orders.indexWhere((o) => o.id == orderId);
    if (index < 0) {
      return FailureResult(
        NotFoundFailure('No se encontró el pedido $orderId'),
      );
    }

    _orders[index] = _orders[index].copyWithStatus(status);
    return const Success(null);
  }
}
