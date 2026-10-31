import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/event_services/domain/entities/consulta_servicio.dart';

void main() {
  group('ConsultaServicio Entity Tests', () {
    const consulta = ConsultaServicio(
      id: 'consulta-001',
      serviceId: 'svc-001',
      serviceTitle: 'Bartender Profesional',
      providerId: 'prov-001',
      customerId: 'customer-001',
      customerName: 'David Vera',
      customerPhone: '0991234567',
      eventDate: '2026-12-15',
      guestCount: 80,
      location: 'Manta, Manabí',
      notes: 'Barra frente a la piscina',
      budgetOffered: 250.0,
      createdAt: '2026-11-01T10:00:00Z',
    );

    test('el estado por defecto es pendiente', () {
      expect(consulta.status, equals(ConsultaServicioStatus.pendiente));
    });

    test('copyWith actualiza el estado y conserva el resto de campos', () {
      final updated = consulta.copyWith(
        status: ConsultaServicioStatus.respondida,
        budgetOffered: 300.0,
      );

      expect(updated.status, equals(ConsultaServicioStatus.respondida));
      expect(updated.budgetOffered, equals(300.0));
      expect(updated.id, equals(consulta.id));
      expect(updated.serviceTitle, equals(consulta.serviceTitle));
      expect(updated.guestCount, equals(consulta.guestCount));
    });

    test('igualdad y hashCode se basan en el ID de la consulta', () {
      const sameId = ConsultaServicio(
        id: 'consulta-001',
        serviceId: 'otro-servicio',
        serviceTitle: 'Otro título',
        providerId: 'otro-proveedor',
        customerId: 'otro-cliente',
        customerName: 'Otro Cliente',
        customerPhone: '0987654321',
        eventDate: '2026-12-20',
        guestCount: 10,
        location: 'Portoviejo',
        createdAt: '2026-11-02T10:00:00Z',
      );

      expect(consulta, equals(sameId));
      expect(consulta.hashCode, equals(sameId.hashCode));
    });

    test('toString incluye el servicio y el estado', () {
      expect(consulta.toString(), contains('Bartender Profesional'));
      expect(consulta.toString(), contains('pendiente'));
    });
  });
}
