import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:intl/intl.dart';
import 'medication_model.dart';

class MedicationRepository {
  final _db = FirebaseFirestore.instance;

  CollectionReference<Map<String, dynamic>> _medsCol(String uid) =>
      _db.collection('users').doc(uid).collection('medications');

  CollectionReference<Map<String, dynamic>> _logsCol(String uid) =>
      _db.collection('users').doc(uid).collection('intake_logs');

  Future<List<Medication>> getMedicationsOnce(String uid) async {
    final snap = await _medsCol(uid).where('isActive', isEqualTo: true).get();
    final list = snap.docs.map(Medication.fromFirestore).toList();
    list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
    return list;
  }

  Stream<List<Medication>> getMedications(String uid) {
    return _medsCol(uid)
        .where('isActive', isEqualTo: true)
        .snapshots()
        .map((s) {
          final list = s.docs.map(Medication.fromFirestore).toList();
          list.sort((a, b) => a.createdAt.compareTo(b.createdAt));
          return list;
        });
  }

  Future<void> addMedication(String uid, Medication med) async {
    await _medsCol(uid).doc(med.id).set(med.toFirestore());
  }

  Future<void> deleteMedication(String uid, String medId) async {
    await _medsCol(uid).doc(medId).update({'isActive': false});
  }

  Stream<List<IntakeLog>> getTodayLogs(String uid) {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    return _logsCol(uid)
        .where('date', isEqualTo: today)
        .snapshots()
        .map((s) {
          final list = s.docs.map(IntakeLog.fromFirestore).toList();
          list.sort((a, b) => a.timeSlot.compareTo(b.timeSlot));
          return list;
        });
  }

  Stream<List<IntakeLog>> getLogsForDays(String uid, int days) {
    final cutoff = DateTime.now().subtract(Duration(days: days));
    final cutoffStr = DateFormat('yyyy-MM-dd').format(cutoff);
    return _logsCol(uid)
        .where('date', isGreaterThanOrEqualTo: cutoffStr)
        .snapshots()
        .map((s) {
          final list = s.docs.map(IntakeLog.fromFirestore).toList();
          list.sort((a, b) {
            final d = a.date.compareTo(b.date);
            return d != 0 ? d : a.timeSlot.compareTo(b.timeSlot);
          });
          return list;
        });
  }

  Future<void> ensureTodayLogs(String uid, List<Medication> medications) async {
    final today = DateFormat('yyyy-MM-dd').format(DateTime.now());
    final batch = _db.batch();
    bool hasNew = false;

    for (final med in medications) {
      for (final time in med.times) {
        final logId = '${med.id}_${time.replaceAll(':', '')}';
        final docRef = _logsCol(uid).doc('${today}_$logId');
        final existing = await docRef.get();
        if (!existing.exists) {
          batch.set(docRef, {
            'medicationId': med.id,
            'medicationName': med.name,
            'dose': med.dose,
            'timeSlot': time,
            'date': today,
            'status': 'pending',
            'takenAt': null,
            'mood': null,
            'colorValue': med.colorValue,
          });
          hasNew = true;
        }
      }
    }
    if (hasNew) await batch.commit();
  }

  Future<void> markTaken(String uid, String logId, {String? mood}) async {
    await _logsCol(uid).doc(logId).update({
      'status': 'taken',
      'takenAt': FieldValue.serverTimestamp(),
      // ignore: use_null_aware_elements
      if (mood != null) 'mood': mood,
    });
  }

  Future<void> markMissed(String uid, String logId) async {
    await _logsCol(uid).doc(logId).update({'status': 'missed'});
  }

  Future<void> _notifyFamily({
    required String patientUid,
    required String type,
    required String patientName,
    required String medicationName,
    required String timeSlot,
  }) async {
    final familySnap = await _db
        .collection('users')
        .where('linkedPatientId', isEqualTo: patientUid)
        .limit(1)
        .get();
    if (familySnap.docs.isEmpty) return;
    await _db
        .collection('users')
        .doc(familySnap.docs.first.id)
        .collection('notifications')
        .add({
      'type': type,
      'patientName': patientName,
      'medicationName': medicationName,
      'timeSlot': timeSlot,
      'createdAt': FieldValue.serverTimestamp(),
      'read': false,
    });
  }

  Future<void> notifyFamilyOfMissed({
    required String patientUid,
    required String patientName,
    required String medicationName,
    required String timeSlot,
  }) => _notifyFamily(
        patientUid: patientUid,
        type: 'missed_medication',
        patientName: patientName,
        medicationName: medicationName,
        timeSlot: timeSlot,
      );

  Future<void> notifyFamilyOfTaken({
    required String patientUid,
    required String patientName,
    required String medicationName,
    required String timeSlot,
  }) => _notifyFamily(
        patientUid: patientUid,
        type: 'taken_medication',
        patientName: patientName,
        medicationName: medicationName,
        timeSlot: timeSlot,
      );

  Stream<List<IntakeLog>> getLogsForMonth(String uid, int year, int month) {
    final start = DateFormat('yyyy-MM-dd').format(DateTime(year, month, 1));
    final end = DateFormat('yyyy-MM-dd').format(DateTime(year, month + 1, 0));
    return _logsCol(uid)
        .where('date', isGreaterThanOrEqualTo: start)
        .where('date', isLessThanOrEqualTo: end)
        .snapshots()
        .map((s) => s.docs.map(IntakeLog.fromFirestore).toList());
  }

  Stream<List<IntakeLog>> getPatientLogs(String patientUid, int days) {
    return getLogsForDays(patientUid, days);
  }

  Stream<List<Medication>> getPatientMedications(String patientUid) {
    return getMedications(patientUid);
  }
}
