import 'package:flutter/material.dart';
import '../../config/theme.dart';
import '../../services/auth_service.dart';
import '../../services/task_service.dart';
import '../tasks/task_detail_screen.dart';
import '../tasks/task_form_dialog.dart';
import '../tasks/widgets/task_card.dart';

class DashboardScreen extends StatefulWidget {
  final Function(int) onNavigateTab;

  const DashboardScreen({super.key, required this.onNavigateTab});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final TaskService _taskService = TaskService();
  final AuthService _authService = AuthService();
  final TextEditingController _searchController = TextEditingController();

  final List<Map<String, String>> _statusOptions = [
    {'label': 'Semua', 'value': ''},
    {'label': 'Menunggu', 'value': 'pending'},
    {'label': 'Berjalan', 'value': 'in_progress'},
    {'label': 'Selesai', 'value': 'completed'},
  ];

  final List<Map<String, String>> _priorityOptions = [
    {'label': 'Semua', 'value': ''},
    {'label': 'Tinggi', 'value': 'high'},
    {'label': 'Sedang', 'value': 'medium'},
    {'label': 'Rendah', 'value': 'low'},
  ];

  @override
  void initState() {
    super.initState();
    _taskService.addListener(_onTaskUpdated);
    _taskService.fetchTasks();
  }

  @override
  void dispose() {
    _taskService.removeListener(_onTaskUpdated);
    _searchController.dispose();
    super.dispose();
  }

  void _onTaskUpdated() {
    if (mounted) setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final user = _authService.currentUser;
    final allTasks = _taskService.tasks;
    final filteredTasks = _taskService.filteredTasks;
    final isLoading = _taskService.isLoading;

    final pendingCount = allTasks.where((t) => t.isPending).length;
    final inProgressCount = allTasks.where((t) => t.isInProgress).length;
    final completedCount = allTasks.where((t) => t.isCompleted).length;

    return Scaffold(
      body: SafeArea(
        child: RefreshIndicator(
          onRefresh: () => _taskService.fetchTasks(),
          child: CustomScrollView(
            slivers: [
              // Top Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
                  child: Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Halo, ${user?.name ?? "Pengguna"} 👋',
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 22,
                                fontWeight: FontWeight.w800,
                                color: theme.textTheme.headlineMedium?.color,
                              ),
                            ),
                            const SizedBox(height: 3),
                            Text(
                              'Kelola tugas dan aktivitas cerdasmu',
                              style: TextStyle(
                                fontSize: 13,
                                color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7),
                              ),
                            ),
                          ],
                        ),
                      ),
                      GestureDetector(
                        onTap: () => widget.onNavigateTab(3), // Navigate to profile
                        child: Container(
                          width: 44,
                          height: 44,
                          decoration: BoxDecoration(
                            gradient: const LinearGradient(
                              colors: [AppTheme.primary, AppTheme.secondary],
                            ),
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              user?.name.isNotEmpty == true ? user!.name[0].toUpperCase() : 'U',
                              style: const TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.bold,
                                fontSize: 18,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // AI Assistant Promotional Card
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 8),
                  child: Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: isDark
                            ? const [Color(0xFF1E293B), Color(0xFF0F172A)]
                            : const [Color(0xFF0F172A), Color(0xFF1E3A8A)],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: [
                        BoxShadow(
                          color: AppTheme.primary.withOpacity(0.2),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(10),
                          decoration: BoxDecoration(
                            color: Colors.white.withOpacity(0.2),
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.support_agent, color: Colors.white, size: 24),
                        ),
                        const SizedBox(width: 14),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: const [
                              Text(
                                'Personal Assistant',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 15,
                                ),
                              ),
                              SizedBox(height: 2),
                              Text(
                                'Tanya jadwal hari ini & rekomendasi prioritas.',
                                style: TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        ElevatedButton(
                          onPressed: () => widget.onNavigateTab(2), // Navigate to Assistant Chat
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: AppTheme.primaryDark,
                            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                          ),
                          child: const Text('Chat Assistant', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ],
                    ),
                  ),
                ),
              ),

