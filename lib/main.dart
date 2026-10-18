import 'package:flutter/material.dart';

import 'features/location/di/location_di.dart';
import 'features/location/presentation/routes/location_routes.dart';
import 'features/cart/di/cart_di.dart';

import 'app/app.dart';
import 'app/dependency_injection/injection_container.dart';
import 'app/router/app_router.dart';
import 'features/auth/di/auth_di.dart';
import 'features/auth/presentation/routes/auth_routes.dart';
import 'features/stores/di/stores_products_di.dart';
import 'features/stores/presentation/routes/stores_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Registrar las rutas de los módulos
  AppRouter.registerModules([AuthRoutes(), StoresRoutes(), LocationRoutes()]);

  // Registrar las dependencias de los módulos
  await InjectionContainer.init([
    AuthDi(),
    StoresProductsDi(),
    LocationDi(),
    CartDi(),
  ]);

  runApp(const BebidasDeliveryApp());
}
