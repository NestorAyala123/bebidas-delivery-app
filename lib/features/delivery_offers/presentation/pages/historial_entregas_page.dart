import 'package:flutter/material.dart';

import '../../../delivery/domain/entities/delivery_status.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../controllers/delivery_negotiation_controller.dart';
import '../delivery_negotiation_factory.dart';
import 'negociacion_entrega_page.dart';

/// Historial de entregas del cliente con estado, tarifa acordada,
/// repartidor y calificación.
class HistorialEntregasPage extends StatefulWidget {
  final DeliveryNegotiationController? controller;
  final String customerId;

  const HistorialEntregasPage({
    super.key,
    this.controller,
    this.customerId = 'customer-demo',
  });

  @override
  State<HistorialEntregasPage> createState() => _HistorialEntregasPageState();
}

class _HistorialEntregasPageState extends State<HistorialEntregasPage> {
  late final DeliveryNegotiationController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? buildDeliveryNegotiationController();
    _controller.addListener(_onUpdate);
    WidgetsBinding.instance.addPostFrameCallback(
      (_) => _controller.loadHistory(widget.customerId),
    );
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

  void _openNegotiation(DeliveryNegotiation negotiation) {
    Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) => NegociacionEntregaPage(negotiationId: negotiation.id),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Historial de entregas'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            tooltip: 'Actualizar historial',
            icon: const Icon(Icons.refresh),
            onPressed: () => _controller.loadHistory(widget.customerId),
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    if (_controller.isLoading && _controller.history.isEmpty) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_controller.history.isEmpty) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.delivery_dining_outlined,
                size: 64,
                color: Colors.grey.shade400,
              ),
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage ??
                    'Aún no tienes entregas registradas',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () => _controller.loadHistory(widget.customerId),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _controller.loadHistory(widget.customerId),
      child: ListView.builder(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        itemCount: _controller.history.length,
        itemBuilder: (context, index) {
          final negotiation = _controller.history[index];
          return _HistoryCard(
            negotiation: negotiation,
            onTap: () => _openNegotiation(negotiation),
          );
        },
      ),
    );
  }
}

class _HistoryCard extends StatelessWidget {
  final DeliveryNegotiation negotiation;
  final VoidCallback onTap;

  const _HistoryCard({required this.negotiation, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final status = negotiation.status;
    final color = _statusColor(status);
    final rating = negotiation.rating;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 3,
                    ),
                    decoration: BoxDecoration(
                      color: color.withAlpha(25),
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(color: color.withAlpha(90)),
                    ),
                    child: Text(
                      status.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Text(
                    _formatDate(negotiation.request.createdAt),
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                negotiation.request.destinationAddress,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                'Origen: ${negotiation.request.originAddress}',
                style: const TextStyle(fontSize: 11, color: Colors.grey),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 12,
                runSpacing: 4,
                children: [
                  _Metric(
                    icon: Icons.local_shipping_outlined,
                    label:
                        negotiation.acceptedOffer?.driverName ?? 'Sin asignar',
                  ),
                  _Metric(
                    icon: Icons.attach_money,
                    label: negotiation.agreedFare == null
                        ? 'Propuesta \$${negotiation.customerOffer.toStringAsFixed(2)}'
                        : '\$${negotiation.agreedFare!.toStringAsFixed(2)}',
                  ),
                  _Metric(
                    icon: Icons.gavel_outlined,
                    label: '${negotiation.offers.length} oferta(s)',
                  ),
                ],
              ),
              if (rating != null) ...[
                const SizedBox(height: 8),
                Row(
                  children: [
                    Text(
                      rating.starsGlyphs,
                      style: const TextStyle(fontSize: 15, color: Colors.amber),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      rating.starsLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    if (rating.comment.isNotEmpty) ...[
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          rating.comment,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(
                            fontSize: 11,
                            fontStyle: FontStyle.italic,
                            color: Colors.grey,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ] else if (negotiation.canRate) ...[
                const SizedBox(height: 8),
                const Text(
                  'Pendiente de calificación',
                  style: TextStyle(fontSize: 11, color: Colors.orange),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  static Color _statusColor(DeliveryStatus status) => switch (status) {
    DeliveryStatus.pendingOffer => Colors.orange,
    DeliveryStatus.driverAssigned => Colors.blue,
    DeliveryStatus.arrivedAtStore => Colors.indigo,
    DeliveryStatus.pickedUp => Colors.purple,
    DeliveryStatus.onTheWay => Colors.teal,
    DeliveryStatus.delivered => Colors.green,
    DeliveryStatus.cancelled => Colors.red,
  };

  static String _formatDate(DateTime date) {
    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');
    return '$day/$month/${date.year}';
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;

  const _Metric({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: Theme.of(context).colorScheme.primary),
        const SizedBox(width: 3),
        Text(label, style: const TextStyle(fontSize: 11)),
      ],
    );
  }
}
