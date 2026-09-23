import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/user_session.dart';

abstract class AuthRepository {
  Future<Result<UserSession, Failure>> login({
    required String email,
    required String password,
  });

  Future<Result<UserSession, Failure>> register({
    required String email,
    required String password,
    required String name,
  });

  Future<Result<void, Failure>> logout();

  Future<Result<UserSession?, Failure>> getCurrentSession();
}
