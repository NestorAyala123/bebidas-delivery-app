import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../chat/presentation/widgets/chat_inbox_button.dart';
import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../../auth/domain/entities/user_session.dart';
import '../../application/use_cases/confirm_order_use_case.dart';
import '../../application/use_cases/get_store_orders_use_case.dart';
import '../../application/use_cases/reject_order_use_case.dart';
import '../../application/use_cases/update_order_status_use_case.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/order_delivery_method.dart';
import '../../domain/entities/order_status.dart';

class StoreOrdersPage extends StatefulWidget {
  final UserSession session;
  final GetStoreOrdersUseCase? getStoreOrdersUseCase;
  final ConfirmOrderUseCase? confirmOrderUseCase;
  final RejectOrderUseCase? rejectOrderUseCase;
  final UpdateOrderStatusUseCase? updateOrderStatusUseCase;

  const StoreOrdersPage({
    super.key,
    required this.session,
    this.getStoreOrdersUseCase,
    this.confirmOrderUseCase,
    this.rejectOrderUseCase,
    this.updateOrderStatusUseCase,
  });

  @override
  State<StoreOrdersPage> createState() => _StoreOrdersPageState();
}

class _StoreOrdersPageState extends State<StoreOrdersPage> {
  bool _loading = true;
  List<Order> _orders = [];
  String? _error;
  String? _workingOrderId;

  GetStoreOrdersUseCase get _getOrders =>
      widget.getStoreOrdersUseCase ?? sl.get<GetStoreOrdersUseCase>();
  ConfirmOrderUseCase get _confirmOrder =>
      widget.confirmOrderUseCase ?? sl.get<ConfirmOrderUseCase>();
  RejectOrderUseCase get _rejectOrder =>
      widget.rejectOrderUseCase ?? sl.get<RejectOrderUseCase>();
  UpdateOrderStatusUseCase get _updateStatus =>
      widget.updateOrderStatusUseCase ?? sl.get<UpdateOrderStatusUseCase>();

  @override
  void initState() {
    super.initState();
    _loadOrders();
  }

