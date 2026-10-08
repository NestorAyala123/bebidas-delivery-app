import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../users/domain/entities/app_user.dart';
import '../domain/entities/user_session.dart';
import '../domain/repositories/auth_repository.dart';

/// In-memory mock adapter for authentication scaffolding and UI testing.
class MockAuthRepository implements AuthRepository {
  UserSession? _session;

  @override
  Future<Result<UserSession, Failure>> login({
    required String email,
    required String password,
  }) async {
    if (password.trim().isEmpty) {
      return const FailureResult(ValidationFailure('Credenciales inválidas'));
    }

    // Role resolution based on email prefix/keyword to test all flows
    final normalized = email.trim().toLowerCase();
    final UserRole resolvedRole;
    if (normalized.contains('driver') || normalized.contains('repartidor')) {
      resolvedRole = UserRole.driver;
    } else if (normalized.contains('store') ||
        normalized.contains('comercio') ||
        normalized.contains('tienda')) {
      resolvedRole = UserRole.store;
    } else if (normalized.contains('event') ||
        normalized.contains('evento') ||
        normalized.contains('proveedor')) {
      resolvedRole = UserRole.eventProvider;
    } else {
      resolvedRole = UserRole.client;
    }

    final session = UserSession(
      userId: 'mock-user-1',
      email: normalized,
      token: 'mock-token-xyz-123',
      role: resolvedRole,
    );
    _session = session;
    return Success(session);
  }

  @override
  Future<Result<UserSession, Failure>> register({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.client,
  }) async {
    if (name.trim().isEmpty) {
      return const FailureResult(
        ValidationFailure('El nombre es obligatorio'),
      );
    }
    final session = UserSession(
      userId: 'mock-user-registered',
      email: email.trim(),
      token: 'mock-token-registered',
      role: role,
    );
    _session = session;
    return Success(session);
  }

  @override
  Future<Result<void, Failure>> logout() async {
    _session = null;
    return const Success(null);
  }

  @override
  Future<Result<UserSession?, Failure>> getCurrentSession() async =>
      Success(_session);
}
