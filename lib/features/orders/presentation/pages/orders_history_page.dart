import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/user_session.dart';
import '../../application/use_cases/get_customer_orders_use_case.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';

/// Screen displaying the customer's initial order history, showing pending status
/// and immutable frozen historical prices (RN08).
class OrdersHistoryPage extends StatefulWidget {
  final UserSession session;
  final GetCustomerOrdersUseCase? getCustomerOrdersUseCase;

  const OrdersHistoryPage({
    super.key,
    required this.session,
    this.getCustomerOrdersUseCase,
  });

  @override
  State<OrdersHistoryPage> createState() => _OrdersHistoryPageState();
}

class _OrdersHistoryPageState extends State<OrdersHistoryPage> {
  bool _isLoading = true;
  List<Order> _orders = [];
  String? _error;

  GetCustomerOrdersUseCase get _useCase =>
      widget.getCustomerOrdersUseCase ??
      (sl.isRegistered<GetCustomerOrdersUseCase>()
          ? sl.get<GetCustomerOrdersUseCase>()
          : throw Exception('GetCustomerOrdersUseCase no registrado'));

  @override
  void initState() {
    super.initState();
    _fetchOrders();
  }

  Future<void> _fetchOrders() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    final res = await _useCase(widget.session.userId);

    if (!mounted) return;

    switch (res) {
      case Success(:final data):
        setState(() {
          _orders = data;
          _isLoading = false;
        });
      case FailureResult(:final failure):
        setState(() {
          _error = failure.message;
          _isLoading = false;
        });
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Historial de Pedidos'),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Actualizar',
            onPressed: _fetchOrders,
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Icon(Icons.error_outline, size: 48, color: Colors.red),
                        const SizedBox(height: 12),
                        Text(_error!, textAlign: TextAlign.center),
                        const SizedBox(height: 12),
                        FilledButton(
                          onPressed: _fetchOrders,
                          child: const Text('Reintentar'),
                        ),
                      ],
                    ),
                  ),
                )
              : _orders.isEmpty
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.all(24.0),
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.receipt_long_outlined, size: 72, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            Text(
                              'Aún no tienes pedidos registrados',
                              style: theme.textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 8),
                            const Text(
                              'Crea tu primer pedido desde el resumen para verlo reflejado en este historial.',
                              textAlign: TextAlign.center,
                              style: TextStyle(color: Colors.grey),
                            ),
                          ],
                        ),
                      ),
                    )
                  : ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _orders.length,
                      itemBuilder: (context, index) {
                        final order = _orders[index];
                        return _buildOrderCard(order);
                      },
                    ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final statusColor = _statusColor(order.status);
    final statusIcon = _statusIcon(order.status);

    return Card(
      elevation: 2,
      margin: const EdgeInsets.only(bottom: 16),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Order ID and Status
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    const Icon(Icons.receipt, size: 20, color: Colors.grey),
                    const SizedBox(width: 8),
                    Text(
                      'Pedido #${order.id}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                  ],
                ),
                Chip(
                  avatar: Icon(statusIcon, size: 14, color: Colors.white),
                  label: Text(
                    order.status.displayName,
                    style: const TextStyle(
                      color: Colors.white,
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                    ),
                  ),
                  backgroundColor: statusColor,
                  visualDensity: VisualDensity.compact,
                  padding: EdgeInsets.zero,
                ),
              ],
            ),
            const SizedBox(height: 6),
            Text(
              'Fecha: ${_formatDate(order.createdAt)}',
              style: const TextStyle(color: Colors.grey, fontSize: 12),
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                const Icon(Icons.store, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Text('Comercio: ${order.storeId}', style: const TextStyle(fontSize: 13)),
              ],
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 16, color: Colors.grey),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    'Entrega: ${order.deliveryAddress}',
                    style: const TextStyle(fontSize: 13),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const Divider(height: 20),

            // Order Items with Frozen Unit Prices
            const Text(
              'Artículos (Precios Históricos Congelados):',
              style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
            ),
            const SizedBox(height: 6),
            ...order.items.map((item) => Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                        decoration: BoxDecoration(
                          color: Colors.grey.shade200,
                          borderRadius: BorderRadius.circular(4),
                        ),
                        child: Text(
                          '${item.quantity}x',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              item.productName,
                              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                            ),
                            Text(
                              'Precio congelado: \$${item.frozenUnitPrice.toStringAsFixed(2)} c/u'
                              '${item.isReturnable ? ' (Retornable)' : ''}',
                              style: TextStyle(fontSize: 11, color: Colors.blueGrey.shade700),
                            ),
                          ],
                        ),
                      ),
                      Text(
                        '\$${item.subtotal.toStringAsFixed(2)}',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                )),

            if (order.missingContainersFee > 0) ...[
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Cargo por envases faltantes:',
                    style: TextStyle(color: Colors.deepOrange, fontSize: 13),
                  ),
                  Text(
                    '+\$${order.missingContainersFee.toStringAsFixed(2)}',
                    style: const TextStyle(
                      color: Colors.deepOrange,
                      fontWeight: FontWeight.bold,
                      fontSize: 13,
                    ),
                  ),
                ],
              ),
            ],

            const Divider(height: 20),

            // Total
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Inalterable:',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '\$${order.total.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 18,
                    color: Colors.blueAccent,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Color _statusColor(OrderStatus status) => switch (status) {
        OrderStatus.created => Colors.orange.shade800,
        OrderStatus.confirmed => Colors.teal.shade700,
        OrderStatus.rejected => Colors.red.shade700,
        OrderStatus.lookingForDriver => Colors.purple.shade700,
        OrderStatus.driverAssigned => Colors.indigo.shade700,
        OrderStatus.inDelivery => Colors.blue.shade700,
        OrderStatus.delivered => Colors.green.shade700,
        OrderStatus.cancelled => Colors.grey.shade700,
      };

  IconData _statusIcon(OrderStatus status) => switch (status) {
        OrderStatus.created => Icons.hourglass_top,
        OrderStatus.confirmed => Icons.check_circle_outline,
        OrderStatus.rejected => Icons.cancel_outlined,
        OrderStatus.lookingForDriver => Icons.search,
        OrderStatus.driverAssigned => Icons.two_wheeler,
        OrderStatus.inDelivery => Icons.local_shipping,
        OrderStatus.delivered => Icons.done_all,
        OrderStatus.cancelled => Icons.block,
      };

  String _formatDate(DateTime dt) {
    return '${dt.day.toString().padLeft(2, '0')}/${dt.month.toString().padLeft(2, '0')}/${dt.year} '
        '${dt.hour.toString().padLeft(2, '0')}:${dt.minute.toString().padLeft(2, '0')}';
  }
}
