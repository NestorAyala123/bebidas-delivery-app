import 'package:flutter/material.dart';

import '../../../../core/router/feature_route_module.dart';
import '../../domain/entities/chat_conversation.dart';
import '../pages/chat_page.dart';
import '../pages/conversations_page.dart';

/// Rutas modulares del chat.
class ChatRoutes implements FeatureRouteModule {
  static const String conversations = '/chat';
  static const String bandeja = '/chat';
  static const String room = '/chat/room';
  static const String conversacion = '/chat/conversacion';

  @override
  Map<String, WidgetBuilder> get routes => {
    conversations: (context) => const ConversationsPage(),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name == room) {
      final args = settings.arguments;
      if (args is! ChatPageArguments) return null;
      return MaterialPageRoute<void>(
        settings: settings,
        builder: (context) => ChatPage(arguments: args),
      );
    }

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
