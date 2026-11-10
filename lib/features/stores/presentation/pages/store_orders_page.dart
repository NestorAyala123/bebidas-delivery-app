import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../../core/errors/failures.dart';
import '../../../orders/domain/entities/order.dart';
import '../../../orders/domain/entities/order_status.dart';
import '../../../orders/domain/repositories/order_repository.dart';
import '../../domain/entities/store.dart';
import '../../domain/repositories/store_repository.dart';

class StoreOrdersPage extends StatefulWidget {
  const StoreOrdersPage({super.key});

  @override
  State<StoreOrdersPage> createState() => _StoreOrdersPageState();
}

class _StoreOrdersPageState extends State<StoreOrdersPage> {
  final _storeRepository = sl.get<StoreRepository>();
  final _orderRepository = sl.get<OrderRepository>();

  List<Store> _stores = [];
  List<Order> _orders = [];
  Store? _selectedStore;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadStores();
  }

  Future<void> _loadStores() async {
    final result = await _storeRepository.getStores();

    if (!mounted) return;

    result.fold(
      onSuccess: (stores) {
        setState(() {
          _stores = stores;
          _selectedStore ??= stores.isEmpty ? null : stores.first;
        });

        _loadOrders();
      },
      onFailure: (failure) {
        setState(() => _loading = false);
        _showFailure(failure);
      },
    );
  }

  Future<void> _loadOrders() async {
    final store = _selectedStore;

    if (store == null) {
      if (!mounted) return;

      setState(() {
        _orders = [];
        _loading = false;
      });
      return;
    }

    setState(() => _loading = true);

    final result = await _orderRepository.getOrdersByStore(store.id);

    if (!mounted) return;

    result.fold(
      onSuccess: (orders) {
        setState(() {
          _orders = orders;
          _loading = false;
        });
      },
      onFailure: (failure) {
        setState(() => _loading = false);
        _showFailure(failure);
      },
    );
  }

  Future<void> _confirmOrder(Order order) async {
    final store = _selectedStore;
    if (store == null) return;

    final result = await _orderRepository.confirmOrder(
      orderId: order.id,
      storeId: store.id,
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        _showMessage('Pedido confirmado');
        _loadOrders();
      },
      onFailure: _showFailure,
    );
  }

  Future<void> _rejectOrder(Order order) async {
    final store = _selectedStore;
    if (store == null) return;

    final controller = TextEditingController();

    final reason = await showDialog<String>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Rechazar pedido'),
          content: TextField(
            controller: controller,
            autofocus: true,
            maxLines: 3,
            decoration: const InputDecoration(
              labelText: 'Motivo del rechazo',
              hintText: 'Indique por qué se rechaza el pedido',
              border: OutlineInputBorder(),
            ),
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () {
                final value = controller.text.trim();

                if (value.isEmpty) return;

                Navigator.pop(dialogContext, value);
              },
              child: const Text('Rechazar pedido'),
            ),
          ],
        );
      },
    );

    controller.dispose();

    if (reason == null || !mounted) return;

    final result = await _orderRepository.rejectOrder(
      orderId: order.id,
      storeId: store.id,
      reason: reason,
    );

    if (!mounted) return;

    result.fold(
      onSuccess: (_) {
        _showMessage('Pedido rechazado');
        _loadOrders();
      },
      onFailure: _showFailure,
    );
  }

  void _showFailure(Failure failure) {
    _showMessage(failure.message);
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Pedidos del comercio')),
      body: RefreshIndicator(
        onRefresh: _loadOrders,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            DropdownButtonFormField<Store>(
              initialValue: _selectedStore,
              decoration: const InputDecoration(
                labelText: 'Comercio',
                border: OutlineInputBorder(),
              ),
              items: _stores
                  .map(
                    (store) => DropdownMenuItem<Store>(
                      value: store,
                      child: Text(store.name),
                    ),
                  )
                  .toList(),
              onChanged: (store) {
                setState(() => _selectedStore = store);
                _loadOrders();
              },
            ),
            const SizedBox(height: 16),
            if (_loading)
              const Center(child: CircularProgressIndicator())
            else if (_orders.isEmpty)
              const Card(
                child: Padding(
                  padding: EdgeInsets.all(24),
                  child: Center(
                    child: Text('No hay pedidos para este comercio.'),
                  ),
                ),
              )
            else
              ..._orders.map(_buildOrderCard),
          ],
        ),
      ),
    );
  }

  Widget _buildOrderCard(Order order) {
    final isPending = order.status == OrderStatus.created;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Pedido ${order.id}',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text('Cliente: ${order.customerId}'),
            Text('Dirección: ${order.deliveryAddress}'),
            Text('Total: \$${order.total.toStringAsFixed(2)}'),
            Text('Estado: ${_statusLabel(order.status)}'),
            const SizedBox(height: 8),
            ...order.items.map(
              (item) => Text('${item.quantity} x ${item.productName}'),
            ),
            if (isPending) ...[
              const SizedBox(height: 12),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () => _rejectOrder(order),
                      child: const Text('Rechazar'),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FilledButton(
                      onPressed: () => _confirmOrder(order),
                      child: const Text('Confirmar'),
                    ),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _statusLabel(OrderStatus status) => switch (status) {
    OrderStatus.created => 'Pendiente',
    OrderStatus.confirmed => 'Confirmado',
    OrderStatus.rejected => 'Rechazado',
    OrderStatus.preparing => 'En preparación',
    OrderStatus.readyForPickup => 'Listo para retirar',
    OrderStatus.pickedUp => 'Retirado',
    OrderStatus.readyForDelivery => 'Listo para entrega',
    OrderStatus.lookingForDriver => 'Buscando repartidor',
    OrderStatus.driverAssigned => 'Repartidor asignado',
    OrderStatus.inDelivery => 'En entrega',
    OrderStatus.delivered => 'Entregado',
    OrderStatus.cancelled => 'Cancelado',
  };
}
