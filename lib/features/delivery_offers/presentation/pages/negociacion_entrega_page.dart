import 'package:flutter/material.dart';

import '../../../chat/domain/entities/chat_conversation.dart';
import '../../../chat/presentation/chat_launcher.dart';
import '../../../delivery/domain/entities/delivery_status.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../../domain/entities/delivery_negotiation_event.dart';
import '../../domain/entities/delivery_offer.dart';
import '../../domain/services/offer_negotiation_service.dart';
import '../controllers/delivery_negotiation_controller.dart';
import '../delivery_negotiation_factory.dart';
import 'historial_entregas_page.dart';

/// Pantalla principal de negociación: el cliente propone una tarifa, compara
/// las ofertas de los repartidores y selecciona una sola (RN06).
class NegociacionEntregaPage extends StatefulWidget {
  final String negotiationId;
  final DeliveryNegotiationController? controller;

  const NegociacionEntregaPage({
    super.key,
    required this.negotiationId,
    this.controller,
  });

  @override
  State<NegociacionEntregaPage> createState() => _NegociacionEntregaPageState();
}

class _NegociacionEntregaPageState extends State<NegociacionEntregaPage> {
  late final DeliveryNegotiationController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? buildDeliveryNegotiationController();
    _controller.addListener(_onUpdate);
    _controller.loadNegotiation(widget.negotiationId);
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

  DeliveryNegotiation? get _negotiation => _controller.negotiation;

