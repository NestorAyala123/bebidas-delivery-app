import 'package:flutter/material.dart';

import '../../../../core/router/feature_route_module.dart';
import '../../domain/entities/delivery_destination.dart';
import '../../domain/entities/geo_coordinates.dart';
import '../pages/mapa_proximo_page.dart';
import '../pages/seleccionar_destino_entrega_page.dart';

/// Rutas modulares para el módulo de ubicación y mapas (Adriano).
class LocationRoutes implements FeatureRouteModule {
  static const String mapa = '/mapa';
  static const String seleccionarDestino = '/mapa/seleccionar-destino';

  @override
  Map<String, WidgetBuilder> get routes => {
        mapa: (context) => const MapaProximoPage(),
        seleccionarDestino: (context) =>
            const SeleccionarDestinoEntregaPage(),
      };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == seleccionarDestino) {
      final args = settings.arguments as Map<String, dynamic>?;
      final origin = args?['origin'] as GeoCoordinates?;
      final storeName = args?['storeName'] as String?;
      final initialDest = args?['initialDestination'] as DeliveryDestination?;

      return MaterialPageRoute<DeliveryDestination?>(
        settings: settings,
        builder: (context) => SeleccionarDestinoEntregaPage(
          originStoreCoordinates: origin,
          storeName: storeName,
          initialDestination: initialDest,
        ),
      );
    }
    return null;
  }
}
