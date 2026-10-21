import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../application/dtos/chat_dtos.dart';
import '../../application/use_cases/send_message_use_case.dart';
import '../../application/use_cases/watch_messages_use_case.dart';
import '../../domain/entities/chat_message.dart';

class ChatPageArguments {
  final String conversationId;
  final String title;

  const ChatPageArguments({required this.conversationId, required this.title});
}

class ChatPage extends StatefulWidget {
  final ChatPageArguments arguments;

  const ChatPage({super.key, required this.arguments});

  @override
  State<ChatPage> createState() => _ChatPageState();
}

class _ChatPageState extends State<ChatPage> {
  final _auth = sl.get<AuthController>();
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
    final requester = _auth.identity;
    if (requester == null) {
      setState(() => _error = 'Inicia sesión para ver esta conversación');
      return;
    }
    final result = await sl.get<WatchMessagesUseCase>()(
      widget.arguments.conversationId,
      requester: requester,
    );
    if (!mounted) return;
    setState(() {
      _messages = result.dataOrNull;
      _error = result.failureOrNull?.message;
    });
  }

  Future<void> _send() async {
    final requester = _auth.identity;
    if (requester == null || _input.text.trim().isEmpty) return;
    setState(() => _sending = true);
    final result = await sl.get<SendMessageUseCase>()(
      SendMessageRequest(
        conversationId: widget.arguments.conversationId,
        senderId: requester.id,
        text: _input.text,
      ),
      requester: requester,
    );
    if (!mounted) return;
    setState(() => _sending = false);
    result.fold(
      onSuccess: (_) => _input.clear(),
      onFailure: (failure) => ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    final myId = _auth.identity?.id;
    return Scaffold(
      appBar: AppBar(title: Text(widget.arguments.title)),
      body: _error != null
          ? Center(child: Text(_error!))
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
                _Composer(
                  controller: _input,
                  sending: _sending,
                  onSend: _send,
                ),
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
