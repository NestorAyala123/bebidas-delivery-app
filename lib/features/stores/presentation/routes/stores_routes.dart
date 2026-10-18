import 'package:flutter/widgets.dart';

import '../../../../core/router/feature_route_module.dart';
import '../pages/store_management_page.dart';

class StoresRoutes implements FeatureRouteModule {
  static const String management = '/stores';

  @override
  Map<String, WidgetBuilder> get routes => {
    management: (context) => const StoreManagementPage(),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) => null;
}
