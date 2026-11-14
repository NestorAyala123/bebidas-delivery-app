import 'package:flutter/material.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../controllers/order_flow_controller.dart';
import '../order_flow_factory.dart';
import 'pedido_estado_page.dart';

/// Historial de pedidos del cliente con su estado actual.
class MisPedidosPage extends StatefulWidget {
  final OrderFlowController? controller;

  const MisPedidosPage({super.key, this.controller});

  @override
  State<MisPedidosPage> createState() => _MisPedidosPageState();
}

class _MisPedidosPageState extends State<MisPedidosPage> {
  late final OrderFlowController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? buildOrderFlowController();
    _controller.addListener(_onUpdate);
    _controller.loadOrders('customer-demo');
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    if (_ownsController) _controller.dispose();
    super.dispose();
  }

  Future<void> _open(Order order) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => PedidoEstadoPage(
          orderId: order.id,
          controller: _controller,
        ),
      ),
    );
    if (mounted) {
      _controller.loadOrders('customer-demo');
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mis pedidos'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: _controller.isLoading && _controller.orders.isEmpty
          ? const Center(child: CircularProgressIndicator())
          : _controller.orders.isEmpty
              ? Center(
                  child: Text(
                    _controller.errorMessage ?? 'Todavía no tienes pedidos',
                  ),
                )
              : RefreshIndicator(
                  onRefresh: () => _controller.loadOrders('customer-demo'),
                  child: ListView.builder(
                    padding: const EdgeInsets.all(12),
                    itemCount: _controller.orders.length,
                    itemBuilder: (context, index) {
                      final order = _controller.orders[index];
                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          onTap: () => _open(order),
                          title: Text(
                            'Pedido ${order.id}',
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          subtitle: Padding(
                            padding: const EdgeInsets.only(top: 4),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  '${_modeLabel(order)} · '
                                  '${order.isPaymentRegistered ? order.paymentMethod!.label : 'Pago pendiente'}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                                Text(
                                  'Total: \$${order.total.toStringAsFixed(2)}',
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                            ),
                          ),
                          trailing: _StatusChip(status: order.status),
                        ),
                      );
                    },
                  ),
                ),
    );
  }

  static String _modeLabel(Order order) {
    if (order.isPickup) return 'Retiro en local';
    if (order.deliveryMode.isOwnDelivery) return 'Delivery del comercio';
    return 'Repartidor externo';
  }
}

class _StatusChip extends StatelessWidget {
  final OrderStatus status;

  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final label = switch (status) {
      OrderStatus.created => 'Creado',
      OrderStatus.confirmed => 'Confirmado',
      OrderStatus.rejected => 'Rechazado',
      OrderStatus.lookingForDriver => 'Buscando repartidor',
      OrderStatus.driverAssigned => 'Repartidor asignado',
      OrderStatus.inDelivery => 'En camino',
      OrderStatus.delivered => 'Entregado',
      OrderStatus.cancelled => 'Cancelado',
    };

    final color = switch (status) {
      OrderStatus.delivered => Colors.green,
      OrderStatus.cancelled || OrderStatus.rejected => Colors.red,
      OrderStatus.lookingForDriver => Colors.orange,
      _ => Theme.of(context).colorScheme.primary,
    };

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withAlpha(30),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withAlpha(120)),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
}
