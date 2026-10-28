import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/chat_message_model.dart';
import 'api_service.dart';

class ChatService extends ChangeNotifier {
  static final ChatService _instance = ChatService._internal();
  factory ChatService() => _instance;
  ChatService._internal();

  final ApiService _apiService = ApiService();

  List<ChatMessageModel> _messages = [];
  bool _isLoading = false;
  bool _isSending = false;

  List<ChatMessageModel> get messages => _messages;
  bool get isLoading => _isLoading;
  bool get isSending => _isSending;

  void cancelSending() {
    _messages.removeWhere((m) => m.id.startsWith('pending_'));
    _isSending = false;
    notifyListeners();
  }

  Future<void> fetchMessages({int limit = 50}) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiService.get(
        ApiConfig.chatMessages,
        queryParams: {'limit': limit.toString()},
      );

      if (res is List) {
        _messages = res.map((item) => ChatMessageModel.fromJson(item)).toList();
      } else if (res is Map<String, dynamic> && res['data'] is List) {
        _messages = (res['data'] as List)
            .map((item) => ChatMessageModel.fromJson(item))
            .toList();
      } else {
        _messages = [];
      }

      // Ensure chronological order (oldest to newest)
      _messages.sort((a, b) {
        final aTime = a.createdAt ?? '';
        final bTime = b.createdAt ?? '';
        return aTime.compareTo(bTime);
      });
    } catch (_) {
      // If error or empty, keep existing
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> sendMessage(String text) async {
    if (text.trim().isEmpty) return;
    final userText = text.trim();

    // 1. Optimistic update: Add user's message immediately so it displays instantly
    final userMsg = ChatMessageModel(
      id: 'temp_${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      role: 'user',
      content: userText,
      createdAt: DateTime.now().toIso8601String(),
    );
    _messages.add(userMsg);

    // 2. Add immediate pending response notification bubble
    final pendingAssistantMsg = ChatMessageModel(
      id: 'pending_${DateTime.now().millisecondsSinceEpoch}',
      userId: '',
      role: 'assistant',
      content: '⏳ Permintaan Anda sedang diproses, mohon tunggu sebentar...',
      createdAt: DateTime.now().toIso8601String(),
    );
    _messages.add(pendingAssistantMsg);

    _isSending = true;
    notifyListeners();

    try {
      // 3. Post message to backend with timeout
      final res = await _apiService.post(
        ApiConfig.chatMessages,
        data: {
          'role': 'user',
          'content': userText,
        },
      );

      // 4. Parse response from BE
      Map<String, dynamic>? dataMap;
      if (res is Map<String, dynamic>) {
        if (res.containsKey('assistant_message') || res.containsKey('user_message') || res.containsKey('reply')) {
          dataMap = res;
        } else if (res['data'] is Map<String, dynamic>) {
          dataMap = res['data'] as Map<String, dynamic>;
        }
      }

      bool hasAssistantReply = false;
      if (dataMap != null) {
        // Sync user_message if returned from backend
        if (dataMap['user_message'] is Map<String, dynamic>) {
          final idx = _messages.indexWhere((m) => m.id == userMsg.id);
          final serverUserMsg = ChatMessageModel.fromJson(dataMap['user_message']);
          if (idx != -1) {
            _messages[idx] = serverUserMsg;
          }
        }

        // Replace pending bubble with real assistant reply from backend
        if (dataMap['assistant_message'] is Map<String, dynamic>) {
          final realReply = ChatMessageModel.fromJson(dataMap['assistant_message']);
          final pendingIdx = _messages.indexWhere((m) => m.id == pendingAssistantMsg.id);
          if (pendingIdx != -1) {
            _messages[pendingIdx] = realReply;
          } else {
            _messages.add(realReply);
          }
          hasAssistantReply = true;
        } else {
          final fallbackText = dataMap['reply'] ?? dataMap['response'] ?? dataMap['message'];
          if (fallbackText != null && fallbackText.toString().trim().isNotEmpty) {
            final realReply = ChatMessageModel(
              id: '${DateTime.now().millisecondsSinceEpoch}_reply',
              userId: '',
              role: 'assistant',
              content: fallbackText.toString(),
              createdAt: DateTime.now().toIso8601String(),
            );
            final pendingIdx = _messages.indexWhere((m) => m.id == pendingAssistantMsg.id);
            if (pendingIdx != -1) {
              _messages[pendingIdx] = realReply;
            } else {
              _messages.add(realReply);
            }
            hasAssistantReply = true;
          }
        }
      }

      if (!hasAssistantReply) {
        // Remove pending bubble and sync history from server
        _messages.removeWhere((m) => m.id == pendingAssistantMsg.id);
        await fetchMessages();

        // If server history still doesn't have an assistant reply, display maintenance info
        final hasLatestAssistant = _messages.isNotEmpty &&
            _messages.last.role == 'assistant' &&
            _messages.last.content.trim().isNotEmpty;
        if (!hasLatestAssistant) {
          _messages.add(ChatMessageModel(
            id: DateTime.now().millisecondsSinceEpoch.toString(),
            userId: '',
            role: 'assistant',
            content: '🛠️ Mohon maaf, respon Assistant sedang diproses atau layanan sedang dalam pemeliharaan (maintenance). Silakan coba beberapa saat lagi.',
            createdAt: DateTime.now().toIso8601String(),
          ));
        }
      }
    } catch (e) {
      // 5. If server or Groq cannot be accessed, inform user that assistant is under maintenance
      final friendlyError = _getFriendlyErrorMessage(e);
      final pendingIdx = _messages.indexWhere((m) => m.id == pendingAssistantMsg.id);
      final errorMsg = ChatMessageModel(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        userId: '',
        role: 'assistant',
        content: friendlyError,
        createdAt: DateTime.now().toIso8601String(),
      );

      if (pendingIdx != -1) {
        _messages[pendingIdx] = errorMsg;
      } else {
        _messages.add(errorMsg);
      }
    } finally {
      _isSending = false;
      notifyListeners();
    }
  }

  String _getFriendlyErrorMessage(dynamic e) {
    final msg = e.toString().toLowerCase();
    if (msg.contains('timeout') || msg.contains('timed out')) {
      return '⏳ Mohon maaf, server Assistant memerlukan waktu lebih lama dari biasanya untuk memproses respon. Assistant kemungkinan sedang sibuk atau dalam pemeliharaan. Silakan coba beberapa saat lagi.';
    } else if (msg.contains('502') || msg.contains('503') || msg.contains('504') || msg.contains('maintenance')) {
      return '🛠️ Mohon maaf, layanan Assistant sedang dalam pemeliharaan (maintenance). Silakan coba beberapa saat lagi.';
    } else if (msg.contains('socket') || msg.contains('failed host lookup') || msg.contains('connection') || msg.contains('refused') || msg.contains('clientexception')) {
      return '⚠️ Mohon maaf, Assistant saat ini tidak dapat diakses atau sedang dalam pemeliharaan (maintenance). Pastikan koneksi internet Anda aktif dan silakan coba beberapa saat lagi.';
    } else if (msg.contains('401') || msg.contains('unauthorized')) {
      return '🔒 Sesi login Anda telah berakhir. Silakan login kembali untuk melanjutkan percakapan.';
    }
    return '🛠️ Mohon maaf, respon Assistant sedang diproses atau layanan sedang dalam pemeliharaan (maintenance). Silakan coba beberapa saat lagi.';
  }

  Future<void> clearHistory() async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.delete(ApiConfig.chatMessages);
      _messages.clear();
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
