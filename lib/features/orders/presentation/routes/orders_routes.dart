import 'package:flutter/material.dart';

import '../../../../core/router/feature_route_module.dart';
import '../../domain/entities/order.dart';
import '../pages/checkout_page.dart';
import '../pages/mis_pedidos_page.dart';
import '../pages/pedido_estado_page.dart';

/// Rutas modulares de pedidos, estado y checkout (David).
class OrdersRoutes implements FeatureRouteModule {
  static const String misPedidos = '/pedidos';
  static const String estado = '/pedidos/estado';
  static const String checkout = '/pedidos/checkout';

  @override
  Map<String, WidgetBuilder> get routes => {
        misPedidos: (context) => const MisPedidosPage(),
      };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == estado) {
      final args = settings.arguments;
      final orderId = args is String ? args : (args as Order?)?.id;
      if (orderId != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => PedidoEstadoPage(orderId: orderId),
        );
      }
    }

    if (settings.name == checkout) {
      final order = settings.arguments as Order?;
      if (order != null) {
        return MaterialPageRoute<bool>(
          settings: settings,
          builder: (context) => CheckoutPage(order: order),
        );
      }
    }

    return null;
  }
}
