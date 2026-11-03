import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../medications/data/medication_model.dart';
import '../providers/family_providers.dart';

const _kFamilyPink = AppTheme.familyPrimary;

class FamilyHomeScreen extends ConsumerWidget {
  const FamilyHomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final linkedPatient = ref.watch(linkedPatientProvider).asData?.value;
    final todayLogs = ref.watch(patientTodayLogsProvider).asData?.value ?? [];
    final weekLogs = ref.watch(patientLogsProvider).asData?.value ?? [];
    final unreadCount = ref.watch(unreadNotificationsCountProvider);

    if (linkedPatient == null) {
      return _NotLinkedState(l10n: l10n);
    }

    final now = DateTime.now();

    // Overdue: pending + scheduled 30+ min ago
    final overdue = todayLogs.where((l) {
      if (l.status != 'pending') return false;
      final parts = l.timeSlot.split(':');
      if (parts.length < 2) return false;
      final h = int.tryParse(parts[0]);
      final m = int.tryParse(parts[1]);
      if (h == null || m == null) return false;
      final scheduled = DateTime(now.year, now.month, now.day, h, m);
      return now.isAfter(scheduled) &&
          now.difference(scheduled).inMinutes >= 30;
    }).toList();

    // Adherence today
    final todayTotal = todayLogs.length;
    final todayTaken = todayLogs.where((l) => l.status == 'taken').length;
    final adherence = todayTotal > 0 ? todayTaken / todayTotal : 0.0;

    // Last activity
    final lastActivity = _lastActivity(weekLogs);

    // Activity feed (last 5 non-pending)
    final activity = _buildActivity(weekLogs);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // ── Pink gradient header ────────────────────────────────────
              _FamilyHeader(patient: linkedPatient, unreadCount: unreadCount),

              // ── Overdue banners ─────────────────────────────────────────
              if (overdue.isNotEmpty)
                _OverdueBanner(logs: overdue, now: now)
                    .animate()
                    .fade(duration: 300.ms)
                    .slideY(begin: -0.1),

