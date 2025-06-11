import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _uid;
  String? _email;
  String _role = '';

  String? get uid => _uid;
  String? get email => _email;
  String get role => _role;

  void setUser(String? uid, String? email, String role) {
    _uid = uid;
    _email = email;
    _role = role;
    notifyListeners();
  }

  void clearUser() {
    _uid = null;
    _email = null;
    _role = '';
    notifyListeners();
  }
}