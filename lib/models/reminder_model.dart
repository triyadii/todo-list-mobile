class ReminderModel {
  final String id;
  final String taskId;
  final String remindAt;
  final String? aiMessage;
  final bool isSent;
  final String? sentAt;
  final String? createdAt;
  final String? updatedAt;

  ReminderModel({
    required this.id,
    required this.taskId,
    required this.remindAt,
    this.aiMessage,
    this.isSent = false,
    this.sentAt,
    this.createdAt,
    this.updatedAt,
  });

  factory ReminderModel.fromJson(Map<String, dynamic> json) {
    return ReminderModel(
      id: json['id'] ?? '',
      taskId: json['task_id'] ?? '',
      remindAt: json['remind_at'] ?? '',
      aiMessage: json['ai_message'],
      isSent: json['is_sent'] ?? false,
      sentAt: json['sent_at'],
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'task_id': taskId,
      'remind_at': remindAt,
      'ai_message': aiMessage,
      'is_sent': isSent,
      'sent_at': sentAt,
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }
}
