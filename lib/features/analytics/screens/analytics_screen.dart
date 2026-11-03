import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../medications/data/medication_model.dart';
import '../../medications/providers/medication_providers.dart';
import '../../report/services/pdf_report_service.dart';

class AnalyticsScreen extends ConsumerWidget {
  const AnalyticsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final weekLogsAsync = ref.watch(weekLogsProvider);
    final monthLogsAsync = ref.watch(monthLogsProvider);
    final todayLogsAsync = ref.watch(todayLogsProvider);

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('analytics_title'))),
      body: weekLogsAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (weekLogs) {
          final todayLogs = todayLogsAsync.asData?.value ?? [];
          final stats = _buildDayStats(weekLogs);
          final totalScheduled = weekLogs.length;
          final totalTaken =
              weekLogs.where((l) => l.status == 'taken').length;
          final compliance = totalScheduled > 0
              ? (totalTaken / totalScheduled * 100).round()
              : 0;
          final missedToday =
              todayLogs.where((l) => l.status == 'missed').toList();

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _ComplianceCard(compliance: compliance, l10n: l10n),
                const SizedBox(height: 20),
                Text(l10n.get('last_7_days'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 16),
                _FlBarChart(stats: stats),
                const SizedBox(height: 24),

                // Monthly calendar
                Text('Ce mois-ci',
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                monthLogsAsync.when(
                  loading: () =>
                      const Center(child: CircularProgressIndicator()),
                  error: (_, _) => const SizedBox.shrink(),
                  data: (monthLogs) =>
                      _MonthCalendar(logs: monthLogs),
                ),
                const SizedBox(height: 24),

                if (missedToday.isNotEmpty) ...[
                  Text(l10n.get('missed_today'),
                      style: Theme.of(context)
                          .textTheme
                          .titleLarge
                          ?.copyWith(color: Colors.red.shade600)),
                  const SizedBox(height: 12),
                  ...missedToday.map((log) => _MissedLogTile(log: log)),
                  const SizedBox(height: 24),
                ],
                Text(l10n.get('weekly_report'),
                    style: Theme.of(context).textTheme.titleLarge),
                const SizedBox(height: 12),
                FilledButton.icon(
                  onPressed: () =>
                      PdfReportService.generateAndShare(weekLogs, l10n),
                  icon: const Icon(Icons.picture_as_pdf_rounded),
                  label: Text(l10n.get('generate_pdf')),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
                const SizedBox(height: 20),
              ],
            ),
          );
        },
      ),
    );
  }

  List<_DayStat> _buildDayStats(List<IntakeLog> logs) {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final dayLogs = logs.where((l) => l.date == dateStr).toList();
      final taken = dayLogs.where((l) => l.status == 'taken').length;
      final total = dayLogs.length;
      String label;
      try {
        label = DateFormat('E', 'fr_FR').format(day);
      } catch (_) {
        label = DateFormat('E').format(day);
      }
      return _DayStat(label: label, taken: taken, total: total);
    });
  }
}

// ── fl_chart bar chart ────────────────────────────────────────────────────────

class _FlBarChart extends StatelessWidget {
  final List<_DayStat> stats;
  const _FlBarChart({required this.stats});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 220,
      padding: const EdgeInsets.fromLTRB(8, 16, 8, 8),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: 100,
          barGroups: stats.asMap().entries.map((e) {
            final pct = e.value.total > 0
                ? (e.value.taken / e.value.total * 100)
                : 0.0;
            return BarChartGroupData(
              x: e.key,
              barRods: [
                BarChartRodData(
                  toY: pct,
                  gradient: const LinearGradient(
                    colors: [AppTheme.secondary, AppTheme.primary],
                    begin: Alignment.bottomCenter,
                    end: Alignment.topCenter,
                  ),
                  width: 22,
                  borderRadius: const BorderRadius.vertical(
                      top: Radius.circular(8)),
                  backDrawRodData: BackgroundBarChartRodData(
                    show: true,
                    toY: 100,
                    color: Colors.grey.shade100,
                  ),
                ),
              ],
            );
          }).toList(),
          titlesData: FlTitlesData(
            leftTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            topTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            rightTitles:
                const AxisTitles(sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= stats.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(
                      stats[i].label,
                      style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600),
                    ),
                  );
                },
              ),
            ),
          ),
          gridData: const FlGridData(show: false),
          borderData: FlBorderData(show: false),
          barTouchData: BarTouchData(
            touchTooltipData: BarTouchTooltipData(
              getTooltipColor: (_) => AppTheme.primary,
              getTooltipItem: (group, _, rod, _) => BarTooltipItem(
                '${rod.toY.round()}%',
                const TextStyle(
                    color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ),
        ),
      ),
    ).animate().fade(delay: 150.ms, duration: 400.ms).slideY(begin: 0.1);
  }
}

// ── Monthly calendar ──────────────────────────────────────────────────────────

