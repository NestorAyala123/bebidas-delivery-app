import '../../domain/entities/delivery_status.dart';
import '../../domain/entities/offer_status.dart';

/// Utilidades de presentación para el módulo de delivery.
/// No contienen reglas de negocio: solo formatean valores ya validados por el
/// dominio y los casos de uso.

/// Formatea un importe canónico en centavos para mostrarlo al usuario.
String formatCents(int cents) => '\$${(cents / 100).toStringAsFixed(2)}';

/// Formatea un importe heredado en unidades monetarias decimales.
/// Se usa únicamente para visualización; la fuente de verdad sigue siendo
/// el entero en centavos.
String formatMoney(double amount) => '\$${amount.toStringAsFixed(2)}';

/// Etiqueta legible del estado de una solicitud de delivery.
String deliveryStatusLabel(DeliveryStatus status) => switch (status) {
  DeliveryStatus.pendingOffer => 'En oferta',
  DeliveryStatus.driverAssigned => 'Repartidor asignado',
  DeliveryStatus.arrivedAtStore => 'Llegó al comercio',
  DeliveryStatus.pickedUp => 'Producto recogido',
  DeliveryStatus.onTheWay => 'En camino',
  DeliveryStatus.delivered => 'Entregado',
  DeliveryStatus.cancelled => 'Cancelada',
};

/// Etiqueta legible del estado de una oferta.
String offerStatusLabel(OfferStatus status) => switch (status) {
  OfferStatus.pending => 'Pendiente',
  OfferStatus.accepted => 'Aceptada',
  OfferStatus.rejected => 'Rechazada',
  OfferStatus.discarded => 'Descartada',
};

/// Etiqueta legible de la modalidad de entrega.
String deliveryModeLabel(String modeName) => switch (modeName) {
  'pickupAtStore' => 'Retiro en local',
  'ownDelivery' => 'Delivery del comercio',
  'externalDriver' => 'Repartidor externo',
  _ => modeName,
};

/// Formatea la fecha de una operación de delivery para mostrarla en la UI.
String formatDateTime(DateTime value) {
  final local = value.toLocal();
  final day = local.day.toString().padLeft(2, '0');
  final month = local.month.toString().padLeft(2, '0');
  final year = local.year.toString();
  final hour = local.hour.toString().padLeft(2, '0');
  final minute = local.minute.toString().padLeft(2, '0');
  return '$day/$month/$year $hour:$minute';
}
