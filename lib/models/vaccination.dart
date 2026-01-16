

import 'package:uuid/uuid.dart';

class Vaccination {
  final String id;
  final String petId;
  final String name;
  final DateTime date;
  final bool isCompleted;
  final DateTime lastDoneDate;
  final bool isPeriodic;
  final int periodMonths;
  final String? notes;

  Vaccination({
    String? id,
    required this.petId,
    required this.name,
    required this.date,
    required this.lastDoneDate,
    this.isPeriodic = false,
    this.periodMonths = 0,
    this.notes,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'name': name,
      'date': date.toIso8601String(),
      'lastDoneDate': lastDoneDate.toIso8601String(),
      'isPeriodic': isPeriodic ? 1 : 0, 
      'periodMonths': periodMonths,
      'isDone': isCompleted ? 1 : 0,
      'notes': notes,
    };
  }

  factory Vaccination.fromMap(Map<String, dynamic> map) {
    return Vaccination(
      id: map['id']?.toString(),
      petId: map['petId']?.toString() ?? '',
      name: map['name'] ?? 'Bilinmeyen Aşı',
      date: map['date'] != null
          ? DateTime.parse(map['date'].toString())
          : DateTime.now(),
      lastDoneDate: map['lastDoneDate'] != null
          ? DateTime.parse(map['lastDoneDate'].toString())
          : (map['date'] != null
                ? DateTime.parse(map['date'].toString())
                : DateTime.now()),
      isPeriodic: map['isPeriodic'] == 1,
      periodMonths: map['periodMonths'] ?? 0,
      isCompleted: map['isCompleted'] == 1 || map['isDone'] == 1,
      notes: map['notes'],
    );
  }

  bool get isExpired {
    if (!isPeriodic || periodMonths <= 0) return false;

    final expiryDate = DateTime(date.year, date.month + periodMonths, date.day);

    return DateTime.now().isAfter(expiryDate);
  }

  DateTime? get nextVaccinationDate {
    if (!isPeriodic || periodMonths <= 0) return null;

    return DateTime(date.year, date.month + periodMonths, date.day);
  }
}