              Padding(
                padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // ── Patient card ──────────────────────────────────────
                    _PatientCard(
                        patient: linkedPatient, lastActivity: lastActivity),
                    const SizedBox(height: 20),

                    // ── Adherence ring ────────────────────────────────────
                    _AdherenceSection(
                      taken: todayTaken,
                      total: todayTotal,
                      value: adherence,
                    ),
                    const SizedBox(height: 24),

                    // ── Today's medications ───────────────────────────────
                    _SectionTitle(
                      icon: Icons.today_rounded,
                      label: 'Médicaments aujourd\'hui',
                    ),
                    const SizedBox(height: 10),
                    if (todayLogs.isEmpty)
                      _EmptyBox(text: 'Aucun médicament prévu aujourd\'hui')
                    else
                      ...todayLogs.asMap().entries.map(
                            (e) => _TodayMedTile(log: e.value)
                                .animate(
                                    delay: Duration(
                                        milliseconds: e.key * 60))
                                .fade()
                                .slideX(begin: 0.1),
                          ),
                    const SizedBox(height: 24),

                    // ── Activity feed ─────────────────────────────────────
                    _SectionTitle(
                      icon: Icons.history_rounded,
                      label: 'Activité récente',
                    ),
                    const SizedBox(height: 10),
                    if (activity.isEmpty)
                      _EmptyBox(text: 'Aucune activité récente')
                    else
                      ...activity.asMap().entries.map(
                            (e) => _ActivityTile(log: e.value)
                                .animate(
                                    delay: Duration(
                                        milliseconds: e.key * 50))
                                .fade()
                                .slideX(begin: 0.1),
                          ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  DateTime? _lastActivity(List<IntakeLog> logs) {
    final taken = logs.where((l) => l.takenAt != null).toList()
      ..sort((a, b) => b.takenAt!.compareTo(a.takenAt!));
    return taken.isEmpty ? null : taken.first.takenAt;
  }

  List<IntakeLog> _buildActivity(List<IntakeLog> weekLogs) {
    final active =
        weekLogs.where((l) => l.status != 'pending').toList();
    active.sort((a, b) => _logTime(b).compareTo(_logTime(a)));
    return active.take(5).toList();
  }

  DateTime _logTime(IntakeLog log) {
    if (log.takenAt != null) return log.takenAt!;
    try {
      final p = log.timeSlot.split(':');
      final d = log.date.split('-');
      return DateTime(
          int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
          int.parse(p[0]), int.parse(p[1]));
    } catch (_) {
      return DateTime(0);
    }
  }
}

// ── Pink gradient header ──────────────────────────────────────────────────────

class _FamilyHeader extends StatelessWidget {
  final Map<String, dynamic> patient;
  final int unreadCount;
  const _FamilyHeader({required this.patient, required this.unreadCount});

  @override
  Widget build(BuildContext context) {
    final h = DateTime.now().hour;
    final greeting =
        h < 12 ? 'Bonjour' : h < 18 ? 'Bon après-midi' : 'Bonsoir';
    final patientName = patient['name'] as String? ?? 'votre patient';

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(24, 30, 24, 30),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [_kFamilyPink, AppTheme.secondary],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.favorite_rounded,
                  color: Colors.white70, size: 16),
              const SizedBox(width: 6),
              const Expanded(
                child: Text('Tableau de bord aidant',
                    style: TextStyle(
                        color: Colors.white70,
                        fontSize: 13,
                        fontWeight: FontWeight.w600)),
              ),
              // Bell icon
              GestureDetector(
                onTap: () => context.push('/notifications'),
                child: Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: BoxDecoration(
                        color: Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.notifications_rounded,
                          color: Colors.white, size: 20),
                    ),
                    if (unreadCount > 0)
                      Positioned(
                        top: -4,
                        right: -4,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: Colors.red,
                            shape: BoxShape.circle,
                          ),
                          child: Text(
                            '$unreadCount',
                            style: const TextStyle(
                                color: Colors.white,
                                fontSize: 10,
                                fontWeight: FontWeight.w800),
                          ),
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          Text('$greeting 👋',
              style: const TextStyle(
                  color: Colors.white,
                  fontSize: 26,
                  fontWeight: FontWeight.w800)),
          const SizedBox(height: 2),
          Text('Vous suivez $patientName',
              style: const TextStyle(color: Colors.white70, fontSize: 14)),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.05);
  }
}

// ── Overdue banner ────────────────────────────────────────────────────────────

