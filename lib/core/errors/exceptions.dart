/// Base class for all custom exceptions in infrastructure or data layers.
abstract class AppException implements Exception {
  final String message;
  final String? code;

  const AppException([this.message = '', this.code]);

  @override
  String toString() =>
      '$runtimeType: $message${code != null ? ' (Code: $code)' : ''}';
}

class ServerException extends AppException {
  const ServerException([super.message = 'Error en el servidor', super.code]);
}

class NetworkException extends AppException {
  const NetworkException([super.message = 'Sin conexión de red', super.code]);
}

class CacheException extends AppException {
  const CacheException([
    super.message = 'Error de caché o almacenamiento local',
    super.code,
  ]);
}

class DomainException extends AppException {
  const DomainException([
    super.message = 'Error de regla de negocio',
    super.code,
  ]);
}
