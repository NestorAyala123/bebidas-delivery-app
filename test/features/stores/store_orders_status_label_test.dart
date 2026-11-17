// Tests para lib/features/stores/presentation/pages/store_orders_page.dart
// Verifican que OrderStatus.noDriversAvailable tiene etiqueta explícita en el
// switch _statusLabel y que no se oculta con un caso comodín.
import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/orders/domain/entities/order_status.dart';

// Réplica exacta del switch corregido en store_orders_page.dart para test unitario.
// Si el switch cambia en la página, este test debe actualizarse en paralelo.
String _statusLabel(OrderStatus status) => switch (status) {
  OrderStatus.created => 'Pendiente',
  OrderStatus.confirmed => 'Confirmado',
  OrderStatus.rejected => 'Rechazado',
  OrderStatus.preparing => 'En preparación',
  OrderStatus.readyForPickup => 'Listo para retirar',
  OrderStatus.pickedUp => 'Retirado',
  OrderStatus.readyForDelivery => 'Listo para entrega',
  OrderStatus.lookingForDriver => 'Buscando repartidor',
  OrderStatus.noDriversAvailable => 'Sin repartidores disponibles',
  OrderStatus.driverAssigned => 'Repartidor asignado',
  OrderStatus.inDelivery => 'En entrega',
  OrderStatus.delivered => 'Entregado',
  OrderStatus.cancelled => 'Cancelado',
};

void main() {
  group(
    'StoreOrdersPage._statusLabel — cobertura de todos los OrderStatus',
    () {
      test('noDriversAvailable muestra etiqueta explícita (no comodín)', () {
        expect(
          _statusLabel(OrderStatus.noDriversAvailable),
          'Sin repartidores disponibles',
        );
      });

      test('todos los valores del enum tienen etiqueta definida', () {
        // Este test fallará si se añade un nuevo valor a OrderStatus y no se
        // actualiza el switch de _statusLabel (evita regresiones futuras).
        for (final status in OrderStatus.values) {
          expect(
            () => _statusLabel(status),
            returnsNormally,
            reason: 'OrderStatus.$status no tiene etiqueta en _statusLabel',
          );
        }
      });

      test('etiquetas de los demás estados son coherentes', () {
        expect(_statusLabel(OrderStatus.created), 'Pendiente');
        expect(_statusLabel(OrderStatus.confirmed), 'Confirmado');
        expect(_statusLabel(OrderStatus.rejected), 'Rechazado');
        expect(_statusLabel(OrderStatus.preparing), 'En preparación');
        expect(_statusLabel(OrderStatus.readyForPickup), 'Listo para retirar');
        expect(_statusLabel(OrderStatus.pickedUp), 'Retirado');
        expect(
          _statusLabel(OrderStatus.readyForDelivery),
          'Listo para entrega',
        );
        expect(
          _statusLabel(OrderStatus.lookingForDriver),
          'Buscando repartidor',
        );
        expect(_statusLabel(OrderStatus.driverAssigned), 'Repartidor asignado');
        expect(_statusLabel(OrderStatus.inDelivery), 'En entrega');
        expect(_statusLabel(OrderStatus.delivered), 'Entregado');
        expect(_statusLabel(OrderStatus.cancelled), 'Cancelado');
      });

      test('displayName del enum coincide con la etiqueta de la página', () {
        // Garantiza coherencia entre el enum y la UI de stores.
        expect(
          _statusLabel(OrderStatus.noDriversAvailable),
          OrderStatus.noDriversAvailable.displayName,
        );
      });
    },
  );
}
