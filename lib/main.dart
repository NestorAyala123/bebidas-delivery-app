import 'package:flutter/material.dart';

import 'app/app.dart';
import 'app/dependency_injection/injection_container.dart';
import 'app/router/app_router.dart';

import 'features/auth/di/auth_di.dart';
import 'features/auth/presentation/routes/auth_routes.dart';
import 'features/delivery/di/delivery_di.dart';
import 'features/delivery/presentation/routes/delivery_routes.dart';
import 'features/event_services/di/event_services_di.dart';
import 'features/event_services/presentation/routes/event_services_routes.dart';
import 'features/location/di/location_di.dart';
import 'features/location/presentation/routes/location_routes.dart';

import 'features/stores/di/stores_products_di.dart';
import 'features/stores/presentation/routes/stores_routes.dart';

import 'features/cart/di/cart_di.dart';
import 'features/orders/di/orders_di.dart';

import 'features/users/di/users_di.dart';

import 'features/chat/di/chat_di.dart';
import 'features/chat/presentation/routes/chat_routes.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Register modular feature routes
  AppRouter.registerModules([
    AuthRoutes(),
    StoresRoutes(),
    LocationRoutes(),
    ChatRoutes(),
    EventServicesRoutes(),
    DeliveryRoutes(),
  ]);

  // Register modular dependency injection modules
  await InjectionContainer.init([
    UsersDi(),
    AuthDi(),
    StoresProductsDi(),
    LocationDi(),
    CartDi(),
    OrdersDi(),
    ChatDi(),
    EventServicesDi(),
    DeliveryDi(),
  ]);

  runApp(const BebidasDeliveryApp());
}
