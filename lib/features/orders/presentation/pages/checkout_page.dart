import 'package:flutter/material.dart';

import '../../../delivery/domain/entities/delivery_mode.dart';
import '../../../pricing/domain/services/delivery_fee_policy.dart';
import '../../domain/entities/order.dart';
import '../../domain/entities/payment_method.dart';
import '../controllers/order_flow_controller.dart';
import '../order_flow_factory.dart';

/// Selección de modalidad de entrega (RN02) y método de pago (efectivo o
/// transferencia) antes de confirmar el checkout.
class CheckoutPage extends StatefulWidget {
  final Order order;
  final OrderFlowController? controller;

  const CheckoutPage({super.key, required this.order, this.controller});

  @override
  State<CheckoutPage> createState() => _CheckoutPageState();
}

class _CheckoutPageState extends State<CheckoutPage> {
  static const _feePolicy = DeliveryFeePolicy();

  late final OrderFlowController _controller;
  late final bool _ownsController;
  late DeliveryMode _mode;
  PaymentMethod? _paymentMethod;
  double _distanceKm = 4;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? buildOrderFlowController();
    _mode = widget.order.deliveryMode;
    _paymentMethod = widget.order.paymentMethod;
    _distanceKm = widget.order.isPickup
        ? 0
        : ((widget.order.deliveryFee - DeliveryFeePolicy.baseFee) /
                  DeliveryFeePolicy.feePerKm)
              .clamp(0, 10)
              .toDouble();

    _controller.addListener(_onUpdate);
    _controller.loadOrder(widget.order.id);
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

  Order get _order => _controller.activeOrder ?? widget.order;

  double get _deliveryFee {
    if (_mode.isPickup) return 0;
    return _feePolicy.calculate(_distanceKm).dataOrNull ?? 0;
  }

  void _onModeChanged(DeliveryMode? value) {
    if (value == null) return;
    final fee = value.isPickup
        ? 0.0
        : (_feePolicy.calculate(_distanceKm).dataOrNull ?? 0);
    final applied = _controller.selectDeliveryMode(value, deliveryFee: fee);
    if (applied) {
      setState(() {
        _mode = value;
        if (value.isPickup) _distanceKm = 0;
      });
    }
  }

  void _onDistanceChanged(double value) {
    setState(() => _distanceKm = value);
    if (!_mode.isPickup) {
      final fee = _feePolicy.calculate(value).dataOrNull ?? 0;
      _controller.selectDeliveryMode(_mode, deliveryFee: fee);
    }
  }

  Future<void> _confirm() async {
    if (_paymentMethod == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecciona efectivo o transferencia para continuar'),
        ),
      );
      return;
    }

    final confirmed = await _controller.confirmCheckout();
    if (!mounted) return;

    if (confirmed) {
      Navigator.pop(context, true);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _controller.errorMessage ?? 'No se pudo confirmar el checkout',
          ),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final subtotal = _order.itemsSubtotal;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Entrega y pago'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          const Text(
            'Modalidad de entrega',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioGroup<DeliveryMode>(
            groupValue: _mode,
            onChanged: (value) => _onModeChanged(value),
            child: Column(
              children: [
                _modeTile(
                  mode: DeliveryMode.externalDriver,
                  title: 'Repartidor externo',
                  subtitle: 'Negocia la tarifa con repartidores de la app',
                  enabled: _controller.supportsExternalDriver,
                  icon: Icons.delivery_dining,
                ),
                _modeTile(
                  mode: DeliveryMode.ownDelivery,
                  title: 'Delivery propio del comercio',
                  subtitle: 'El comercio entrega con su propio personal',
                  enabled: _controller.supportsOwnDelivery,
                  icon: Icons.storefront,
                ),
                _modeTile(
                  mode: DeliveryMode.pickupAtStore,
                  title: 'Retiro en local',
                  subtitle: 'Sin costo de envío',
                  enabled: _controller.supportsPickup,
                  icon: Icons.shopping_bag_outlined,
                ),
              ],
            ),
          ),
          if (!_mode.isPickup) ...[
            const SizedBox(height: 16),
            Text(
              'Distancia estimada: ${_distanceKm.toStringAsFixed(1)} km',
              style: const TextStyle(fontWeight: FontWeight.w600),
            ),
            Slider(
              value: _distanceKm,
              min: 0,
              max: 10,
              divisions: 20,
              label: '${_distanceKm.toStringAsFixed(1)} km',
              onChanged: _onDistanceChanged,
            ),
          ],
          const Divider(height: 32),
          const Text(
            'Método de pago',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          RadioGroup<PaymentMethod>(
            groupValue: _paymentMethod,
            onChanged: (value) {
              if (value == null) return;
              setState(() => _paymentMethod = value);
              _controller.registerPayment(value);
            },
            child: Column(
              children: [
                for (final method in PaymentMethod.values)
                  RadioListTile<PaymentMethod>(
                    value: method,
                    title: Text(method.label),
                    subtitle: Text(method.description),
                    secondary: Icon(
                      method.isCash
                          ? Icons.payments_outlined
                          : Icons.account_balance,
                    ),
                  ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(
                children: [
                  _row('Productos', subtotal),
                  _row('Envío', _deliveryFee),
                  if (_order.missingContainersFee > 0)
                    _row('Envases faltantes', _order.missingContainersFee),
                  const Divider(),
                  _row(
                    'Total',
                    subtotal + _deliveryFee + _order.missingContainersFee,
                    bold: true,
                  ),
                ],
              ),
            ),
          ),
          if (_controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.only(top: 12),
              child: Text(
                _controller.errorMessage!,
                style: const TextStyle(color: Colors.red),
              ),
            ),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _controller.isSaving ? null : _confirm,
            icon: const Icon(Icons.check_circle_outline),
            label: Text(
              _controller.isSaving ? 'Confirmando...' : 'Confirmar checkout',
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'RN02: la modalidad elegida se valida contra las capacidades del '
            'comercio. El pago queda registrado antes de buscar repartidor.',
            style: TextStyle(fontSize: 11, color: colorScheme.onSurfaceVariant),
          ),
        ],
      ),
    );
  }

  Widget _modeTile({
    required DeliveryMode mode,
    required String title,
    required String subtitle,
    required bool enabled,
    required IconData icon,
  }) {
    return RadioListTile<DeliveryMode>(
      value: mode,
      enabled: enabled,
      title: Text(title),
      subtitle: Text(enabled ? subtitle : 'No disponible en este comercio'),
      secondary: Icon(icon),
    );
  }

  Widget _row(String label, double amount, {bool bold = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label),
          Text(
            '\$${amount.toStringAsFixed(2)}',
            style: TextStyle(
              fontWeight: bold ? FontWeight.bold : FontWeight.normal,
              fontSize: bold ? 16 : 14,
            ),
          ),
        ],
      ),
    );
  }
}
