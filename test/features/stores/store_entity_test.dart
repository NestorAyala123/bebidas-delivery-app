import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/stores/domain/entities/store.dart';

void main() {
  test('Stores the minimum registration information', () {
    const store = Store(
      id: 'store-1',
      ownerId: 'user-1',
      name: 'Licorería La Esquina',
      address: 'Av. 4 de Noviembre',
      phone: '0991234567',
      latitude: -0.95,
      longitude: -80.72,
      openingHours: {'monday': '09:00-22:00'},
      isOpen: true,
    );

    expect(store.ownerId, 'user-1');
    expect(store.openingHours['monday'], '09:00-22:00');
    expect(store.canAcceptOrders(), isTrue);
  });
}
