import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/categories_provider.dart';
import '../../../core/providers/sessions_provider.dart';
import '../../../core/storage/models.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/date_formatters.dart';
import '../../../core/utils/duration_formatters.dart';
import '../../../core/widgets/confirm_dialog.dart';
import '../../../core/widgets/empty_state_widget.dart';
import 'widgets/session_detail_dialog.dart';

class HistoryScreen extends ConsumerStatefulWidget {
  const HistoryScreen({super.key});

  @override
  ConsumerState<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends ConsumerState<HistoryScreen> {
  String _dateFilter = 'all'; // 'today', 'yesterday', 'week', 'month', 'all'
  String? _categoryFilter;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final sessionsAsync = ref.watch(sessionsProvider);
    final categories = ref.watch(categoriesProvider).valueOrNull ?? [];

    return Scaffold(
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Text(
                      'Focus History',
                      style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Browse, analyze, and manage all your past focus sessions.',
                      style: TextStyle(
                        fontSize: 13,
                        color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Filter Bar
            Row(
              children: [
                // Date filter tabs
                Container(
                  padding: const EdgeInsets.all(4),
                  decoration: BoxDecoration(
                    color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                    borderRadius: AppSpacing.roundedMd,
                    border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                  ),
                  child: Row(
                    children: [
                      _buildDateTab('All Time', 'all'),
                      _buildDateTab('Today', 'today'),
                      _buildDateTab('Yesterday', 'yesterday'),
                      _buildDateTab('This Week', 'week'),
                      _buildDateTab('This Month', 'month'),
                    ],
                  ),
                ),
                const SizedBox(width: 16),

                // Category filter
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

            // Grouped Session List
            Expanded(
              child: sessionsAsync.when(
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (err, _) => Center(child: Text('Error: $err')),
                data: (sessions) {
                  final filtered = _applyFilters(sessions);

                  if (filtered.isEmpty) {
                    return EmptyStateWidget(
                      icon: PhosphorIconsRegular.clockCounterClockwise,
                      title: 'No focus sessions found',
                      description: 'Complete your focus sessions to build a rich historical record of your productivity.',
                    );
                  }

                  // Group sessions by day string (e.g. YYYY-MM-DD)
                  final Map<String, List<FocusSessionModel>> grouped = {};
                  for (final s in filtered) {
                    final dayKey = DateFormatters.toIsoDay(s.startedAt);
                    grouped.putIfAbsent(dayKey, () => []).add(s);
                  }

                  final sortedKeys = grouped.keys.toList()..sort((a, b) => b.compareTo(a));

                  return ListView.builder(
                    itemCount: sortedKeys.length,
                    itemBuilder: (context, i) {
                      final dayKey = sortedKeys[i];
                      final daySessions = grouped[dayKey]!;
                      final firstSessionDate = daySessions.first.startedAt;
                      final totalDaySeconds = daySessions.fold<int>(0, (sum, s) => sum + s.durationSeconds);

                      return Padding(
                        padding: const EdgeInsets.only(bottom: 24),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            // Day header with total time
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(
                                  DateFormatters.groupDayTitle(firstSessionDate),
                                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                  decoration: BoxDecoration(
                                    color: isDark ? AppColors.darkSurfaceCard : AppColors.lightSurfaceCard,
                                    borderRadius: AppSpacing.roundedFull,
                                    border: Border.all(color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder),
                                  ),
                                  child: Text(
                                    '${DurationFormatters.formatHoursMinutes(totalDaySeconds)} total',
                                    style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 12),

                            // Sessions cards for this day
                            ...daySessions.map((session) => _buildSessionCard(context, session, isDark)),
                          ],
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

  Widget _buildSessionCard(BuildContext context, FocusSessionModel session, bool isDark) {
    final catColor = AppColors.getCategoryColor(session.categoryName);

    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Row(
          children: [
            // Category color indicator
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(color: catColor, shape: BoxShape.circle),
            ),
            const SizedBox(width: 16),

            // Title & sub-details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        session.title,
                        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w600),
                      ),
                      const SizedBox(width: 10),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                        decoration: BoxDecoration(
                          color: catColor.withValues(alpha: 0.15),
                          borderRadius: AppSpacing.roundedFull,
                        ),
                        child: Text(
                          session.categoryName,
                          style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600, color: catColor),
                        ),
                      ),
                      if (session.taskId != null) ...[
                        const SizedBox(width: 8),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                          decoration: BoxDecoration(
                            color: isDark ? AppColors.darkSurfaceElevated : AppColors.lightSurfaceElevated,
                            borderRadius: AppSpacing.roundedFull,
                          ),
                          child: Text(
                            'Task: ${session.taskTitle ?? "Linked"}',
                            style: TextStyle(
                              fontSize: 11,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  const SizedBox(height: 6),
                  Row(
                    children: [
                      Text(
                        '${DateFormatters.formatTime(session.startedAt)} - ${DateFormatters.formatTime(session.endedAt)}',
                        style: TextStyle(
                          fontSize: 12,
                          color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                        ),
                      ),
                      if (session.pauseCount > 0) ...[
                        const SizedBox(width: 12),
                        Icon(PhosphorIconsRegular.pause, size: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted),
                        const SizedBox(width: 4),
                        Text('${session.pauseCount} pauses', style: TextStyle(fontSize: 12, color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted)),
                      ],
                      if (session.distractionCount > 0) ...[
                        const SizedBox(width: 12),
                        const Icon(PhosphorIconsRegular.warningCircle, size: 12, color: AppColors.warning),
                        const SizedBox(width: 4),
                        Text(
                          '${session.distractionCount} distractions',
                          style: const TextStyle(fontSize: 12, color: AppColors.warning),
                        ),
                      ],
                      if (session.notes.isNotEmpty) ...[
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Note: ${session.notes}',
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 12,
                              fontStyle: FontStyle.italic,
                              color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ],
              ),
            ),

            // Rating Stars
            if (session.rating != null && session.rating! > 0)
              Row(
                children: List.generate(session.rating!, (_) => const Icon(PhosphorIconsFill.star, size: 14, color: AppColors.warning)),
              ),
            const SizedBox(width: 20),

            // Duration badge
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
              decoration: BoxDecoration(
                color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                borderRadius: AppSpacing.roundedMd,
              ),
              child: Text(
                DurationFormatters.formatHMS(session.durationSeconds),
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  fontFamily: 'monospace',
                ),
              ),
            ),
            const SizedBox(width: 12),

            // Edit & Delete
            IconButton(
              tooltip: 'Edit Session',
              icon: const Icon(PhosphorIconsRegular.pencilSimple, size: 16),
              onPressed: () => SessionDetailDialog.show(context, session),
            ),
            IconButton(
              tooltip: 'Delete Session',
              icon: const Icon(PhosphorIconsRegular.trash, size: 16),
              onPressed: () async {
                final confirm = await ConfirmDialog.show(
                  context,
                  title: 'Delete Focus Session',
                  message: 'Are you sure you want to permanently delete "${session.title}" (${DurationFormatters.formatHoursMinutes(session.durationSeconds)})? This will adjust your total stats.',
                  confirmLabel: 'Delete',
                  isDestructive: true,
                );
                if (confirm) {
                  ref.read(sessionsProvider.notifier).deleteSession(session.id);
                }
              },
            ),
          ],
        ),
      ),
    );
  }

  List<FocusSessionModel> _applyFilters(List<FocusSessionModel> sessions) {
    final now = DateTime.now();

    return sessions.where((s) {
      if (_categoryFilter != null && s.categoryName != _categoryFilter) {
        return false;
      }

      switch (_dateFilter) {
        case 'today':
          return DateFormatters.isToday(s.startedAt);
        case 'yesterday':
          return DateFormatters.isYesterday(s.startedAt);
        case 'week':
          final startOfWeek = now.subtract(Duration(days: now.weekday - 1));
          return s.startedAt.isAfter(DateTime(startOfWeek.year, startOfWeek.month, startOfWeek.day));
        case 'month':
          return s.startedAt.year == now.year && s.startedAt.month == now.month;
        case 'all':
        default:
          return true;
      }
    }).toList();
  }

  Widget _buildDateTab(String label, String value) {
    final isSelected = _dateFilter == value;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return InkWell(
      borderRadius: AppSpacing.roundedSm,
      onTap: () => setState(() => _dateFilter = value),
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