class _OverdueBanner extends StatelessWidget {
  final List<IntakeLog> logs;
  final DateTime now;
  const _OverdueBanner({required this.logs, required this.now});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.orange.shade50,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      child: Column(
        children: logs.map((log) {
          final parts = log.timeSlot.split(':');
          final h = int.tryParse(parts[0]) ?? 0;
          final m = int.tryParse(parts[1]) ?? 0;
          final scheduled =
              DateTime(now.year, now.month, now.day, h, m);
          final mins = now.difference(scheduled).inMinutes;
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 6),
            child: Row(
              children: [
                const Text('⚠️', style: TextStyle(fontSize: 18)),
                const SizedBox(width: 10),
                Expanded(
                  child: Text(
                    '${log.medicationName} non pris depuis $mins minutes',
                    style: TextStyle(
                        color: Colors.orange.shade800,
                        fontWeight: FontWeight.w600,
                        fontSize: 13),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }
}

// ── Patient info card ─────────────────────────────────────────────────────────

class _PatientCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final DateTime? lastActivity;
  const _PatientCard({required this.patient, this.lastActivity});

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? '';
    final condition = patient['condition'] as String?;
    final email = patient['email'] as String? ?? '';

    String? lastText;
    if (lastActivity != null) {
      final diff = DateTime.now().difference(lastActivity!);
      if (diff.inMinutes < 1) {
        lastText = 'À l\'instant';
      } else if (diff.inMinutes < 60) {
        lastText = 'il y a ${diff.inMinutes} min';
      } else if (diff.inHours < 24) {
        lastText = 'il y a ${diff.inHours}h';
      } else {
        lastText = 'il y a ${diff.inDays}j';
      }
    }

    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: _kFamilyPink.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: _kFamilyPink.withValues(alpha: 0.2)),
      ),
      child: Row(
        children: [
          Container(
            width: 60,
            height: 60,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                colors: [_kFamilyPink, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.w800),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 18, fontWeight: FontWeight.w800)),
                const SizedBox(height: 2),
                if (condition != null && condition.isNotEmpty)
                  Text(condition,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade600,
                          fontStyle: FontStyle.italic))
                else
                  Text(email,
                      style: TextStyle(
                          fontSize: 13, color: Colors.grey.shade600)),
                if (lastText != null) ...[
                  const SizedBox(height: 5),
                  Row(
                    children: [
                      Icon(Icons.access_time_rounded,
                          size: 13, color: Colors.grey.shade500),
                      const SizedBox(width: 4),
                      Text(
                        'Dernière activité : $lastText',
                        style: TextStyle(
                            fontSize: 12, color: Colors.grey.shade500),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(duration: 350.ms).slideY(begin: 0.05);
  }
}

// ── Adherence ring ────────────────────────────────────────────────────────────

class _AdherenceSection extends StatelessWidget {
  final int taken;
  final int total;
  final double value;
  const _AdherenceSection(
      {required this.taken, required this.total, required this.value});

  @override
  Widget build(BuildContext context) {
    final pct = total > 0 ? (value * 100).round() : 0;
    final ringColor = pct >= 70
        ? Colors.green
        : pct >= 40
            ? Colors.orange
            : total == 0
                ? Colors.grey
                : Colors.red;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Theme.of(context).cardTheme.color ??
            Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          // Adherence ring
          SizedBox(
            width: 90,
            height: 90,
            child: Stack(
              alignment: Alignment.center,
              children: [
                CircularProgressIndicator(
                  value: total > 0 ? value : 0,
                  strokeWidth: 9,
                  backgroundColor: Colors.grey.shade200,
                  color: ringColor,
                ),
                Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text('$pct%',
                        style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w800,
                            color: ringColor)),
                    Text('aujourd\'hui',
                        style: TextStyle(
                            fontSize: 9, color: Colors.grey.shade500)),
                  ],
                ),
              ],
            ),
          ).animate().scale(
              delay: 100.ms,
              duration: 600.ms,
              curve: Curves.elasticOut),
          const SizedBox(width: 24),
          // Stats column
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Observance du jour',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade500)),
                const SizedBox(height: 10),
                _StatRow(
                    icon: Icons.check_circle_outline,
                    color: Colors.green,
                    label: 'Pris',
                    value: '$taken'),
                const SizedBox(height: 6),
                _StatRow(
                    icon: Icons.cancel_outlined,
                    color: Colors.red,
                    label: 'Oubliés',
                    value:
                        '${total - taken > 0 ? total - taken : 0}'),
                const SizedBox(height: 6),
                _StatRow(
                    icon: Icons.calendar_today_outlined,
                    color: Colors.grey,
                    label: 'Total',
                    value: '$total'),
              ],
            ),
          ),
        ],
      ),
    ).animate().fade(delay: 100.ms, duration: 400.ms);
  }
}

class _StatRow extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  const _StatRow(
      {required this.icon,
      required this.color,
      required this.label,
      required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 15),
        const SizedBox(width: 6),
        Text(label,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade600)),
        const Spacer(),
        Text(value,
            style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w700,
                color: color)),
      ],
    );
  }
}

// ── Today med tile ────────────────────────────────────────────────────────────

