import '../../../core/errors/failures.dart';
import '../../../core/result/result.dart';
import '../domain/entities/app_user.dart';
import '../domain/repositories/user_repository.dart';

/// In-memory adapter for local development and tests. Replace with Firestore.
///
/// It is the single source of truth for [AppUser] data; the auth adapter keeps
/// only credentials and resolves users through [add] / [findByEmail].
class InMemoryUserRepository implements UserRepository {
  final Map<String, AppUser> _users = {};

  InMemoryUserRepository([Iterable<AppUser> seed = const []]) {
    for (final user in seed) {
      _users[user.id] = user;
    }
  }

  void add(AppUser user) => _users[user.id] = user;

  int get length => _users.length;

  AppUser? findByEmail(String email) {
    final normalized = email.trim().toLowerCase();
    for (final user in _users.values) {
      if (user.email == normalized) return user;
    }
    return null;
  }

  @override
  Future<Result<AppUser, Failure>> getUserById(String id) async {
    final user = _users[id];
    if (user == null) {
      return const FailureResult(NotFoundFailure('Usuario no encontrado'));
    }
    return Success(user);
  }

  @override
  Future<Result<List<AppUser>, Failure>> listUsers() async =>
      Success(List.unmodifiable(_users.values));

  @override
  Future<Result<void, Failure>> updateProfile(AppUser user) async {
    if (!_users.containsKey(user.id)) {
      return const FailureResult(NotFoundFailure('Usuario no encontrado'));
    }
    _users[user.id] = user;
    return const Success(null);
  }
}
