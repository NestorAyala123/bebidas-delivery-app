import 'package:flutter/material.dart';

import '../../../../core/router/feature_route_module.dart';
import '../pages/chat_page.dart';
import '../pages/conversations_page.dart';

class ChatRoutes implements FeatureRouteModule {
  static const String conversations = '/chat';
  static const String room = '/chat/room';

  @override
  Map<String, WidgetBuilder> get routes => {
    conversations: (context) => const ConversationsPage(),
  };

  @override
  Route<dynamic>? onGenerateRoute(RouteSettings settings) {
    if (settings.name != room) return null;
    final args = settings.arguments;
    if (args is! ChatPageArguments) return null;
    return MaterialPageRoute<void>(
      settings: settings,
      builder: (context) => ChatPage(arguments: args),
    );
  }
}
