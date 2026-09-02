import 'dart:math';
import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import '../../../core/providers/statistics_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/duration_formatters.dart';
import '../../../core/utils/productivity_score.dart';
import '../../../core/widgets/stat_card.dart';

class StatisticsScreen extends ConsumerWidget {
  const StatisticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final stats = ref.watch(statisticsProvider);

    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Productivity & Insights',
                  style: TextStyle(fontSize: 24, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 4),
                Text(
                  'Objective trends, category distribution, and motivational focus metrics.',
                  style: TextStyle(
                    fontSize: 13,
                    color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 28),

            // Top 4 Metric Cards
            LayoutBuilder(
              builder: (context, constraints) {
                final cardWidth = (constraints.maxWidth - (3 * 16)) / 4;
                return Wrap(
                  spacing: 16,
                  runSpacing: 16,
                  children: [
                    SizedBox(
                      width: cardWidth.clamp(200, 350),
                      child: StatCard(
                        icon: PhosphorIconsRegular.chartLineUp,
                        iconColor: AppColors.primary,
                        title: 'Weekly Focus Time',
                        value: DurationFormatters.formatHoursMinutes(stats.weeklyTotalMinutes * 60),
                        subtitle: 'Last 7 days total',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth.clamp(200, 350),
                      child: StatCard(
                        icon: PhosphorIconsRegular.clock,
                        iconColor: AppColors.info,
                        title: 'Average Session',
                        value: '${stats.averageSessionMinutes} min',
                        subtitle: 'Across completed sprints',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth.clamp(200, 350),
                      child: StatCard(
                        icon: PhosphorIconsRegular.trophy,
                        iconColor: AppColors.warning,
                        title: 'Best Focus Day',
                        value: stats.bestDayInfo,
                        subtitle: 'Peak performance day',
                      ),
                    ),
                    SizedBox(
                      width: cardWidth.clamp(200, 350),
                      child: StatCard(
                        icon: PhosphorIconsRegular.folderSimple,
                        iconColor: AppColors.success,
                        title: 'Top Category',
                        value: stats.mostProductiveCategory,
                        subtitle: 'Most focused domain',
                      ),
                    ),
                  ],
                );
              },
            ),

            const SizedBox(height: 28),

            // Middle Section: 7-Day Chart & Motivational Productivity Score
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 7-Day Bar Chart
                Expanded(
                  flex: 3,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'Daily Focus Time (Last 7 Days)',
                                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    'Focus minutes completed per day',
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary,
                                    ),
                                  ),
                                ],
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: AppColors.primary.withValues(alpha: 0.15),
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: Text(
                                  '${stats.weeklyTotalMinutes}m Total',
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: AppColors.primary,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 32),

                          // FL_CHART Bar Chart
                          SizedBox(
                            height: 240,
                            child: _buildBarChart(stats.last7DaysBars, isDark),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Motivational Productivity Score Card
                Expanded(
                  flex: 2,
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Container(
                                padding: const EdgeInsets.all(8),
                                decoration: BoxDecoration(
                                  color: AppColors.warning.withValues(alpha: 0.15),
                                  borderRadius: AppSpacing.roundedSm,
                                ),
                                child: const Icon(PhosphorIconsFill.sparkle, size: 18, color: AppColors.warning),
                              ),
                              const SizedBox(width: 10),
                              const Text(
                                'Productivity Score',
                                style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                              ),
                            ],
                          ),
                          const SizedBox(height: 24),

                          // Big Score Number & Label
                          Center(
                            child: Column(
                              children: [
                                Text(
                                  '${stats.productivityScore}',
                                  style: const TextStyle(
                                    fontSize: 64,
                                    fontWeight: FontWeight.w800,
                                    letterSpacing: -1.0,
                                    color: AppColors.primary,
                                  ),
                                ),
                                Text(
                                  ProductivityScoreCalculator.getLabel(stats.productivityScore),
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 20),

                          // Score Progress Ring / Bar
                          ClipRRect(
                            borderRadius: AppSpacing.roundedFull,
                            child: LinearProgressIndicator(
                              value: (stats.productivityScore / 100).clamp(0.0, 1.0),
                              minHeight: 10,
                              backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                              valueColor: const AlwaysStoppedAnimation<Color>(AppColors.primary),
                            ),
                          ),
                          const SizedBox(height: 16),

                          // Explicit motivational disclaimer
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                              borderRadius: AppSpacing.roundedMd,
                            ),
                            child: Row(
                              children: [
                                const Icon(PhosphorIconsRegular.info, size: 16, color: AppColors.info),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    'Motivational metric derived from focus ratio, completed goals, and distraction discipline. Purely for self-reflection.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                                      height: 1.3,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 28),

            // Bottom Section: Category Breakdown & Secondary Metrics
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Category Distribution
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Focus Time by Category',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 16),
                          if (stats.categoryMinutes.isEmpty)
                            const Padding(
                              padding: EdgeInsets.symmetric(vertical: 24),
                              child: Center(child: Text('No categorized sessions recorded yet')),
                            )
                          else
                            ...stats.categoryMinutes.entries.map((entry) {
                              final total = max(stats.weeklyTotalMinutes, 1);
                              final pct = (entry.value / total).clamp(0.0, 1.0);
                              final color = AppColors.getCategoryColor(entry.key);

                              return Padding(
                                padding: const EdgeInsets.only(bottom: 14),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: [
                                        Row(
                                          children: [
                                            Container(width: 8, height: 8, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                                            const SizedBox(width: 8),
                                            Text(entry.key, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 13)),
                                          ],
                                        ),
                                        Text(
                                          '${entry.value}m (${(pct * 100).toInt()}%)',
                                          style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600, fontFamily: 'monospace'),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 6),
                                    ClipRRect(
                                      borderRadius: AppSpacing.roundedFull,
                                      child: LinearProgressIndicator(
                                        value: pct,
                                        minHeight: 6,
                                        backgroundColor: isDark ? AppColors.darkSurface : AppColors.lightSurfaceElevated,
                                        valueColor: AlwaysStoppedAnimation<Color>(color),
                                      ),
                                    ),
                                  ],
                                ),
                              );
                            }),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(width: 20),

                // Distractions & Quality Summary
                Expanded(
                  child: Card(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'Session Quality & Focus Sprints',
                            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 20),
                          _buildQualityRow(
                            icon: PhosphorIconsRegular.checkCircle,
                            iconColor: AppColors.success,
                            title: 'Completion Rate',
                            value: '${(stats.completionRate * 100).toInt()}%',
                            subtitle: 'Sessions completed to full duration',
                            isDark: isDark,
                          ),
                          const Divider(height: 28),
                          _buildQualityRow(
                            icon: PhosphorIconsRegular.warningCircle,
                            iconColor: AppColors.warning,
                            title: 'Distractions Logged',
                            value: '${stats.totalDistractions}',
                            subtitle: 'Attention pulls recorded across all sessions',
                            isDark: isDark,
                          ),
                          const Divider(height: 28),
                          _buildQualityRow(
                            icon: PhosphorIconsRegular.listNumbers,
                            iconColor: AppColors.info,
                            title: 'Total Sessions Recorded',
                            value: '${stats.totalSessions}',
                            subtitle: 'Historical focus sprint entries',
                            isDark: isDark,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBarChart(List<DailyBarData> bars, bool isDark) {
    final maxMinutes = bars.fold<int>(60, (m, b) => b.focusMinutes > m ? b.focusMinutes : m);
    final maxY = (maxMinutes * 1.25).ceilToDouble();

    return BarChart(
      BarChartData(
        maxY: maxY,
        alignment: BarChartAlignment.spaceAround,
        barTouchData: BarTouchData(
          touchTooltipData: BarTouchTooltipData(
            getTooltipItem: (group, groupIndex, rod, rodIndex) {
              final bar = bars[groupIndex];
              return BarTooltipItem(
                '${bar.dayLabel}\n${bar.focusMinutes} min',
                const TextStyle(color: Colors.white, fontWeight: FontWeight.w700, fontSize: 12),
              );
            },
          ),
        ),
        titlesData: FlTitlesData(
          topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
          leftTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              reservedSize: 40,
              getTitlesWidget: (value, meta) {
                if (value == 0) return const SizedBox();
                final valInt = value.toInt();
                if (valInt % 30 != 0 && valInt != maxY.toInt()) return const SizedBox();
                return Text(
                  valInt >= 60 ? '${valInt ~/ 60}h' : '${valInt}m',
                  style: TextStyle(
                    fontSize: 11,
                    color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                  ),
                );
              },
            ),
          ),
          bottomTitles: AxisTitles(
            sideTitles: SideTitles(
              showTitles: true,
              getTitlesWidget: (value, meta) {
                final index = value.toInt();
                if (index < 0 || index >= bars.length) return const SizedBox();
                final bar = bars[index];
                final isToday = index == bars.length - 1;

                return Padding(
                  padding: const EdgeInsets.only(top: 8),
                  child: Text(
                    bar.dayLabel,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: isToday ? FontWeight.w700 : FontWeight.w500,
                      color: isToday
                          ? AppColors.primary
                          : (isDark ? AppColors.darkTextSecondary : AppColors.lightTextSecondary),
                    ),
                  ),
                );
              },
            ),
          ),
        ),
        gridData: FlGridData(
          show: true,
          drawVerticalLine: false,
          horizontalInterval: 30,
          getDrawingHorizontalLine: (value) => FlLine(
            color: isDark ? AppColors.darkBorderSubtle : AppColors.lightBorder,
            strokeWidth: 1,
          ),
        ),
        borderData: FlBorderData(show: false),
        barGroups: List.generate(bars.length, (index) {
          final bar = bars[index];
          final isToday = index == bars.length - 1;

          return BarChartGroupData(
            x: index,
            barRods: [
              BarChartRodData(
                toY: bar.focusMinutes.toDouble(),
                color: isToday ? AppColors.primary : AppColors.primaryLight.withValues(alpha: 0.6),
                width: 24,
                borderRadius: const BorderRadius.vertical(top: Radius.circular(6)),
              ),
            ],
          );
        }),
      ),
    );
  }

  Widget _buildQualityRow({
    required IconData icon,
    required Color iconColor,
    required String title,
    required String value,
    required String subtitle,
    required bool isDark,
  }) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: iconColor.withValues(alpha: 0.15),
            borderRadius: AppSpacing.roundedSm,
          ),
          child: Icon(icon, size: 20, color: iconColor),
        ),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
              const SizedBox(height: 2),
              Text(
                subtitle,
                style: TextStyle(
                  fontSize: 11,
                  color: isDark ? AppColors.darkTextMuted : AppColors.lightTextMuted,
                ),
              ),
            ],
          ),
        ),
        Text(
          value,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w700,
            color: iconColor,
            fontFamily: 'monospace',
          ),
        ),
      ],
    );
  }
}
