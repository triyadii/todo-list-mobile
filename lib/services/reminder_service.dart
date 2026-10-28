import '../config/api_config.dart';
import '../models/reminder_model.dart';
import 'api_service.dart';

class ReminderService {
  static final ReminderService _instance = ReminderService._internal();
  factory ReminderService() => _instance;
  ReminderService._internal();

  final ApiService _apiService = ApiService();

  Future<List<ReminderModel>> getTaskReminders(String taskId) async {
    final res = await _apiService.get(ApiConfig.taskReminders(taskId));
    if (res is List) {
      return res.map((item) => ReminderModel.fromJson(item)).toList();
    }
    return [];
  }

  Future<ReminderModel> createReminder({
    required String taskId,
    required String remindAt,
    String? aiMessage,
  }) async {
    final res = await _apiService.post(
      ApiConfig.reminders,
      data: {
        'task_id': taskId,
        'remind_at': remindAt,
        'ai_message': aiMessage ?? '',
      },
    );
    return ReminderModel.fromJson(res);
  }

  Future<void> deleteReminder(String id) async {
    await _apiService.delete(ApiConfig.reminderById(id));
  }
}