  void _showFeedback() {
    if (!mounted) return;
    final message = _controller.errorMessage ?? _controller.successMessage;
    if (message == null) return;
    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: _controller.errorMessage != null
              ? Theme.of(context).colorScheme.error
              : null,
        ),
      );
    _controller.clearMessages();
  }

  Future<void> _proposeOffer() async {
    final negotiation = _negotiation;
    if (negotiation == null) return;

    final textController = TextEditingController(
      text: negotiation.customerOffer.toStringAsFixed(2),
    );
    final amount = await showDialog<double>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Tu propuesta de entrega'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Tarifa referencial: \$${negotiation.referenceFare.toStringAsFixed(2)}',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: textController,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto a pagar (USD)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final value = double.tryParse(textController.text.trim());
              if (value == null) return;
              Navigator.pop(context, value);
            },
            child: const Text('Enviar propuesta'),
          ),
        ],
      ),
    );
    textController.dispose();

    if (amount == null || !mounted) return;
    await _controller.proposeClientOffer(amount);
    _showFeedback();
  }

  Future<void> _addDriverOffer() async {
    final nameController = TextEditingController();
    final amountController = TextEditingController(
      text: (_negotiation?.customerOffer ?? 3).toStringAsFixed(2),
    );

    final result = await showDialog<({String name, double amount})>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Oferta de repartidor'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(
              controller: nameController,
              autofocus: true,
              decoration: const InputDecoration(
                labelText: 'Nombre del repartidor',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: amountController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Monto ofertado (USD)',
                prefixText: '\$ ',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () {
              final name = nameController.text.trim();
              final amount = double.tryParse(amountController.text.trim());
              if (name.isEmpty || amount == null) return;
              Navigator.pop(context, (name: name, amount: amount));
            },
            child: const Text('Registrar oferta'),
          ),
        ],
      ),
    );
    nameController.dispose();
    amountController.dispose();

    if (result == null || !mounted) return;
    await _controller.addDriverOffer(
      driverId: 'drv-manual-${DateTime.now().microsecondsSinceEpoch}',
      driverName: result.name,
      amount: result.amount,
    );
    _showFeedback();
  }

  Future<void> _simulateTwoDrivers() async {
    await _controller.simulateTwoDriverOffers();
    _showFeedback();
  }

  Future<void> _selectOffer(DeliveryOffer offer) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Aceptar oferta'),
        content: Text(
          '¿Asignar la entrega a ${offer.driverName} por '
          '${offer.amountLabel}? Las demás ofertas se cerrarán '
          'automáticamente.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Aceptar oferta'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _controller.selectOffer(offer.id);
    _showFeedback();
  }

  Future<void> _advanceStatus() async {
    await _controller.advanceStatus();
    _showFeedback();
  }

  Future<void> _cancelDelivery() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cancelar entrega'),
        content: const Text(
          'La entrega quedará registrada como cancelada en el historial.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Volver'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Cancelar entrega'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;
    await _controller.cancelDelivery();
    _showFeedback();
  }

  Future<void> _rateDelivery() async {
    var stars = 5;
    final commentController = TextEditingController();

    final result = await showDialog<({int stars, String comment})>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('Calificar entrega'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text('¿Cómo fue tu experiencia con el repartidor?'),
              const SizedBox(height: 8),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  for (var index = 1; index <= 5; index++)
                    IconButton(
                      tooltip: '$index estrellas',
                      onPressed: () => setDialogState(() => stars = index),
                      icon: Icon(
                        index <= stars ? Icons.star : Icons.star_border,
                        color: Colors.amber,
                      ),
                    ),
                ],
              ),
              TextField(
                controller: commentController,
                maxLines: 3,
                decoration: const InputDecoration(
                  labelText: 'Comentario (opcional)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, (
                stars: stars,
                comment: commentController.text.trim(),
              )),
              child: const Text('Enviar calificación'),
            ),
          ],
        ),
      ),
    );
    commentController.dispose();

    if (result == null || !mounted) return;
    await _controller.rateDelivery(result.stars, comment: result.comment);
    _showFeedback();
  }

  void _openChat() {
    final negotiation = _negotiation;
    if (negotiation == null) return;

    final driver =
        negotiation.acceptedOffer?.driverName ??
        'Repartidor ${negotiation.request.assignedDriverId ?? ''}';
    final driverId =
        negotiation.acceptedOffer?.driverId ??
        negotiation.request.assignedDriverId;

    if (driverId == null || driverId.isEmpty) return;

    ChatLauncher.open(
      context,
      counterpartId: driverId,
      counterpartName: driver,
      role: ChatPeerRole.driver,
      contextId: negotiation.id,
      contextLabel:
          '${negotiation.request.originAddress} → ${negotiation.request.destinationAddress}',
    );
  }

  void _openHistory() {
    Navigator.push<void>(
      context,
      MaterialPageRoute(builder: (_) => const HistorialEntregasPage()),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        title: const Text('Negociación de entrega'),
        centerTitle: true,
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          IconButton(
            tooltip: 'Historial de entregas',
            icon: const Icon(Icons.history),
            onPressed: _openHistory,
          ),
        ],
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final negotiation = _negotiation;

    if (negotiation == null) {
      if (_controller.isLoading) {
        return const Center(child: CircularProgressIndicator());
      }
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.error_outline, size: 52, color: Colors.red),
              const SizedBox(height: 12),
              Text(
                _controller.errorMessage ?? 'No se encontró la negociación',
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: () =>
                    _controller.loadNegotiation(widget.negotiationId),
                icon: const Icon(Icons.refresh),
                label: const Text('Reintentar'),
              ),
            ],
          ),
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () => _controller.loadNegotiation(widget.negotiationId),
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 32),
        children: [
          _buildRouteCard(negotiation),
          const SizedBox(height: 12),
          _buildStatusCard(negotiation),
          if (negotiation.offers.isNotEmpty ||
              negotiation.isAwaitingOffers) ...[
            const SizedBox(height: 16),
            _buildOffersSection(negotiation),
          ],
          if (negotiation.hasSelection) ...[
            const SizedBox(height: 16),
            _buildAssignmentCard(negotiation),
          ],
          if (negotiation.canRate) ...[
            const SizedBox(height: 12),
            _buildRatingPrompt(negotiation),
          ],
          if (negotiation.hasRating) ...[
            const SizedBox(height: 12),
            _buildRatingCard(negotiation),
          ],
          const SizedBox(height: 16),
          _buildHistoryCard(negotiation),
          if (negotiation.status.isActive && negotiation.hasSelection) ...[
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: _controller.isSaving ? null : _cancelDelivery,
              icon: const Icon(Icons.cancel_outlined),
              label: const Text('Cancelar entrega'),
              style: OutlinedButton.styleFrom(
                foregroundColor: Theme.of(context).colorScheme.error,
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildRouteCard(DeliveryNegotiation negotiation) {
    final request = negotiation.request;
    return Card(
      elevation: 1,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                const Icon(
                  Icons.storefront,
                  size: 18,
                  color: Colors.deepOrange,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.originAddress,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Padding(
              padding: EdgeInsets.symmetric(vertical: 6, horizontal: 3),
              child: Icon(Icons.more_vert, size: 16, color: Colors.grey),
            ),
            Row(
              children: [
                const Icon(Icons.location_on, size: 18, color: Colors.red),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    request.destinationAddress,
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const Divider(height: 24),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: [
                if (request.distanceInKm != null)
                  _InfoChip(
                    icon: Icons.route,
                    label: '${request.distanceInKm!.toStringAsFixed(1)} km',
                  ),
                _InfoChip(
                  icon: Icons.receipt_long,
                  label:
                      'Referencia \$${negotiation.referenceFare.toStringAsFixed(2)}',
                ),
                _InfoChip(
                  icon: Icons.handshake_outlined,
                  label:
                      'Tu propuesta \$${negotiation.customerOffer.toStringAsFixed(2)}',
                  color: Colors.blue,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusCard(DeliveryNegotiation negotiation) {
    final color = _statusColor(negotiation.status);
    return Card(
      elevation: 0,
      color: color.withAlpha(18),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: color.withAlpha(80)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_statusIcon(negotiation.status), color: color),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    negotiation.status.label,
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                if (_controller.isSaving)
                  const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  ),
              ],
            ),
            const SizedBox(height: 10),
            ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: LinearProgressIndicator(
                value: negotiation.progress,
                minHeight: 8,
                backgroundColor: color.withAlpha(30),
                color: color,
              ),
            ),
            const SizedBox(height: 10),
            Text(
              _controller.nextActionLabel,
              style: const TextStyle(fontSize: 12, color: Colors.black54),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOffersSection(DeliveryNegotiation negotiation) {
    final comparison = _controller.comparison;
    final sortedOffers = [...negotiation.offers]
      ..sort((a, b) => a.offeredAmount.compareTo(b.offeredAmount));

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            const Expanded(
              child: Text(
                'Ofertas de repartidores',
                style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
            Chip(
              visualDensity: VisualDensity.compact,
              label: Text('${negotiation.offers.length}'),
            ),
          ],
        ),
        const SizedBox(height: 4),
        Text(
          negotiation.isAwaitingOffers
              ? 'Compara precio y condición. Al aceptar una oferta, el resto '
                    'se cierra automáticamente (RN06).'
              : 'Oferta seleccionada. Las demás ofertas quedaron cerradas '
                    'automáticamente.',
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        const SizedBox(height: 10),
        if (negotiation.offers.isEmpty)
          _buildEmptyOffers()
        else ...[
          if (comparison.hasMultipleOffers)
            _buildComparisonBanner(negotiation, comparison),
          const SizedBox(height: 8),
          for (final offer in sortedOffers) ...[
            _OfferCard(
              offer: offer,
              isBestPrice:
                  comparison.cheapest?.id == offer.id && offer.status.isActive,
              enabled: !_controller.isSaving && negotiation.isAwaitingOffers,
              onAccept: () => _selectOffer(offer),
            ),
            const SizedBox(height: 8),
          ],
          if (negotiation.isAwaitingOffers)
            OutlinedButton.icon(
              onPressed: _controller.isSaving ? null : _addDriverOffer,
              icon: const Icon(Icons.person_add_alt_1),
              label: const Text('Registrar otra oferta'),
            ),
        ],
      ],
    );
  }

  Widget _buildEmptyOffers() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.orange.withAlpha(18),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.orange.withAlpha(70)),
      ),
      child: Column(
        children: [
          const Icon(Icons.hourglass_empty, color: Colors.orange, size: 32),
          const SizedBox(height: 8),
          const Text(
            'Aún no hay ofertas de repartidores',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          const Text(
            'Puedes esperar, subir tu propuesta o simular la llegada de dos '
            'repartidores para la demostración.',
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: _controller.isSaving ? null : _simulateTwoDrivers,
            icon: const Icon(Icons.group_add_outlined),
            label: const Text('Simular 2 repartidores'),
          ),
          const SizedBox(height: 6),
          TextButton.icon(
            onPressed: _controller.isSaving ? null : _proposeOffer,
            icon: const Icon(Icons.edit_outlined),
            label: const Text('Cambiar mi propuesta'),
          ),
        ],
      ),
    );
  }

  Widget _buildComparisonBanner(
    DeliveryNegotiation negotiation,
    OfferComparison comparison,
  ) {
    final savings = comparison.savingsVsReference(negotiation.referenceFare);
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withAlpha(80),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.compare_arrows, size: 18),
              const SizedBox(width: 6),
              Text(
                'Comparación de ${comparison.offerCount} ofertas',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text(
            'Mejor precio: ${comparison.cheapest?.amountLabel} · '
            'Promedio: \$${comparison.averageAmount.toStringAsFixed(2)} · '
            'Diferencia: \$${comparison.spread.toStringAsFixed(2)}',
            style: const TextStyle(fontSize: 12),
          ),
          Text(
            savings >= 0
                ? 'Ahorro frente a la referencia: \$${savings.toStringAsFixed(2)}'
                : 'La mejor oferta supera la referencia en \$${savings.abs().toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 12,
              color: savings >= 0
                  ? Colors.green.shade800
                  : Colors.orange.shade800,
            ),
          ),
          if (comparison.counterOfferCount > 0)
            Text(
              '${comparison.counterOfferCount} contraoferta(s) recibida(s)',
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
        ],
      ),
    );
  }

  Widget _buildAssignmentCard(DeliveryNegotiation negotiation) {
    final driver =
        negotiation.acceptedOffer?.driverName ??
        'Repartidor ${negotiation.request.assignedDriverId ?? ''}';
    final fare = negotiation.agreedFare;
    final next = _controller.nextStatus;

    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Row(
              children: [
                Icon(Icons.verified, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'Repartidor asignado',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 10),
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Theme.of(context).colorScheme.onPrimary,
                  child: Text(_initials(driver)),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        driver,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      if (fare != null)
                        Text(
                          'Tarifa acordada: \$${fare.toStringAsFixed(2)}',
                          style: const TextStyle(fontSize: 12),
                        ),
                    ],
                  ),
                ),
                IconButton.filledTonal(
                  tooltip: 'Chatear con el repartidor',
                  onPressed: _openChat,
                  icon: const Icon(Icons.chat_bubble_outline),
                ),
              ],
            ),
            if (fare != null && negotiation.savingsVsReference != null) ...[
              const SizedBox(height: 8),
              Text(
                negotiation.savingsVsReference! >= 0
                    ? 'Ahorraste \$${negotiation.savingsVsReference!.toStringAsFixed(2)} frente a la referencia'
                    : 'Pagaste \$${negotiation.savingsVsReference!.abs().toStringAsFixed(2)} sobre la referencia',
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
            const Divider(height: 24),
            if (negotiation.status == DeliveryStatus.delivered)
              const Row(
                children: [
                  Icon(Icons.check_circle, color: Colors.green),
                  SizedBox(width: 8),
                  Text(
                    'Entrega completada',
                    style: TextStyle(fontWeight: FontWeight.bold),
                  ),
                ],
              )
            else if (negotiation.status == DeliveryStatus.cancelled)
              const Text('Esta entrega fue cancelada.')
            else
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: next == null || _controller.isSaving
                      ? null
                      : _advanceStatus,
                  icon: const Icon(Icons.arrow_forward),
                  label: Text(
                    _controller.nextActionLabel,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  style: FilledButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 13),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingPrompt(DeliveryNegotiation negotiation) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.amber.withAlpha(25),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.amber.shade300),
      ),
      child: Column(
        children: [
          const Text(
            '¿Cómo estuvo la entrega?',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 6),
          const Text(
            'Califica al repartidor para cerrar el ciclo de la entrega.',
            style: TextStyle(fontSize: 12, color: Colors.black54),
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            onPressed: _controller.isSaving ? null : _rateDelivery,
            icon: const Icon(Icons.star_outline),
            label: const Text('Calificar entrega'),
          ),
        ],
      ),
    );
  }

  Widget _buildRatingCard(DeliveryNegotiation negotiation) {
    final rating = negotiation.rating!;
    return Card(
      elevation: 0,
      color: Colors.amber.withAlpha(20),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              '${rating.starsGlyphs}  ${rating.starsLabel}',
              style: const TextStyle(fontSize: 18, color: Colors.amber),
            ),
            if (rating.comment.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                rating.comment,
                style: const TextStyle(
                  fontSize: 12,
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildHistoryCard(DeliveryNegotiation negotiation) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ExpansionTile(
        leading: const Icon(Icons.timeline),
        title: Text('Historial de la entrega (${negotiation.history.length})'),
        children: [
          for (final event in negotiation.history.reversed)
            ListTile(
              dense: true,
              leading: Icon(_eventIcon(event.type), size: 18),
              title: Text(
                event.description,
                style: const TextStyle(fontSize: 13),
              ),
              subtitle: Text(
                event.type.label,
                style: const TextStyle(fontSize: 11),
              ),
            ),
        ],
      ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return 'R';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return (parts.first.substring(0, 1) + parts[1].substring(0, 1))
        .toUpperCase();
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

  static IconData _statusIcon(DeliveryStatus status) => switch (status) {
    DeliveryStatus.pendingOffer => Icons.hourglass_top,
    DeliveryStatus.driverAssigned => Icons.person_pin_circle,
    DeliveryStatus.arrivedAtStore => Icons.storefront,
    DeliveryStatus.pickedUp => Icons.shopping_bag,
    DeliveryStatus.onTheWay => Icons.two_wheeler,
    DeliveryStatus.delivered => Icons.check_circle,
    DeliveryStatus.cancelled => Icons.cancel,
  };

  static IconData _eventIcon(DeliveryNegotiationEventType type) {
    switch (type) {
      case DeliveryNegotiationEventType.requestCreated:
        return Icons.add_circle_outline;
      case DeliveryNegotiationEventType.clientOfferUpdated:
        return Icons.edit_outlined;
      case DeliveryNegotiationEventType.driverOfferReceived:
        return Icons.local_shipping_outlined;
      case DeliveryNegotiationEventType.offerSelected:
        return Icons.verified_outlined;
      case DeliveryNegotiationEventType.offerClosed:
        return Icons.lock_outline;
      case DeliveryNegotiationEventType.statusChanged:
        return Icons.sync;
      case DeliveryNegotiationEventType.deliveryCancelled:
        return Icons.cancel_outlined;
      case DeliveryNegotiationEventType.deliveryRated:
        return Icons.star_outline;
    }
  }
}

class _OfferCard extends StatelessWidget {
  final DeliveryOffer offer;
  final bool isBestPrice;
  final bool enabled;
  final VoidCallback onAccept;

  const _OfferCard({
    required this.offer,
    required this.isBestPrice,
    required this.enabled,
    required this.onAccept,
  });

  @override
  Widget build(BuildContext context) {
    final statusColor = offer.status.isActive
        ? Colors.orange
        : offer.isAccepted
        ? Colors.green
        : Colors.grey;

    return Card(
      elevation: isBestPrice ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(14),
        side: BorderSide(
          color: isBestPrice ? Colors.green.withAlpha(140) : Colors.black12,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  backgroundColor: statusColor.withAlpha(40),
                  foregroundColor: statusColor,
                  child: Text(
                    offer.driverName.substring(0, 1).toUpperCase(),
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        offer.driverName,
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${offer.amountLabel} · ${offer.status.label}',
                        style: const TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),
                if (offer.status.isActive)
                  FilledButton(
                    onPressed: enabled ? onAccept : null,
                    child: const Text('Aceptar'),
                  )
                else
                  Icon(
                    offer.isAccepted ? Icons.verified : Icons.lock,
                    color: statusColor,
                  ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: [
                if (isBestPrice)
                  const _Badge(label: 'Mejor precio', color: Colors.green),
                if (offer.isCounterOffer)
                  const _Badge(label: 'Contraoferta', color: Colors.orange),
                if (offer.wasClosedByAnotherAcceptance)
                  const _Badge(
                    label: 'Cerrada por otra aceptación',
                    color: Colors.grey,
                  ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _Badge extends StatelessWidget {
  final String label;
  final Color color;

  const _Badge({required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: color.withAlpha(25),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withAlpha(90)),
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

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color? color;

  const _InfoChip({required this.icon, required this.label, this.color});

  @override
  Widget build(BuildContext context) {
    final effective = color ?? Theme.of(context).colorScheme.primary;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: effective.withAlpha(18),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: effective.withAlpha(70)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: effective),
          const SizedBox(width: 4),
          Text(label, style: const TextStyle(fontSize: 11)),
        ],
      ),
    );
  }
}
