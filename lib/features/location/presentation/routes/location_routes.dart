import 'package:flutter/widgets.dart';

import '../../../../core/router/feature_route_module.dart';
import '../pages/mapa_proximo_page.dart';

/// Rutas modulares para el módulo de ubicación y mapas (Adriano).
class LocationRoutes implements FeatureRouteModule {
  static const String mapa = '/mapa';

  @override
  Map<String, WidgetBuilder> get routes => {
    mapa: (context) => const MapaProximoPage(),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }
}
