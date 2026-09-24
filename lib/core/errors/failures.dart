/// Base class for all domain and application failures.
abstract class Failure {
  final String message;
  final String? code;

  const Failure([this.message = '', this.code]);

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

class ServerFailure extends Failure {
  const ServerFailure([
    super.message = 'Error en el servidor o servicio externo',
    super.code,
  ]);
}

class NetworkFailure extends Failure {
  const NetworkFailure([super.message = 'Sin conexión a internet', super.code]);
}

class ValidationFailure extends Failure {
  const ValidationFailure([
    super.message = 'Error de validación de datos',
    super.code,
  ]);
}

class NotFoundFailure extends Failure {
  const NotFoundFailure([super.message = 'Elemento no encontrado', super.code]);
}

class UnauthorizedFailure extends Failure {
  const UnauthorizedFailure([
    super.message = 'Acción no autorizada o sesión expirada',
    super.code,
  ]);
}

class BusinessRuleFailure extends Failure {
  const BusinessRuleFailure([
    super.message = 'Violación de regla de negocio',
    super.code,
  ]);
}
