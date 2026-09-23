import '../../core/di/service_locator.dart';

class InjectionContainer {
  InjectionContainer._();

  /// Orchestrates the registration of all feature modules.
  /// Each developer provides their own [FeatureDiModule] implementation.
  static Future<void> init(List<FeatureDiModule> modules) async {
    for (final module in modules) {
      module.registerDependencies(sl);
    }
  }
}