  Future<void> _loadOrders() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    final result = await _getOrders(widget.session.userId);
    if (!mounted) return;
    switch (result) {
      case Success(:final data):
        setState(() {
          _orders = data;
          _loading = false;
        });
      case FailureResult(:final failure):
        setState(() {
          _error = failure.message;
          _loading = false;
        });
    }
  }

  Future<void> _reject(Order order) async {
    final reasonController = TextEditingController();
    final reason = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Rechazar pedido'),
        content: TextField(
          controller: reasonController,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Motivo del rechazo',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () =>
                Navigator.pop(context, reasonController.text.trim()),
            child: const Text('Rechazar'),
          ),
        ],
      ),
    );
    reasonController.dispose();
    if (reason == null || !mounted) return;
    if (reason.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Indica el motivo del rechazo.')),
      );
      return;
    }

    await _runAction(
      order.id,
      () => _rejectOrder(
        RejectOrderInput(
          orderId: order.id,
          storeId: widget.session.userId,
          reason: reason,
        ),
      ),
    );
  }

  Future<void> _confirm(Order order) => _runAction(
    order.id,
    () => _confirmOrder(
      ConfirmOrderInput(orderId: order.id, storeId: widget.session.userId),
    ),
  );

  Future<void> _advance(Order order, OrderStatus status) => _runAction(
    order.id,
    () => _updateStatus(
      UpdateOrderStatusInput(
        orderId: order.id,
        storeId: widget.session.userId,
        status: status,
      ),
    ),
  );

  Future<void> _runAction(
    String orderId,
    Future<Result<Order, Failure>> Function() action,
  ) async {
    setState(() => _workingOrderId = orderId);
    final result = await action();
    if (!mounted) return;
    setState(() => _workingOrderId = null);
    switch (result) {
      case Success():
        await _loadOrders();
      case FailureResult(:final failure):
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(failure.message)));
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!widget.session.user.isStore) {
      return Scaffold(
        appBar: AppBar(title: const Text('Pedidos del comercio')),
        body: const Center(
          child: Text('Esta pantalla es solo para comercios.'),
        ),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: const Text('Pedidos del comercio'),
        actions: [
          // Acceso al chat desde el comercio (módulo chat).
          const ChatInboxButton(),
          IconButton(
            tooltip: 'Actualizar',
            onPressed: _loading ? null : _loadOrders,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
          ? Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(_error!),
                  const SizedBox(height: 8),
                  FilledButton(
                    onPressed: _loadOrders,
                    child: const Text('Reintentar'),
                  ),
                ],
              ),
            )
          : _orders.isEmpty
          ? const Center(child: Text('No hay pedidos para este comercio.'))
          : ListView.builder(
              padding: const EdgeInsets.all(16),
              itemCount: _orders.length,
              itemBuilder: (context, index) => _orderCard(_orders[index]),
            ),
    );
  }

  Widget _orderCard(Order order) {
    final busy = _workingOrderId == order.id;
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Pedido #${order.id}',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 4),
            Text('Estado: ${order.status.displayName}'),
            Text('Modalidad: ${_methodLabel(order.deliveryMethod)}'),
            Text('Cliente: ${order.customerId}'),
            Text('Dirección: ${order.deliveryAddress}'),
            Text('Total: \$${order.total.toStringAsFixed(2)}'),
            const Divider(),
            ...order.items.map(
              (item) => Text(
                '${item.quantity} × ${item.productName} '
                '(\$${item.frozenUnitPrice.toStringAsFixed(2)})',
              ),
            ),
            const SizedBox(height: 12),
            if (busy)
              const Center(child: CircularProgressIndicator())
            else
              Wrap(spacing: 8, runSpacing: 4, children: _actions(order)),
          ],
        ),
      ),
    );
  }

  List<Widget> _actions(Order order) => switch (order.status) {
    OrderStatus.created => [
      FilledButton(
        onPressed: () => _confirm(order),
        child: const Text('Aceptar pedido'),
      ),
      OutlinedButton(
        onPressed: () => _reject(order),
        child: const Text('Rechazar'),
      ),
    ],
    OrderStatus.confirmed => [
      FilledButton(
        onPressed: () => _advance(order, OrderStatus.preparing),
        child: const Text('Iniciar preparación'),
      ),
    ],
    OrderStatus.preparing => switch (order.deliveryMethod) {
      OrderDeliveryMethod.pickup => [
        FilledButton(
          onPressed: () => _advance(order, OrderStatus.readyForPickup),
          child: const Text('Listo para retirar'),
        ),
      ],
      OrderDeliveryMethod.storeDelivery => [
        FilledButton(
          onPressed: () => _advance(order, OrderStatus.readyForDelivery),
          child: const Text('Listo para entrega'),
        ),
      ],
      OrderDeliveryMethod.externalDelivery => [
        const Chip(label: Text('Despacho externo tras confirmación')),
      ],
    },
    OrderStatus.readyForPickup => [
      FilledButton(
        onPressed: () => _advance(order, OrderStatus.pickedUp),
        child: const Text('Registrar retiro'),
      ),
    ],
    OrderStatus.pickedUp => [
      FilledButton(
        onPressed: () => _advance(order, OrderStatus.delivered),
        child: const Text('Finalizar pedido'),
      ),
    ],
    OrderStatus.readyForDelivery => [
      FilledButton(
        onPressed: () => _advance(order, OrderStatus.inDelivery),
        child: const Text('Iniciar entrega'),
      ),
    ],
    OrderStatus.inDelivery
        when order.deliveryMethod == OrderDeliveryMethod.storeDelivery =>
      [
        FilledButton(
          onPressed: () => _advance(order, OrderStatus.delivered),
          child: const Text('Marcar entregado'),
        ),
      ],
    _ => const [],
  };

  String _methodLabel(OrderDeliveryMethod method) => switch (method) {
    OrderDeliveryMethod.pickup => 'Retiro en el local',
    OrderDeliveryMethod.storeDelivery => 'Delivery propio',
    OrderDeliveryMethod.externalDelivery => 'Repartidor externo',
  };
}
