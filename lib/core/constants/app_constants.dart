/// Global system constants (cross-cutting only).
/// Do NOT store feature-specific business rules here.
class AppConstants {
  AppConstants._();

  static const String appName = 'Bebidas Delivery';
  static const String appVersion = '1.0.0';

  // Environment & Collections defaults
  static const int connectTimeoutSeconds = 15;
  static const int locationUpdateIntervalSeconds = 10;
}
