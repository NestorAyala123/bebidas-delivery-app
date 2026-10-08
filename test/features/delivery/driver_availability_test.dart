import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/get_driver_availability_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/domain/use_cases/set_driver_availability_use_case.dart';
import 'package:bebidas_delivery_app/features/delivery/infrastructure/repositories/mock_delivery_repository.dart';
import 'package:bebidas_delivery_app/features/delivery/presentation/pages/driver_availability_page.dart';

void main() {
  testWidgets(
    'DriverAvailabilityPage muestra Disponible y cambia a Ocupado y de vuelta a Disponible',
    (WidgetTester tester) async {
      final repository = MockDeliveryRepository(
        latency: Duration.zero,
        seedTime: DateTime(2026, 1, 15),
      );
      final getUseCase = GetDriverAvailabilityUseCase(repository);
      final setUseCase = SetDriverAvailabilityUseCase(repository);

      await tester.pumpWidget(
        MaterialApp(
          home: DriverAvailabilityPage(
            driverId: 'driver-1',
            getAvailabilityUseCase: getUseCase,
            setAvailabilityUseCase: setUseCase,
          ),
        ),
      );
      await tester.pumpAndSettle();

      // 1. Al cargar se muestra "Disponible"
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Cambiar a Ocupado'), findsOneWidget);

      // 2. Tocar el botón para alternar estado
      await tester.tap(find.text('Cambiar a Ocupado'));
      await tester.pumpAndSettle();

      // 3. Verificar que se muestra "Ocupado"
      expect(find.text('Ocupado'), findsOneWidget);
      expect(find.text('Cambiar a Disponible'), findsOneWidget);

      // 4. Tocar de nuevo
      await tester.tap(find.text('Cambiar a Disponible'));
      await tester.pumpAndSettle();

      // 5. Verificar que vuelve a "Disponible"
      expect(find.text('Disponible'), findsOneWidget);
      expect(find.text('Cambiar a Ocupado'), findsOneWidget);
    },
  );
}
