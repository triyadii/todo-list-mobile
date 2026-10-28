class ChatMessageModel {
  final String id;
  final String userId;
  final String role; // user, assistant, system
  final String content;
  final String? createdAt;

  ChatMessageModel({
    required this.id,
    required this.userId,
    required this.role,
    required this.content,
    this.createdAt,
  });

  bool get isUser => role.toLowerCase() == 'user';
  bool get isAssistant => role.toLowerCase() == 'assistant';
  bool get isSystem => role.toLowerCase() == 'system';

  factory ChatMessageModel.fromJson(Map<String, dynamic> json) {
    final role = (json['role'] ?? 'user').toString();
    String content = (json['content'] ??
            json['message'] ??
            json['reply'] ??
            json['response'] ??
            json['text'] ??
            '')
        .toString();

    // Prevent empty bubble if assistant content is empty or unhandled
    if (role.toLowerCase() == 'assistant' && content.trim().isEmpty) {
      content =
          '🛠️ Mohon maaf, respon Assistant sedang diproses atau layanan sedang dalam pemeliharaan (maintenance). Silakan coba beberapa saat lagi.';
    }

    return ChatMessageModel(
      id: json['id']?.toString() ?? '',
      userId: json['user_id']?.toString() ?? '',
      role: role,
      content: content,
      createdAt: json['created_at']?.toString(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'role': role,
      'content': content,
      'created_at': createdAt,
    };
  }
}
