import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../services/task_service.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/task_form_dialog.dart';
import '../tasks/widgets/task_card.dart';

class CalendarScreen extends StatefulWidget {
  const CalendarScreen({super.key});

  @override
  State<CalendarScreen> createState() => _CalendarScreenState();
}

class _CalendarScreenState extends State<CalendarScreen> {
  final TaskService _taskService = TaskService();
  DateTime _selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    _taskService.addListener(_onTaskUpdated);
  }

  @override
  void dispose() {
    _taskService.removeListener(_onTaskUpdated);
    super.dispose();
  }

  void _onTaskUpdated() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final selectedDateStr = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final dayTasks = _taskService.tasks
        .where((t) => t.cleanDueDate == selectedDateStr)
        .toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Jadwal & Kalender'),
        actions: [
          IconButton(
            icon: const Icon(Icons.add),
            onPressed: () {
              showDialog(
                context: context,
                builder: (ctx) => const TaskFormDialog(),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Horizontal date picker strip (7 days ahead & behind)
          Container(
            height: 90,
            padding: const EdgeInsets.symmetric(vertical: 8),
            decoration: BoxDecoration(
              color: theme.colorScheme.surface,
              border: Border(bottom: BorderSide(color: theme.colorScheme.outline.withOpacity(0.4))),
            ),
            child: ListView.builder(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              itemCount: 30,
              itemBuilder: (context, index) {
                final date = DateTime.now().add(Duration(days: index - 5));
                final isSelected = date.year == _selectedDate.year &&
                    date.month == _selectedDate.month &&
                    date.day == _selectedDate.day;

                final dayCount = _taskService.tasks
                    .where((t) => t.cleanDueDate == DateFormat('yyyy-MM-dd').format(date))
                    .length;

                return GestureDetector(
                  onTap: () => setState(() => _selectedDate = date),
                  child: Container(
                    width: 58,
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.secondary
                          : (isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC)),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.secondary : theme.colorScheme.outline.withOpacity(0.4),
                      ),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          DateFormat('E').format(date).toUpperCase(),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: isSelected ? Colors.white70 : (theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          DateFormat('dd').format(date),
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: isSelected ? Colors.white : (theme.textTheme.titleMedium?.color ?? const Color(0xFF1E293B)),
                          ),
                        ),
                        const SizedBox(height: 4),
                        if (dayCount > 0)
                          Container(
                            width: 6,
                            height: 6,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              color: isSelected ? Colors.white : AppTheme.secondary,
                            ),
                          )
                        else
                          const SizedBox(height: 6),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),

          // Date Header info
          Padding(
            padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                ),
                Text(
                  '${dayTasks.length} Task',
                  style: const TextStyle(color: Color(0xFF64748B), fontSize: 13),
                ),
              ],
            ),
          ),

          // Task List for Selected Date
          Expanded(
            child: dayTasks.isEmpty
                ? Center(
                    child: SingleChildScrollView(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.event_available, size: 56, color: Colors.grey[300]),
                          const SizedBox(height: 12),
                          const Text(
                            'Tidak ada agenda untuk tanggal ini.',
                            style: TextStyle(color: Color(0xFF64748B), fontSize: 14),
                          ),
                          const SizedBox(height: 12),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => const TaskFormDialog(),
                              );
                            },
                            icon: const Icon(Icons.add, size: 16),
                            label: const Text('Buat Task Baru'),
                          ),
                        ],
                      ),
                    ),
                  )
                : ListView.builder(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    itemCount: dayTasks.length,
                    itemBuilder: (context, index) {
                      final task = dayTasks[index];
                      return TaskCard(
                        task: task,
                        onTap: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(
                              builder: (_) => TaskDetailScreen(initialTask: task),
                            ),
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
