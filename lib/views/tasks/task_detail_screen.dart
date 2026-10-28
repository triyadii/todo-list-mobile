import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/reminder_model.dart';
import '../../models/task_model.dart';
import '../../services/reminder_service.dart';
import '../../services/task_service.dart';
import 'task_form_dialog.dart';
import 'widgets/priority_badge.dart';
import 'widgets/status_badge.dart';

class TaskDetailScreen extends StatefulWidget {
  final TaskModel initialTask;

  const TaskDetailScreen({super.key, required this.initialTask});

  @override
  State<TaskDetailScreen> createState() => _TaskDetailScreenState();
}

class _TaskDetailScreenState extends State<TaskDetailScreen> {
  late TaskModel _task;
  final ReminderService _reminderService = ReminderService();
  final TaskService _taskService = TaskService();

  List<ReminderModel> _reminders = [];
  bool _isLoadingReminders = false;

  @override
  void initState() {
    super.initState();
    _task = widget.initialTask;
    _loadReminders();
  }

  Future<void> _loadReminders() async {
    setState(() => _isLoadingReminders = true);
    try {
      final res = await _reminderService.getTaskReminders(_task.id);
      setState(() => _reminders = res);
    } catch (_) {
    } finally {
      if (mounted) setState(() => _isLoadingReminders = false);
    }
  }

  Future<void> _showAddReminderDialog() async {
    DateTime selectedDate = DateTime.now();
    TimeOfDay selectedTime = TimeOfDay.now();
    final messageController = TextEditingController(
      text: 'Pengingat untuk task: ${_task.title}',
    );

    final added = await showDialog<bool>(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (ctx, setDialogState) {
          return AlertDialog(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            title: const Text('Tambah Pengingat (Reminder)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Waktu Pengingat', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final pickedDate = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime.now(),
                        lastDate: DateTime(2035),
                      );
                      if (pickedDate != null) {
                        setDialogState(() => selectedDate = pickedDate);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_today, size: 16),
                          const SizedBox(width: 8),
                          Text(DateFormat('yyyy-MM-dd').format(selectedDate)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  InkWell(
                    onTap: () async {
                      final pickedTime = await showTimePicker(
                        context: context,
                        initialTime: selectedTime,
                      );
                      if (pickedTime != null) {
                        setDialogState(() => selectedTime = pickedTime);
                      }
                    },
                    child: Container(
                      padding: const EdgeInsets.all(10),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF1F5F9),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.access_time, size: 16),
                          const SizedBox(width: 8),
                          Text(selectedTime.format(context)),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text('Pesan Notifikasi Assistant', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: messageController,
                    maxLines: 2,
                    decoration: const InputDecoration(
                      hintText: 'Pesan pengingat otomatis...',
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: const Text('Batal'),
              ),
              ElevatedButton(
                onPressed: () async {
                  final formattedDate = DateFormat('yyyy-MM-dd').format(selectedDate);
                  final h = selectedTime.hour.toString().padLeft(2, '0');
                  final m = selectedTime.minute.toString().padLeft(2, '0');
                  final remindAt = '$formattedDate $h:$m:00';

                  try {
                    await _reminderService.createReminder(
                      taskId: _task.id,
                      remindAt: remindAt,
                      aiMessage: messageController.text.trim(),
                    );
                    if (ctx.mounted) Navigator.pop(ctx, true);
                  } catch (e) {
                    if (ctx.mounted) {
                      ScaffoldMessenger.of(ctx).showSnackBar(
                        SnackBar(content: Text('Gagal membuat reminder: $e')),
                      );
                    }
                  }
                },
                child: const Text('Simpan'),
              ),
            ],
          );
        },
      ),
    );

    if (added == true) {
      _loadReminders();
    }
  }

