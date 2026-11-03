import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../data/medication_model.dart';
import '../providers/medication_providers.dart';
import '../../mood/widgets/mood_tracker_dialog.dart';

class MedicationCard extends ConsumerWidget {
  final IntakeLog log;
  final int index;

  const MedicationCard({super.key, required this.log, required this.index});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final l10n = ref.watch(l10nProvider);
    final color = Color(log.colorValue);
    final isTaken = log.status == 'taken';
    final isMissed = log.status == 'missed';

    return Card(
      child: ClipRRect(
        borderRadius: BorderRadius.circular(20),
        child: IntrinsicHeight(
          child: Row(
            children: [
              // Colored accent strip
              Container(
                width: 5,
                color: isTaken
                    ? Colors.green.shade400
                    : isMissed
                        ? Colors.red.shade300
                        : color,
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Row(
                    children: [
                      // Color dot + pill icon
                      Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: isTaken
                              ? Colors.green.withValues(alpha: 0.15)
                              : isMissed
                                  ? Colors.red.withValues(alpha: 0.15)
                                  : color.withValues(alpha: 0.18),
                          borderRadius: BorderRadius.circular(14),
                          border: Border.all(
                            color: isTaken
                                ? Colors.green.withValues(alpha: 0.4)
                                : isMissed
                                    ? Colors.red.withValues(alpha: 0.4)
                                    : color.withValues(alpha: 0.4),
                            width: 1.5,
                          ),
                        ),
                        child: Center(
                          child: Text(
                            '💊',
                            style: TextStyle(fontSize: isTaken ? 26 : 22),
                          ),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              log.medicationName,
                              style: const TextStyle(
                                  fontSize: 16, fontWeight: FontWeight.w700),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              '${log.dose} • ${log.timeSlot}',
                              style: TextStyle(
                                  fontSize: 13,
                                  color: Colors.grey.shade600),
                            ),
                            if (log.mood != null) ...[
                              const SizedBox(height: 4),
                              _MoodChip(mood: log.mood!),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(width: 8),
                      _StatusSection(log: log, l10n: l10n, ref: ref),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    )
        .animate(delay: Duration(milliseconds: index * 80))
        .fade(duration: 350.ms)
        .slideX(begin: 0.15, curve: Curves.easeOutCubic);
  }
}

class _StatusSection extends StatelessWidget {
  final IntakeLog log;
  final AppLocalizations l10n;
  final WidgetRef ref;

  const _StatusSection(
      {required this.log, required this.l10n, required this.ref});

  @override
  Widget build(BuildContext context) {
    if (log.status == 'taken') {
      return _Chip(
          label: l10n.get('taken'),
          color: Colors.green,
          icon: Icons.check_circle);
    }
    if (log.status == 'missed') {
      return _Chip(
          label: l10n.get('missed'),
          color: Colors.red,
          icon: Icons.cancel);
    }
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        SizedBox(
          height: 36,
          child: FilledButton(
            style: FilledButton.styleFrom(
              minimumSize: const Size(76, 36),
              backgroundColor: AppTheme.primary,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () => _markTaken(context),
            child: Text(l10n.get('take_now'),
                style: const TextStyle(fontSize: 12)),
          ),
        ),
        const SizedBox(height: 6),
        SizedBox(
          height: 30,
          child: OutlinedButton(
            style: OutlinedButton.styleFrom(
              minimumSize: const Size(76, 30),
              padding: const EdgeInsets.symmetric(horizontal: 12),
              side: BorderSide(color: Colors.grey.shade300),
              shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12)),
            ),
            onPressed: () =>
                ref.read(medicationNotifierProvider.notifier).markMissed(log),
            child: Text(l10n.get('mark_missed'),
                style:
                    TextStyle(fontSize: 11, color: Colors.grey.shade600)),
          ),
        ),
      ],
    );
  }

  Future<void> _markTaken(BuildContext context) async {
    final mood = await showMoodTrackerDialog(context, ref);
    await ref
        .read(medicationNotifierProvider.notifier)
        .markTaken(log, mood: mood);
  }
}

class _Chip extends StatelessWidget {
  final String label;
  final Color color;
  final IconData icon;
  const _Chip(
      {required this.label, required this.color, required this.icon});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 15),
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

class _MoodChip extends StatelessWidget {
  final String mood;
  const _MoodChip({required this.mood});

  @override
  Widget build(BuildContext context) {
    final emoji =
        mood == 'great' ? '😊' : mood == 'ok' ? '😐' : '😔';
    return Text(emoji, style: const TextStyle(fontSize: 16));
  }
}
