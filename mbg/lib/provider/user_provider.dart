import 'package:flutter/material.dart';

class UserProvider with ChangeNotifier {
  String? _uid;
  String? _email;
  String _role = '';
  String? _fullName;
  String? _schoolId; // Untuk Admin, Guru, Tim Katering (jika terhubung ke sekolah)
  String? _profilePictureUrl;
  bool? _isApproved; // Untuk Orang Tua
  List<String>? _childIds; // Untuk Orang Tua

  String? get uid => _uid;
  String? get email => _email;
  String get role => _role;
  String? get fullName => _fullName;
  String? get schoolId => _schoolId;
  String? get profilePictureUrl => _profilePictureUrl;
  bool? get isApproved => _isApproved;
  List<String>? get childIds => _childIds;

  void setUser(String? uid, String? email, String role, {String? fullName, String? schoolId, String? profilePictureUrl, bool? isApproved, List<String>? childIds}) {
    _uid = uid;
    _email = email;
    _role = role;
    _fullName = fullName;
    _schoolId = schoolId;
    _profilePictureUrl = profilePictureUrl;
    _isApproved = isApproved;
    _childIds = childIds;
    notifyListeners();
  }

  void clearUser() {
    _uid = null;
    _email = null;
    _role = '';
    _fullName = null;
    _schoolId = null;
    _profilePictureUrl = null;
    _isApproved = null;
    _childIds = null;
    notifyListeners();
  }

  void updateProfilePictureUrl(String? url) {
    _profilePictureUrl = url;
    notifyListeners();
  }

  void updateApprovalStatus(bool status) {
    _isApproved = status;
    notifyListeners();
  }

  // Metode baru untuk menambah/menghapus childId dari daftar Orang Tua
  void addChildId(String childId) {
    if (_childIds == null) {
      _childIds = [];
    }
    if (!_childIds!.contains(childId)) { // Perbaikan: Tambah '!' karena _childIds sudah dipastikan tidak null
      _childIds!.add(childId);
      notifyListeners();
    }
  }

  void removeChildId(String childId) {
    if (_childIds != null) {
      _childIds!.remove(childId);
      notifyListeners();
    }
  }
}