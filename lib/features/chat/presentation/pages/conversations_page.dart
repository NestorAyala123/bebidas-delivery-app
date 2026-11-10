import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/widgets/session_gate.dart';
import '../../../users/application/use_cases/list_contacts_use_case.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../application/dtos/chat_dtos.dart';
import '../../application/use_cases/create_conversation_use_case.dart';
import '../../application/use_cases/list_conversations_use_case.dart';
import '../../domain/entities/conversation.dart';
import '../../domain/services/conversation_policy.dart';
import '../routes/chat_routes.dart';
import 'chat_page.dart';

class ConversationsPage extends StatelessWidget {
  const ConversationsPage({super.key});

  @override
  Widget build(BuildContext context) => SessionGate(
    title: 'Mensajes',
    builder: (context, identity) => _ConversationsView(requester: identity),
  );
}

class _ConversationsView extends StatefulWidget {
  final IdentityContract requester;

  const _ConversationsView({required this.requester});

  @override
  State<_ConversationsView> createState() => _ConversationsViewState();
}

class _ConversationsViewState extends State<_ConversationsView> {
  late Future<List<ConversationSummary>> _conversations = _load();

  Future<List<ConversationSummary>> _load() async {
    final result = await sl.get<ListConversationsUseCase>()(
      requester: widget.requester,
    );
    return result.fold(
      onSuccess: (items) => items,
      onFailure: (failure) => throw failure,
    );
  }

  Future<void> _openRoom(String conversationId, String title) async {
    await Navigator.pushNamed(
      context,
      ChatRoutes.room,
      arguments: ChatPageArguments(
        conversationId: conversationId,
        title: title,
      ),
    );
    if (mounted) setState(() => _conversations = _load());
  }

  Future<void> _startConversation() async {
    final requester = widget.requester;
    final contacts = await sl.get<ListContactsUseCase>()(requester: requester);
    if (!mounted) return;
    // Only people this role is allowed to talk to (see ConversationPolicy).
    final list = (contacts.dataOrNull ?? const <IdentityContract>[])
        .where(
          (c) => ConversationPolicy.canTalkDirectly(
            requester.rbacRole,
            c.rbacRole,
          ),
        )
        .toList();
    final selected = await showModalBottomSheet<IdentityContract>(
      context: context,
      builder: (context) => SafeArea(
        child: list.isEmpty
            ? const Padding(
                padding: EdgeInsets.all(24),
                child: Text('No hay usuarios con los que puedas conversar'),
              )
            : ListView(
                shrinkWrap: true,
                children: [
                  const ListTile(title: Text('Conversar con')),
                  for (final contact in list)
                    ListTile(
                      leading: const Icon(Icons.person_outline),
                      title: Text(contact.displayName),
                      subtitle: Text(_roleLabel(contact.role)),
                      onTap: () => Navigator.pop(context, contact),
                    ),
                ],
              ),
      ),
    );
    if (selected == null || !mounted) return;

    final now = DateTime.now();
    final result = await sl.get<CreateConversationUseCase>()(
      CreateConversationRequest(
        type: ConversationType.direct,
        participants: [
          ConversationParticipant(
            userId: requester.id,
            role: requester.rbacRole.value,
            joinedAt: now,
          ),
          ConversationParticipant(
            userId: selected.id,
            role: selected.rbacRole.value,
            joinedAt: now,
          ),
        ],
      ),
      requester: requester,
    );
    if (!mounted) return;
    result.fold(
      onSuccess: (conversation) =>
          _openRoom(conversation.id, selected.displayName),
      onFailure: (failure) =>
          ScaffoldMessenger.of(context)
              .showSnackBar(SnackBar(content: Text(failure.message))),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mensajes')),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startConversation,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Nueva conversación'),
      ),
      body: FutureBuilder<List<ConversationSummary>>(
        future: _conversations,
        builder: (context, snapshot) {
          if (snapshot.connectionState != ConnectionState.done) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return const Center(child: Text('No se pudo cargar tus mensajes'));
          }
          final items = snapshot.data ?? const [];
          if (items.isEmpty) {
            return const Center(
              child: Text('Aún no tienes conversaciones. Inicia una.'),
            );
          }
          return ListView.separated(
            itemCount: items.length,
            separatorBuilder: (_, _) => const Divider(height: 1),
            itemBuilder: (context, index) {
              final item = items[index];
              return ListTile(
                leading: CircleAvatar(
                  child: Icon(_kindIcon(item.conversation.type)),
                ),
                title: Text(item.title),
                subtitle: Text(item.kindLabel),
                onTap: () => _openRoom(item.conversation.id, item.title),
              );
            },
          );
        },
      ),
    );
  }
}

IconData _kindIcon(ConversationType type) => switch (type) {
  ConversationType.storeInquiry => Icons.storefront_outlined,
  ConversationType.serviceInquiry => Icons.celebration_outlined,
  ConversationType.orderSupport => Icons.receipt_long_outlined,
  ConversationType.direct => Icons.chat_outlined,
};

String _roleLabel(UserRole role) => switch (role) {
  UserRole.client => 'Cliente',
  UserRole.store => 'Comercio',
  UserRole.driver => 'Repartidor',
  UserRole.eventProvider => 'Proveedor de eventos',
};
