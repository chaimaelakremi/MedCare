import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../data/medication_model.dart';
import '../providers/medication_providers.dart';
import '../widgets/medication_card.dart';

class HomeScreen extends ConsumerStatefulWidget {
  const HomeScreen({super.key});

  @override
  ConsumerState<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends ConsumerState<HomeScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      ref.read(medicationNotifierProvider.notifier).ensureTodayLogs();
    });
  }

  String _formatLocalizedDate(DateTime date, String pattern, String locale) {
    try {
      return DateFormat(pattern, locale).format(date);
    } catch (_) {
      return DateFormat('yyyy-MM-dd').format(date);
    }
  }

  String _greeting(AppLocalizations l10n) {
    final h = DateTime.now().hour;
    if (h < 12) return l10n.get('greeting_morning');
    if (h < 18) return l10n.get('greeting_afternoon');
    return l10n.get('greeting_evening');
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final userDoc = ref.watch(userDocProvider).asData?.value;
    final logsAsync = ref.watch(todayLogsProvider);
    final streak = ref.watch(streakProvider);
    final name = (userDoc?['name'] as String?)?.split(' ').first ?? '';
    final today = _formatLocalizedDate(
        DateTime.now(),
        'EEEE d MMMM yyyy',
        l10n.locale == 'fr' ? 'fr_FR' : 'en_US');

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(24, 24, 24, 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                '${_greeting(l10n)}${name.isNotEmpty ? ', $name' : ''} 👋',
                                style: Theme.of(context).textTheme.headlineSmall,
                              ),
                              const SizedBox(height: 4),
                              Text(today,
                                  style: Theme.of(context)
                                      .textTheme
                                      .bodyMedium),
                            ],
                          ),
                        ),
                        const SizedBox(width: 12),
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppTheme.primary.withValues(alpha: 0.12),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(Icons.medical_services_rounded,
                              color: AppTheme.primary, size: 24),
                        ),
                      ],
                    ).animate().fade(duration: 400.ms).slideY(begin: -0.1),
                    const SizedBox(height: 12),
                    _StreakBadge(streak: streak)
                        .animate()
                        .scale(delay: 200.ms, curve: Curves.elasticOut),
                    const SizedBox(height: 20),
                    logsAsync.when(
                      loading: () => const SizedBox.shrink(),
                      error: (_, _) => const SizedBox.shrink(),
                      data: (logs) => _SummaryCard(logs: logs, l10n: l10n),
                    ),
                    const SizedBox(height: 20),
                    Text(l10n.get('medications_today'),
                        style: Theme.of(context).textTheme.titleLarge),
                    const SizedBox(height: 4),
                  ],
                ),
              ),
            ),
            logsAsync.when(
              loading: () => const SliverToBoxAdapter(
                child: Padding(
                  padding: EdgeInsets.all(40),
                  child: Center(child: CircularProgressIndicator()),
                ),
              ),
              error: (e, _) => SliverToBoxAdapter(
                child: Center(child: Text('Erreur: $e')),
              ),
              data: (logs) {
                if (logs.isEmpty) {
                  return SliverToBoxAdapter(
                    child: Padding(
                      padding: const EdgeInsets.all(40),
                      child: Column(
                        children: [
                          const Text('💊', style: TextStyle(fontSize: 64)),
                          const SizedBox(height: 16),
                          Text(l10n.get('no_medications'),
                              style: Theme.of(context).textTheme.titleMedium,
                              textAlign: TextAlign.center),
                        ],
                      ),
                    ).animate().fade(duration: 500.ms),
                  );
                }
                final groups = _groupLogs(logs);
                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 100),
                  sliver: SliverList(
                    delegate: SliverChildListDelegate(
                      _buildGroupedList(context, groups, l10n),
                    ),
                  ),
                );
              },
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/add-medication'),
        icon: const Icon(Icons.add),
        label: Text(l10n.get('add_medication')),
      ).animate().scale(delay: 300.ms, curve: Curves.elasticOut),
    );
  }

  Map<String, List<IntakeLog>> _groupLogs(List<IntakeLog> logs) {
    final groups = <String, List<IntakeLog>>{
      'morning': [],
      'afternoon': [],
      'evening': [],
    };
    for (final log in logs) {
      final hour = int.tryParse(log.timeSlot.split(':').first) ?? 0;
      if (hour >= 5 && hour < 12) {
        groups['morning']!.add(log);
      } else if (hour >= 12 && hour < 18) {
        groups['afternoon']!.add(log);
      } else {
        groups['evening']!.add(log);
      }
    }
    return groups;
  }

  List<Widget> _buildGroupedList(
    BuildContext context,
    Map<String, List<IntakeLog>> groups,
    AppLocalizations l10n,
  ) {
    final sections = [
      ('morning', '🌅', 'Matin'),
      ('afternoon', '☀️', 'Après-midi'),
      ('evening', '🌙', 'Soir'),
    ];

    final widgets = <Widget>[];
    int globalIndex = 0;

    for (final (key, emoji, label) in sections) {
      final sectionLogs = groups[key] ?? [];
      if (sectionLogs.isEmpty) continue;

      widgets.add(
        Padding(
          padding: const EdgeInsets.fromLTRB(4, 16, 0, 8),
          child: Row(
            children: [
              Text(emoji, style: const TextStyle(fontSize: 18)),
              const SizedBox(width: 8),
              Text(
                label,
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      );

      for (final log in sectionLogs) {
        widgets.add(MedicationCard(log: log, index: globalIndex++));
      }
    }
    return widgets;
  }
}

// ── Streak badge ──────────────────────────────────────────────────────────────

class _StreakBadge extends StatelessWidget {
  final int streak;
  const _StreakBadge({required this.streak});

  @override
  Widget build(BuildContext context) {
    if (streak == 0) {
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
        decoration: BoxDecoration(
          color: AppTheme.primary.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('💪', style: TextStyle(fontSize: 18)),
            SizedBox(width: 6),
            Text(
              'Commencez votre série !',
              style: TextStyle(
                color: AppTheme.primary,
                fontWeight: FontWeight.w700,
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [Color(0xFFFF6B35), Color(0xFFFF8C42)],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.orange.withValues(alpha: 0.35),
            blurRadius: 10,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Text('🔥', style: TextStyle(fontSize: 18)),
          const SizedBox(width: 6),
          Text(
            '$streak jour${streak > 1 ? 's' : ''} sans oubli !',
            style: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.w800,
              fontSize: 14,
            ),
          ),
        ],
      ),
    )
        .animate(onPlay: (c) => c.repeat(reverse: true))
        .shimmer(duration: 2.seconds, color: Colors.white30);
  }
}

// ── Summary card ──────────────────────────────────────────────────────────────

class _SummaryCard extends StatelessWidget {
  final List logs;
  final AppLocalizations l10n;
  const _SummaryCard({required this.logs, required this.l10n});

  @override
  Widget build(BuildContext context) {
    final taken = logs.where((l) => l.status == 'taken').length;
    final missed = logs.where((l) => l.status == 'missed').length;
    final upcoming = logs.where((l) => l.status == 'pending').length;

    return Container(
      padding: const EdgeInsets.all(20),
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
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _StatItem(count: taken,    label: l10n.get('taken_count'),    emoji: '✅'),
          _Divider(),
          _StatItem(count: missed,   label: l10n.get('missed_count'),   emoji: '❌'),
          _Divider(),
          _StatItem(count: upcoming, label: l10n.get('upcoming_count'), emoji: '⏰'),
        ],
      ),
    ).animate().fade(delay: 100.ms, duration: 400.ms).slideY(begin: 0.1);
  }
}

class _StatItem extends StatelessWidget {
  final int count;
  final String label;
  final String emoji;
  const _StatItem({required this.count, required this.label, required this.emoji});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        Text(emoji, style: const TextStyle(fontSize: 22)),
        const SizedBox(height: 4),
        Text('$count',
            style: const TextStyle(
                fontSize: 28, fontWeight: FontWeight.w800, color: Colors.white)),
        Text(label,
            style: const TextStyle(fontSize: 12, color: Colors.white70),
            textAlign: TextAlign.center),
      ],
    );
  }
}

class _Divider extends StatelessWidget {
  @override
  Widget build(BuildContext context) =>
      Container(width: 1, height: 50, color: Colors.white30);
}
