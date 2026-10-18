import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../dtos/auth_dtos.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';

class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<Result<UserSession, Failure>> call(RegisterRequest request) {
    if (request.name.trim().isEmpty) {
      return Future.value(
        const FailureResult(ValidationFailure('El nombre es obligatorio')),
      );
    }

    if (request.email.trim().isEmpty || !request.email.contains('@')) {
      return Future.value(
        const FailureResult(ValidationFailure('Formato de correo inválido')),
      );
    }

    if (request.password.trim().length < 6) {
      return Future.value(
        const FailureResult(
          ValidationFailure('La contraseña debe tener al menos 6 caracteres'),
        ),
      );
    }

    return repository.register(
      email: request.email.trim(),
      password: request.password,
      name: request.name.trim(),
    );
  }
}
