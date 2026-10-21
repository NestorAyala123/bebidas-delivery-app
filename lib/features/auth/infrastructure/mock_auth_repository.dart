import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../../users/domain/entities/app_user.dart';
import '../../users/infrastructure/in_memory_user_repository.dart';
import '../domain/entities/user_session.dart';
import '../domain/repositories/auth_repository.dart';

/// In-memory adapter for local development and tests. Replace with Firebase/API.
///
/// Credentials live here; user data lives in [InMemoryUserRepository] so that
/// profile edits survive a logout/login cycle.
class MockAuthRepository implements AuthRepository {
  final InMemoryUserRepository users;
  final Map<String, String> _passwords = {
    for (final account in MockAccounts.all) account.email: account.password,
  };
  UserSession? _session;

  MockAuthRepository({InMemoryUserRepository? users})
    : users =
          users ??
          InMemoryUserRepository(MockAccounts.all.map((a) => a.user));

  @override
  Future<Result<UserSession, Failure>> login({
    required String email,
    required String password,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    final user = users.findByEmail(normalizedEmail);
    if (user == null || _passwords[normalizedEmail] != password) {
      return const FailureResult(
        UnauthorizedFailure('Correo o contraseña incorrectos'),
      );
    }
    _session = _sessionFor(user);
    return Success(_session!);
  }

  @override
  Future<Result<UserSession, Failure>> register({
    required String email,
    required String password,
    required String name,
    UserRole role = UserRole.client,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();
    if (name.trim().isEmpty || normalizedEmail.isEmpty) {
      return const FailureResult(ValidationFailure('El nombre es obligatorio'));
    }
    if (users.findByEmail(normalizedEmail) != null) {
      return const FailureResult(
        ValidationFailure('Ya existe una cuenta con ese correo'),
      );
    }
    final user = AppUser(
      id: 'user-${users.length + 1}',
      email: normalizedEmail,
      name: name.trim(),
      role: role,
      createdAt: DateTime.now(),
    );
    users.add(user);
    _passwords[normalizedEmail] = password;
    _session = _sessionFor(user);
    return Success(_session!);
  }

  @override
  Future<Result<void, Failure>> logout() async {
    _session = null;
    return const Success(null);
  }

  @override
  Future<Result<UserSession?, Failure>> getCurrentSession() async =>
      Success(_session);

  UserSession _sessionFor(AppUser user) => UserSession(
    userId: user.id,
    email: user.email,
    token: 'mock-token-${user.id}',
    user: user,
  );
}

class MockAccount {
  final String email;
  final String password;
  final AppUser user;

  const MockAccount({
    required this.email,
    required this.password,
    required this.user,
  });
}

class MockAccounts {
  MockAccounts._();

  static final List<MockAccount> all = [
    _account('cliente@demo.com', 'cliente123', 'Cliente Demo', UserRole.client),
    _account(
      'comercio@demo.com',
      'comercio123',
      'Comercio Demo',
      UserRole.store,
    ),
    _account(
      'repartidor@demo.com',
      'repartidor123',
      'Repartidor Demo',
      UserRole.driver,
    ),
    _account(
      'eventos@demo.com',
      'eventos123',
      'Eventos Demo',
      UserRole.eventProvider,
    ),
  ];

  static MockAccount _account(
    String email,
    String password,
    String name,
    UserRole role,
  ) => MockAccount(
    email: email,
    password: password,
    user: AppUser(
      id: 'seed-${role.name}',
      email: email,
      name: name,
      role: role,
      createdAt: DateTime.utc(2026, 1, 1),
    ),
  );
}
