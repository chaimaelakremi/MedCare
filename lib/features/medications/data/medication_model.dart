import 'package:cloud_firestore/cloud_firestore.dart';

class Medication {
  final String id;
  final String userId;
  final String name;
  final String dose;
  final List<String> times;
  final String frequency;
  final int colorValue;
  final bool isActive;
  final DateTime createdAt;

  const Medication({
    required this.id,
    required this.userId,
    required this.name,
    required this.dose,
    required this.times,
    required this.frequency,
    required this.colorValue,
    required this.isActive,
    required this.createdAt,
  });

  factory Medication.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return Medication(
      id: doc.id,
      userId: d['userId'] as String? ?? '',
      name: d['name'] as String? ?? '',
      dose: d['dose'] as String? ?? '',
      times: List<String>.from(d['times'] as List? ?? []),
      frequency: d['frequency'] as String? ?? 'daily',
      colorValue: d['colorValue'] as int? ?? 0xFF9B7EBD,
      isActive: d['isActive'] as bool? ?? true,
      createdAt: (d['createdAt'] as Timestamp?)?.toDate() ?? DateTime.now(),
    );
  }

  Map<String, dynamic> toFirestore() => {
        'userId': userId,
        'name': name,
        'dose': dose,
        'times': times,
        'frequency': frequency,
        'colorValue': colorValue,
        'isActive': isActive,
        'createdAt': Timestamp.fromDate(createdAt),
      };
}

class IntakeLog {
  final String id;
  final String medicationId;
  final String medicationName;
  final String dose;
  final String timeSlot;
  final String date;
  final String status;
  final DateTime? takenAt;
  final String? mood;
  final int colorValue;

  const IntakeLog({
    required this.id,
    required this.medicationId,
    required this.medicationName,
    required this.dose,
    required this.timeSlot,
    required this.date,
    required this.status,
    this.takenAt,
    this.mood,
    required this.colorValue,
  });

  factory IntakeLog.fromFirestore(DocumentSnapshot doc) {
    final d = doc.data() as Map<String, dynamic>;
    return IntakeLog(
      id: doc.id,
      medicationId: d['medicationId'] as String? ?? '',
      medicationName: d['medicationName'] as String? ?? '',
      dose: d['dose'] as String? ?? '',
      timeSlot: d['timeSlot'] as String? ?? '',
      date: d['date'] as String? ?? '',
      status: d['status'] as String? ?? 'pending',
      takenAt: (d['takenAt'] as Timestamp?)?.toDate(),
      mood: d['mood'] as String?,
      colorValue: d['colorValue'] as int? ?? 0xFF9B7EBD,
    );
  }

  IntakeLog copyWith({String? status, DateTime? takenAt, String? mood}) {
    return IntakeLog(
      id: id,
      medicationId: medicationId,
      medicationName: medicationName,
      dose: dose,
      timeSlot: timeSlot,
      date: date,
      status: status ?? this.status,
      takenAt: takenAt ?? this.takenAt,
      mood: mood ?? this.mood,
      colorValue: colorValue,
    );
  }
}
