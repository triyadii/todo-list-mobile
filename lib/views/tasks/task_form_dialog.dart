import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../../config/theme.dart';
import '../../models/task_model.dart';
import '../../services/task_service.dart';

class TaskFormDialog extends StatefulWidget {
  final TaskModel? taskToEdit;

  const TaskFormDialog({super.key, this.taskToEdit});

  @override
  State<TaskFormDialog> createState() => _TaskFormDialogState();
}

class _TaskFormDialogState extends State<TaskFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descController = TextEditingController();

  DateTime _selectedDate = DateTime.now();
  TimeOfDay _selectedStartTime = const TimeOfDay(hour: 9, minute: 0);
  TimeOfDay _selectedEndTime = const TimeOfDay(hour: 10, minute: 0);

  String _status = 'pending';
  String _priority = 'medium';
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();
    if (widget.taskToEdit != null) {
      final task = widget.taskToEdit!;
      _titleController.text = task.title;
      _descController.text = task.description;
      _status = task.status;
      _priority = task.priority;

      try {
        _selectedDate = DateTime.parse(task.dueDate);
      } catch (_) {}

      try {
        if (task.startTime.contains(' ') || task.startTime.contains('T')) {
          final dt = DateTime.parse(task.startTime.replaceAll(' ', 'T'));
          _selectedStartTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } else {
          final startParts = task.startTime.split(':');
          if (startParts.length >= 2) {
            _selectedStartTime = TimeOfDay(
              hour: int.parse(startParts[0]),
              minute: int.parse(startParts[1]),
            );
          }
        }
      } catch (_) {}

      try {
        if (task.endTime.contains(' ') || task.endTime.contains('T')) {
          final dt = DateTime.parse(task.endTime.replaceAll(' ', 'T'));
          _selectedEndTime = TimeOfDay(hour: dt.hour, minute: dt.minute);
        } else {
          final endParts = task.endTime.split(':');
          if (endParts.length >= 2) {
            _selectedEndTime = TimeOfDay(
              hour: int.parse(endParts[0]),
              minute: int.parse(endParts[1]),
            );
          }
        }
      } catch (_) {}
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  String _formatTimeOfDay(TimeOfDay time) {
    final h = time.hour.toString().padLeft(2, '0');
    final m = time.minute.toString().padLeft(2, '0');
    return '$h:$m:00';
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isSubmitting = true);
    final taskService = TaskService();

    final formattedDate = DateFormat('yyyy-MM-dd').format(_selectedDate);
    final formattedStart = _formatTimeOfDay(_selectedStartTime);
    final formattedEnd = _formatTimeOfDay(_selectedEndTime);

    // Format timestamp lengkap (YYYY-MM-DD HH:MM:SS) yang valid untuk PostgreSQL
    final startTimestamp = '$formattedDate $formattedStart';
    final endTimestamp = '$formattedDate $formattedEnd';

    try {
      if (widget.taskToEdit != null) {
        await taskService.updateTask(
          id: widget.taskToEdit!.id,
          title: _titleController.text,
          description: _descController.text,
          dueDate: formattedDate,
          startTime: startTimestamp,
          endTime: endTimestamp,
          status: _status,
          priority: _priority,
        );
      } else {
        await taskService.createTask(
          title: _titleController.text,
          description: _descController.text,
          dueDate: formattedDate,
          startTime: startTimestamp,
          endTime: endTimestamp,
          status: _status,
          priority: _priority,
        );
      }

      if (mounted) {
        Navigator.of(context).pop(true);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Terjadi kesalahan: $e'),
            backgroundColor: AppTheme.priorityHigh,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final isEdit = widget.taskToEdit != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      backgroundColor: theme.colorScheme.surface,
      insetPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 24),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    isEdit ? 'Edit Task' : 'Tambah Task Baru',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w700,
                      color: theme.textTheme.titleMedium?.color ?? const Color(0xFF0F172A),
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.of(context).pop(),
                    icon: Icon(Icons.close, size: 20, color: theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B)),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title Field
              const Text('Judul Kegiatan *', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(
                  hintText: 'Contoh: Rapat Evaluasi Proyek',
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) {
                    return 'Judul kegiatan tidak boleh kosong';
                  }
                  return null;
                },
              ),
              const SizedBox(height: 14),

              // Description Field
              const Text('Deskripsi (Opsional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              TextFormField(
                controller: _descController,
                maxLines: 3,
                decoration: const InputDecoration(
                  hintText: 'Tambahkan catatan atau detail tugas...',
                ),
              ),
              const SizedBox(height: 14),

              // Date Picker Field
              const Text('Tanggal Jatuh Tempo', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 6),
              InkWell(
                onTap: () async {
                  final picked = await showDatePicker(
                    context: context,
                    initialDate: _selectedDate,
                    firstDate: DateTime(2020),
                    lastDate: DateTime(2035),
                  );
                  if (picked != null) {
                    setState(() => _selectedDate = picked);
                  }
                },
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.calendar_month, size: 18, color: AppTheme.secondary),
                      const SizedBox(width: 10),
                      Text(
                        DateFormat('EEEE, dd MMMM yyyy').format(_selectedDate),
                        style: TextStyle(
                          fontSize: 14,
                          color: theme.textTheme.bodyMedium?.color ?? const Color(0xFF1E293B),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 14),

              // Time Pickers (Start - End)
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam Mulai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedStartTime,
                            );
                            if (picked != null) {
                              setState(() => _selectedStartTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time, size: 16, color: theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedStartTime.format(context),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Jam Selesai', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        InkWell(
                          onTap: () async {
                            final picked = await showTimePicker(
                              context: context,
                              initialTime: _selectedEndTime,
                            );
                            if (picked != null) {
                              setState(() => _selectedEndTime = picked);
                            }
                          },
                          child: Container(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
                            ),
                            child: Row(
                              children: [
                                Icon(Icons.access_time_filled, size: 16, color: theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B)),
                                const SizedBox(width: 8),
                                Text(
                                  _selectedEndTime.format(context),
                                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),

              // Priority & Status Selectors
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Prioritas', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _priority,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          items: const [
                            DropdownMenuItem(value: 'low', child: Text('Rendah', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'medium', child: Text('Sedang', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'high', child: Text('Tinggi', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _priority = val);
                          },
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Status', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
                        DropdownButtonFormField<String>(
                          initialValue: _status,
                          decoration: const InputDecoration(contentPadding: EdgeInsets.symmetric(horizontal: 10, vertical: 8)),
                          items: const [
                            DropdownMenuItem(value: 'pending', child: Text('Menunggu', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'in_progress', child: Text('Berjalan', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'completed', child: Text('Selesai', style: TextStyle(fontSize: 13))),
                            DropdownMenuItem(value: 'cancelled', child: Text('Batal', style: TextStyle(fontSize: 13))),
                          ],
                          onChanged: (val) {
                            if (val != null) setState(() => _status = val);
                          },
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Action Buttons
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isSubmitting ? null : _submit,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primary,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: _isSubmitting
                      ? const SizedBox(
                          width: 20,
                          height: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : Text(isEdit ? 'Simpan Perubahan' : 'Buat Task'),
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
  }
}
