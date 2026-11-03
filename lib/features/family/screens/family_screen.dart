import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../auth/providers/auth_providers.dart';
import '../../medications/data/medication_model.dart';
import '../../report/services/pdf_report_service.dart';
import '../data/notification_model.dart';
import '../providers/family_providers.dart';

// ── Shell ─────────────────────────────────────────────────────────────────────

class FamilyScreen extends ConsumerStatefulWidget {
  const FamilyScreen({super.key});

  @override
  ConsumerState<FamilyScreen> createState() => _FamilyScreenState();
}

class _FamilyScreenState extends ConsumerState<FamilyScreen> {
  final _codeCtrl = TextEditingController();
  bool _linking = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      final user = ref.read(authStateProvider).asData?.value;
      if (user != null) {
        ref.read(familyRepositoryProvider).markNotificationsRead(user.uid);
      }
    });
  }

  @override
  void dispose() {
    _codeCtrl.dispose();
    super.dispose();
  }

  Future<void> _link() async {
    if (_codeCtrl.text.trim().isEmpty) return;
    setState(() => _linking = true);
    final error = await ref
        .read(familyNotifierProvider.notifier)
        .linkToPatient(_codeCtrl.text.trim());
    setState(() => _linking = false);
    if (!mounted) return;
    final l10n = ref.read(l10nProvider);
    if (error == 'not_found') {
      _showSnack(l10n.get('patient_not_found'), isError: true);
    } else if (error == 'already_linked') {
      _showSnack(l10n.get('already_linked'), isError: true);
    } else {
      _codeCtrl.clear();
    }
  }

  void _showSnack(String msg, {bool isError = false}) {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: isError ? Colors.red : AppTheme.primary,
      behavior: SnackBarBehavior.floating,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    final userDoc = ref.watch(userDocProvider).asData?.value;
    final role = userDoc?['role'] as String? ?? 'patient';

    return Scaffold(
      appBar: AppBar(title: Text(l10n.get('family'))),
      body: role == 'patient'
          ? _PatientView(userDoc: userDoc, l10n: l10n)
          : _FamilyView(
              l10n: l10n,
              codeCtrl: _codeCtrl,
              linking: _linking,
              onLink: _link,
              onUnlink: () =>
                  ref.read(familyNotifierProvider.notifier).unlink(),
            ),
    );
  }
}

// ── Patient side ──────────────────────────────────────────────────────────────

class _PatientView extends ConsumerWidget {
  final Map<String, dynamic>? userDoc;
  final AppLocalizations l10n;
  const _PatientView({required this.userDoc, required this.l10n});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final code = userDoc?['familyCode'] as String? ?? '------';
    final linkedMembers =
        ref.watch(linkedFamilyMembersProvider).asData?.value ?? [];

    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Code box ────────────────────────────────────────────────────
          Text(l10n.get('family_code'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 6),
          Text('Partagez ce code avec votre aidant pour lui donner accès.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 20),
          GestureDetector(
            onTap: () {
              Clipboard.setData(ClipboardData(text: code));
              ScaffoldMessenger.of(context).showSnackBar(SnackBar(
                content: Text(l10n.get('family_code_copied')),
                backgroundColor: AppTheme.primary,
                behavior: SnackBarBehavior.floating,
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12)),
              ));
            },
            child: Container(
              width: double.infinity,
              padding:
                  const EdgeInsets.symmetric(vertical: 28, horizontal: 24),
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
              child: Column(
                children: [
                  const Text('Code Famille',
                      style: TextStyle(color: Colors.white70, fontSize: 14)),
                  const SizedBox(height: 12),
                  Text(
                    code,
                    style: const TextStyle(
                      fontSize: 44,
                      fontWeight: FontWeight.w800,
                      color: Colors.white,
                      letterSpacing: 10,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.copy, color: Colors.white70, size: 16),
                      SizedBox(width: 6),
                      Text('Appuyer pour copier',
                          style:
                              TextStyle(color: Colors.white70, fontSize: 13)),
                    ],
                  ),
                ],
              ),
            ),
          ).animate().fade(duration: 400.ms).scale(begin: const Offset(0.92, 0.92)),

          const SizedBox(height: 32),

          // ── Linked family members ────────────────────────────────────────
          Row(
            children: [
              const Icon(Icons.people_rounded, color: AppTheme.primary, size: 20),
              const SizedBox(width: 8),
              Text(
                'Aidants liés (${linkedMembers.length})',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      color: AppTheme.primary,
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          if (linkedMembers.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(28),
              decoration: BoxDecoration(
                color: Colors.grey.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.grey.shade200),
              ),
              child: Column(
                children: [
                  const Text('👨‍👩‍👧', style: TextStyle(fontSize: 40)),
                  const SizedBox(height: 10),
                  Text(
                    'Aucun aidant lié pour l\'instant.\nPartagez votre code !',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                        color: Colors.grey.shade500, fontSize: 14),
                  ),
                ],
              ),
            ).animate().fade(duration: 300.ms)
          else
            ...linkedMembers.asMap().entries.map(
                  (e) => _FamilyMemberTile(member: e.value)
                      .animate(delay: Duration(milliseconds: e.key * 60))
                      .fade()
                      .slideX(begin: -0.1),
                ),
        ],
      ),
    );
  }
}

