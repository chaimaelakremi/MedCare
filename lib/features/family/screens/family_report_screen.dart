import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../medications/data/medication_model.dart';
import '../../report/services/pdf_report_service.dart';
import '../providers/family_providers.dart';

const _kPink = AppTheme.familyPrimary;

class FamilyReportScreen extends ConsumerWidget {
  const FamilyReportScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final patientAsync = ref.watch(linkedPatientProvider);
    final logsAsync = ref.watch(patientLogsProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Rapport patient'),
        backgroundColor: _kPink.withValues(alpha: 0.08),
        foregroundColor: _kPink,
        titleTextStyle: const TextStyle(
          color: _kPink,
          fontSize: 20,
          fontWeight: FontWeight.w600,
        ),
        iconTheme: const IconThemeData(color: _kPink),
      ),
      body: patientAsync.when(
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Erreur: $e')),
        data: (patient) {
          if (patient == null) {
            return const _NotLinkedView();
          }
          final patientName = patient['name'] as String? ?? 'Patient';
          return logsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (logs) => _ReportBody(
              logs: logs,
              patientName: patientName,
              l10n: l10n,
            ),
          );
        },
      ),
    );
  }
}

// ── Not linked ────────────────────────────────────────────────────────────────

class _NotLinkedView extends StatelessWidget {
  const _NotLinkedView();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: _kPink.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
              child:
                  const Icon(Icons.link_off_rounded, size: 40, color: _kPink),
            ),
            const SizedBox(height: 20),
            const Text('Aucun patient lié',
                style:
                    TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            Text(
              'Allez dans l\'onglet Famille pour entrer le code du patient.',
              textAlign: TextAlign.center,
              style:
                  TextStyle(fontSize: 14, color: Colors.grey.shade600),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Report body ───────────────────────────────────────────────────────────────

class _ReportBody extends StatelessWidget {
  final List<IntakeLog> logs;
  final String patientName;
  final AppLocalizations l10n;

  const _ReportBody(
      {required this.logs,
      required this.patientName,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    final taken = logs.where((l) => l.status == 'taken').length;
    final missed = logs.where((l) => l.status == 'missed').length;
    final total = logs.length;
    final rate =
        total > 0 ? (taken / total * 100).round() : 0;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Patient banner ───────────────────────────────────────────
          _PatientBanner(name: patientName),
          const SizedBox(height: 24),

          // ── Period label ─────────────────────────────────────────────
          Text('7 derniers jours',
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 16),

          // ── Stats row ────────────────────────────────────────────────
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '$rate%',
                  label: 'Observance',
                  icon: Icons.pie_chart_outline_rounded,
                  color: rate >= 70 ? Colors.green : Colors.orange,
                ).animate().fade(duration: 300.ms).slideY(begin: 0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '$taken',
                  label: 'Médicaments pris',
                  icon: Icons.check_circle_outline_rounded,
                  color: Colors.green.shade600,
                ).animate(delay: 60.ms).fade(duration: 300.ms).slideY(begin: 0.1),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _StatCard(
                  value: '$missed',
                  label: 'Oubliés',
                  icon: Icons.cancel_outlined,
                  color: Colors.red.shade500,
                ).animate(delay: 120.ms).fade(duration: 300.ms).slideY(begin: 0.1),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _StatCard(
                  value: '$total',
                  label: 'Total planifié',
                  icon: Icons.calendar_month_outlined,
                  color: Colors.blue.shade500,
                ).animate(delay: 180.ms).fade(duration: 300.ms).slideY(begin: 0.1),
              ),
            ],
          ),

          const SizedBox(height: 32),

          // ── Compliance ring ──────────────────────────────────────────
          Center(
            child: _ComplianceRing(rate: rate),
          ).animate(delay: 200.ms).fade(duration: 400.ms).scale(begin: const Offset(0.85, 0.85)),

          const SizedBox(height: 32),

          // ── Generate PDF ─────────────────────────────────────────────
          Text(l10n.get('weekly_report'),
              style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          _PdfButton(logs: logs, l10n: l10n),

          const SizedBox(height: 20),

          // ── Disclaimer ───────────────────────────────────────────────
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.08),
              borderRadius: BorderRadius.circular(12),
              border:
                  Border.all(color: Colors.orange.withValues(alpha: 0.25)),
            ),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Icon(Icons.info_outline_rounded,
                    color: Colors.orange, size: 18),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Ce rapport est généré automatiquement. '
                    'Il ne remplace pas l\'avis d\'un professionnel de santé.',
                    style: TextStyle(
                        fontSize: 12, color: Colors.grey.shade700),
                  ),
                ),
              ],
            ),
          ).animate(delay: 300.ms).fade(duration: 300.ms),
        ],
      ),
    );
  }
}

