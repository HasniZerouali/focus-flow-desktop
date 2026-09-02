import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:uuid/uuid.dart';
import '../../../../core/providers/categories_provider.dart';
import '../../../../core/providers/tasks_provider.dart';
import '../../../../core/storage/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

class AddEditTaskDialog extends ConsumerStatefulWidget {
  final TaskModel? initialTask;

  const AddEditTaskDialog({super.key, this.initialTask});

  static Future<void> show(BuildContext context, {TaskModel? task}) async {
    await showDialog(
      context: context,
      builder: (ctx) => AddEditTaskDialog(initialTask: task),
    );
  }

  @override
  ConsumerState<AddEditTaskDialog> createState() => _AddEditTaskDialogState();
}

class _AddEditTaskDialogState extends ConsumerState<AddEditTaskDialog> {
  late TextEditingController _titleController;
  late TextEditingController _descController;
  late String _selectedCategory;
  late TaskPriority _priority;
  late int _estimatedMinutes;

  @override
  void initState() {
    super.initState();
    final task = widget.initialTask;
    _titleController = TextEditingController(text: task?.title ?? '');
    _descController = TextEditingController(text: task?.description ?? '');
    _selectedCategory = task?.categoryName ?? 'Development';
    _priority = task?.priority ?? TaskPriority.medium;
    _estimatedMinutes = task?.estimatedMinutes ?? 25;
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descController.dispose();
    super.dispose();
  }

  void _save() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final category = categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => const CategoryModel(id: 'Development', name: 'Development', colorHex: '6366F1', iconName: 'code'),
    );

    final task = widget.initialTask != null
        ? widget.initialTask!.copyWith(
            title: title,
            description: _descController.text.trim(),
            categoryId: category.id,
            categoryName: category.name,
            priority: _priority,
            estimatedMinutes: _estimatedMinutes,
          )
        : TaskModel(
            id: const Uuid().v4(),
            title: title,
            description: _descController.text.trim(),
            categoryId: category.id,
            categoryName: category.name,
            priority: _priority,
            estimatedMinutes: _estimatedMinutes,
            createdAt: DateTime.now(),
          );

    ref.read(tasksProvider.notifier).saveTask(task);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final isEditing = widget.initialTask != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 520),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                isEditing ? 'Edit Task' : 'Create New Task',
                style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w700),
              ),
              const SizedBox(height: 20),

              // Title
              const Text('Task Title', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _titleController,
                autofocus: true,
                decoration: const InputDecoration(
                  hintText: 'e.g. Write integration test suite...',
                ),
              ),
              const SizedBox(height: 16),

              // Description
              const Text('Description (optional)', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 8),
              TextField(
                controller: _descController,
                decoration: const InputDecoration(
                  hintText: 'Add details, sub-goals, or reference links...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Category & Priority
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<String>(
                              isExpanded: true,
                              value: categories.any((c) => c.name == _selectedCategory)
                                  ? _selectedCategory
                                  : (categories.isNotEmpty ? categories.first.name : 'Development'),
                              onChanged: (v) {
                                if (v != null) setState(() => _selectedCategory = v);
                              },
                              items: categories.map((c) {
                                return DropdownMenuItem(value: c.name, child: Text(c.name));
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Priority', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                            borderRadius: AppSpacing.roundedMd,
                            border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                          ),
                          child: DropdownButtonHideUnderline(
                            child: DropdownButton<TaskPriority>(
                              isExpanded: true,
                              value: _priority,
                              onChanged: (v) {
                                if (v != null) setState(() => _priority = v);
                              },
                              items: TaskPriority.values.map((p) {
                                return DropdownMenuItem(
                                  value: p,
                                  child: Row(
                                    children: [
                                      Container(width: 8, height: 8, decoration: BoxDecoration(color: p.color, shape: BoxShape.circle)),
                                      const SizedBox(width: 8),
                                      Text(p.label),
                                    ],
                                  ),
                                );
                              }).toList(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Estimated Duration
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Estimated Focus Time', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                      Text('$_estimatedMinutes min', style: const TextStyle(fontWeight: FontWeight.w700, color: AppColors.primary)),
                    ],
                  ),
                  Slider(
                    value: _estimatedMinutes.toDouble(),
                    min: 5,
                    max: 180,
                    divisions: 35,
                    onChanged: (v) => setState(() => _estimatedMinutes = v.round()),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Actions
              Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  OutlinedButton(
                    onPressed: () => Navigator.of(context).pop(),
                    child: const Text('Cancel'),
                  ),
                  const SizedBox(width: 12),
                  ElevatedButton(
                    onPressed: _save,
                    child: Text(isEditing ? 'Save Changes' : 'Create Task'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
