// lib/providers/auth_provider.dart
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider with ChangeNotifier {
  final AuthService _authService = AuthService();
  
  User? _user;
  UserModel? _userModel;
  String? _userRole;
  bool _isLoading = true;

  User? get user => _user;
  UserModel? get userModel => _userModel;
  String? get userRole => _userRole;
  bool get isLoading => _isLoading;

  AuthProvider() {
    _authService.authStateChanges.listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? user) async {
    _user = user;
    
    if (user != null) {
      _userRole = await _authService.getUserRole(user.uid);
    } else {
      _userRole = null;
      _userModel = null;
    }
    
    _isLoading = false;
    notifyListeners();
  }

  Future<bool> signIn(String email, String password) async {
    try {
      _userModel = await _authService.signIn(email, password);
      return _userModel != null;
    } catch (e) {
      print('Sign in error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _authService.signOut();
    _user = null;
    _userModel = null;
    _userRole = null;
    notifyListeners();
  }
}
