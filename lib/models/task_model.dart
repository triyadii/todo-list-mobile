import 'package:intl/intl.dart';
import 'reminder_model.dart';

class TaskModel {
  final String id;
  final String userId;
  final String title;
  final String description;
  final String dueDate;
  final String startTime;
  final String endTime;
  final String status; // pending, in_progress, completed, cancelled
  final String priority; // low, medium, high
  final List<ReminderModel> reminders;
  final String? createdAt;
  final String? updatedAt;

  TaskModel({
    required this.id,
    required this.userId,
    required this.title,
    required this.description,
    required this.dueDate,
    required this.startTime,
    required this.endTime,
    required this.status,
    required this.priority,
    this.reminders = const [],
    this.createdAt,
    this.updatedAt,
  });

  bool get isCompleted => status.toLowerCase() == 'completed';
  bool get isInProgress => status.toLowerCase() == 'in_progress';
  bool get isPending => status.toLowerCase() == 'pending';
  bool get isCancelled => status.toLowerCase() == 'cancelled';

  String get formattedStartTime {
    if (startTime.isEmpty) return '';
    try {
      if (startTime.contains('T') || startTime.contains(' ')) {
        final dt = DateTime.parse(startTime.replaceAll(' ', 'T'));
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      final parts = startTime.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    } catch (_) {}
    return startTime;
  }

  String get formattedEndTime {
    if (endTime.isEmpty) return '';
    try {
      if (endTime.contains('T') || endTime.contains(' ')) {
        final dt = DateTime.parse(endTime.replaceAll(' ', 'T'));
        final h = dt.hour.toString().padLeft(2, '0');
        final m = dt.minute.toString().padLeft(2, '0');
        return '$h:$m';
      }
      final parts = endTime.split(':');
      if (parts.length >= 2) {
        return '${parts[0].padLeft(2, '0')}:${parts[1].padLeft(2, '0')}';
      }
    } catch (_) {}
    return endTime;
  }

  String get timeRangeString {
    final start = formattedStartTime;
    final end = formattedEndTime;
    if (start.isEmpty && end.isEmpty) return '';
    if (start.isNotEmpty && end.isNotEmpty) return '$start - $end';
    if (start.isNotEmpty) return start;
    return end;
  }

  String get cleanDueDate {
    if (dueDate.isEmpty) return '';
    if (dueDate.contains('T')) return dueDate.split('T')[0];
    if (dueDate.contains(' ')) return dueDate.split(' ')[0];
    return dueDate;
  }

  String get formattedDueDate {
    final clean = cleanDueDate;
    if (clean.isEmpty) return '-';
    try {
      final dt = DateTime.parse(clean);
      return DateFormat('dd MMM yyyy').format(dt);
    } catch (_) {
      return clean;
    }
  }

  String get fullFormattedDueDate {
    final clean = cleanDueDate;
    if (clean.isEmpty) return '-';
    try {
      final dt = DateTime.parse(clean);
      return DateFormat('dd MMMM yyyy').format(dt);
    } catch (_) {
      return clean;
    }
  }

  factory TaskModel.fromJson(Map<String, dynamic> json) {
    var remindersList = <ReminderModel>[];
    if (json['reminders'] != null && json['reminders'] is List) {
      remindersList = (json['reminders'] as List)
          .map((item) => ReminderModel.fromJson(item))
          .toList();
    }

    return TaskModel(
      id: json['id'] ?? '',
      userId: json['user_id'] ?? '',
      title: json['title'] ?? '',
      description: json['description'] ?? '',
      dueDate: json['due_date'] ?? '',
      startTime: json['start_time'] ?? '',
      endTime: json['end_time'] ?? '',
      status: json['status'] ?? 'pending',
      priority: json['priority'] ?? 'medium',
      reminders: remindersList,
      createdAt: json['created_at'],
      updatedAt: json['updated_at'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'user_id': userId,
      'title': title,
      'description': description,
      'due_date': dueDate,
      'start_time': startTime,
      'end_time': endTime,
      'status': status,
      'priority': priority,
      'reminders': reminders.map((e) => e.toJson()).toList(),
      'created_at': createdAt,
      'updated_at': updatedAt,
    };
  }

  TaskModel copyWith({
    String? id,
    String? userId,
    String? title,
    String? description,
    String? dueDate,
    String? startTime,
    String? endTime,
    String? status,
    String? priority,
    List<ReminderModel>? reminders,
    String? createdAt,
    String? updatedAt,
  }) {
    return TaskModel(
      id: id ?? this.id,
      userId: userId ?? this.userId,
      title: title ?? this.title,
      description: description ?? this.description,
      dueDate: dueDate ?? this.dueDate,
      startTime: startTime ?? this.startTime,
      endTime: endTime ?? this.endTime,
      status: status ?? this.status,
      priority: priority ?? this.priority,
      reminders: reminders ?? this.reminders,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}
