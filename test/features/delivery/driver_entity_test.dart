import 'package:flutter_test/flutter_test.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/entities/driver_status.dart';

void main() {
  group('Driver Domain Entity Tests', () {
    final testCreatedAt = DateTime(2026, 9, 23, 10, 0);

    test('Creates driver with default offline status', () {
      final driver = Driver(
        id: 'drv-001',
        name: 'Carlos Mendoza',
        phoneNumber: '+51987654321',
        createdAt: testCreatedAt,
      );

      expect(driver.id, equals('drv-001'));
      expect(driver.name, equals('Carlos Mendoza'));
      expect(driver.status, equals(DriverStatus.offline));
      expect(driver.canAcceptDeliveries, isFalse);
      expect(driver.status.isOffline, isTrue);
      expect(driver.status.isAvailable, isFalse);
      expect(driver.status.isBusy, isFalse);
    });

    test('Transitions from offline to available', () {
      final driver = Driver(
        id: 'drv-001',
        name: 'Carlos Mendoza',
        status: DriverStatus.offline,
        createdAt: testCreatedAt,
      );

      final availableDriver = driver.copyWithStatus(DriverStatus.available);

      expect(availableDriver.status, equals(DriverStatus.available));
      expect(availableDriver.canAcceptDeliveries, isTrue);
      expect(availableDriver.status.isAvailable, isTrue);
    });

    test('Transitions from available to busy', () {
      final driver = Driver(
        id: 'drv-001',
        name: 'Carlos Mendoza',
        status: DriverStatus.available,
        createdAt: testCreatedAt,
      );

      final busyDriver = driver.copyWithStatus(DriverStatus.busy);

      expect(busyDriver.status, equals(DriverStatus.busy));
      expect(busyDriver.canAcceptDeliveries, isFalse);
      expect(busyDriver.status.isBusy, isTrue);
    });

    test('Transitions from busy back to available or offline', () {
      final driver = Driver(
        id: 'drv-001',
        name: 'Carlos Mendoza',
        status: DriverStatus.busy,
        createdAt: testCreatedAt,
      );

      final availableAgain = driver.copyWithStatus(DriverStatus.available);
      expect(availableAgain.status, equals(DriverStatus.available));
      expect(availableAgain.canAcceptDeliveries, isTrue);

      final offlineDriver = driver.copyWithStatus(DriverStatus.offline);
      expect(offlineDriver.status, equals(DriverStatus.offline));
      expect(offlineDriver.canAcceptDeliveries, isFalse);
    });

    test('Throws assertion error when id or name are empty', () {
      expect(
        () => Driver(id: '', name: 'Carlos', createdAt: testCreatedAt),
        throwsA(isA<AssertionError>()),
      );

      expect(
        () => Driver(id: 'drv-1', name: '  ', createdAt: testCreatedAt),
        throwsA(isA<AssertionError>()),
      );
    });
  });
}
