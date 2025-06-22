import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'dart:async';
import 'package:flutter/foundation.dart';

class UserProvider with ChangeNotifier {
  String? _uid;
  String? _email;
  String _role = '';
  String? _fullName;
  String? _schoolId;
  String? _schoolName;
  String? _profilePictureUrl;
  bool? _isApproved;
  List<String>? _childIds;

  bool _isLoading = true;
  bool _isInitialized = false;

  StreamSubscription<User?>? _authStateChangesSubscription;
  StreamSubscription<DocumentSnapshot>? _userDocSubscription;

  bool get isLoading => _isLoading;
  bool get isInitialized => _isInitialized;

  UserProvider() {
    _authStateChangesSubscription = FirebaseAuth.instance.authStateChanges().listen((user) async {
      _userDocSubscription?.cancel();
      if (user != null) {
        _uid = user.uid;
        _email = user.email;
        _listenToUserDocument(user.uid);
      } else {
        clearUser();
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
      }
    });
  }

  Future<void> initializeUser() async {
    if (_isInitialized) return;

    _isLoading = true;
    notifyListeners();

    await Future.delayed(const Duration(milliseconds: 500));

    if (FirebaseAuth.instance.currentUser == null) {
        _isLoading = false;
        _isInitialized = true;
        notifyListeners();
        return;
    }

    if (_uid != null && _role.isEmpty) {
    } else {
        _isLoading = false;
        _isInitialized = true;
    }
    notifyListeners();
  }

  void _listenToUserDocument(String uid) {
    _userDocSubscription = FirebaseFirestore.instance
        .collection('users')
        .doc(uid)
        .snapshots()
        .listen((snapshot) {
      if (snapshot.exists) {
        _uid = uid;
        _email = snapshot.get('email') ?? _email;
        _role = snapshot.get('role') ?? '';
        _fullName = snapshot.get('fullName');
        _schoolId = snapshot.get('schoolId');
        _schoolName = snapshot.get('schoolName');
        _profilePictureUrl = snapshot.get('profilePictureUrl');
        _isApproved = snapshot.get('isApproved');
        _childIds = List<String>.from(snapshot.get('childIds') ?? []);
      } else {
        _role = '';
      }
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    }, onError: (error) {
      debugPrint("Error listening to user document: $error");
      _isLoading = false;
      _isInitialized = true;
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _authStateChangesSubscription?.cancel();
    _userDocSubscription?.cancel();
    super.dispose();
  }

  String? get uid => _uid;
  String? get email => _email;
  String get role => _role;
  String? get fullName => _fullName;
  String? get schoolId => _schoolId;
  String? get schoolName => _schoolName;
  String? get profilePictureUrl => _profilePictureUrl;
  bool? get isApproved => _isApproved;
  List<String>? get childIds => _childIds;

  void setUser({
    String? uid,
    String? email,
    String? role,
    String? fullName,
    String? schoolId,
    String? schoolName,
    String? profilePictureUrl,
    bool? isApproved,
    List<String>? childIds,
  }) {
    _uid = uid;
    _email = email;
    _role = role ?? _role;
    _fullName = fullName;
    _schoolId = schoolId;
    _schoolName = schoolName;
    _profilePictureUrl = profilePictureUrl;
    _isApproved = isApproved;
    _childIds = childIds;
    _isLoading = false;
    _isInitialized = true;
    notifyListeners();
  }

  void clearUser() {
    _uid = null;
    _email = null;
    _role = '';
    _fullName = null;
    _schoolId = null;
    _schoolName = null;
    _profilePictureUrl = null;
    _isApproved = null;
    _childIds = null;
    _isLoading = false;
    _isInitialized = true;
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

  void addChildId(String childId) {
    _childIds ??= [];
    if (!_childIds!.contains(childId)) {
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