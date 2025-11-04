// lib/models/menu_model.dart
class MenuModel {
  final String date;
  final List<String> breakfast;
  final List<String> lunch;
  final List<String> snacks;
  final List<String> dinner;

  MenuModel({
    required this.date,
    required this.breakfast,
    required this.lunch,
    required this.snacks,
    required this.dinner,
  });

  factory MenuModel.fromMap(Map<String, dynamic> map, String date) {
    return MenuModel(
      date: date,
      breakfast: List<String>.from(map['breakfast'] ?? []),
      lunch: List<String>.from(map['lunch'] ?? []),
      snacks: List<String>.from(map['snacks'] ?? []),
      dinner: List<String>.from(map['dinner'] ?? []),
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'breakfast': breakfast,
      'lunch': lunch,
      'snacks': snacks,
    };
  }
}
