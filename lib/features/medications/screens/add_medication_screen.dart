import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/l10n/app_localizations.dart';
import '../../../core/theme/app_theme.dart';
import '../providers/medication_providers.dart';

const _colors = [
  Color(0xFF9B7EBD),
  Color(0xFFE8A0BF),
  Color(0xFF7EC8B8),
  Color(0xFFFFB347),
  Color(0xFF87CEEB),
  Color(0xFFFF8C94),
];

class AddMedicationScreen extends ConsumerStatefulWidget {
  const AddMedicationScreen({super.key});

  @override
  ConsumerState<AddMedicationScreen> createState() =>
      _AddMedicationScreenState();
}

class _AddMedicationScreenState extends ConsumerState<AddMedicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _doseCtrl = TextEditingController();
  String _frequency = 'daily';
  TimeOfDay _time1 = const TimeOfDay(hour: 8, minute: 0);
  TimeOfDay _time2 = const TimeOfDay(hour: 14, minute: 0);
  TimeOfDay _time3 = const TimeOfDay(hour: 20, minute: 0);
  int _colorIdx = 0;
  bool _saving = false;
  Uint8List? _prescriptionBytes;

  // ── Prescription image ──────────────────────────────────────────────────────

  Future<void> _pickPrescription() async {
    try {
      final image =
          await ImagePicker().pickImage(source: ImageSource.gallery);
      if (image == null || !mounted) return;
      final bytes = await image.readAsBytes();
      if (!mounted) return;
      setState(() => _prescriptionBytes = bytes);
    } catch (_) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Impossible de charger l\'image. Réessayez.'),
          backgroundColor: Colors.red,
          behavior: SnackBarBehavior.floating,
          shape:
              RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        ),
      );
    }
  }

  void _removePrescription() => setState(() => _prescriptionBytes = null);

  // ── Save ────────────────────────────────────────────────────────────────────

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _saving = true);

    final times = [_fmt(_time1)];
    if (_doseCount >= 2) times.add(_fmt(_time2));
    if (_doseCount >= 3) times.add(_fmt(_time3));

    await ref.read(medicationNotifierProvider.notifier).addMedication(
          name: _nameCtrl.text.trim(),
          dose: _doseCtrl.text.trim(),
          times: times,
          frequency: _frequency,
          colorValue: _colors[_colorIdx].toARGB32(),
        );

    if (!mounted) return;
    await ref.read(medicationNotifierProvider.notifier).ensureTodayLogs();
    if (!mounted) return;

    setState(() => _saving = false);
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(ref.read(l10nProvider).get('success_med_added')),
        backgroundColor: AppTheme.primary,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      ),
    );
    context.pop();
  }

  // ── Helpers ─────────────────────────────────────────────────────────────────

  int get _doseCount {
    if (_frequency == 'twice_daily') return 2;
    if (_frequency == 'thrice_daily') return 3;
    return 1;
  }

  String _fmt(TimeOfDay t) =>
      '${t.hour.toString().padLeft(2, '0')}:${t.minute.toString().padLeft(2, '0')}';

  Future<void> _pickTime(int slot) async {
    final initial = slot == 1 ? _time1 : slot == 2 ? _time2 : _time3;
    final picked =
        await showTimePicker(context: context, initialTime: initial);
    if (picked == null) return;
    setState(() {
      if (slot == 1) _time1 = picked;
      if (slot == 2) _time2 = picked;
      if (slot == 3) _time3 = picked;
    });
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _doseCtrl.dispose();
    super.dispose();
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final l10n = ref.watch(l10nProvider);

    return Scaffold(
      appBar: AppBar(
        title: Text(l10n.get('add_med_title')),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => context.pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // ── Prescription photo ──────────────────────────────────────
                _prescriptionBytes == null
                    ? OutlinedButton.icon(
                        style: OutlinedButton.styleFrom(
                          minimumSize: const Size(double.infinity, 50),
                          side: const BorderSide(color: AppTheme.primary),
                          shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14)),
                        ),
                        onPressed: _pickPrescription,
                        icon: const Icon(Icons.upload_file_outlined,
                            color: AppTheme.primary),
                        label: const Text(
                          '📄 Ajouter une photo d\'ordonnance',
                          style: TextStyle(
                              color: AppTheme.primary,
                              fontWeight: FontWeight.w600),
                        ),
                      ).animate().fade(duration: 300.ms)
                    : Stack(
                        children: [
                          ClipRRect(
                            borderRadius: BorderRadius.circular(14),
                            child: Image.memory(
                              _prescriptionBytes!,
                              width: double.infinity,
                              height: 200,
                              fit: BoxFit.cover,
                            ),
                          ),
                          Positioned(
                            top: 8,
                            right: 8,
                            child: GestureDetector(
                              onTap: _removePrescription,
                              child: Container(
                                padding: const EdgeInsets.all(4),
                                decoration: const BoxDecoration(
                                  color: Colors.red,
                                  shape: BoxShape.circle,
                                ),
                                child: const Icon(Icons.close,
                                    color: Colors.white, size: 18),
                              ),
                            ),
                          ),
                        ],
                      ).animate().fade(duration: 300.ms),

                const SizedBox(height: 20),

                // ── Name ───────────────────────────────────────────────────
                TextFormField(
                  controller: _nameCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.get('med_name'),
                    prefixIcon: const Text('💊',
                        style: TextStyle(fontSize: 20)),
                    prefixIconConstraints: const BoxConstraints(
                        minWidth: 52, minHeight: 40),
                  ),
                  style: const TextStyle(fontSize: 17),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.get('err_required')
                      : null,
                ).animate().fade(delay: 50.ms).slideX(begin: -0.1),

                const SizedBox(height: 16),

                // ── Dose ───────────────────────────────────────────────────
                TextFormField(
                  controller: _doseCtrl,
                  decoration: InputDecoration(
                    labelText: l10n.get('med_dose'),
                    prefixIcon: const Icon(Icons.scale_outlined),
                  ),
                  style: const TextStyle(fontSize: 17),
                  validator: (v) => (v == null || v.isEmpty)
                      ? l10n.get('err_required')
                      : null,
                ).animate().fade(delay: 100.ms).slideX(begin: -0.1),

                const SizedBox(height: 24),

                // ── Frequency ──────────────────────────────────────────────
                Text(l10n.get('med_frequency'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Wrap(
                  spacing: 10,
                  runSpacing: 10,
                  children: [
                    _FreqChip(
                      label: l10n.get('freq_daily'),
                      selected: _frequency == 'daily',
                      onTap: () => setState(() => _frequency = 'daily'),
                    ),
                    _FreqChip(
                      label: l10n.get('freq_twice'),
                      selected: _frequency == 'twice_daily',
                      onTap: () =>
                          setState(() => _frequency = 'twice_daily'),
                    ),
                    _FreqChip(
                      label: l10n.get('freq_thrice'),
                      selected: _frequency == 'thrice_daily',
                      onTap: () =>
                          setState(() => _frequency = 'thrice_daily'),
                    ),
                    _FreqChip(
                      label: l10n.get('freq_weekly'),
                      selected: _frequency == 'weekly',
                      onTap: () => setState(() => _frequency = 'weekly'),
                    ),
                  ],
                ).animate().fade(delay: 150.ms),

                const SizedBox(height: 24),

                // ── Times ──────────────────────────────────────────────────
                Text(l10n.get('med_time'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                _TimePicker(
                  label: _doseCount > 1
                      ? '1ère prise'
                      : l10n.get('med_time'),
                  time: _time1,
                  onTap: () => _pickTime(1),
                ),
                if (_doseCount >= 2) ...[
                  const SizedBox(height: 10),
                  _TimePicker(
                    label: l10n.get('second_time'),
                    time: _time2,
                    onTap: () => _pickTime(2),
                  ),
                ],
                if (_doseCount >= 3) ...[
                  const SizedBox(height: 10),
                  _TimePicker(
                    label: l10n.get('third_time'),
                    time: _time3,
                    onTap: () => _pickTime(3),
                  ),
                ],

                const SizedBox(height: 24),

                // ── Color ──────────────────────────────────────────────────
                Text(l10n.get('color_pick'),
                    style: Theme.of(context).textTheme.titleMedium),
                const SizedBox(height: 12),
                Row(
                  children: List.generate(
                    _colors.length,
                    (i) => Padding(
                      padding: const EdgeInsets.only(right: 12),
                      child: GestureDetector(
                        onTap: () => setState(() => _colorIdx = i),
                        child: AnimatedContainer(
                          duration: 200.ms,
                          width: _colorIdx == i ? 40 : 32,
                          height: _colorIdx == i ? 40 : 32,
                          decoration: BoxDecoration(
                            color: _colors[i],
                            shape: BoxShape.circle,
                            border: _colorIdx == i
                                ? Border.all(
                                    color: Colors.black26, width: 3)
                                : null,
                            boxShadow: _colorIdx == i
                                ? [
                                    BoxShadow(
                                      color: _colors[i]
                                          .withValues(alpha: 0.5),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                        ),
                      ),
                    ),
                  ),
                ).animate().fade(delay: 200.ms),

                const SizedBox(height: 40),

                // ── Save button ────────────────────────────────────────────
                FilledButton(
                  onPressed: _saving ? null : _save,
                  child: _saving
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              color: Colors.white, strokeWidth: 2.5),
                        )
                      : Text(l10n.get('save'),
                          style: const TextStyle(fontSize: 17)),
                ).animate().fade(delay: 300.ms).slideY(begin: 0.2),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ── Widgets ───────────────────────────────────────────────────────────────────

class _FreqChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _FreqChip(
      {required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: 200.ms,
        padding:
            const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        decoration: BoxDecoration(
          color: selected ? AppTheme.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(20),
          border: Border.all(
              color: selected
                  ? AppTheme.primary
                  : Colors.grey.shade300),
        ),
        child: Text(
          label,
          style: TextStyle(
            color: selected ? Colors.white : null,
            fontWeight:
                selected ? FontWeight.w700 : FontWeight.w500,
            fontSize: 14,
          ),
        ),
      ),
    );
  }
}

class _TimePicker extends StatelessWidget {
  final String label;
  final TimeOfDay time;
  final VoidCallback onTap;

  const _TimePicker(
      {required this.label, required this.time, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final formatted =
        '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding:
            const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
          color: Theme.of(context).inputDecorationTheme.fillColor,
        ),
        child: Row(
          children: [
            const Icon(Icons.access_time, color: AppTheme.primary),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(label,
                      style: TextStyle(
                          fontSize: 13,
                          color: Colors.grey.shade500)),
                  Text(formatted,
                      style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w700,
                          color: AppTheme.primary)),
                ],
              ),
            ),
            Icon(Icons.chevron_right, color: Colors.grey.shade400),
          ],
        ),
      ),
    );
  }
}
