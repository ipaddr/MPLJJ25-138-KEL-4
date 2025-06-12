import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _uid;
  String? _email;
  String _role = '';
  String? _profilePictureUrl;

  String? get uid => _uid;
  String? get email => _email;
  String get role => _role;
  String? get profilePictureUrl => _profilePictureUrl;

  void setUser(String? uid, String? email, String role, {String? profilePictureUrl}) {
    _uid = uid;
    _email = email;
    _role = role;
    _profilePictureUrl = profilePictureUrl;
    notifyListeners();
  }

  void clearUser() {
    _uid = null;
    _email = null;
    _role = '';
    _profilePictureUrl = null;
    notifyListeners();
  }

  void updateProfilePictureUrl(String? url) {
    _profilePictureUrl = url;
    notifyListeners();
  }
}