  Future<void> _deleteReminder(String id) async {
    try {
      await _reminderService.deleteReminder(id);
      _loadReminders();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus reminder: $e')),
        );
      }
    }
  }

  Future<void> _confirmDeleteTask() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Task?'),
        content: const Text('Apakah Anda yakin ingin menghapus tugas ini? Tindakan ini tidak dapat dibatalkan.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Batal')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: AppTheme.priorityHigh),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      try {
        await _taskService.deleteTask(_task.id);
        if (mounted) Navigator.pop(context);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Gagal menghapus: $e')),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isDone = _task.isCompleted;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detail Task'),
        actions: [
          IconButton(
            icon: const Icon(Icons.edit_outlined),
            onPressed: () async {
              final updated = await showDialog<bool>(
                context: context,
                builder: (ctx) => TaskFormDialog(taskToEdit: _task),
              );
              if (updated == true) {
                final fresh = await _taskService.getTaskById(_task.id);
                setState(() => _task = fresh);
              }
            },
          ),
          IconButton(
            icon: const Icon(Icons.delete_outline, color: AppTheme.priorityHigh),
            onPressed: _confirmDeleteTask,
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Status and Priority Row
            Wrap(
              spacing: 8,
              runSpacing: 8,
              crossAxisAlignment: WrapCrossAlignment.center,
              alignment: WrapAlignment.spaceBetween,
              children: [
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    StatusBadge(status: _task.status),
                    const SizedBox(width: 8),
                    PriorityBadge(priority: _task.priority),
                  ],
                ),
                GestureDetector(
                  onTap: () async {
                    final updated = await _taskService.toggleTaskStatus(_task);
                    setState(() => _task = updated);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                    decoration: BoxDecoration(
                      color: isDone
                          ? (isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9))
                          : (isDark ? AppTheme.secondary.withOpacity(0.2) : AppTheme.primaryLight),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isDone ? Icons.undo : Icons.check_circle,
                          size: 16,
                          color: isDone ? const Color(0xFF64748B) : AppTheme.secondary,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          isDone ? 'Tandai Belum Selesai' : 'Tandai Selesai',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: isDone ? const Color(0xFF64748B) : AppTheme.secondary,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Title
            Text(
              _task.title,
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w800,
                color: theme.textTheme.headlineMedium?.color,
                decoration: isDone ? TextDecoration.lineThrough : null,
              ),
            ),
            const SizedBox(height: 12),

            // Description
            if (_task.description.isNotEmpty) ...[
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
                ),
                child: Text(
                  _task.description,
                  style: TextStyle(
                    fontSize: 14,
                    height: 1.5,
                    color: theme.textTheme.bodyMedium?.color?.withOpacity(0.9),
                  ),
                ),
              ),
              const SizedBox(height: 16),
            ],

            // Schedule info card
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: theme.colorScheme.surface,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
              ),
              child: Column(
                children: [
                  Row(
                    children: [
                      const Icon(Icons.calendar_today, size: 18, color: AppTheme.secondary),
                      const SizedBox(width: 12),
                      const Text('Jatuh Tempo:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _task.fullFormattedDueDate,
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                  const Divider(height: 24, thickness: 0.5),
                  Row(
                    children: [
                      const Icon(Icons.access_time, size: 18, color: AppTheme.secondary),
                      const SizedBox(width: 12),
                      const Text('Waktu Kegiatan:', style: TextStyle(color: Color(0xFF64748B), fontSize: 13)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _task.timeRangeString.isNotEmpty ? _task.timeRangeString : '-',
                          textAlign: TextAlign.end,
                          overflow: TextOverflow.ellipsis,
                          style: const TextStyle(fontWeight: FontWeight.w700, fontSize: 14),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Reminders Section Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Pengingat & Notifikasi Assistant',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: theme.textTheme.titleMedium?.color,
                  ),
                ),
                TextButton.icon(
                  onPressed: _showAddReminderDialog,
                  icon: const Icon(Icons.add_alarm, size: 18),
                  label: const Text('Tambah'),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Reminders List
            if (_isLoadingReminders)
              const Center(child: Padding(padding: EdgeInsets.all(16), child: CircularProgressIndicator()))
            else if (_reminders.isEmpty)
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
                ),
                child: Column(
                  children: [
                    Icon(Icons.notifications_none, size: 36, color: Colors.grey[400]),
                    const SizedBox(height: 8),
                    const Text(
                      'Belum ada pengingat yang diatur.',
                      style: TextStyle(fontSize: 13, color: Color(0xFF64748B)),
                    ),
                  ],
                ),
              )
            else
              ListView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                itemCount: _reminders.length,
                itemBuilder: (ctx, i) {
                  final rem = _reminders[i];
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surface,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.alarm, color: AppTheme.secondary, size: 20),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                rem.remindAt,
                                style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                              ),
                              if (rem.aiMessage != null && rem.aiMessage!.isNotEmpty)
                                Text(
                                  rem.aiMessage!,
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B),
                                  ),
                                ),
                            ],
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.delete_outline, size: 18, color: Colors.red),
                          onPressed: () => _deleteReminder(rem.id),
                        ),
                      ],
                    ),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }
}
