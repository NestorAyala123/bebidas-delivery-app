import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/widgets/session_gate.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../application/dtos/chat_dtos.dart';
import '../../application/use_cases/mark_conversation_read_use_case.dart';
import '../../application/use_cases/send_message_use_case.dart';
import '../../application/use_cases/watch_messages_use_case.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../chat_controller_factory.dart';
import '../controllers/chat_controller.dart';

class ChatPageArguments {
  final String conversationId;
  final String title;

  const ChatPageArguments({required this.conversationId, required this.title});
}

/// Pantalla de chat que soporta tanto el flujo de sesión autenticada con
/// [arguments] como el flujo modular reactivo con [conversation] y [controller].
class ChatPage extends StatelessWidget {
  final ChatPageArguments? arguments;
  final ChatConversation? conversation;
  final ChatController? controller;

  const ChatPage({
    super.key,
    this.arguments,
    this.conversation,
    this.controller,
  }) : assert(
         arguments != null || conversation != null,
         'Debe proporcionar arguments o conversation',
       );

  @override
  Widget build(BuildContext context) {
    if (arguments != null) {
      return SessionGate(
        title: arguments!.title,
        builder: (context, identity) =>
            _ChatRoom(arguments: arguments!, requester: identity),
      );
    }

    return _ChatConversationRoom(
      conversation: conversation!,
      controller: controller,
    );
  }
}

// =============================================================================
// Modo 1: Flujo con SessionGate (HEAD / Auth-Users-Chat)
// =============================================================================

class _ChatRoom extends StatefulWidget {
  final ChatPageArguments arguments;
  final IdentityContract requester;

  const _ChatRoom({required this.arguments, required this.requester});

  @override
  State<_ChatRoom> createState() => _ChatRoomState();
}

class _ChatRoomState extends State<_ChatRoom> {
  final _input = TextEditingController();
  Stream<List<ChatMessage>>? _messages;
  String? _error;
  bool _sending = false;

  @override
  void initState() {
    super.initState();
    _open();
  }

  @override
  void dispose() {
    _input.dispose();
    super.dispose();
  }

  Future<void> _open() async {
    final result = await sl.get<WatchMessagesUseCase>()(
      widget.arguments.conversationId,
      requester: widget.requester,
    );
    if (!mounted) return;
    setState(() {
      _messages = result.dataOrNull?.map((messages) {
        _markRead();
        return messages;
      });
      _error = result.failureOrNull?.message;
    });
  }

  void _markRead() {
    if (!sl.isRegistered<MarkConversationReadUseCase>()) return;
    sl.get<MarkConversationReadUseCase>()(
      widget.arguments.conversationId,
      requester: widget.requester,
    );
  }

  Future<void> _send() async {
    if (_sending || _input.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final result = await sl.get<SendMessageUseCase>()(
      SendMessageRequest(
        conversationId: widget.arguments.conversationId,
        senderId: widget.requester.id,
        text: _input.text,
      ),
      requester: widget.requester,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      onSuccess: (_) => _input.clear(),
      onFailure: (failure) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = widget.requester.id;
    return Scaffold(
      appBar: AppBar(title: Text(widget.arguments.title)),
      body: _error != null
          ? Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(_error!, textAlign: TextAlign.center),
              ),
            )
          : _messages == null
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: StreamBuilder<List<ChatMessage>>(
                    stream: _messages,
                    builder: (context, snapshot) {
                      final messages = snapshot.data ?? const [];
                      if (messages.isEmpty) {
                        return const Center(
                          child: Text('Escribe el primer mensaje'),
                        );
                      }
                      return ListView.builder(
                        reverse: true,
                        padding: const EdgeInsets.all(12),
                        itemCount: messages.length,
                        itemBuilder: (context, index) {
                          final message = messages[messages.length - 1 - index];
                          return _Bubble(
                            message: message,
                            mine: message.senderId == myId,
                          );
                        },
                      );
                    },
                  ),
                ),
                _Composer(controller: _input, sending: _sending, onSend: _send),
              ],
            ),
    );
  }
}

class _Bubble extends StatelessWidget {
  final ChatMessage message;
  final bool mine;

