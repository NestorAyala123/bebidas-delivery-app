/// Lightweight service locator interface to avoid forcing external packages
/// while keeping full dependency injection decoupling.
class ServiceLocator {
  ServiceLocator._();
  static final ServiceLocator instance = ServiceLocator._();

  final Map<Type, dynamic Function()> _factories = {};
  final Map<Type, dynamic> _singletons = {};

  /// Registers a singleton instance
  void registerSingleton<T>(T instance) {
    _singletons[T] = instance;
  }

  /// Registers a lazy singleton factory
  void registerLazySingleton<T>(T Function() factory) {
    _factories[T] = () {
      if (!_singletons.containsKey(T)) {
        _singletons[T] = factory();
      }
      return _singletons[T] as T;
    };
  }

  /// Registers a factory that creates a new instance on every call
  void registerFactory<T>(T Function() factory) {
    _factories[T] = factory;
  }

  /// Resolves an instance of type [T]
  T get<T>() {
    if (_singletons.containsKey(T)) {
      return _singletons[T] as T;
    }
    final factory = _factories[T];
    if (factory != null) {
      return factory() as T;
    }
    throw StateError('ServiceLocator: No registration found for type $T');
  }

  /// Checks if an instance of type [T] is registered
  bool isRegistered<T>() =>
      _singletons.containsKey(T) || _factories.containsKey(T);

  /// Resets all registrations (useful for unit tests)
  void reset() {
    _factories.clear();
    _singletons.clear();
  }
}

/// Shorthand global accessor
final sl = ServiceLocator.instance;

/// Contract for feature modules to register their own dependencies
abstract class FeatureDiModule {
  void registerDependencies(ServiceLocator locator);
}
