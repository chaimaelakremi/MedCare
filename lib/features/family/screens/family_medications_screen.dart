import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../../medications/data/medication_model.dart';
import '../providers/family_providers.dart';

const _kPink = AppTheme.familyPrimary;

class FamilyMedicationsScreen extends ConsumerWidget {
  const FamilyMedicationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final patientAsync = ref.watch(linkedPatientProvider);
    final medsAsync = ref.watch(patientMedicationsProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('family_medications')),
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
            return const _LinkFormView();
          }
          final patientName = patient['name'] as String? ?? 'Patient';
          return medsAsync.when(
            loading: () =>
                const Center(child: CircularProgressIndicator()),
            error: (e, _) => Center(child: Text('Erreur: $e')),
            data: (meds) => _MedList(
              meds: meds,
              patientName: patientName,
              l10n: l10n,
            ),
          );
        },
      ),
    );
  }
}

// ── Link form (when not yet linked) ──────────────────────────────────────────

class _LinkFormView extends ConsumerStatefulWidget {
  const _LinkFormView();

  @override
  ConsumerState<_LinkFormView> createState() => _LinkFormViewState();
}

class _LinkFormViewState extends ConsumerState<_LinkFormView> {
  final _codeCtrl = TextEditingController();
  bool _linking = false;

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
    if (!mounted) return;
    setState(() => _linking = false);
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
      backgroundColor: isError ? Colors.red : _kPink,
      behavior: SnackBarBehavior.floating,
      shape:
          RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);
    return SingleChildScrollView(
      padding: const EdgeInsets.all(28),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Center(
            child: const Text('👨‍👩‍👧', style: TextStyle(fontSize: 64))
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
          ),
          const SizedBox(height: 24),
          Text(l10n.get('family_link'),
              style: Theme.of(context).textTheme.headlineSmall),
          const SizedBox(height: 8),
          Text(
            'Entrez le code famille du patient pour suivre ses médicaments.',
            style: Theme.of(context).textTheme.bodyMedium,
          ),
          const SizedBox(height: 32),
          TextField(
            controller: _codeCtrl,
            textCapitalization: TextCapitalization.characters,
            style: const TextStyle(
                fontSize: 22, fontWeight: FontWeight.w700, letterSpacing: 4),
            decoration: InputDecoration(
              labelText: l10n.get('family_enter_code'),
              prefixIcon: const Icon(Icons.vpn_key_outlined, color: _kPink),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(color: _kPink, width: 2),
              ),
              labelStyle: const TextStyle(color: _kPink),
            ),
          ).animate().fade(delay: 100.ms).slideX(begin: -0.1),
          const SizedBox(height: 20),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: _kPink),
            onPressed: _linking ? null : _link,
            child: _linking
                ? const SizedBox(
                    width: 22,
                    height: 22,
                    child: CircularProgressIndicator(
                        color: Colors.white, strokeWidth: 2.5),
                  )
                : Text(l10n.get('family_confirm_link')),
          ).animate().fade(delay: 200.ms).slideY(begin: 0.2),
        ],
      ),
    );
  }
}

// ── Medication list (when linked) ─────────────────────────────────────────────

class _MedList extends StatelessWidget {
  final List<Medication> meds;
  final String patientName;
  final AppLocalizations l10n;

  const _MedList(
      {required this.meds,
      required this.patientName,
      required this.l10n});

  @override
  Widget build(BuildContext context) {
    return CustomScrollView(
      slivers: [
        SliverToBoxAdapter(
          child: _PatientBanner(name: patientName),
        ),
        if (meds.isEmpty)
          SliverFillRemaining(
            child: Center(
              child: Text(
                'Aucun médicament actif pour ce patient.',
                style: TextStyle(color: Colors.grey.shade500),
              ),
            ),
          )
        else
          SliverPadding(
            padding: const EdgeInsets.fromLTRB(16, 0, 16, 24),
            sliver: SliverList(
              delegate: SliverChildBuilderDelegate(
                (ctx, i) => _MedCard(
                    med: meds[i], index: i, l10n: l10n),
                childCount: meds.length,
              ),
            ),
          ),
      ],
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
      margin: const EdgeInsets.all(16),
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
            decoration: const BoxDecoration(
              gradient: LinearGradient(
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
                Text(
                  name,
                  style: const TextStyle(
                      fontSize: 16, fontWeight: FontWeight.w700),
                ),
                Text(
                  'Ordonnances actives',
                  style: TextStyle(
                      fontSize: 13, color: Colors.grey.shade600),
                ),
              ],
            ),
          ),
          const Icon(Icons.medication_rounded, color: _kPink),
        ],
      ),
    ).animate().fade(duration: 300.ms).slideY(begin: -0.1);
  }
}

// ── Medication card ───────────────────────────────────────────────────────────

class _MedCard extends StatelessWidget {
  final Medication med;
  final int index;
  final AppLocalizations l10n;

  const _MedCard(
      {required this.med, required this.index, required this.l10n});

  String _freqLabel() {
    switch (med.frequency) {
      case 'twice_daily':
        return l10n.get('freq_twice');
      case 'thrice_daily':
        return l10n.get('freq_thrice');
      case 'weekly':
        return l10n.get('freq_weekly');
      default:
        return l10n.get('freq_daily');
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = Color(med.colorValue);
    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              Container(width: 5, color: color),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      Container(
                        width: 48,
                        height: 48,
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                              color: color.withValues(alpha: 0.4),
                              width: 1.5),
                        ),
                        child: const Center(
                          child: Text('💊',
                              style: TextStyle(fontSize: 22)),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              med.name,
                              style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${med.dose} • ${_freqLabel()}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600),
                            ),
                            const SizedBox(height: 6),
                            Wrap(
                              spacing: 6,
                              children: med.times
                                  .map((t) => _TimeTag(time: t))
                                  .toList(),
                            ),
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
    )
        .animate(delay: Duration(milliseconds: index * 70))
        .fade(duration: 300.ms)
        .slideX(begin: 0.1, curve: Curves.easeOutCubic);
  }
}

class _TimeTag extends StatelessWidget {
  final String time;
  const _TimeTag({required this.time});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: _kPink.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.access_time, size: 11, color: _kPink),
          const SizedBox(width: 3),
          Text(time,
              style: const TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: _kPink)),
        ],
      ),
    );
  }
}