class _MonthCalendar extends StatelessWidget {
  final List<IntakeLog> logs;
  const _MonthCalendar({required this.logs});

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final daysInMonth = DateTime(now.year, now.month + 1, 0).day;
    // weekday: Mon=1 Sun=7, we want Mon=0
    final startOffset = (firstDay.weekday - 1) % 7;

    final byDate = <String, List<IntakeLog>>{};
    for (final log in logs) {
      byDate.putIfAbsent(log.date, () => []).add(log);
    }

    const weekDays = ['L', 'M', 'M', 'J', 'V', 'S', 'D'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        children: [
          // Weekday headers
          Row(
            children: weekDays
                .map((d) => Expanded(
                      child: Center(
                        child: Text(d,
                            style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: Colors.grey.shade500)),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),
          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              childAspectRatio: 1,
              mainAxisSpacing: 4,
              crossAxisSpacing: 4,
            ),
            itemCount: startOffset + daysInMonth,
            itemBuilder: (_, index) {
              if (index < startOffset) return const SizedBox();
              final day = index - startOffset + 1;
              final date = DateTime(now.year, now.month, day);
              final dateStr = DateFormat('yyyy-MM-dd').format(date);
              final dayLogs = byDate[dateStr] ?? [];
              final isToday = day == now.day;
              final isFuture = date.isAfter(now);

              Color bgColor;
              if (isFuture) {
                bgColor = Colors.grey.shade100;
              } else if (dayLogs.isEmpty) {
                bgColor = Colors.grey.shade200;
              } else if (dayLogs.any((l) => l.status == 'missed')) {
                bgColor = Colors.red.shade200;
              } else if (dayLogs.every((l) => l.status == 'taken')) {
                bgColor = Colors.green.shade300;
              } else {
                bgColor = Colors.orange.shade200;
              }

              return Container(
                decoration: BoxDecoration(
                  color: bgColor,
                  shape: BoxShape.circle,
                  border: isToday
                      ? Border.all(color: AppTheme.primary, width: 2)
                      : null,
                ),
                child: Center(
                  child: Text(
                    '$day',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight:
                          isToday ? FontWeight.w800 : FontWeight.w500,
                      color: isFuture
                          ? Colors.grey.shade400
                          : Colors.black87,
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 12),
          // Legend
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              _LegendDot(color: Colors.green.shade300, label: 'Tout pris'),
              const SizedBox(width: 16),
              _LegendDot(color: Colors.red.shade200, label: 'Oubli'),
              const SizedBox(width: 16),
              _LegendDot(
                  color: Colors.orange.shade200, label: 'En cours'),
            ],
          ),
        ],
      ),
    ).animate().fade(delay: 200.ms, duration: 400.ms);
  }
}

class _LegendDot extends StatelessWidget {
  final Color color;
  final String label;
  const _LegendDot({required this.color, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
            width: 10,
            height: 10,
            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
        const SizedBox(width: 4),
        Text(label,
            style:
                TextStyle(fontSize: 11, color: Colors.grey.shade600)),
      ],
    );
  }
}

// ── Supporting types ──────────────────────────────────────────────────────────

class _DayStat {
  final String label;
  final int taken;
  final int total;
  const _DayStat(
      {required this.label, required this.taken, required this.total});
  double get rate => total > 0 ? taken / total : 0;
}

// ── Compliance card ───────────────────────────────────────────────────────────

class _ComplianceCard extends StatelessWidget {
  final int compliance;
  final AppLocalizations l10n;
  const _ComplianceCard({required this.compliance, required this.l10n});

  String get _message {
    if (compliance >= 90) return l10n.get('compliance_perfect');
    if (compliance >= 70) return l10n.get('compliance_good');
    if (compliance >= 50) return l10n.get('compliance_fair');
    return l10n.get('compliance_poor');
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [AppTheme.primary, Color(0xFFB89DD4)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: AppTheme.primary.withValues(alpha: 0.3),
            blurRadius: 16,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(l10n.get('compliance'),
                    style:
                        const TextStyle(color: Colors.white70, fontSize: 15)),
                const SizedBox(height: 8),
                Text('$compliance%',
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 48,
                        fontWeight: FontWeight.w800)),
                Text(_message,
                    style: const TextStyle(
                        color: Colors.white, fontSize: 15)),
              ],
            ),
          ),
          SizedBox(
            width: 80,
            height: 80,
            child: CircularProgressIndicator(
              value: compliance / 100,
              strokeWidth: 8,
              backgroundColor: Colors.white24,
              color: Colors.white,
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.1);
  }
}

// ── Missed log tile ───────────────────────────────────────────────────────────

class _MissedLogTile extends StatelessWidget {
  final IntakeLog log;
  const _MissedLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        leading: Container(
          width: 44,
          height: 44,
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Icon(Icons.cancel_outlined, color: Colors.red),
        ),
        title: Text(log.medicationName,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 16)),
        subtitle: Text('${log.dose} • ${log.timeSlot}'),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.red.shade50,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text('Oublié',
              style: TextStyle(
                  color: Colors.red.shade700,
                  fontWeight: FontWeight.w700,
                  fontSize: 13)),
        ),
      ),
    );
  }
}
