import 'package:flutter/material.dart';
import '../../core/router/feature_route_module.dart';

class AppRouter {
  AppRouter._();

  static const String initialRoute = '/';

  /// List of registered feature route modules.
  /// Each developer registers their module here or through modular initialization.
  static final List<FeatureRouteModule> _modules = [];

  static void registerModule(FeatureRouteModule module) {
    _modules.add(module);
  }

  static void registerModules(List<FeatureRouteModule> modules) {
    _modules.addAll(modules);
  }

  /// Aggregates static routes from all feature modules
  static Map<String, WidgetBuilder> get routes {
    final Map<String, WidgetBuilder> combinedRoutes = {};
    for (final module in _modules) {
      combinedRoutes.addAll(module.routes);
    }
    return combinedRoutes;
  }

  /// Handles dynamic routes or routes requiring argument extraction
  static Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    for (final module in _modules) {
      final route = module.onGenerateRoute(settings);
      if (route != null) {
        return route;
      }
    }

    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => Scaffold(
        appBar: AppBar(title: const Text('Ruta no encontrada')),
        body: Center(
          child: Text('No existe la ruta: ${settings.name}'),
        ),
      ),
    );
  }
}
