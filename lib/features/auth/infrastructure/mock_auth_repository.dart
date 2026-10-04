import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../users/domain/entities/app_user.dart';
import '../domain/entities/user_session.dart';
import '../domain/repositories/auth_repository.dart';

/// In-memory adapter for UI scaffolding and tests. Replace with Firebase/API.
class MockAuthRepository implements AuthRepository {
  UserSession? _session;

  @override
  Future<Result<UserSession, Failure>> login({
    required String email,
    required String password,
  }) async {
    if (password.isEmpty) {
      return const FailureResult(ValidationFailure('Credenciales inválidas'));
    }
    final session = UserSession(
      userId: 'mock-user-1',
      email: email,
      token: 'mock-access-token',
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
    if (name.isEmpty) {
      return const FailureResult(ValidationFailure('El nombre es obligatorio'));
    }
    return login(email: email, password: password);
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
