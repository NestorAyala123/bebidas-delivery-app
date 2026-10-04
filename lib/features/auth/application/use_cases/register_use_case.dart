import '../../../../core/errors/failures.dart';
import '../../../../core/result/result.dart';
import '../../domain/entities/user_session.dart';
import '../../domain/repositories/auth_repository.dart';
import '../dtos/auth_dtos.dart';

class RegisterUseCase {
  final AuthRepository repository;

  const RegisterUseCase(this.repository);

  Future<Result<UserSession, Failure>> call(RegisterRequest request) {
    final email = request.email.trim();
    if (!email.contains('@') || request.name.trim().isEmpty) {
      return Future.value(
        const FailureResult(
          ValidationFailure('Nombre y correo son obligatorios'),
        ),
      );
    }
    if (request.password.length < 8) {
      return Future.value(
        const FailureResult(
          ValidationFailure('La contraseña debe tener al menos 8 caracteres'),
        ),
      );
    }
    return repository.register(
      email: email,
      password: request.password,
      name: request.name.trim(),
      role: request.role,
    );
  }
}