              // Statistics Cards
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 16),
                  child: Row(
                    children: [
                      _buildStatCard(context, 'Total', '${allTasks.length}', AppTheme.secondary, Icons.checklist),
                      const SizedBox(width: 8),
                      _buildStatCard(context, 'Menunggu', '$pendingCount', AppTheme.statusPending, Icons.hourglass_top),
                      const SizedBox(width: 8),
                      _buildStatCard(context, 'Berjalan', '$inProgressCount', AppTheme.statusInProgress, Icons.pending_actions),
                      const SizedBox(width: 8),
                      _buildStatCard(context, 'Selesai', '$completedCount', AppTheme.statusCompleted, Icons.check_circle_outline),
                    ],
                  ),
                ),
              ),

              // Search Box
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  child: TextField(
                    controller: _searchController,
                    onChanged: (val) => _taskService.setSearchQuery(val),
                    decoration: InputDecoration(
                      hintText: 'Cari nama atau deskripsi task...',
                      prefixIcon: const Icon(Icons.search, size: 20, color: Color(0xFF94A3B8)),
                      suffixIcon: _searchController.text.isNotEmpty
                          ? IconButton(
                              icon: const Icon(Icons.clear, size: 18),
                              onPressed: () {
                                _searchController.clear();
                                _taskService.setSearchQuery('');
                              },
                            )
                          : null,
                    ),
                  ),
                ),
              ),

              // Filter Chips
              SliverToBoxAdapter(
                child: Column(
                  children: [
                    Container(
                      height: 38,
                      margin: const EdgeInsets.only(top: 6, bottom: 4),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _statusOptions.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final opt = _statusOptions[index];
                          final isSelected = (_taskService.selectedStatusFilter ?? '') == opt['value'];
                          return ChoiceChip(
                            label: Text(opt['label']!),
                            selected: isSelected,
                            selectedColor: AppTheme.primary,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? const Color(0xFF64748B)),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 12,
                            ),
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(
                              color: isSelected ? AppTheme.primary : theme.colorScheme.outline.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (selected) {
                              _taskService.setFilter(
                                status: selected ? opt['value'] : null,
                                priority: _taskService.selectedPriorityFilter,
                              );
                            },
                          );
                        },
                      ),
                    ),
                    Container(
                      height: 34,
                      margin: const EdgeInsets.only(bottom: 6),
                      child: ListView.separated(
                        scrollDirection: Axis.horizontal,
                        padding: const EdgeInsets.symmetric(horizontal: 20),
                        itemCount: _priorityOptions.length,
                        separatorBuilder: (context, index) => const SizedBox(width: 8),
                        itemBuilder: (context, index) {
                          final opt = _priorityOptions[index];
                          final isSelected = (_taskService.selectedPriorityFilter ?? '') == opt['value'];
                          return ChoiceChip(
                            label: Text(opt['label']!),
                            selected: isSelected,
                            selectedColor: AppTheme.secondary,
                            visualDensity: VisualDensity.compact,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            labelStyle: TextStyle(
                              color: isSelected ? Colors.white : (theme.textTheme.bodyMedium?.color?.withOpacity(0.8) ?? const Color(0xFF64748B)),
                              fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                              fontSize: 11,
                            ),
                            backgroundColor: theme.colorScheme.surface,
                            side: BorderSide(
                              color: isSelected ? AppTheme.secondary : theme.colorScheme.outline.withOpacity(0.5),
                            ),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                            onSelected: (selected) {
                              _taskService.setFilter(
                                status: _taskService.selectedStatusFilter,
                                priority: selected ? opt['value'] : null,
                              );
                            },
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),

              // Task List Header
              SliverToBoxAdapter(
                child: Padding(
                  padding: const EdgeInsets.fromLTRB(20, 4, 20, 8),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        'Daftar Kegiatan (${filteredTasks.length})',
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: FontWeight.bold,
                          color: theme.textTheme.titleMedium?.color ?? const Color(0xFF0F172A),
                        ),
                      ),
                      if (_taskService.selectedStatusFilter != null || _taskService.searchQuery.isNotEmpty)
                        TextButton(
                          onPressed: () {
                            _searchController.clear();
                            _taskService.clearFilters();
                          },
                          child: const Text('Reset Filter', style: TextStyle(fontSize: 12)),
                        ),
                    ],
                  ),
                ),
              ),

              // Tasks Content
              if (isLoading && allTasks.isEmpty)
                const SliverFillRemaining(
                  child: Center(child: CircularProgressIndicator()),
                )
              else if (filteredTasks.isEmpty)
                SliverToBoxAdapter(
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(32, 28, 32, 20),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(16),
                            decoration: BoxDecoration(
                              color: isDark ? const Color(0xFF1E293B) : const Color(0xFFF1F5F9),
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(Icons.assignment_outlined, size: 48, color: Color(0xFF94A3B8)),
                          ),
                          const SizedBox(height: 16),
                          Text(
                            'Tidak ada task yang cocok',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: theme.textTheme.titleMedium?.color ?? const Color(0xFF0F172A),
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Tambahkan task baru atau sesuaikan filter pencarian Anda.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              color: theme.textTheme.bodyMedium?.color?.withOpacity(0.7) ?? const Color(0xFF64748B),
                              fontSize: 13,
                            ),
                          ),
                          const SizedBox(height: 18),
                          ElevatedButton.icon(
                            onPressed: () {
                              showDialog(
                                context: context,
                                builder: (ctx) => const TaskFormDialog(),
                              );
                            },
                            icon: const Icon(Icons.add, size: 18),
                            label: const Text('Buat Task Baru'),
                            style: ElevatedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                )
              else
                SliverPadding(
                  padding: const EdgeInsets.symmetric(horizontal: 20),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final task = filteredTasks[index];
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
                      childCount: filteredTasks.length,
                    ),
                  ),
                ),

              const SliverToBoxAdapter(
                child: SizedBox(height: 100),
              ),
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          showDialog(
            context: context,
            builder: (ctx) => const TaskFormDialog(),
          );
        },
        icon: const Icon(Icons.add),
        label: const Text('Task Baru'),
      ),
    );
  }

  Widget _buildStatCard(BuildContext context, String title, String count, Color color, IconData icon) {
    final theme = Theme.of(context);
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 4),
        decoration: BoxDecoration(
          color: theme.colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: theme.colorScheme.outline.withOpacity(0.4)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, size: 18, color: color),
            const SizedBox(height: 4),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                count,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color,
                ),
              ),
            ),
            const SizedBox(height: 2),
            FittedBox(
              fit: BoxFit.scaleDown,
              child: Text(
                title,
                maxLines: 1,
                style: TextStyle(
                  fontSize: 10,
                  color: theme.textTheme.bodySmall?.color ?? const Color(0xFF64748B),
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
