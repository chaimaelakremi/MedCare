import 'package:cloud_firestore/cloud_firestore.dart';
import 'notification_model.dart';

class FamilyRepository {
  final _db = FirebaseFirestore.instance;

  Future<Map<String, dynamic>?> findPatientByCode(String code) async {
    final snap = await _db
        .collection('users')
        .where('familyCode', isEqualTo: code.toUpperCase())
        .where('role', isEqualTo: 'patient')
        .limit(1)
        .get();

    if (snap.docs.isEmpty) return null;
    return {'uid': snap.docs.first.id, ...snap.docs.first.data()};
  }

  Future<void> linkFamilyToPatient(String familyUid, String patientUid) async {
    await _db.collection('users').doc(familyUid).update({
      'linkedPatientId': patientUid,
    });
  }

  Future<Map<String, dynamic>?> getLinkedPatient(String patientUid) async {
    final doc = await _db.collection('users').doc(patientUid).get();
    if (!doc.exists) return null;
    return {'uid': doc.id, ...doc.data()!};
  }

  Future<void> unlinkFamily(String familyUid) async {
    await _db.collection('users').doc(familyUid).update({
      'linkedPatientId': null,
    });
  }

  Stream<List<Map<String, dynamic>>> watchLinkedFamilyMembers(String patientUid) {
    return _db
        .collection('users')
        .where('linkedPatientId', isEqualTo: patientUid)
        .snapshots()
        .map((s) =>
            s.docs.map((d) => {'uid': d.id, ...d.data()}).toList());
  }

  Stream<List<AppNotification>> getNotifications(String uid) {
    return _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .snapshots()
        .map((s) {
          final list = s.docs.map(AppNotification.fromFirestore).toList();
          list.sort((a, b) =>
              (b.createdAt ?? DateTime(0)).compareTo(a.createdAt ?? DateTime(0)));
          return list;
        });
  }

  Future<void> deleteNotification(String uid, String notifId) async {
    await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .doc(notifId)
        .delete();
  }

  Future<void> markNotificationsRead(String uid) async {
    final unread = await _db
        .collection('users')
        .doc(uid)
        .collection('notifications')
        .where('read', isEqualTo: false)
        .get();
    if (unread.docs.isEmpty) return;
    final batch = _db.batch();
    for (final doc in unread.docs) {
      batch.update(doc.reference, {'read': true});
    }
    await batch.commit();
  }
}
