import 'package:flutter/material.dart';

import '../../domain/entities/order.dart';
import '../../domain/entities/order_status.dart';
import '../../domain/services/order_flow_service.dart';
import '../controllers/order_flow_controller.dart';
import '../order_flow_factory.dart';
import 'checkout_page.dart';

/// Estado del pedido, alternativas sin repartidores (RN03) y acceso al
/// checkout de modalidad/pago.
class PedidoEstadoPage extends StatefulWidget {
  final String orderId;
  final OrderFlowController? controller;

  const PedidoEstadoPage({
    super.key,
    required this.orderId,
    this.controller,
  });

  @override
  State<PedidoEstadoPage> createState() => _PedidoEstadoPageState();
}

class _PedidoEstadoPageState extends State<PedidoEstadoPage> {
  late final OrderFlowController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? buildOrderFlowController();
    _controller.addListener(_onUpdate);
    _controller.loadOrder(widget.orderId);
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

  Order? get _order => _controller.activeOrder;

  Future<void> _openCheckout() async {
    final order = _order;
    if (order == null) return;

    final changed = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (_) => CheckoutPage(order: order, controller: _controller),
      ),
    );

    if (changed == true) {
      await _controller.loadOrder(widget.orderId);
    }
  }

  Future<void> _advance(OrderStatus next) async {
    await _controller.advanceTo(next);
    _showFeedback();
  }

  void _showFeedback() {
    if (!mounted) return;
    final message = _controller.errorMessage ?? _controller.successMessage;
    if (message == null) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(SnackBar(content: Text(message)));
    _controller.clearMessages();
  }

  Future<void> _openNoDriversSheet() async {
    final action = await showModalBottomSheet<OrderNoDriversAction>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 4),
              child: Text(
                'No hay repartidores disponibles',
                style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold),
              ),
            ),
            const Padding(
              padding: EdgeInsets.fromLTRB(20, 0, 20, 12),
              child: Text(
                'RN03: elige cómo continuar con tu pedido.',
                style: TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ),
            for (final option in _controller.noDriverActions)
              ListTile(
                leading: Icon(_iconFor(option)),
                title: Text(option.label),
                onTap: () => Navigator.pop(context, option),
              ),
          ],
        ),
      ),
    );

    if (action == null || !mounted) return;

    double? increasedFee;
    if (action == OrderNoDriversAction.increaseOffer) {
      increasedFee = await _askNewFee();
      if (increasedFee == null) return;
    }

    await _controller.resolveNoDrivers(action, increasedFee: increasedFee);
    _showFeedback();
  }

  Future<double?> _askNewFee() async {
    final order = _order;
    if (order == null) return null;
    final controller = TextEditingController(
      text: (order.deliveryFee + 1).toStringAsFixed(2),
    );

    final value = await showDialog<String>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aumentar tarifa'),
        content: TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: const InputDecoration(
            labelText: 'Nueva tarifa de envío',
            prefixText: '\$ ',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, controller.text),
            child: const Text('Ofertar'),
          ),
        ],
      ),
    );

    controller.dispose();
    return double.tryParse((value ?? '').replaceAll(',', '.'));
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final order = _order;

    return Scaffold(
      appBar: AppBar(
        title: Text('Pedido ${widget.orderId}'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: order == null
          ? Center(
              child: _controller.errorMessage != null
                  ? Text(_controller.errorMessage!)
                  : const CircularProgressIndicator(),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                _StatusHeader(order: order),
                const SizedBox(height: 16),
                Card(
                  child: Column(
                    children: [
                      _infoTile(
                        Icons.delivery_dining,
                        'Modalidad',
                        _modeLabel(order),
                      ),
                      _infoTile(
                        Icons.payments_outlined,
                        'Método de pago',
                        order.isPaymentRegistered
                            ? order.paymentMethod!.label
                            : 'Pendiente de registrar',
                      ),
                      _infoTile(
                        Icons.location_on_outlined,
                        'Dirección',
                        order.deliveryAddress,
                      ),
                      _infoTile(
                        Icons.receipt_long_outlined,
                        'Total',
                        '\$${order.total.toStringAsFixed(2)} '
                            '(envío \$${order.deliveryFee.toStringAsFixed(2)})',
                      ),
                      _infoTile(
                        Icons.inventory_2_outlined,
                        'Envases faltantes',
                        '\$${order.missingContainersFee.toStringAsFixed(2)}',
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Seguimiento',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                if (order.status == OrderStatus.cancelled ||
                    order.status == OrderStatus.rejected)
                  Card(
                    color: Colors.red.shade50,
                    child: Padding(
                      padding: const EdgeInsets.all(14),
                      child: Text(
                        order.status == OrderStatus.cancelled
                            ? 'Este pedido fue cancelado.'
                            : 'El comercio rechazó este pedido.',
                      ),
                    ),
                  )
                else
                  _Timeline(current: order.status),
                const SizedBox(height: 24),
                ..._actionButtons(order),
                const SizedBox(height: 12),
                if (!order.status.isTerminal)
                  OutlinedButton.icon(
                    onPressed: _openCheckout,
                    icon: const Icon(Icons.tune),
                    label: const Text('Editar modalidad y método de pago'),
                  ),
              ],
            ),
    );
  }

  List<Widget> _actionButtons(Order order) {
    final buttons = <Widget>[];

    switch (order.status) {
      case OrderStatus.created:
        buttons.add(
          ElevatedButton.icon(
            onPressed: _controller.isSaving
                ? null
                : () => _advance(OrderStatus.confirmed),
            icon: const Icon(Icons.verified_outlined),
            label: const Text('Confirmar pedido'),
          ),
        );
      case OrderStatus.confirmed:
        buttons.add(
          ElevatedButton.icon(
            onPressed: _controller.isSaving
                ? null
                : () => _advance(OrderStatus.lookingForDriver),
            icon: const Icon(Icons.search),
            label: const Text('Buscar repartidor'),
          ),
        );
      case OrderStatus.lookingForDriver:
        buttons.add(
          ElevatedButton.icon(
            onPressed: _openNoDriversSheet,
            icon: const Icon(Icons.help_outline),
            label: const Text('Ver alternativas sin repartidores'),
          ),
        );
      case OrderStatus.driverAssigned:
        buttons.add(
          ElevatedButton.icon(
            onPressed: _controller.isSaving
                ? null
                : () => _advance(OrderStatus.inDelivery),
            icon: const Icon(Icons.local_shipping_outlined),
            label: const Text('Iniciar entrega'),
          ),
        );
      case OrderStatus.inDelivery:
        buttons.add(
          ElevatedButton.icon(
            onPressed: _controller.isSaving
                ? null
                : () => _advance(OrderStatus.delivered),
            icon: const Icon(Icons.check_circle_outline),
            label: const Text('Marcar como entregado'),
          ),
        );
      case OrderStatus.delivered:
      case OrderStatus.rejected:
      case OrderStatus.cancelled:
        break;
    }

    return buttons;
  }

  static String _modeLabel(Order order) {
    if (order.isPickup) return 'Retiro en local';
    if (order.deliveryMode.isOwnDelivery) return 'Delivery propio del comercio';
    return 'Repartidor externo';
  }

  static IconData _iconFor(OrderNoDriversAction action) => switch (action) {
        OrderNoDriversAction.wait => Icons.hourglass_empty,
        OrderNoDriversAction.increaseOffer => Icons.trending_up,
        OrderNoDriversAction.pickupAtStore => Icons.shopping_bag_outlined,
        OrderNoDriversAction.useStoreOwnDelivery => Icons.storefront,
        OrderNoDriversAction.cancelOrder => Icons.cancel_outlined,
      };

  Widget _infoTile(IconData icon, String label, String value) {
    return ListTile(
      dense: true,
      leading: Icon(icon),
      title: Text(label, style: const TextStyle(fontSize: 12)),
      subtitle: Text(
        value,
        style: const TextStyle(fontWeight: FontWeight.w600),
      ),
    );
  }
}

class _StatusHeader extends StatelessWidget {
  final Order order;

  const _StatusHeader({required this.order});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colorScheme.primaryContainer.withAlpha(90),
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            _label(order.status),
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            order.isCheckoutReady
                ? 'Checkout completo'
                : 'Falta registrar modalidad o método de pago',
            style: TextStyle(
              fontSize: 12,
              color: colorScheme.onSurfaceVariant,
            ),
          ),
        ],
      ),
    );
  }

  static String _label(OrderStatus status) => switch (status) {
        OrderStatus.created => 'Pedido creado',
        OrderStatus.confirmed => 'Confirmado por el comercio',
        OrderStatus.rejected => 'Rechazado',
        OrderStatus.lookingForDriver => 'Buscando repartidor',
        OrderStatus.driverAssigned => 'Repartidor asignado',
        OrderStatus.inDelivery => 'En camino',
        OrderStatus.delivered => 'Entregado',
        OrderStatus.cancelled => 'Cancelado',
      };
}

