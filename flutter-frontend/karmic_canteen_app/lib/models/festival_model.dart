// lib/models/festival_model.dart
class FestivalModel {
  final String id;
  final String title;
  final String description;
  final String date;
  final String time;
  final String location;
  final String createdBy;
  final bool requiresRSVP;
  final int attendeesCount;

  FestivalModel({
    required this.id,
    required this.title,
    required this.description,
    required this.date,
    required this.time,
    required this.location,
    required this.createdBy,
    required this.requiresRSVP,
    this.attendeesCount = 0,
  });

  factory FestivalModel.fromFirestore(Map<String, dynamic> data, String id) {
    return FestivalModel(
      id: id,
      title: data['title'] ?? '',
      description: data['description'] ?? '',
      date: data['date'] ?? '',
      time: data['time'] ?? '',
      location: data['location'] ?? '',
      createdBy: data['createdBy'] ?? '',
      requiresRSVP: data['requiresRSVP'] ?? false,
      attendeesCount: data['attendeesCount'] ?? 0,
    );
  }

  Map<String, dynamic> toFirestore() {
    return {
      'title': title,
      'description': description,
      'date': date,
      'time': time,
      'location': location,
      'createdBy': createdBy,
      'requiresRSVP': requiresRSVP,
      'attendeesCount': attendeesCount,
    };
  }
}
