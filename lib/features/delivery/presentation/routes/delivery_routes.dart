import 'package:flutter/widgets.dart';

import '../../../../core/router/feature_route_module.dart';
import '../../../auth/presentation/widgets/session_gate.dart';
import '../pages/delivery_driver_ratings_page.dart';
import '../pages/delivery_history_page.dart';
import '../pages/delivery_offers_page.dart';

/// Rutas del módulo Delivery.
class DeliveryRoutes implements FeatureRouteModule {
  static const String offers = '/delivery';
  static const String history = '/delivery/history';
  static const String driverRatings = '/delivery/ratings';

  @override
  Map<String, WidgetBuilder> get routes => {
    offers: (context) => SessionGate(
      title: 'Delivery',
      builder: (context, identity) => DeliveryOffersPage(identity: identity),
    ),
    history: (context) => SessionGate(
      title: 'Historial',
      builder: (context, identity) => DeliveryHistoryPage(identity: identity),
    ),
    driverRatings: (context) => SessionGate(
      title: 'Mis Calificaciones',
      builder: (context, identity) =>
          DeliveryDriverRatingsPage(identity: identity),
    ),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) => null;
}
