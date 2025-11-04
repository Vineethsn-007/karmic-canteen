// lib/models/meal_selection_model.dart
class MealSelectionModel {
  final bool breakfast;
  final bool lunch;
  final bool snacks;
  final String email;
  final String timestamp;

  MealSelectionModel({
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.email,
    required this.timestamp,
  });

  factory MealSelectionModel.fromMap(Map<String, dynamic> map) {
    return MealSelectionModel(
      breakfast: map['breakfast'] ?? false,
      lunch: map['lunch'] ?? false,
      snacks: map['snacks'] ?? false,
      email: map['email'] ?? '',
      timestamp: map['timestamp'] ?? '',
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'breakfast': breakfast,
      'lunch': lunch,
      'snacks': snacks,
      'email': email,
      'timestamp': timestamp,
    };
  }
}
