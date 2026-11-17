import 'dart:async';

import 'package:flutter/material.dart';

import '../../../../core/di/service_locator.dart';
import '../../../auth/presentation/state/auth_controller.dart';
import '../../../users/domain/entities/identity_contract.dart';
import '../../application/use_cases/watch_unread_messages_use_case.dart';
import '../routes/chat_routes.dart';

/// "Mensajes" button with the unread count, for any module's app bar.
///
/// While its screen is the visible one, it also shows an in-app notice when a
/// new message arrives. It renders nothing when the chat module is not
/// registered (e.g. other modules' isolated widget tests).
class ChatInboxButton extends StatefulWidget {
  /// Show the in-app notice (SnackBar) for new messages.
  final bool notify;

  const ChatInboxButton({super.key, this.notify = true});

  @override
  State<ChatInboxButton> createState() => _ChatInboxButtonState();
}

class _ChatInboxButtonState extends State<ChatInboxButton> {
  AuthController? _auth;
  StreamSubscription<UnreadMessages>? _subscription;
  String? _watchedUserId;
  UnreadMessages _unread = UnreadMessages.none;

  bool get _available =>
      sl.isRegistered<WatchUnreadMessagesUseCase>() &&
      sl.isRegistered<AuthController>();

  @override
  void initState() {
    super.initState();
    if (!_available) return;
    _auth = sl.get<AuthController>()..addListener(_onSessionChanged);
    _onSessionChanged();
  }

  @override
  void dispose() {
    _auth?.removeListener(_onSessionChanged);
    _subscription?.cancel();
    super.dispose();
  }

  /// Re-subscribes for the signed-in user; logout clears the count.
  void _onSessionChanged() {
    final identity = _auth?.identity;
    if (identity?.id == _watchedUserId) return;
    _subscription?.cancel();
    _subscription = null;
    _watchedUserId = identity?.id;
    if (mounted) setState(() => _unread = UnreadMessages.none);
    if (identity != null) _watch(identity);
  }

  void _watch(IdentityContract identity) {
    final stream = sl
        .get<WatchUnreadMessagesUseCase>()(requester: identity)
        .dataOrNull;
    var first = true;
    _subscription = stream?.listen((unread) {
      if (!mounted) return;
      final previous = _unread;
      setState(() => _unread = unread);
      // The first value is the current state, not a new message.
      if (!first) _maybeNotify(previous, unread);
      first = false;
    });
  }

  void _maybeNotify(UnreadMessages previous, UnreadMessages current) {
    final latest = current.latest;
    final isNew =
        current.total > previous.total &&
        latest != null &&
        latest.id != previous.latest?.id;
    // Only the button on the visible screen speaks, so there is one notice.
    if (!widget.notify || !isNew || ModalRoute.of(context)?.isCurrent != true) {
      return;
    }
    final preview = latest.text.length > 60
        ? '${latest.text.substring(0, 60)}…'
        : latest.text;
    ScaffoldMessenger.maybeOf(context)
      ?..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text('Nuevo mensaje: $preview'),
          action: SnackBarAction(label: 'Ver', onPressed: _openInbox),
        ),
      );
  }

  void _openInbox() => Navigator.pushNamed(context, ChatRoutes.conversations);

  @override
  Widget build(BuildContext context) {
    if (!_available) return const SizedBox.shrink();
    final count = _unread.total;
    return IconButton(
      tooltip: count == 0 ? 'Mensajes' : 'Mensajes ($count sin leer)',
      onPressed: _openInbox,
      icon: Badge(
        isLabelVisible: count > 0,
        label: Text(count > 99 ? '99+' : '$count'),
        child: const Icon(Icons.chat_bubble_outline),
      ),
    );
  }
}
