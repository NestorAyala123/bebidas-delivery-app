import 'package:flutter/widgets.dart';

/// Contract that each feature must implement to register its routes
/// without causing Git merge conflicts in the main router file.
abstract class FeatureRouteModule {
  /// Named routes provided by this feature.
  Map<String, WidgetBuilder> get routes => const {};

  /// Custom route generator for dynamic routes with arguments.
  Route<dynamic>? onGenerateRoute(RouteSettings settings) => null;
}
