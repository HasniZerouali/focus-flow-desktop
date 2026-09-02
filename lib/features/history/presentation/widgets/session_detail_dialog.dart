import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../../core/providers/categories_provider.dart';
import '../../../../core/providers/database_provider.dart';
import '../../../../core/providers/sessions_provider.dart';
import '../../../../core/storage/models.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';
import '../../../../core/utils/date_formatters.dart';
import '../../../../core/utils/duration_formatters.dart';

class SessionDetailDialog extends ConsumerStatefulWidget {
  final FocusSessionModel session;

  const SessionDetailDialog({super.key, required this.session});

  static Future<void> show(BuildContext context, FocusSessionModel session) async {
    await showDialog(
      context: context,
      builder: (ctx) => SessionDetailDialog(session: session),
    );
  }

  @override
  ConsumerState<SessionDetailDialog> createState() => _SessionDetailDialogState();
}

class _SessionDetailDialogState extends ConsumerState<SessionDetailDialog> {
  late TextEditingController _titleController;
  late TextEditingController _notesController;
  late String _selectedCategory;
  int? _rating;
  List<DistractionModel> _distractions = [];
  bool _loadingDistractions = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.session.title);
    _notesController = TextEditingController(text: widget.session.notes);
    _selectedCategory = widget.session.categoryName;
    _rating = widget.session.rating;
    _loadDistractions();
  }

  Future<void> _loadDistractions() async {
    final db = ref.read(appDatabaseProvider);
    final list = await db.getDistractionsForSession(widget.session.id);
    if (mounted) {
      setState(() {
        _distractions = list;
        _loadingDistractions = false;
      });
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _saveChanges() {
    final title = _titleController.text.trim();
    if (title.isEmpty) return;

    final categories = ref.read(categoriesProvider).valueOrNull ?? [];
    final category = categories.firstWhere(
      (c) => c.name == _selectedCategory,
      orElse: () => const CategoryModel(id: 'Development', name: 'Development', colorHex: '6366F1', iconName: 'code'),
    );

    final updated = widget.session.copyWith(
      title: title,
      categoryId: category.id,
      categoryName: category.name,
      rating: _rating,
      notes: _notesController.text.trim(),
    );

    ref.read(sessionsProvider.notifier).updateSession(updated);
    Navigator.of(context).pop();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];
    final catColor = AppColors.getCategoryColor(_selectedCategory);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: AppSpacing.roundedXl),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 540),
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Session Details', style: TextStyle(fontSize: 20, fontWeight: FontWeight.w700)),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: catColor.withValues(alpha: 0.15),
                      borderRadius: AppSpacing.roundedFull,
                    ),
                    child: Text(
                      _selectedCategory,
                      style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: catColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title input
              TextField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: 'Session Title'),
              ),
              const SizedBox(height: 16),

              // Stats summary row
              Container(
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                  borderRadius: AppSpacing.roundedMd,
                  border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _buildMiniStat('Duration', DurationFormatters.formatHMS(widget.session.durationSeconds)),
                    _buildMiniStat('Started', DateFormatters.formatTime(widget.session.startedAt)),
                    _buildMiniStat('Ended', DateFormatters.formatTime(widget.session.endedAt)),
                    _buildMiniStat('Pauses', '${widget.session.pauseCount}'),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Category Picker & Star Rating
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('Category', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 6),
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
                              items: categories.map((c) => DropdownMenuItem(value: c.name, child: Text(c.name))).toList(),
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
                        const Text('Rating', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                        const SizedBox(height: 4),
                        Row(
                          children: List.generate(5, (index) {
                            final star = index + 1;
                            final filled = star <= (_rating ?? 0);
                            return IconButton(
                              padding: EdgeInsets.zero,
                              constraints: const BoxConstraints(minWidth: 26),
                              icon: Icon(
                                filled ? PhosphorIconsFill.star : PhosphorIconsRegular.star,
                                size: 20,
                                color: filled ? AppColors.warning : AppColors.darkTextMuted,
                              ),
                              onPressed: () => setState(() => _rating = star),
                            );
                          }),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Notes
              TextField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Session Notes',
                  hintText: 'Add reflections...',
                ),
                maxLines: 2,
              ),
              const SizedBox(height: 16),

              // Distractions List (if any logged)
              if (!_loadingDistractions && _distractions.isNotEmpty) ...[
                const Text('Logged Distractions', style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                const SizedBox(height: 8),
                Container(
                  constraints: const BoxConstraints(maxHeight: 110),
                  child: ListView.separated(
                    shrinkWrap: true,
                    itemCount: _distractions.length,
                    separatorBuilder: (_, __) => const SizedBox(height: 6),
                    itemBuilder: (context, i) {
                      final d = _distractions[i];
                      return Container(
                        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                        decoration: BoxDecoration(
                          color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                          borderRadius: AppSpacing.roundedSm,
                        ),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.spaceBetween,
                          children: [
                            Text('${d.type}${d.note.isNotEmpty ? " (${d.note})" : ""}', style: const TextStyle(fontSize: 12)),
                            Text(DateFormatters.formatTime(d.timestamp), style: TextStyle(fontSize: 11, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
                const SizedBox(height: 16),
              ],

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
                    onPressed: _saveChanges,
                    child: const Text('Save Changes'),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildMiniStat(String label, String value) {
    return Column(
      children: [
        Text(value, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700, fontFamily: 'monospace')),
        const SizedBox(height: 2),
        Text(label, style: const TextStyle(fontSize: 11, color: AppColors.darkTextMuted)),
      ],
    );
  }
}