class _FamilyMemberTile extends StatelessWidget {
  final Map<String, dynamic> member;
  const _FamilyMemberTile({required this.member});

  @override
  Widget build(BuildContext context) {
    final name = member['name'] as String? ?? '';
    final email = member['email'] as String? ?? '';
    return Card(
      margin: const EdgeInsets.only(bottom: 10),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: Container(
          width: 46,
          height: 46,
          decoration: BoxDecoration(
            color: AppTheme.primary.withValues(alpha: 0.12),
            shape: BoxShape.circle,
          ),
          child: Center(
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: AppTheme.primary),
            ),
          ),
        ),
        title: Text(name,
            style:
                const TextStyle(fontWeight: FontWeight.w700, fontSize: 15)),
        subtitle: Text(email,
            style:
                TextStyle(fontSize: 13, color: Colors.grey.shade500)),
        trailing: Container(
          padding:
              const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
          decoration: BoxDecoration(
            color: Colors.green.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: const Text('Actif',
              style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ),
      ),
    );
  }
}

// ── Family side ───────────────────────────────────────────────────────────────

class _FamilyView extends ConsumerWidget {
  final AppLocalizations l10n;
  final TextEditingController codeCtrl;
  final bool linking;
  final VoidCallback onLink;
  final VoidCallback onUnlink;

  const _FamilyView({
    required this.l10n,
    required this.codeCtrl,
    required this.linking,
    required this.onLink,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final linkedPatient = ref.watch(linkedPatientProvider).asData?.value;
    final todayLogs =
        ref.watch(patientTodayLogsProvider).asData?.value ?? [];
    final weekLogs =
        ref.watch(patientLogsProvider).asData?.value ?? [];
    final notifications =
        ref.watch(notificationsProvider).asData?.value ?? [];

    if (linkedPatient != null) {
      return _FamilyDashboard(
        patient: linkedPatient,
        todayLogs: todayLogs,
        weekLogs: weekLogs,
        notifications: notifications,
        l10n: l10n,
        onUnlink: onUnlink,
      );
    }

    // ── Link form ──────────────────────────────────────────────────────────
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('👨‍👩‍👧', style: TextStyle(fontSize: 64))
              .animate()
              .scale(duration: 400.ms, curve: Curves.elasticOut),
          const SizedBox(height: 16),
          Text(l10n.get('family_link'),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text('Entrez le code famille du patient pour suivre ses médicaments.',
              style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 28),
          TextField(
            controller: codeCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 4),
            decoration: InputDecoration(
              labelText: l10n.get('family_enter_code'),
              prefixIcon: const Icon(Icons.vpn_key_outlined),
            ),
          ).animate().fade(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 20),
          FilledButton(
            onPressed: linking ? null : onLink,
            child: linking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5))
                : Text(l10n.get('family_confirm_link')),
          ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}

// ── Family Dashboard ──────────────────────────────────────────────────────────

class _FamilyDashboard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final List<IntakeLog> todayLogs;
  final List<IntakeLog> weekLogs;
  final List<AppNotification> notifications;
  final AppLocalizations l10n;
  final VoidCallback onUnlink;

  const _FamilyDashboard({
    required this.patient,
    required this.todayLogs,
    required this.weekLogs,
    required this.notifications,
    required this.l10n,
    required this.onUnlink,
  });

  int get _compliance {
    if (weekLogs.isEmpty) return 0;
    final taken = weekLogs.where((l) => l.status == 'taken').length;
    return (taken / weekLogs.length * 100).round();
  }

