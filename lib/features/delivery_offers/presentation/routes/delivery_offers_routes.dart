import 'package:flutter/material.dart';

import '../../../../core/router/feature_route_module.dart';
import '../../domain/entities/delivery_negotiation.dart';
import '../pages/historial_entregas_page.dart';
import '../pages/negociacion_entrega_page.dart';

/// Rutas modulares de negociación y seguimiento de entregas.
class DeliveryOffersRoutes implements FeatureRouteModule {
  static const String negociacion = '/entregas/negociacion';
  static const String historial = '/entregas/historial';

  @override
  Map<String, WidgetBuilder> get routes => {
    historial: (context) => const HistorialEntregasPage(),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == negociacion) {
      final args = settings.arguments;
      final negotiationId = args is String
          ? args
          : args is DeliveryNegotiation
          ? args.id
          : null;

      if (negotiationId != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) =>
              NegociacionEntregaPage(negotiationId: negotiationId),
        );
      }
    }

    return null;
  }
}
