// lib/services/firestore_service.dart
import 'package:cloud_firestore/cloud_firestore.dart';
import '../models/menu_model.dart';
import '../models/meal_selection_model.dart';

class FirestoreService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;

  // Get menu for a specific date
  Future<MenuModel?> getMenu(String date) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('menus')
          .doc(date)
          .get();

      if (doc.exists) {
        return MenuModel.fromMap(
          doc.data() as Map<String, dynamic>,
          date,
        );
      }
      return null;
    } catch (e) {
      print('Get menu error: $e');
      return null;
    }
  }

  // Save meal selection
  Future<void> saveMealSelection(
    String date,
    String userId,
    String email,
    MealSelectionModel selection,
  ) async {
    try {
      await _firestore
          .collection('mealSelections')
          .doc(date)
          .collection('users')
          .doc(userId)
          .set({
        ...selection.toMap(),
        'userId': userId,
        'modified': true,
      });
    } catch (e) {
      print('Save meal selection error: $e');
      rethrow;
    }
  }

  // Get user's meal selection
  Future<MealSelectionModel?> getMealSelection(
    String date,
    String userId,
  ) async {
    try {
      DocumentSnapshot doc = await _firestore
          .collection('mealSelections')
          .doc(date)
          .collection('users')
          .doc(userId)
          .get();

      if (doc.exists) {
        return MealSelectionModel.fromMap(
          doc.data() as Map<String, dynamic>,
        );
      }
      return null;
    } catch (e) {
      print('Get meal selection error: $e');
      return null;
    }
  }

  // Admin: Save menu
  Future<void> saveMenu(String date, MenuModel menu) async {
    try {
      await _firestore
          .collection('menus')
          .doc(date)
          .set(menu.toMap());
    } catch (e) {
      print('Save menu error: $e');
      rethrow;
    }
  }

  // Admin: Get all meal selections for a date
  Future<Map<String, dynamic>> getMealSelections(String date) async {
    try {
      QuerySnapshot snapshot = await _firestore
          .collection('mealSelections')
          .doc(date)
          .collection('users')
          .get();

      int breakfast = 0;
      int lunch = 0;
      int snacks = 0;
      List<Map<String, dynamic>> participants = [];

      for (var doc in snapshot.docs) {
        var data = doc.data() as Map<String, dynamic>;
        if (data['breakfast'] == true) breakfast++;
        if (data['lunch'] == true) lunch++;
        if (data['snacks'] == true) snacks++;

        participants.add({
          'email': data['email'],
          'breakfast': data['breakfast'] ?? false,
          'lunch': data['lunch'] ?? false,
          'snacks': data['snacks'] ?? false,
        });
      }

      return {
        'breakfast': breakfast,
        'lunch': lunch,
        'snacks': snacks,
        'totalParticipants': participants.length,
        'participants': participants,
      };
    } catch (e) {
      print('Get meal selections error: $e');
      rethrow;
    }
  }
}
