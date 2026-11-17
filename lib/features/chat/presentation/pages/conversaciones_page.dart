import 'package:flutter/material.dart';

import '../../domain/entities/chat_conversation.dart';
import '../chat_controller_factory.dart';
import '../controllers/chat_controller.dart';
import 'chat_page.dart';

/// Bandeja de entrada del chat con comercios, proveedores y repartidores.
class ConversacionesPage extends StatefulWidget {
  final ChatController? controller;

  const ConversacionesPage({super.key, this.controller});

  @override
  State<ConversacionesPage> createState() => _ConversacionesPageState();
}

class _ConversacionesPageState extends State<ConversacionesPage> {
  late final ChatController _controller;
  late final bool _ownsController;

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? buildChatController();
    _controller.addListener(_onUpdate);
    _controller.loadConversations();
  }

  void _onUpdate() {
    if (mounted) setState(() {});
  }

  @override
  void dispose() {
    _controller.removeListener(_onUpdate);
    if (_ownsController) {
      _controller.dispose();
    }
    super.dispose();
  }

  Future<void> _open(ChatConversation conversation) async {
    await Navigator.push<void>(
      context,
      MaterialPageRoute(
        builder: (_) =>
            ChatPage(conversation: conversation, controller: _controller),
      ),
    );
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final conversations = _controller.conversations;
    final notification = _controller.latestNotification;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Mensajes'),
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        actions: [
          if (_controller.totalUnread > 0)
            Center(
              child: Container(
                margin: const EdgeInsets.only(right: 16),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  '${_controller.totalUnread} nuevos',
                  style: const TextStyle(
                    color: Colors.black87,
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
        ],
      ),
      body: Column(
        children: [
          if (notification != null)
            MaterialBanner(
              backgroundColor: Colors.amber.shade100,
              leading: const Icon(
                Icons.notifications_active,
                color: Colors.black87,
              ),
              content: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    notification.title,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  Text(notification.body, style: const TextStyle(fontSize: 12)),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: _controller.dismissNotification,
                  child: const Text('Cerrar aviso'),
                ),
              ],
            ),
          Expanded(
            child: _controller.isLoading && conversations.isEmpty
                ? const Center(child: CircularProgressIndicator())
                : conversations.isEmpty
                ? _EmptyChats(colorScheme: colorScheme)
                : ListView.separated(
                    itemCount: conversations.length,
                    separatorBuilder: (_, _) => const Divider(height: 1),
                    itemBuilder: (context, index) {
                      final conversation = conversations[index];
                      return ListTile(
                        leading: CircleAvatar(
                          backgroundColor: colorScheme.primaryContainer,
                          child: Icon(
                            _iconForRole(conversation.role),
                            color: colorScheme.primary,
                          ),
                        ),
                        title: Text(
                          conversation.counterpartName,
                          style: TextStyle(
                            fontWeight: conversation.hasUnreadMessages
                                ? FontWeight.bold
                                : FontWeight.w500,
                          ),
                        ),
                        subtitle: Text(
                          conversation.lastMessage?.text ??
                              'Sin mensajes todavía',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        trailing: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text(
                              _formatTime(conversation.updatedAt),
                              style: const TextStyle(
                                fontSize: 10,
                                color: Colors.grey,
                              ),
                            ),
                            if (conversation.hasUnreadMessages)
                              Container(
                                margin: const EdgeInsets.only(top: 4),
                                padding: const EdgeInsets.symmetric(
                                  horizontal: 7,
                                  vertical: 2,
                                ),
                                decoration: BoxDecoration(
                                  color: colorScheme.primary,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Text(
                                  '${conversation.unreadCount}',
                                  style: TextStyle(
                                    color: colorScheme.onPrimary,
                                    fontSize: 10,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                          ],
                        ),
                        onTap: () => _open(conversation),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }

  static IconData _iconForRole(ChatPeerRole role) => switch (role) {
    ChatPeerRole.store => Icons.storefront,
    ChatPeerRole.eventProvider => Icons.celebration,
    ChatPeerRole.driver => Icons.delivery_dining,
    ChatPeerRole.support => Icons.support_agent,
  };

  static String _formatTime(DateTime time) {
    final now = DateTime.now();
    if (now.difference(time).inDays == 0) {
      return '${time.hour.toString().padLeft(2, '0')}:'
          '${time.minute.toString().padLeft(2, '0')}';
    }
    return '${time.day}/${time.month}';
  }
}

class _EmptyChats extends StatelessWidget {
  final ColorScheme colorScheme;

  const _EmptyChats({required this.colorScheme});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.forum_outlined,
              size: 64,
              color: colorScheme.primary.withAlpha(120),
            ),
            const SizedBox(height: 16),
            const Text(
              'Todavía no tienes conversaciones',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              'Abre el chat desde un comercio, una ficha de servicios de '
              'eventos o una entrega en curso.',
              textAlign: TextAlign.center,
              style: TextStyle(color: colorScheme.onSurfaceVariant),
            ),
          ],
        ),
      ),
    );
  }
}
