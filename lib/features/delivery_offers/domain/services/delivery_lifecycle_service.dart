import '../../../delivery/domain/entities/delivery_status.dart';

/// Secuencia válida de estados de una entrega negociada.
class DeliveryLifecycleService {
  const DeliveryLifecycleService();

  static const List<DeliveryStatus> sequence = [
    DeliveryStatus.pendingOffer,
    DeliveryStatus.driverAssigned,
    DeliveryStatus.arrivedAtStore,
    DeliveryStatus.pickedUp,
    DeliveryStatus.onTheWay,
    DeliveryStatus.delivered,
  ];

  /// Siguiente estado natural o `null` si la entrega ya terminó.
  DeliveryStatus? nextStatus(DeliveryStatus current) {
    final index = sequence.indexOf(current);
    if (current.isTerminal || index < 0 || index == sequence.length - 1) {
      return null;
    }
    return sequence[index + 1];
  }

  /// Permite avanzar un paso o cancelar mientras la entrega siga activa.
  bool canTransition(DeliveryStatus from, DeliveryStatus to) {
    if (from.isTerminal) return false;
    if (to == DeliveryStatus.cancelled) return true;
    return nextStatus(from) == to;
  }

  bool canRate(DeliveryStatus status) => status == DeliveryStatus.delivered;

  String nextActionLabel(DeliveryStatus current) => switch (current) {
    DeliveryStatus.pendingOffer => 'Selecciona un repartidor',
    DeliveryStatus.driverAssigned => 'Confirmar llegada al comercio',
    DeliveryStatus.arrivedAtStore => 'Confirmar retiro del pedido',
    DeliveryStatus.pickedUp => 'Iniciar ruta al cliente',
    DeliveryStatus.onTheWay => 'Confirmar entrega',
    DeliveryStatus.delivered => 'Entrega completada',
    DeliveryStatus.cancelled => 'Entrega cancelada',
  };
}