  DateTime? get _lastActivity {
    final taken = weekLogs
        .where((l) => l.takenAt != null)
        .toList()
      ..sort((a, b) => b.takenAt!.compareTo(a.takenAt!));
    return taken.isEmpty ? null : taken.first.takenAt;
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Patient header
          _PatientHeaderCard(
            patient: patient,
            compliance: _compliance,
            onUnlink: onUnlink,
          ),
          const SizedBox(height: 14),

          // Last activity
          if (_lastActivity != null)
            _LastActivityBanner(at: _lastActivity!)
                .animate().fade(duration: 300.ms),

          if (_lastActivity != null) const SizedBox(height: 14),

          // Alerts
          if (notifications.isNotEmpty) ...[
            _SectionTitle(
              icon: Icons.notifications_active_rounded,
              label: 'Alertes récentes',
              color: Colors.orange.shade700,
            ),
            const SizedBox(height: 10),
            ...notifications.take(5).toList().asMap().entries.map(
                  (e) => _NotifTile(notif: e.value)
                      .animate(delay: Duration(milliseconds: e.key * 50))
                      .fade()
                      .slideX(begin: 0.08),
                ),
            const SizedBox(height: 20),
          ],

          // Today's medications
          _SectionTitle(
            icon: Icons.today_rounded,
            label: 'Médicaments aujourd\'hui',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          if (todayLogs.isEmpty)
            _EmptyBox(text: 'Aucun médicament prévu aujourd\'hui')
          else
            ...todayLogs.asMap().entries.map(
                  (e) => _PatientLogTile(log: e.value)
                      .animate(delay: Duration(milliseconds: e.key * 60))
                      .fade()
                      .slideX(begin: 0.1),
                ),

          const SizedBox(height: 24),

          // Weekly bar chart
          _SectionTitle(
            icon: Icons.bar_chart_rounded,
            label: '7 derniers jours',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          _FamilyBarChart(weekLogs: weekLogs),

          const SizedBox(height: 24),

          // PDF report
          _SectionTitle(
            icon: Icons.picture_as_pdf_rounded,
            label: 'Rapport hebdomadaire',
            color: AppTheme.primary,
          ),
          const SizedBox(height: 10),
          FilledButton.icon(
            style: FilledButton.styleFrom(
                minimumSize: const Size(double.infinity, 52)),
            onPressed: () =>
                PdfReportService.generateAndShare(weekLogs, l10n),
            icon: const Icon(Icons.download_rounded),
            label: const Text('Télécharger le rapport PDF'),
          ).animate().fade(delay: 300.ms),
        ],
      ),
    );
  }
}

// ── Reusable section title ────────────────────────────────────────────────────

class _SectionTitle extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  const _SectionTitle(
      {required this.icon, required this.label, required this.color});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(icon, color: color, size: 20),
        const SizedBox(width: 8),
        Text(
          label,
          style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
                color: color,
              ),
        ),
      ],
    );
  }
}

// ── Patient header card ───────────────────────────────────────────────────────

class _PatientHeaderCard extends StatelessWidget {
  final Map<String, dynamic> patient;
  final int compliance;
  final VoidCallback onUnlink;
  const _PatientHeaderCard({
    required this.patient,
    required this.compliance,
    required this.onUnlink,
  });

  @override
  Widget build(BuildContext context) {
    final name = patient['name'] as String? ?? '';
    final email = patient['email'] as String? ?? '';
    final barColor =
        compliance >= 70 ? Colors.greenAccent : Colors.orangeAccent;

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
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.25),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 26,
                    fontWeight: FontWeight.w800,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text('Patient lié',
                    style: TextStyle(color: Colors.white70, fontSize: 12)),
                Text(name,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 18,
                        fontWeight: FontWeight.w800)),
                Text(email,
                    style: const TextStyle(
                        color: Colors.white70, fontSize: 12)),
                const SizedBox(height: 6),
                Container(
                  padding: const EdgeInsets.symmetric(
                      horizontal: 10, vertical: 3),
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    'Observance cette semaine : $compliance%',
                    style: TextStyle(
                        color: barColor,
                        fontWeight: FontWeight.w700,
                        fontSize: 12),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 10),
          Column(
            children: [
              SizedBox(
                width: 48,
                height: 48,
                child: CircularProgressIndicator(
                  value: compliance / 100,
                  strokeWidth: 5,
                  backgroundColor: Colors.white24,
                  color: barColor,
                ),
              ),
              const SizedBox(height: 8),
              GestureDetector(
                onTap: onUnlink,
                child: const Tooltip(
                  message: 'Délier',
                  child: Icon(Icons.link_off,
                      color: Colors.white70, size: 20),
                ),
              ),
            ],
          ),
        ],
      ),
    ).animate().fade(duration: 400.ms).slideY(begin: -0.08);
  }
}

// ── Last activity ─────────────────────────────────────────────────────────────

class _LastActivityBanner extends StatelessWidget {
  final DateTime at;
  const _LastActivityBanner({required this.at});

