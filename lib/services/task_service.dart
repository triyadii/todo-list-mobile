import 'package:flutter/foundation.dart';
import '../config/api_config.dart';
import '../models/task_model.dart';
import 'api_service.dart';

class TaskService extends ChangeNotifier {
  static final TaskService _instance = TaskService._internal();
  factory TaskService() => _instance;
  TaskService._internal();

  final ApiService _apiService = ApiService();

  List<TaskModel> _tasks = [];
  bool _isLoading = false;
  String? _selectedStatusFilter;
  String? _selectedPriorityFilter;
  String? _selectedDateFilter;
  String _searchQuery = '';

  List<TaskModel> get tasks => _tasks;
  bool get isLoading => _isLoading;
  String? get selectedStatusFilter => _selectedStatusFilter;
  String? get selectedPriorityFilter => _selectedPriorityFilter;
  String? get selectedDateFilter => _selectedDateFilter;
  String get searchQuery => _searchQuery;

  List<TaskModel> get filteredTasks {
    return _tasks.where((task) {
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        final matchTitle = task.title.toLowerCase().contains(q);
        final matchDesc = task.description.toLowerCase().contains(q);
        if (!matchTitle && !matchDesc) return false;
      }
      if (_selectedStatusFilter != null && _selectedStatusFilter!.isNotEmpty) {
        if (task.status.toLowerCase() != _selectedStatusFilter!.toLowerCase()) {
          return false;
        }
      }
      if (_selectedPriorityFilter != null && _selectedPriorityFilter!.isNotEmpty) {
        if (task.priority.toLowerCase() != _selectedPriorityFilter!.toLowerCase()) {
          return false;
        }
      }
      if (_selectedDateFilter != null && _selectedDateFilter!.isNotEmpty) {
        if (task.dueDate != _selectedDateFilter) {
          return false;
        }
      }
      return true;
    }).toList();
  }

  void setSearchQuery(String query) {
    _searchQuery = query;
    notifyListeners();
  }

  void setFilter({
    String? status,
    String? priority,
    String? date,
  }) {
    _selectedStatusFilter = status;
    _selectedPriorityFilter = priority;
    _selectedDateFilter = date;
    notifyListeners();
  }

  void clearFilters() {
    _selectedStatusFilter = null;
    _selectedPriorityFilter = null;
    _selectedDateFilter = null;
    _searchQuery = '';
    notifyListeners();
  }

  Future<List<TaskModel>> fetchTasks({
    String? status,
    String? priority,
    String? dueDate,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final queryParams = <String, String>{};
      if (status != null && status.isNotEmpty) queryParams['status'] = status;
      if (priority != null && priority.isNotEmpty) queryParams['priority'] = priority;
      if (dueDate != null && dueDate.isNotEmpty) queryParams['due_date'] = dueDate;

      final res = await _apiService.get(
        ApiConfig.tasks,
        queryParams: queryParams.isNotEmpty ? queryParams : null,
      );

      if (res is List) {
        _tasks = res.map((item) => TaskModel.fromJson(item)).toList();
      } else {
        _tasks = [];
      }
      return _tasks;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TaskModel> getTaskById(String id) async {
    final res = await _apiService.get(ApiConfig.taskById(id));
    final task = TaskModel.fromJson(res);
    final index = _tasks.indexWhere((t) => t.id == id);
    if (index != -1) {
      _tasks[index] = task;
      notifyListeners();
    }
    return task;
  }

  Future<TaskModel> createTask({
    required String title,
    required String description,
    required String dueDate,
    required String startTime,
    required String endTime,
    String status = 'pending',
    String priority = 'medium',
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiService.post(
        ApiConfig.tasks,
        data: {
          'title': title.trim(),
          'description': description.trim(),
          'due_date': dueDate,
          'start_time': startTime,
          'end_time': endTime,
          'status': status,
          'priority': priority,
        },
      );

      final newTask = TaskModel.fromJson(res);
      _tasks.insert(0, newTask);
      return newTask;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TaskModel> updateTask({
    required String id,
    required String title,
    required String description,
    required String dueDate,
    required String startTime,
    required String endTime,
    required String status,
    required String priority,
  }) async {
    _isLoading = true;
    notifyListeners();

    try {
      final res = await _apiService.put(
        ApiConfig.taskById(id),
        data: {
          'title': title.trim(),
          'description': description.trim(),
          'due_date': dueDate,
          'start_time': startTime,
          'end_time': endTime,
          'status': status,
          'priority': priority,
        },
      );

      final updatedTask = TaskModel.fromJson(res);
      final index = _tasks.indexWhere((t) => t.id == id);
      if (index != -1) {
        _tasks[index] = updatedTask;
      }
      return updatedTask;
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<TaskModel> toggleTaskStatus(TaskModel task) async {
    final newStatus = task.isCompleted ? 'pending' : 'completed';
    return await updateTask(
      id: task.id,
      title: task.title,
      description: task.description,
      dueDate: task.dueDate,
      startTime: task.startTime,
      endTime: task.endTime,
      status: newStatus,
      priority: task.priority,
    );
  }

  Future<void> deleteTask(String id) async {
    _isLoading = true;
    notifyListeners();

    try {
      await _apiService.delete(ApiConfig.taskById(id));
      _tasks.removeWhere((t) => t.id == id);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }
}