  const _Bubble({required this.message, required this.mine});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Align(
      alignment: mine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        constraints: BoxConstraints(
          maxWidth: MediaQuery.sizeOf(context).width * 0.75,
        ),
        decoration: BoxDecoration(
          color: mine ? scheme.primaryContainer : scheme.surfaceContainerHigh,
          borderRadius: BorderRadius.circular(16),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            Text(message.text),
            const SizedBox(height: 2),
            Text(
              _time(message.sentAt),
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _Composer extends StatelessWidget {
  final TextEditingController controller;
  final bool sending;
  final VoidCallback onSend;

  const _Composer({
    required this.controller,
    required this.sending,
    required this.onSend,
  });

  @override
  Widget build(BuildContext context) => SafeArea(
    child: Padding(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 8),
      child: Row(
        children: [
          Expanded(
            child: TextField(
              controller: controller,
              minLines: 1,
              maxLines: 4,
              maxLength: SendMessageUseCase.maxLength,
              textInputAction: TextInputAction.send,
              onSubmitted: (_) => onSend(),
              decoration: const InputDecoration(
                hintText: 'Escribe un mensaje',
                counterText: '',
              ),
            ),
          ),
          const SizedBox(width: 8),
          IconButton.filled(
            onPressed: sending ? null : onSend,
            icon: const Icon(Icons.send),
            tooltip: 'Enviar',
          ),
        ],
      ),
    ),
  );
}

String _time(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
}

// =============================================================================
// Modo 2: Flujo reactivo con ChatController (Ubicación & Servicios)
// =============================================================================

class _ChatConversationRoom extends StatefulWidget {
  final ChatConversation conversation;
  final ChatController? controller;

  const _ChatConversationRoom({required this.conversation, this.controller});

  @override
  State<_ChatConversationRoom> createState() => _ChatConversationRoomState();
}

class _ChatConversationRoomState extends State<_ChatConversationRoom> {
  late final ChatController _controller;
  late final bool _ownsController;
  final TextEditingController _textController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _ownsController = widget.controller == null;
    _controller = widget.controller ?? buildChatController();

    _controller.addListener(_onUpdate);
    if (_ownsController) {
      _controller.loadConversations();
    }
    _controller.openConversation(widget.conversation);
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
    _textController.dispose();
    _scrollController.dispose();
    super.dispose();
  }

  Future<void> _send() async {
    final text = _textController.text.trim();
    if (text.isEmpty) return;

    final sent = await _controller.sendMessage(text);
    if (sent) {
      _textController.clear();
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          0,
          duration: const Duration(milliseconds: 200),
          curve: Curves.easeOut,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final messages = _controller.messages;
    final notification = _controller.latestNotification;

    return Scaffold(
      backgroundColor: colorScheme.surfaceContainerLowest,
      appBar: AppBar(
        backgroundColor: colorScheme.primary,
        foregroundColor: colorScheme.onPrimary,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.conversation.counterpartName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            Text(
              widget.conversation.role.label,
              style: const TextStyle(fontSize: 11),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Simular mensaje entrante',
            icon: const Icon(Icons.mark_unread_chat_alt_outlined),
            onPressed: _controller.simulateIncomingMessage,
          ),
        ],
      ),
      body: Column(
        children: [
          if (widget.conversation.contextLabel.trim().isNotEmpty)
            Container(
              width: double.infinity,
              color: colorScheme.primaryContainer.withAlpha(80),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                widget.conversation.contextLabel,
                style: TextStyle(
                  fontSize: 11,
                  color: colorScheme.onSurfaceVariant,
                ),
              ),
            ),
          if (notification != null)
            MaterialBanner(
              backgroundColor: Colors.amber.shade100,
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
              leading: const Icon(
                Icons.notifications_active,
                color: Colors.black87,
              ),
              actions: [
                TextButton(
                  onPressed: _controller.dismissNotification,
                  child: const Text('Entendido'),
                ),
              ],
            ),
          Expanded(
            child: messages.isEmpty
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Text(
                        'Aún no hay mensajes. Escribe el primero para '
                        'coordinar con ${widget.conversation.counterpartName}.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: colorScheme.onSurfaceVariant),
                      ),
                    ),
                  )
                : ListView.builder(
                    controller: _scrollController,
                    reverse: true,
                    padding: const EdgeInsets.all(12),
                    itemCount: messages.length,
                    itemBuilder: (context, index) {
                      final message = messages[messages.length - 1 - index];
                      final isMine = message.senderId == _controller.userId;
                      return _MessageBubble(message: message, isMine: isMine);
                    },
                  ),
          ),
          if (_controller.errorMessage != null)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Text(
                _controller.errorMessage!,
                style: const TextStyle(color: Colors.red, fontSize: 12),
              ),
            ),
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _textController,
                      textInputAction: TextInputAction.send,
                      maxLength: 500,
                      maxLines: 4,
                      minLines: 1,
                      onSubmitted: (_) => _send(),
                      decoration: const InputDecoration(
                        hintText: 'Escribe un mensaje...',
                        counterText: '',
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  IconButton.filled(
                    tooltip: 'Enviar mensaje',
                    onPressed: _controller.isSending ? null : _send,
                    icon: const Icon(Icons.send),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _MessageBubble extends StatelessWidget {
  final ChatMessage message;
  final bool isMine;

  const _MessageBubble({required this.message, required this.isMine});

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;
    final time =
        '${message.sentAt.hour.toString().padLeft(2, '0')}:'
        '${message.sentAt.minute.toString().padLeft(2, '0')}';

    return Align(
      alignment: isMine ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        constraints: const BoxConstraints(maxWidth: 320),
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
        decoration: BoxDecoration(
          color: isMine
              ? colorScheme.primary
              : colorScheme.surfaceContainerHigh,
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(14),
            topRight: const Radius.circular(14),
            bottomLeft: Radius.circular(isMine ? 14 : 2),
            bottomRight: Radius.circular(isMine ? 2 : 14),
          ),
        ),
        child: Column(
          crossAxisAlignment: isMine
              ? CrossAxisAlignment.end
              : CrossAxisAlignment.start,
          children: [
            if (!isMine && message.senderName.isNotEmpty)
              Text(
                message.senderName,
                style: TextStyle(
                  fontSize: 10,
                  fontWeight: FontWeight.bold,
                  color: colorScheme.primary,
                ),
              ),
            Text(
              message.text,
              style: TextStyle(
                fontSize: 14,
                color: isMine ? colorScheme.onPrimary : colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              time,
              style: TextStyle(
                fontSize: 9,
                color: isMine
                    ? colorScheme.onPrimary.withAlpha(180)
                    : colorScheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}
