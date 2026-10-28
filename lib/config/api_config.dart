class ApiConfig {
  static const String baseUrl = 'https://mdt-solution.site/todo-list';

  // Auth endpoints
  static const String login = '$baseUrl/api/v1/auth/login';
  static const String register = '$baseUrl/api/v1/auth/register';

  // User endpoints
  static const String userProfile = '$baseUrl/api/v1/user/profile';
  static const String users = '$baseUrl/api/v1/users';

  // Tasks endpoints
  static const String tasks = '$baseUrl/api/v1/tasks';
  static String taskById(String id) => '$baseUrl/api/v1/tasks/$id';

  // Reminders endpoints
  static const String reminders = '$baseUrl/api/v1/reminders';
  static String reminderById(String id) => '$baseUrl/api/v1/reminders/$id';
  static String taskReminders(String taskId) => '$baseUrl/api/v1/tasks/$taskId/reminders';

  // Chat & AI endpoints
  static const String chatMessages = '$baseUrl/api/v1/chat/messages';
}
