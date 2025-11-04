// lib/models/user_model.dart
class UserModel {
  final String uid;
  final String email;
  final String name;
  final String role;
  final String? employeeId;
  final String? department;

  UserModel({
    required this.uid,
    required this.email,
    required this.name,
    required this.role,
    this.employeeId,
    this.department,
  });

  factory UserModel.fromMap(Map<String, dynamic> map, String uid) {
    return UserModel(
      uid: uid,
      email: map['email'] ?? '',
      name: map['name'] ?? '',
      role: map['role'] ?? 'employee',
      employeeId: map['employeeId'],
      department: map['department'],
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'email': email,
      'name': name,
      'role': role,
      'employeeId': employeeId,
      'department': department,
    };
  }
}
