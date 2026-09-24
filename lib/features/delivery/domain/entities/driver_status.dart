/// Operational states of a delivery driver.
enum DriverStatus {
  /// Repartidor conectado y disponible para recibir solicitudes y ofertas
  available,

  /// Repartidor ocupado atendiendo una entrega en curso
  busy,

  /// Repartidor desconectado de la plataforma
  offline;

  bool get isAvailable => this == DriverStatus.available;
  bool get isBusy => this == DriverStatus.busy;
  bool get isOffline => this == DriverStatus.offline;
}
