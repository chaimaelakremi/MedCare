import 'package:cloud_firestore/cloud_firestore.dart';

class AppNotification {
  final String id;
  final String type; // 'taken_medication' | 'missed_medication'
  final String patientName;
  final String medicationName;
  final String timeSlot;
  final DateTime? createdAt;
  final bool read;

  const AppNotification({
    required this.id,
    required this.type,
    required this.patientName,
    required this.medicationName,
    required this.timeSlot,
    this.createdAt,
    required this.read,
  });

  factory AppNotification.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return AppNotification(
      id: doc.id,
      type: d['type'] as String? ?? 'missed_medication',
      patientName: d['patientName'] as String? ?? '',
      medicationName: d['medicationName'] as String? ?? '',
      timeSlot: d['timeSlot'] as String? ?? '',
      createdAt: (d['createdAt'] as Timestamp?)?.toDate(),
      read: d['read'] as bool? ?? false,
    );
  }
}
