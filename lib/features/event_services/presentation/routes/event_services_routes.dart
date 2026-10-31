import 'package:flutter/material.dart';

import '../../../../core/router/feature_route_module.dart';
import '../../domain/entities/ficha_servicio.dart';
import '../pages/detalle_ficha_page.dart';
import '../pages/listado_servicios_page.dart';
import '../pages/publicar_ficha_page.dart';

/// Rutas modulares para el módulo de Servicios de Eventos (Adriano).
class EventServicesRoutes implements FeatureRouteModule {
  static const String listado = '/eventos';
  static const String publicar = '/eventos/publicar';
  static const String detalle = '/eventos/detalle';

  @override
  Map<String, WidgetBuilder> get routes => {
        listado: (context) => const ListadoServiciosPage(),
        publicar: (context) => const PublicarFichaPage(),
      };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == detalle) {
      final ficha = settings.arguments as FichaServicio?;
      if (ficha != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => DetalleFichaPage(ficha: ficha),
        );
      }
    }
    return null;
  }
}

