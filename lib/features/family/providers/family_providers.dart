import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../data/family_repository.dart';
import '../data/notification_model.dart';
import '../../auth/providers/auth_providers.dart';
import '../../medications/data/medication_model.dart';
import '../../medications/providers/medication_providers.dart';

final familyRepositoryProvider =
    Provider<FamilyRepository>((ref) => FamilyRepository());

final linkedPatientProvider = FutureProvider<Map<String, dynamic>?>((ref) async {
  final userDoc = await ref.watch(userDocProvider.future);
  final patientId = userDoc?['linkedPatientId'] as String?;
  if (patientId == null) return null;
  return ref.read(familyRepositoryProvider).getLinkedPatient(patientId);
});

final patientMedicationsProvider = StreamProvider<List<Medication>>((ref) {
  final userDoc = ref.watch(userDocProvider).asData?.value;
  final patientId = userDoc?['linkedPatientId'] as String?;
  if (patientId == null) return const Stream.empty();
  return ref.watch(medicationRepositoryProvider).getPatientMedications(patientId);
});

final patientLogsProvider = StreamProvider<List<IntakeLog>>((ref) {
  final userDoc = ref.watch(userDocProvider).asData?.value;
  final patientId = userDoc?['linkedPatientId'] as String?;
  if (patientId == null) return const Stream.empty();
  return ref.watch(medicationRepositoryProvider).getPatientLogs(patientId, 7);
});

class FamilyNotifier extends AsyncNotifier<void> {
  @override
  Future<void> build() async {}

  Future<String?> linkToPatient(String code) async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return null;
    final patient = await ref.read(familyRepositoryProvider).findPatientByCode(code);
    if (patient == null) return 'not_found';
    final userDoc = await ref.read(authRepositoryProvider).getUserDoc(user.uid);
    if (userDoc?['linkedPatientId'] == patient['uid']) return 'already_linked';
    await ref
        .read(familyRepositoryProvider)
        .linkFamilyToPatient(user.uid, patient['uid'] as String);
    ref.invalidate(linkedPatientProvider);
    ref.invalidate(userDocProvider);
    return null;
  }

  Future<void> unlink() async {
    final user = ref.read(authStateProvider).asData?.value;
    if (user == null) return;
    await ref.read(familyRepositoryProvider).unlinkFamily(user.uid);
    ref.invalidate(linkedPatientProvider);
    ref.invalidate(userDocProvider);
  }
}

final familyNotifierProvider =
    AsyncNotifierProvider<FamilyNotifier, void>(FamilyNotifier.new);

final patientTodayLogsProvider = StreamProvider<List<IntakeLog>>((ref) {
  final userDoc = ref.watch(userDocProvider).asData?.value;
  final patientId = userDoc?['linkedPatientId'] as String?;
  if (patientId == null) return const Stream.empty();
  return ref.watch(medicationRepositoryProvider).getTodayLogs(patientId);
});

final linkedFamilyMembersProvider =
    StreamProvider<List<Map<String, dynamic>>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(familyRepositoryProvider).watchLinkedFamilyMembers(user.uid);
});

final notificationsProvider = StreamProvider<List<AppNotification>>((ref) {
  final user = ref.watch(authStateProvider).asData?.value;
  if (user == null) return const Stream.empty();
  return ref.watch(familyRepositoryProvider).getNotifications(user.uid);
});

final unreadNotificationsCountProvider = Provider<int>((ref) {
  final notifs = ref.watch(notificationsProvider).asData?.value ?? [];
  return notifs.where((n) => !n.read).length;
});