class _TodayMedTile extends StatelessWidget {
  final IntakeLog log;
  const _TodayMedTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isTaken = log.status == 'taken';
    final isMissed = log.status == 'missed';
    final color = Color(log.colorValue);
    final statusColor =
        isTaken ? Colors.green : isMissed ? Colors.red : Colors.grey;
    final statusLabel =
        isTaken ? 'Pris' : isMissed ? 'Oublié' : 'En attente';
    final statusIcon = isTaken
        ? Icons.check_circle
        : isMissed
            ? Icons.cancel
            : Icons.schedule;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(
                width: 4,
                color: isTaken
                    ? Colors.green.shade400
                    : isMissed
                        ? Colors.red.shade300
                        : color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 14, vertical: 12),
                  child: Row(
                    children: [
                      Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: isTaken
                              ? Colors.green.withValues(alpha: 0.12)
                              : isMissed
                                  ? Colors.red.withValues(alpha: 0.12)
                                  : color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: const Center(
                            child: Text('💊',
                                style: TextStyle(fontSize: 20))),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(log.medicationName,
                                style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700)),
                            Text('${log.dose} • ${log.timeSlot}',
                                style: TextStyle(
                                    fontSize: 12,
                                    color: Colors.grey.shade600)),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 10, vertical: 5),
                        decoration: BoxDecoration(
                          color:
                              statusColor.withValues(alpha: 0.12),
                          borderRadius: BorderRadius.circular(20),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(statusIcon,
                                color: statusColor, size: 13),
                            const SizedBox(width: 4),
                            Text(statusLabel,
                                style: TextStyle(
                                    color: statusColor,
                                    fontWeight: FontWeight.w700,
                                    fontSize: 12)),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Activity tile ─────────────────────────────────────────────────────────────

class _ActivityTile extends StatelessWidget {
  final IntakeLog log;
  const _ActivityTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final isTaken = log.status == 'taken';
    final color = isTaken ? Colors.green : Colors.red;
    final emoji = isTaken ? '✅' : '⚠️';
    final action = isTaken ? 'a pris' : 'a oublié';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 38,
          height: 38,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(10),
          ),
          child: Center(
              child:
                  Text(emoji, style: const TextStyle(fontSize: 18))),
        ),
        title: Text('$action ${log.medicationName}',
            style: const TextStyle(
                fontWeight: FontWeight.w600, fontSize: 13)),
        subtitle: Text('${log.dose} • ${log.timeSlot}',
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade500)),
        trailing: Text(_formatRelativeTime(log),
            style: TextStyle(
                fontSize: 11, color: Colors.grey.shade500)),
      ),
    );
  }

  String _formatRelativeTime(IntakeLog log) {
    final now = DateTime.now();
    DateTime? t = log.takenAt;
    if (t == null) {
      try {
        final p = log.timeSlot.split(':');
        final d = log.date.split('-');
        t = DateTime(int.parse(d[0]), int.parse(d[1]), int.parse(d[2]),
            int.parse(p[0]), int.parse(p[1]));
      } catch (_) {
        return log.timeSlot;
      }
    }
    final diff = now.difference(t);
    if (diff.inMinutes < 1) return 'à l\'instant';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min';
    if (diff.inHours < 24) return '${diff.inHours}h';
    return '${diff.inDays}j';
  }
}

// ── Shared section title ──────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  const _SectionTitle({required this.icon, required this.label});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: _kFamilyPink, size: 20),
        const SizedBox(width: 8),
        Text(label,
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700, color: _kFamilyPink)),
      ],
    );
  }
}

class _EmptyBox extends StatelessWidget {
  final String text;
  const _EmptyBox({required this.text});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
    );
  }
}

// ── Not linked ────────────────────────────────────────────────────────────────

class _NotLinkedState extends StatelessWidget {
  final AppLocalizations l10n;
  const _NotLinkedState({required this.l10n});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Text('👨‍👩‍👧', style: TextStyle(fontSize: 64))
                  .animate()
                  .scale(duration: 400.ms, curve: Curves.elasticOut),
              const SizedBox(height: 20),
              Text('Aucun patient lié',
                  style: Theme.of(context).textTheme.headlineSmall),
              const SizedBox(height: 8),
              Text(
                'Rendez-vous dans l\'onglet Médicaments pour lier un patient avec son code.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 24),
              FilledButton.icon(
                style: FilledButton.styleFrom(
                    backgroundColor: _kFamilyPink),
                onPressed: () => context.go('/family-medications'),
                icon: const Icon(Icons.link_rounded),
                label: const Text('Lier un patient'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