  @override
  Widget build(BuildContext context) {
    final diff = DateTime.now().difference(at);
    final String ago;
    if (diff.inMinutes < 1) {
      ago = 'à l\'instant';
    } else if (diff.inMinutes < 60) {
      ago = 'il y a ${diff.inMinutes} min';
    } else if (diff.inHours < 24) {
      ago = 'il y a ${diff.inHours}h';
    } else {
      ago = 'il y a ${diff.inDays}j';
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.green.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Colors.green.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          const Icon(Icons.access_time_rounded, color: Colors.green, size: 18),
          const SizedBox(width: 10),
          Text(
            'Dernière activité : $ago',
            style: const TextStyle(
                color: Colors.green, fontWeight: FontWeight.w600, fontSize: 13),
          ),
        ],
      ),
    );
  }
}

// ── Notification tile ─────────────────────────────────────────────────────────

class _NotifTile extends StatelessWidget {
  final AppNotification notif;
  const _NotifTile({required this.notif});

  @override
  Widget build(BuildContext context) {
    final isTaken = notif.type == 'taken_medication';
    final color = isTaken ? Colors.green : Colors.orange.shade700;
    final icon = isTaken
        ? Icons.check_circle_outline_rounded
        : Icons.warning_amber_rounded;
    final prefix = isTaken ? '✅' : '⚠️';

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
      child: ListTile(
        contentPadding:
            const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
        leading: Container(
          width: 40,
          height: 40,
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.12),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Icon(icon, color: color, size: 22),
        ),
        title: Text(
          '$prefix ${notif.patientName} ${isTaken ? 'a pris' : 'a oublié'} ${notif.medicationName}',
          style:
              const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
        ),
        subtitle: notif.createdAt != null
            ? Text(
                DateFormat('HH:mm').format(notif.createdAt!),
                style: TextStyle(
                    fontSize: 11, color: Colors.grey.shade500),
              )
            : null,
        trailing: notif.read
            ? null
            : Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                    color: Colors.red, shape: BoxShape.circle),
              ),
      ),
    );
  }
}

// ── Patient log tile ──────────────────────────────────────────────────────────

class _PatientLogTile extends StatelessWidget {
  final IntakeLog log;
  const _PatientLogTile({required this.log});

  @override
  Widget build(BuildContext context) {
    final color = Color(log.colorValue);
    final isTaken = log.status == 'taken';
    final isMissed = log.status == 'missed';

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
                          color: color.withValues(alpha: 0.15),
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
                      _StatusChip(status: log.status),
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

class _StatusChip extends StatelessWidget {
  final String status;
  const _StatusChip({required this.status});

  @override
  Widget build(BuildContext context) {
    final isTaken = status == 'taken';
    final isMissed = status == 'missed';
    final color =
        isTaken ? Colors.green : isMissed ? Colors.red : Colors.grey;
    final label =
        isTaken ? 'Pris' : isMissed ? 'Oublié' : 'En attente';
    final icon = isTaken
        ? Icons.check_circle
        : isMissed
            ? Icons.cancel
            : Icons.schedule;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 13),
          const SizedBox(width: 4),
          Text(label,
              style: TextStyle(
                  color: color,
                  fontWeight: FontWeight.w700,
                  fontSize: 12)),
        ],
      ),
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
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Text(text,
          textAlign: TextAlign.center,
          style: TextStyle(color: Colors.grey.shade500, fontSize: 14)),
    );
  }
}

// ── Weekly bar chart ──────────────────────────────────────────────────────────

class _FamilyBarChart extends StatelessWidget {
  final List<IntakeLog> weekLogs;
  const _FamilyBarChart({required this.weekLogs});

  List<_DayStat> _buildStats() {
    final today = DateTime.now();
    return List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      final dateStr = DateFormat('yyyy-MM-dd').format(day);
      final dayLogs = weekLogs.where((l) => l.date == dateStr).toList();
      String label;
      try {
        label = DateFormat('E', 'fr_FR').format(day);
      } catch (_) {
        label = DateFormat('E').format(day);
      }
      return _DayStat(
        label: label,
        taken: dayLogs.where((l) => l.status == 'taken').length,
        total: dayLogs.length,
      );
    });
  }

  @override
  Widget build(BuildContext context) {
    final stats = _buildStats();
    return Container(
      height: 200,
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
                  borderRadius:
                      const BorderRadius.vertical(top: Radius.circular(8)),
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
            leftTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            topTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            rightTitles: const AxisTitles(
                sideTitles: SideTitles(showTitles: false)),
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 30,
                getTitlesWidget: (value, meta) {
                  final i = value.toInt();
                  if (i < 0 || i >= stats.length) return const SizedBox();
                  return Padding(
                    padding: const EdgeInsets.only(top: 8),
                    child: Text(stats[i].label,
                        style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w600,
                            color: Colors.grey.shade600)),
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

class _DayStat {
  final String label;
  final int taken;
  final int total;
  const _DayStat(
      {required this.label, required this.taken, required this.total});
}
