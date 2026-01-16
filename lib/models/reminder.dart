import 'package:uuid/uuid.dart';

enum ReminderType { appointment, medication, grooming, general }

class Reminder {
  final String id;
  final String petId;
  final String title;
  final DateTime date;
  final ReminderType type;
  final bool isCompleted;

  Reminder({
    String? id,
    required this.petId,
    required this.title,
    required this.date,
    required this.type,
    this.isCompleted = false,
  }) : id = id ?? const Uuid().v4();

  
  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'petId': petId,
      'title': title,
      'date': date.toIso8601String(),
      'type': type.name,
      'isCompleted': isCompleted ? 1 : 0,
    };
  }

  
  factory Reminder.fromMap(Map<String, dynamic> map) {
    return Reminder(
      id: map['id'] as String,
      petId: map['petId'] as String,
      title: map['title'] as String,
      date: DateTime.parse(map['date'] as String),
      type: ReminderType.values.firstWhere(
        (e) => e.name == (map['type'] as String),
        orElse: () => ReminderType.general,
      ),
      isCompleted: (map['isCompleted'] as int) == 1,
    );
  }
}
