import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/features/auth/application/dtos/auth_dtos.dart';
import 'package:bebidas_delivery_app/features/auth/application/use_cases/register_use_case.dart';
import 'package:bebidas_delivery_app/features/auth/infrastructure/mock_auth_repository.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/role.dart';

void main() {
  group('Identity scaffolding', () {
    test('exposes the documented RBAC permissions', () {
      expect(hasPermission(Role.client, Permission.sendMessage), isTrue);
      expect(hasPermission(Role.client, Permission.manageCatalog), isFalse);
      expect(hasPermission(Role.store, Permission.manageCatalog), isTrue);
      expect(
        hasPermission(Role.driver, Permission.manageDeliveryOffers),
        isTrue,
      );
      expect(
        hasPermission(Role.eventProvider, Permission.manageEventServices),
        isTrue,
      );
    });

    test(
      'register use case returns a mock session for a valid request',
      () async {
        final useCase = RegisterUseCase(MockAuthRepository());

        final result = await useCase(
          const RegisterRequest(
            email: 'client@example.com',
            password: 'password-123',
            name: 'Client',
            role: UserRole.client,
          ),
        );

        expect(result.isSuccess, isTrue);
        expect(result.dataOrNull?.email, 'client@example.com');
      },
    );
  });
}
