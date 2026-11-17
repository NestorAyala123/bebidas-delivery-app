import 'package:flutter/material.dart';

import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/offer_status.dart';
import '../utils/delivery_formatters.dart';

/// Chip reutilizable que representa el estado de una solicitud de delivery.
class DeliveryStatusChip extends StatelessWidget {
  final DeliveryStatus status;

  const DeliveryStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors(status);
    return _BaseChip(
      label: deliveryStatusLabel(status),
      background: background,
      foreground: foreground,
    );
  }

  (Color, Color) _colors(DeliveryStatus status) => switch (status) {
    DeliveryStatus.pendingOffer => (Colors.blue.shade50, Colors.blue.shade800),
    DeliveryStatus.driverAssigned => (
      Colors.indigo.shade50,
      Colors.indigo.shade800,
    ),
    DeliveryStatus.arrivedAtStore => (
      Colors.orange.shade50,
      Colors.orange.shade900,
    ),
    DeliveryStatus.pickedUp => (Colors.amber.shade50, Colors.amber.shade900),
    DeliveryStatus.onTheWay => (
      Colors.deepOrange.shade50,
      Colors.deepOrange.shade800,
    ),
    DeliveryStatus.delivered => (Colors.green.shade50, Colors.green.shade800),
    DeliveryStatus.cancelled => (Colors.grey.shade200, Colors.grey.shade800),
  };
}

/// Chip reutilizable que representa el estado de una oferta.
class OfferStatusChip extends StatelessWidget {
  final OfferStatus status;

  const OfferStatusChip({super.key, required this.status});

  @override
  Widget build(BuildContext context) {
    final (background, foreground) = _colors(status);
    return _BaseChip(
      label: offerStatusLabel(status),
      background: background,
      foreground: foreground,
    );
  }

  (Color, Color) _colors(OfferStatus status) => switch (status) {
    OfferStatus.pending => (Colors.blue.shade50, Colors.blue.shade800),
    OfferStatus.accepted => (Colors.green.shade50, Colors.green.shade800),
    OfferStatus.rejected => (Colors.red.shade50, Colors.red.shade800),
    OfferStatus.discarded => (Colors.grey.shade200, Colors.grey.shade800),
  };
}

class _BaseChip extends StatelessWidget {
  final String label;
  final Color background;
  final Color foreground;

  const _BaseChip({
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
