import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../data/medication_model.dart';
import '../data/medication_repository.dart';
import '../../auth/providers/auth_providers.dart';

final medicationRepositoryProvider = Provider<MedicationRepository>(
  (ref) => MedicationRepository(),
);

final medicationsProvider = StreamProvider<List<Medication>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(medicationRepositoryProvider).getMedications(user.uid);
});

final todayLogsProvider = StreamProvider<List<IntakeLog>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(medicationRepositoryProvider).getTodayLogs(user.uid);
});

final weekLogsProvider = StreamProvider<List<IntakeLog>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(medicationRepositoryProvider).getLogsForDays(user.uid, 7);
});

class MedicationNotifier extends Notifier<void> {
  @override
  void build() {}

  Future<void> addMedication({
    required String name,
    required String dose,
    required List<String> times,
    required String frequency,
    required int colorValue,
  }) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    final id = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('medications')
        .doc()
        .id;
    final med = Medication(
      id: id,
      userId: user.uid,
      name: name,
      dose: dose,
      times: times,
      frequency: frequency,
      colorValue: colorValue,
      isActive: true,
      createdAt: DateTime.now(),
    );
    await ref.read(medicationRepositoryProvider).addMedication(user.uid, med);
  }

  Future<void> deleteMedication(String medId) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    await ref.read(medicationRepositoryProvider).deleteMedication(user.uid, medId);
  }

  Future<void> ensureTodayLogs() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    final repo = ref.read(medicationRepositoryProvider);
    // Fetch directly from Firestore (not stream cache) so newly added meds are included.
    final meds = await repo.getMedicationsOnce(user.uid);
    await repo.ensureTodayLogs(user.uid, meds);
  }

  Future<void> markTaken(IntakeLog log, {String? mood}) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    final repo = ref.read(medicationRepositoryProvider);
    await repo.markTaken(user.uid, log.id, mood: mood);
    final userDoc = ref.read(userDocProvider).asData?.value;
    final patientName = userDoc?['name'] as String? ?? 'Le patient';
    await repo.notifyFamilyOfTaken(
      patientUid: user.uid,
      patientName: patientName,
      medicationName: log.medicationName,
      timeSlot: log.timeSlot,
    );
  }

  Future<void> markMissed(IntakeLog log) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    final repo = ref.read(medicationRepositoryProvider);
    await repo.markMissed(user.uid, log.id);
    final userDoc = ref.read(userDocProvider).asData?.value;
    final patientName = userDoc?['name'] as String? ?? 'Le patient';
    await repo.notifyFamilyOfMissed(
      patientUid: user.uid,
      patientName: patientName,
      medicationName: log.medicationName,
      timeSlot: log.timeSlot,
    );
  }
}

final medicationNotifierProvider =
    NotifierProvider<MedicationNotifier, void>(MedicationNotifier.new);

final monthLogsProvider = StreamProvider<List<IntakeLog>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();
  final now = DateTime.now();
  return ref
      .watch(medicationRepositoryProvider)
      .getLogsForMonth(user.uid, now.year, now.month);
});

final streakProvider = Provider<int>((ref) {
  final logs = ref.watch(monthLogsProvider).asData?.value ?? [];
  return _calcStreak(logs);
});

int _calcStreak(List<IntakeLog> logs) {
  final byDate = <String, List<IntakeLog>>{};
  for (final log in logs) {
    byDate.putIfAbsent(log.date, () => []).add(log);
  }
  int streak = 0;
  for (int i = 0; i < 31; i++) {
    final dateStr = DateFormat('yyyy-MM-dd')
        .format(DateTime.now().subtract(Duration(days: i)));
    final dayLogs = byDate[dateStr] ?? [];
    if (dayLogs.isEmpty) {
      if (i == 0) continue; // today not yet started
      break;
    }
    if (dayLogs.any((l) => l.status == 'missed')) break;
    if (i == 0 && dayLogs.any((l) => l.status == 'pending')) continue;
    streak++;
  }
  return streak;
}
