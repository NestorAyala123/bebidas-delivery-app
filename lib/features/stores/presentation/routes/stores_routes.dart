import 'package:flutter/widgets.dart';

import '../../../../core/router/feature_route_module.dart';
import '../../../auth/presentation/widgets/role_access_gate.dart';
import '../../../users/domain/entities/role.dart';
import '../pages/store_management_page.dart';
import '../pages/store_orders_page.dart';

class StoresRoutes implements FeatureRouteModule {
  static const String management = '/stores';
  static const String orders = '/stores/orders';

  @override
  Map<String, WidgetBuilder> get routes => {
    management: (context) => RoleAccessGate(
      title: 'Administración del comercio',
      allowedRoles: const {Role.store},
      child: const StoreManagementPage(),
    ),
    orders: (context) => RoleAccessGate(
      title: 'Pedidos del comercio',
      allowedRoles: const {Role.store},
      child: const StoreOrdersPage(),
    ),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) => null;
}
