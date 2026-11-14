import 'package:flutter/material.dart';

import '../../../../core/router/feature_route_module.dart';
import '../../domain/entities/chat_conversation.dart';
import '../pages/chat_page.dart';
import '../pages/conversaciones_page.dart';

/// Rutas modulares del chat (Nibia).
class ChatRoutes implements FeatureRouteModule {
  static const String bandeja = '/chat';
  static const String conversacion = '/chat/conversacion';

  @override
  Map<String, WidgetBuilder> get routes => {
        bandeja: (context) => const ConversacionesPage(),
      };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == conversacion) {
      final conversation = settings.arguments as ChatConversation?;
      if (conversation != null) {
        return MaterialPageRoute<void>(
          settings: settings,
          builder: (context) => ChatPage(conversation: conversation),
        );
      }
    }
    return null;
  }
}
