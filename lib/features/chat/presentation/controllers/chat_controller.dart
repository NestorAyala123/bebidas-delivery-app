import 'dart:async';

import 'package:flutter/foundation.dart';

import '../../../../core/result/result.dart';
import '../../domain/entities/chat_conversation.dart';
import '../../domain/entities/chat_message.dart';
import '../../domain/entities/chat_notification.dart';
import '../../domain/repositories/chat_repository.dart';
import '../../domain/usecases/enviar_mensaje_use_case.dart';
import '../../domain/usecases/marcar_conversacion_leida_use_case.dart';
import '../../domain/usecases/obtener_conversaciones_use_case.dart';

/// Controlador compartido por la lista de conversaciones y la pantalla de chat.
class ChatController extends ChangeNotifier {
  final ObtenerConversacionesUseCase obtenerConversacionesUseCase;
  final EnviarMensajeUseCase enviarMensajeUseCase;
  final MarcarConversacionLeidaUseCase marcarConversacionLeidaUseCase;
  final ChatRepository chatRepository;
  final String userId;
  final String userName;

  /// Gancho opcional para demostrar la recepción de mensajes en vivo.
  final Future<void> Function(String conversationId)? simulateIncoming;

  List<ChatConversation> _conversations = [];
  List<ChatMessage> _messages = [];
  ChatConversation? _activeConversation;
  ChatNotification? _latestNotification;
  String? _errorMessage;
  bool _isLoading = false;
  bool _isSending = false;

  StreamSubscription<List<ChatConversation>>? _conversationsSub;
  StreamSubscription<List<ChatMessage>>? _messagesSub;
  StreamSubscription<ChatNotification>? _notificationsSub;

  ChatController({
    required this.obtenerConversacionesUseCase,
    required this.enviarMensajeUseCase,
    required this.marcarConversacionLeidaUseCase,
    required this.chatRepository,
    this.userId = 'customer-demo',
    this.userName = 'Cliente',
    this.simulateIncoming,
  });

  List<ChatConversation> get conversations => List.unmodifiable(_conversations);
  List<ChatMessage> get messages => List.unmodifiable(_messages);
  ChatConversation? get activeConversation => _activeConversation;
  ChatNotification? get latestNotification => _latestNotification;
  String? get errorMessage => _errorMessage;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;

  int get totalUnread => _conversations.fold(
        0,
        (total, conversation) => total + conversation.unreadCount,
      );

  /// Carga la lista y comienza a escuchar avisos de mensajes nuevos.
  void loadConversations() {
    _conversationsSub?.cancel();
    _notificationsSub?.cancel();

    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    final result = obtenerConversacionesUseCase(userId);
    switch (result) {
      case FailureResult(:final failure):
        _isLoading = false;
        _errorMessage = failure.message;
        notifyListeners();
      case Success(:final data):
        _conversationsSub = data.listen((items) {
          _conversations = items;
          _isLoading = false;
          notifyListeners();
        });
        _notificationsSub = chatRepository.notificationsStream.listen(
          (notification) {
            _latestNotification = notification;
            notifyListeners();
          },
        );
    }
  }

  /// Abre un hilo, escucha sus mensajes y limpia el contador de no leídos.
  void openConversation(ChatConversation conversation) {
    _messagesSub?.cancel();
    _activeConversation = conversation;
    _messages = [];
    _latestNotification = null;
    notifyListeners();

    _messagesSub = chatRepository
        .getMessagesStream(conversation.id)
        .listen((items) {
      _messages = items;
      notifyListeners();
    });

    marcarConversacionLeidaUseCase(
      conversationId: conversation.id,
      userId: userId,
    ).then((_) {
      _activeConversation = conversation.copyWith(unreadCount: 0);
      notifyListeners();
    });
  }

  Future<bool> sendMessage(String text) async {
    final conversation = _activeConversation;
    if (conversation == null) {
      _errorMessage = 'Selecciona una conversación antes de enviar';
      notifyListeners();
      return false;
    }

    _isSending = true;
    _errorMessage = null;
    notifyListeners();

    final result = await enviarMensajeUseCase(
      conversationId: conversation.id,
      senderId: userId,
      senderName: userName,
      text: text,
    );

    _isSending = false;
    switch (result) {
      case Success():
        return true;
      case FailureResult(:final failure):
        _errorMessage = failure.message;
        notifyListeners();
        return false;
    }
  }

  /// Genera un mensaje entrante de demostración y su aviso en la app.
  Future<void> simulateIncomingMessage() async {
    final conversation = _activeConversation;
    if (conversation == null) return;

    final hook = simulateIncoming;
    if (hook != null) {
      await hook(conversation.id);
    }
  }

  void dismissNotification() {
    _latestNotification = null;
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }

  @override
  void dispose() {
    _conversationsSub?.cancel();
    _messagesSub?.cancel();
    _notificationsSub?.cancel();
    super.dispose();
  }
}
