import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../entities/app_user.dart';

abstract class UserRepository {
  Future<Result<AppUser, Failure>> getUserById(String id);
  Future<Result<void, Failure>> updateProfile(AppUser user);
}
