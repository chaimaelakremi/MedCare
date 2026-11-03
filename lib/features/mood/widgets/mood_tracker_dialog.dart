import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../data/mood_model.dart';

Future<String?> showMoodTrackerDialog(BuildContext context, WidgetRef ref) {
  return showDialog<String>(
    context: context,
    barrierDismissible: false,
    builder: (ctx) => _MoodDialog(ref: ref),
  );
}

class _MoodDialog extends StatefulWidget {
  final WidgetRef ref;
  const _MoodDialog({required this.ref});

  @override
  State<_MoodDialog> createState() => _MoodDialogState();
}

class _MoodDialogState extends State<_MoodDialog> {
  String? _selected;

  @override
  Widget build(BuildContext context) {
    final l10n = widget.ref.read(l10nProvider);

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(28)),
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text('✅', style: const TextStyle(fontSize: 48))
                .animate()
                .scale(duration: 400.ms, curve: Curves.elasticOut),
            const SizedBox(height: 16),
            Text(l10n.get('how_feel'),
                style: Theme.of(context).textTheme.titleLarge,
                textAlign: TextAlign.center),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: MoodEntry.moods.map((mood) {
                final isSelected = _selected == mood.key;
                return GestureDetector(
                  onTap: () => setState(() => _selected = mood.key),
                  child: AnimatedContainer(
                    duration: 200.ms,
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: isSelected
                          ? AppTheme.primary.withValues(alpha:0.15)
                          : Colors.transparent,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: isSelected ? AppTheme.primary : Colors.grey.shade200,
                        width: isSelected ? 2 : 1,
                      ),
                    ),
                    child: Column(
                      children: [
                        Text(mood.emoji, style: const TextStyle(fontSize: 36)),
                        const SizedBox(height: 4),
                        Text(
                          l10n.locale == 'fr' ? mood.labelFr : mood.labelEn,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                            color: isSelected ? AppTheme.primary : Colors.black54,
                          ),
                        ),
                      ],
                    ),
                  ),
                ).animate(target: isSelected ? 1 : 0).scale(begin: const Offset(1, 1), end: const Offset(1.05, 1.05));
              }).toList(),
            ),
            const SizedBox(height: 28),
            FilledButton(
              onPressed: _selected != null
                  ? () => Navigator.of(context).pop(_selected)
                  : null,
              child: const Text('Continuer'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.of(context).pop(null),
              child: Text('Passer', style: TextStyle(color: Colors.grey.shade500)),
            ),
          ],
        ),
      ),
    );
  }
}
