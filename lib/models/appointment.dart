import 'package:uuid/uuid.dart';

class Appointment {
  final String id;
  final String petId;
  final String title;
  final DateTime date;
  final String type;
  final String notes;

  Appointment({
    String? id,
    required this.petId,
    required this.title,
    required this.date,
    required this.type,
    this.notes = "",
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'date': date.toIso8601String(),
      'type': type,
      'notes': notes,
    };
  }

  factory Appointment.fromMap(Map<String, dynamic> map) {
    return Appointment(
      id: map['id'],
      petId: map['petId'],
      title: map['title'],
      date: DateTime.parse(map['date']),
      type: map['type'],
      notes: map['notes'] ?? "",
    );
  }
}