// ── Patient banner ────────────────────────────────────────────────────────────

class _PatientBanner extends StatelessWidget {
  final String name;
  const _PatientBanner({required this.name});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            _kPink.withValues(alpha: 0.18),
            AppTheme.secondary.withValues(alpha: 0.12),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _kPink.withValues(alpha: 0.25)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [_kPink, AppTheme.secondary],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              shape: BoxShape.circle,
            ),
            child: Center(
              child: Text(
                name.isNotEmpty ? name[0].toUpperCase() : '?',
                style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.white),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(name,
                    style: const TextStyle(
                        fontSize: 16, fontWeight: FontWeight.w700)),
                Text('Rapport des 7 derniers jours',
                    style: TextStyle(
                        fontSize: 13, color: Colors.grey.shade600)),
              ],
            ),
          ),
          const Icon(Icons.description_outlined, color: _kPink),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: -0.1);
  }
}

// ── Stat card ─────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  final String value;
  final String label;
  final IconData icon;
  final Color color;

  const _StatCard(
      {required this.value,
      required this.label,
      required this.icon,
      required this.color});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(value,
              style: TextStyle(
                  fontSize: 26,
                  fontWeight: FontWeight.w800,
                  color: color)),
          const SizedBox(height: 2),
          Text(label,
              style:
                  TextStyle(fontSize: 12, color: Colors.grey.shade600)),
        ],
      ),
    );
  }
}

// ── Compliance ring ───────────────────────────────────────────────────────────

class _ComplianceRing extends StatelessWidget {
  final int rate;
  const _ComplianceRing({required this.rate});

  @override
  Widget build(BuildContext context) {
    final color = rate >= 80
        ? Colors.green.shade500
        : rate >= 50
            ? Colors.orange.shade500
            : Colors.red.shade500;

    return Container(
      padding: const EdgeInsets.all(28),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.06),
        shape: BoxShape.circle,
        border: Border.all(color: color.withValues(alpha: 0.15), width: 2),
      ),
      child: SizedBox(
        width: 120,
        height: 120,
        child: Stack(
          alignment: Alignment.center,
          children: [
            CircularProgressIndicator(
              value: rate / 100,
              strokeWidth: 10,
              backgroundColor: color.withValues(alpha: 0.15),
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
            Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text('$rate%',
                    style: TextStyle(
                        fontSize: 26,
                        fontWeight: FontWeight.w800,
                        color: color)),
                Text('observance',
                    style: TextStyle(
                        fontSize: 11, color: Colors.grey.shade500)),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

// ── PDF button ────────────────────────────────────────────────────────────────

class _PdfButton extends ConsumerStatefulWidget {
  final List<IntakeLog> logs;
  final AppLocalizations l10n;

  const _PdfButton({required this.logs, required this.l10n});

  @override
  ConsumerState<_PdfButton> createState() => _PdfButtonState();
}

class _PdfButtonState extends ConsumerState<_PdfButton> {
  bool _loading = false;

  Future<void> _generate() async {
    setState(() => _loading = true);
    try {
      await PdfReportService.generateAndShare(widget.logs, widget.l10n);
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: _loading ? null : _generate,
      style: FilledButton.styleFrom(backgroundColor: _kPink),
      icon: _loading
          ? const SizedBox(
              width: 18,
              height: 18,
              child: CircularProgressIndicator(
                  color: Colors.white, strokeWidth: 2),
            )
          : const Icon(Icons.picture_as_pdf_outlined),
      label: Text(_loading
          ? 'Génération...'
          : widget.l10n.get('generate_pdf')),
    ).animate(delay: 250.ms).fade(duration: 300.ms).slideY(begin: 0.15);
  }
}
