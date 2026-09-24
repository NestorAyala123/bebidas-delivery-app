import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';

class LoginUseCase {
  final AuthRepository repository;

  const LoginUseCase(this.repository);

  Future<Result<UserSession, Failure>> call({
    required String email,
    required String password,
  }) {
    if (email.trim().isEmpty || !email.contains('@')) {
      return Future.value(
        const FailureResult(ValidationFailure('Formato de correo inválido')),
      );
    }
    if (password.trim().length < 6) {
      return Future.value(
        const FailureResult(
          ValidationFailure('La contraseña debe tener al menos 6 caracteres'),
        ),
      );
    }

    return repository.login(email: email.trim(), password: password);
  }
}