class _Timeline extends StatelessWidget {
  final OrderStatus current;

  const _Timeline({required this.current});

  static const _steps = [
    (OrderStatus.created, 'Pedido creado'),
    (OrderStatus.confirmed, 'Confirmado'),
    (OrderStatus.lookingForDriver, 'Buscando repartidor'),
    (OrderStatus.driverAssigned, 'Repartidor asignado'),
    (OrderStatus.inDelivery, 'En camino'),
    (OrderStatus.delivered, 'Entregado'),
  ];

  @override
  Widget build(BuildContext context) {
    final currentIndex = _steps.indexWhere((step) => step.$1 == current);

    return Column(
      children: [
        for (var i = 0; i < _steps.length; i++)
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                children: [
                  Icon(
                    i <= currentIndex
                        ? Icons.check_circle
                        : Icons.radio_button_unchecked,
                    color: i <= currentIndex
                        ? Theme.of(context).colorScheme.primary
                        : Colors.grey,
                    size: 20,
                  ),
                  if (i < _steps.length - 1)
                    Container(
                      width: 2,
                      height: 28,
                      color: i < currentIndex
                          ? Theme.of(context).colorScheme.primary
                          : Colors.grey.shade300,
                    ),
                ],
              ),
              const SizedBox(width: 12),
              Padding(
                padding: const EdgeInsets.only(top: 2),
                child: Text(
                  _steps[i].$2,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight:
                        i == currentIndex ? FontWeight.bold : FontWeight.normal,
                    color: i <= currentIndex ? null : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
      ],
    );
  }
}
