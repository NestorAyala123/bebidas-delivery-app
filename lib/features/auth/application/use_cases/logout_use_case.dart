import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/repositories/auth_repository.dart';

class LogoutUseCase {
  final AuthRepository repository;

  const LogoutUseCase(this.repository);

  Future<Result<void, Failure>> call() => repository.logout();
}
