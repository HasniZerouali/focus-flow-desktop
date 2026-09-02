import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/tasks_provider.dart';
import '../../../core/providers/timer_provider.dart';
import '../../../core/storage/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'widgets/add_edit_task_dialog.dart';

class TasksScreen extends ConsumerStatefulWidget {
  const TasksScreen({super.key});

  @override
  ConsumerState<TasksScreen> createState() => _TasksScreenState();
}

class _TasksScreenState extends ConsumerState<TasksScreen> {
  String _searchQuery = '';
  String _filter = 'active'; // 'all', 'active', 'completed'
  String? _categoryFilter;

  void _startFocusOnTask(TaskModel task) {
    ref.read(timerServiceProvider).startSession(
          title: task.title,
          categoryId: task.categoryId,
          categoryName: task.categoryName,
          taskId: task.id,
          taskTitle: task.title,
          mode: TimerMode.free,
        );

    context.go('/focus');
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    final tasksAsync = ref.watch(tasksProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header: Title & "+ Add Task" button
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Tasks & Projects',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Organize items and launch targeted focus sprints directly.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
                ElevatedButton.icon(
                  onPressed: () => AddEditTaskDialog.show(context),
                  icon: const Icon(PhosphorIconsBold.plus, size: 16),
                  label: const Text('Add Task', style: TextStyle(fontWeight: FontWeight.w600)),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Bar: Search, Status tabs, Category filter
            Row(
              children: [
                // Search field
                Expanded(
                  child: TextField(
                    onChanged: (v) => setState(() => _searchQuery = v.trim().toLowerCase()),
                    decoration: const InputDecoration(
                      hintText: 'Search tasks by title...',
                      prefixIcon: Icon(PhosphorIconsRegular.magnifyingGlass, size: 18),
                      contentPadding: EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    ),
                  ),
                ),
                const SizedBox(width: 16),

                // Status Tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      _buildFilterChip('Active', 'active'),
                      _buildFilterChip('All', 'all'),
                      _buildFilterChip('Completed', 'completed'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Category Filter
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                  ),
                  child: DropdownButtonHideUnderline(
                    child: DropdownButton<String?>(
                      value: _categoryFilter,
                      hint: const Text('All Categories', style: TextStyle(fontSize: 13)),
                      icon: const Icon(PhosphorIconsRegular.funnel, size: 16),
                      onChanged: (v) => setState(() => _categoryFilter = v),
                      items: [
                        const DropdownMenuItem<String?>(
                          value: null,
                          child: Text('All Categories'),
                        ),
                        ...categories.map((c) {
                          return DropdownMenuItem<String?>(
                            value: c.name,
                            child: Text(c.name),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 24),

            // Tasks List
            Expanded(
              child: tasksAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (tasks) {
                  var filtered = tasks.where((t) {
                    if (_filter == 'active' && t.completed) return false;
                    if (_filter == 'completed' && !t.completed) return false;
                    if (_categoryFilter != null && t.categoryName != _categoryFilter) return false;
                    if (_searchQuery.isNotEmpty && !t.title.toLowerCase().contains(_searchQuery)) return false;
                    return true;
                  }).toList();

                  if (filtered.isEmpty) {
                    return EmptyStateWidget(
                      icon: PhosphorIconsRegular.checkSquare,
                      title: _searchQuery.isNotEmpty
                          ? 'No matching tasks found'
                          : (_filter == 'completed' ? 'No completed tasks yet' : 'No tasks on your list'),
                      description: 'Create actionable tasks and launch focused timer sessions directly from them.',
                      actionLabel: 'Create New Task',
                      onAction: () => AddEditTaskDialog.show(context),
                    );
                  }

                  return ListView.separated(
                    itemCount: filtered.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 10),
                    itemBuilder: (context, index) {
                      final task = filtered[index];
                      final catColor = AppColors.getCategoryColor(task.categoryName);

                      return Card(
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
                          child: Row(
                            children: [
                              // Checkbox
                              Checkbox(
                                value: task.completed,
                                activeColor: AppColors.success,
                                shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedSm),
                                onChanged: (_) {
                                  ref.read(tasksProvider.notifier).toggleTaskCompleted(task.id);
                                },
                              ),
                              const SizedBox(width: 12),

                              // Priority pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: task.priority.color.withValues(alpha: 0.15),
                                  borderRadius: AppSpacing.roundedFull,
                                ),
                                child: Text(
                                  task.priority.label,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w700,
                                    color: task.priority.color,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 10),

                              // Category pill
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: catColor.withValues(alpha: 0.15),
                                  borderRadius: AppSpacing.roundedFull,
                                ),
                                child: Text(
                                  task.categoryName,
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w600,
                                    color: catColor,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 14),

                              // Task details
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      task.title,
                                      style: TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w600,
                                        decoration: task.completed ? TextDecoration.lineThrough : null,
                                        color: task.completed
                                            ? (isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)
                                            : (isDark ? AppColors.darkTextPrimary : AppColors.lightTextPrimary),
                                      ),
                                    ),
                                    if (task.description.isNotEmpty) ...[
                                      const SizedBox(height: 2),
                                      Text(
                                        task.description,
                                        maxLines: 1,
                                        overflow: TextOverflow.ellipsis,
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),

                              // Focus Time comparison
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.end,
                                children: [
                                  Text(
                                    '${DurationFormatters.formatHoursMinutes(task.totalFocusTimeSeconds)} focused',
                                    style: const TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      fontFamily: 'monospace',
                                    ),
                                  ),
                                  Text(
                                    'est. ${task.estimatedMinutes}m',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(width: 16),

                              // "Start Focus" pre-linked button
                              if (!task.completed) ...[
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                                    textStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                                  ),
                                  onPressed: () => _startFocusOnTask(task),
                                  icon: const Icon(PhosphorIconsFill.play, size: 12),
                                  label: const Text('Focus'),
                                ),
                                const SizedBox(width: 8),
                              ],

                              // Edit & Delete
                              IconButton(
                                tooltip: 'Edit Task',
                                icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16),
                                onPressed: () => AddEditTaskDialog.show(context, task: task),
                              ),
                              IconButton(
                                tooltip: 'Delete Task',
                                icon: const Icon(PhosphorIconsRegular.trash, size: 16),
                                onPressed: () async {
                                  final confirm = await ConfirmDialog.show(
                                    context,
                                    title: 'Delete Task',
                                    message: 'Are you sure you want to delete "${task.title}"?',
                                    confirmLabel: 'Delete',
                                    isDestructive: true,
                                  );
                                  if (confirm) {
                                    ref.read(tasksProvider.notifier).deleteTask(task.id);
                                  }
                                },
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFilterChip(String label, String value) {
    final isSelected = _filter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: AppSpacing.roundedSm,
      onTap: () => setState(() => _filter = value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: isSelected ? AppColors.primary : Colors.transparent,
          borderRadius: AppSpacing.roundedSm,
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w600,
            color: isSelected
                ? Colors.white
                : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
          ),
        ),
      ),
    );
  }
}
