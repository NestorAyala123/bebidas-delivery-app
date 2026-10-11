import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection/injection_container.dart';
import 'app/router/app_router.dart';
import 'features/auth/di/auth_di.dart';
import 'features/auth/presentation/routes/auth_routes.dart';
import 'features/stores/di/stores_products_di.dart';
import 'features/stores/presentation/routes/stores_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register modular feature routes
  AppRouter.registerModules([AuthRoutes(), StoresRoutes()]);

  // Register modular dependency injection modules
  await InjectionContainer.init([AuthDi(), StoresProductsDi()]);

  runApp(const BebidasDeliveryApp());
}
