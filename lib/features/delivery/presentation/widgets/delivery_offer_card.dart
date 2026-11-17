import 'package:flutter/material.dart';

import '../../domain/entities/delivery_offer.dart';
import '../utils/delivery_formatters.dart';
import 'delivery_status_chip.dart';

/// Tarjeta reutilizable para comparar una oferta o contraoferta de repartidor.
class DeliveryOfferCard extends StatelessWidget {
  final DeliveryOffer offer;

  /// Indica si es la propuesta pendiente con la tarifa más baja.
  final bool isBestOffer;

  /// Indica si la identidad actual puede aceptar o rechazar esta oferta.
  final bool canRespond;

  /// Deshabilita los botones mientras hay una operación en curso.
  final bool isWorking;

  final VoidCallback? onAccept;
  final VoidCallback? onReject;

  const DeliveryOfferCard({
    super.key,
    required this.offer,
    this.isBestOffer = false,
    this.canRespond = false,
    this.isWorking = false,
    this.onAccept,
    this.onReject,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      key: Key('offer-${offer.id}'),
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Text(
                    offer.driverName,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
                Text(
                  formatCents(offer.offeredFareInCents),
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                OfferStatusChip(status: offer.status),
                if (isBestOffer && offer.isPending)
                  _Chip(
                    label: 'Mejor tarifa',
                    background: Colors.green.shade50,
                    foreground: Colors.green.shade800,
                  ),
                _Chip(
                  label: offer.isCounterOffer
                      ? 'Contraoferta'
                      : 'Oferta directa',
                  background: offer.isCounterOffer
                      ? Colors.amber.shade50
                      : Colors.blue.shade50,
                  foreground: offer.isCounterOffer
                      ? Colors.amber.shade900
                      : Colors.blue.shade800,
                ),
              ],
            ),
            const SizedBox(height: 10),
            Text(
              'Tarifa de referencia: ${formatCents(offer.referenceFareInCents)}',
              style: const TextStyle(color: Colors.grey),
            ),
            if (offer.comment != null && offer.comment!.trim().isNotEmpty) ...[
              const SizedBox(height: 8),
              Text('“${offer.comment!.trim()}”'),
            ],
            const SizedBox(height: 8),
            Text(
              _formatDateTime(offer.createdAt),
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
            if (canRespond) ...[
              const Divider(height: 24),
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  TextButton(
                    key: Key('reject-offer-${offer.id}'),
                    onPressed: isWorking ? null : onReject,
                    child: const Text('Rechazar'),
                  ),
                  const SizedBox(width: 8),
                  FilledButton(
                    key: Key('accept-offer-${offer.id}'),
                    onPressed: isWorking ? null : onAccept,
                    child: const Text('Aceptar'),
                  ),
                ],
              ),
            ],
          ],
        ),
      ),
    );
  }

  String _formatDateTime(DateTime value) {
    final local = value.toLocal();
    final day = local.day.toString().padLeft(2, '0');
    final month = local.month.toString().padLeft(2, '0');
    final hour = local.hour.toString().padLeft(2, '0');
    final minute = local.minute.toString().padLeft(2, '0');
    return '$day/$month/${local.year} $hour:$minute';
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _Chip({
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: foreground,
          fontSize: 12,
          fontWeight: FontWeight.w600,
        ),
      ),
    );
  }
}
