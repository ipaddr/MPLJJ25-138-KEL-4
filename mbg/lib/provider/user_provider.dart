import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String _role = 'Guru'; // Ubah role sesuai login

  String get role => _role;

  void setRole(String role) {
    _role = role;
    notifyListeners();
  }
}