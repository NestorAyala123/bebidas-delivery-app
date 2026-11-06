import 'package:flutter/widgets.dart';

import '../../../../core/router/feature_route_module.dart';
import '../pages/store_management_page.dart';
import '../pages/store_orders_page.dart';

class StoresRoutes implements FeatureRouteModule {
  static const String management = '/stores';
  static const String orders = '/stores/orders';

  @override
  Map<String, WidgetBuilder> get routes => {
    management: (context) => const StoreManagementPage(),
    orders: (context) => const StoreOrdersPage(),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) => null;
}
