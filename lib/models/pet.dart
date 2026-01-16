import 'package:uuid/uuid.dart';

class Pet {
  String id;
  String name;
  double? weight;
  double? targetWeight;
  final String species;
  final DateTime birthDate;
  final String gender;
  final String? photoPath;
  final double foodStockKg;
  final bool isSterilized;

  Pet({
    String? id,
    required this.name,
    required this.weight,
    this.targetWeight = 0.0,
    required this.species,
    required this.birthDate,
    required this.gender,
    this.photoPath,
    this.foodStockKg = 0.0,
    this.isSterilized = false,
  }) : id = id ?? const Uuid().v4();

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'name': name,
      'species': species,
      'birthDate': birthDate.toIso8601String(),
      'gender': gender,
      'isSterilized': isSterilized ? 1 : 0,
      'photoPath': photoPath,
      'weight': weight,
      'targetWeight': targetWeight,
      'foodStockKg': foodStockKg,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      id: map['id'],
      name: map['name'],
      species: map['species'],
      birthDate: DateTime.parse(map['birthDate']),
      gender: map['gender'],
      photoPath: map['photoPath'],
      foodStockKg: map['foodStockKg']?.toDouble() ?? 0.0,
      isSterilized: map['isSterilized'] == 1,
      weight: map['weight']?.toDouble() ?? 0.0,
      targetWeight: map['targetWeight']?.toDouble() ?? 0.0,
    );
  }

  String get ageString {
    final now = DateTime.now();
    final difference = now.difference(birthDate);
    final years = difference.inDays ~/ 365;
    final months = (difference.inDays % 365) ~/ 30;
    if (years > 0) return '$years Yıl ve $months Ay';
    if (months > 0) return '$months Ay';
    return 'Yeni Doğdu';
  }
}
