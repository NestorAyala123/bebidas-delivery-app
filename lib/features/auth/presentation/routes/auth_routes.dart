import 'package:flutter/widgets.dart';

import '../../../../core/router/feature_route_module.dart';
import '../pages/login_page.dart';
import '../pages/welcome_page.dart';

class AuthRoutes implements FeatureRouteModule {
  static const String welcome = '/';
  static const String login = '/login';
  static const String register = '/register';

  @override
  Map<String, WidgetBuilder> get routes => {
    welcome: (context) => const WelcomePage(),
    login: (context) => const LoginPage(),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    return null;
  }
}
