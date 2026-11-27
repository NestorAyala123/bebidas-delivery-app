import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/widgets/session_gate.dart';
import '../../../users/application/use_cases/list_contacts_use_case.dart';
import '../../../users/domain/entities/app_user.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../application/dtos/chat_dtos.dart';
import '../../application/use_cases/create_conversation_use_case.dart';
import '../../application/use_cases/list_conversations_use_case.dart';
import '../../application/use_cases/watch_unread_messages_use_case.dart';
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
  List<ConversationSummary>? _items;
  String? _errorMessage;
  StreamSubscription<UnreadMessages>? _changes;

  @override
  void initState() {
    super.initState();
    _reload();
    // New messages or reads elsewhere refresh the inbox in place.
    _changes = sl
        .get<WatchUnreadMessagesUseCase>()(requester: widget.requester)
        .dataOrNull
        ?.skip(1)
        .listen((_) => _reload());
  }

  @override
  void dispose() {
    _changes?.cancel();
    super.dispose();
  }

  Future<void> _reload() async {
    final result = await sl.get<ListConversationsUseCase>()(
      requester: widget.requester,
    );
    if (!mounted) return;
    setState(() {
      _items = result.dataOrNull ?? _items;
      _errorMessage = result.failureOrNull?.message;
    });
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
    if (mounted) _reload();
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
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Mensajes'),
            Text(
              'Tus conversaciones',
              style: Theme.of(context).textTheme.labelMedium,
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _startConversation,
        icon: const Icon(Icons.add_comment_outlined),
        label: const Text('Nueva conversación'),
      ),
      body: _buildBody(context),
    );
  }

  Widget _buildBody(BuildContext context) {
    final items = _items;
    if (items == null) {
      if (_errorMessage != null) {
        return _InboxStatus(
          icon: Icons.cloud_off_outlined,
          title: 'No se pudieron cargar tus mensajes',
          message: _errorMessage!,
          actionLabel: 'Intentar de nuevo',
          onAction: _reload,
        );
      }
      return const _InboxStatus(
        loading: true,
        title: 'Cargando conversaciones',
        message: 'Enseguida verás tus mensajes aquí.',
      );
    }
    if (items.isEmpty) {
      return _InboxStatus(
        icon: Icons.forum_outlined,
        title: 'Aún no tienes conversaciones',
        message: 'Inicia un chat para coordinar pedidos o resolver dudas.',
        actionLabel: 'Nueva conversación',
        onAction: _startConversation,
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 96),
      itemCount: items.length,
      separatorBuilder: (_, _) => const SizedBox(height: 8),
      itemBuilder: (context, index) => _ConversationTile(
        item: items[index],
        myId: widget.requester.id,
        onTap: () =>
            _openRoom(items[index].conversation.id, items[index].title),
      ),
    );
  }
}

class _ConversationTile extends StatelessWidget {
  final ConversationSummary item;
  final String myId;
  final VoidCallback onTap;

  const _ConversationTile({
    required this.item,
    required this.myId,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final colors = theme.colorScheme;
    final unread = item.unreadCount;
    final last = item.lastMessage;
    final preview = last == null
        ? item.kindLabel
        : '${last.senderId == myId ? 'Tú: ' : ''}${last.text}';
    return Card(
      elevation: 0,
      color: unread > 0
          ? colors.primaryContainer.withAlpha(90)
          : colors.surface,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(18),
        side: BorderSide(color: colors.outlineVariant.withAlpha(120)),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
        leading: CircleAvatar(
          backgroundColor: colors.primaryContainer,
          foregroundColor: colors.onPrimaryContainer,
          child: Icon(_kindIcon(item.conversation.type)),
        ),
        title: Text(
          item.title,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: theme.textTheme.titleSmall?.copyWith(
            fontWeight: unread > 0 ? FontWeight.w700 : FontWeight.w600,
          ),
        ),
        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4),
          child: Text(
            preview,
            maxLines: 2,
            overflow: TextOverflow.ellipsis,
            style: TextStyle(
              color: unread > 0 ? colors.onSurface : colors.onSurfaceVariant,
              fontWeight: unread > 0 ? FontWeight.w500 : FontWeight.normal,
            ),
          ),
        ),
        trailing: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.end,
          children: [
            if (last != null)
              Text(_shortTime(last.sentAt), style: theme.textTheme.labelSmall),
            if (unread > 0) ...[
              const SizedBox(height: 6),
              Semantics(
                label: '$unread sin leer',
                child: Badge(
                  backgroundColor: colors.primary,
                  label: Text('$unread'),
                ),
              ),
            ],
          ],
        ),
        onTap: onTap,
      ),
    );
  }
}

class _InboxStatus extends StatelessWidget {
  final IconData? icon;
  final String title;
  final String message;
  final bool loading;
  final String? actionLabel;
  final VoidCallback? onAction;

  const _InboxStatus({
    this.icon,
    required this.title,
    required this.message,
    this.loading = false,
    this.actionLabel,
    this.onAction,
  });

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 360),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              if (loading)
                CircularProgressIndicator(color: colors.primary)
              else
                Icon(
                  icon ?? Icons.chat_bubble_outline,
                  size: 44,
                  color: colors.primary,
                ),
              const SizedBox(height: 16),
              Text(
                title,
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 8),
              Text(
                message,
                textAlign: TextAlign.center,
                style: TextStyle(color: colors.onSurfaceVariant),
              ),
              if (actionLabel != null && onAction != null) ...[
                const SizedBox(height: 16),
                FilledButton.tonalIcon(
                  onPressed: onAction,
                  icon: const Icon(Icons.add_comment_outlined),
                  label: Text(actionLabel!),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

String _shortTime(DateTime value) {
  final local = value.toLocal();
  String two(int n) => n.toString().padLeft(2, '0');
  return '${two(local.hour)}:${two(local.minute)}';
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
