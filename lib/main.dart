import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection/injection_container.dart';
import 'app/router/app_router.dart';
import 'features/auth/di/auth_di.dart';
import 'features/auth/presentation/routes/auth_routes.dart';
import 'features/event_services/di/event_services_di.dart';
import 'features/event_services/presentation/routes/event_services_routes.dart';
import 'features/location/di/location_di.dart';
import 'features/location/presentation/routes/location_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register modular feature routes
  AppRouter.registerModules([
    AuthRoutes(),
    LocationRoutes(),
    EventServicesRoutes(),
  ]);

  // Register modular dependency injection modules
  await InjectionContainer.init([
    AuthDi(),
    LocationDi(),
    EventServicesDi(),
  ]);

  runApp(const BebidasDeliveryApp());
}
