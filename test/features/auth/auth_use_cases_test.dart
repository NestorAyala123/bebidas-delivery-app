import 'package:flutter_test/flutter_test.dart';

import 'package:bebidas_delivery_app/features/auth/application/dtos/auth_dtos.dart';
import 'package:bebidas_delivery_app/features/auth/application/use_cases/check_access_rules_use_case.dart';
import 'package:bebidas_delivery_app/features/auth/application/use_cases/get_current_user_use_case.dart';
import 'package:bebidas_delivery_app/features/auth/application/use_cases/login_use_case.dart';
import 'package:bebidas_delivery_app/features/auth/application/use_cases/logout_use_case.dart';
import 'package:bebidas_delivery_app/features/auth/application/use_cases/register_use_case.dart';
import 'package:bebidas_delivery_app/features/auth/infrastructure/mock_auth_repository.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/app_user.dart';
import 'package:bebidas_delivery_app/features/users/domain/entities/role.dart';

void main() {
  late MockAuthRepository repository;

  setUp(() => repository = MockAuthRepository());

  test('logs in with each seeded role', () async {
    final result = await LoginUseCase(repository)(
      email: 'comercio@demo.com',
      password: 'comercio123',
    );

    expect(result.isSuccess, isTrue);
    expect(result.dataOrNull?.role.name, 'store');
  });

  test('registers, restores and logs out a user', () async {
    final registerResult = await RegisterUseCase(repository)(
      const RegisterRequest(
        email: 'new@example.com',
        password: 'password-123',
        name: 'Nuevo usuario',
        role: UserRole.driver,
      ),
    );

    expect(registerResult.isSuccess, isTrue);
    expect(
      (await GetCurrentUserUseCase(repository)()).dataOrNull?.user.name,
      'Nuevo usuario',
    );

    expect((await LogoutUseCase(repository)()).isSuccess, isTrue);
    expect((await GetCurrentUserUseCase(repository)()).dataOrNull, isNull);
  });

  test('rejects malformed credentials before reaching repository', () async {
    final result = await LoginUseCase(repository)(
      email: 'not-an-email',
      password: 'short',
    );

    expect(result.isFailure, isTrue);
  });

  test('checks role permissions through the application boundary', () {
    const checkAccess = CheckAccessRulesUseCase();

    expect(
      checkAccess(
        role: Role.store,
        permission: Permission.manageCatalog,
      ).dataOrNull,
      isTrue,
    );
    expect(
      checkAccess(
        role: Role.client,
        permission: Permission.manageCatalog,
      ).dataOrNull,
      isFalse,
    );
  });
}
