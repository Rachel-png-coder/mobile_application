import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';
import '../models/user_model.dart';

class AuthProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  User? _user;
  UserModel? _userProfile;
  bool _isLoading = false;
  String? _errorMessage;

  User? get user => _user;
  UserModel? get userProfile => _userProfile;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;
  bool get isEmailVerified => _user?.emailVerified ?? false;

  AuthProvider() {
    _authService.authStateChanges.listen((User? user) {
      _user = user;
      if (user != null) {
        _loadUserProfile(user.uid);
      } else {
        _userProfile = null;
      }
      notifyListeners();
    });
  }

  Future<void> _loadUserProfile(String uid) async {
    _userProfile = await _authService.getUserProfile(uid);
    notifyListeners();
  }

  Future<bool> signUp({
    required String email,
    required String password,
    String? displayName,
  }) async {
    _setLoading(true);

    final result = await _authService.signUp(
      email: email,
      password: password,
      displayName: displayName,
    );

    _setLoading(false);

    if (!result['success']) {
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<bool> signIn({required String email, required String password}) async {
    _setLoading(true);

    final result = await _authService.signIn(email: email, password: password);

    _setLoading(false);

    if (!result['success']) {
      _errorMessage = result['error'];
      notifyListeners();
      return false;
    }

    return true;
  }

  Future<void> signOut() async {
    _setLoading(true);
    await _authService.signOut();
    _setLoading(false);
  }

  Future<bool> checkEmailVerification() async {
    bool verified = await _authService.isEmailVerified();
    if (verified && _user != null) {
      await _user?.reload();
      _user = _authService.currentUser;
      notifyListeners();
    }
    return verified;
  }

  Future<void> sendVerificationEmail() async {
    await _authService.sendVerificationEmail();
  }

  void _setLoading(bool loading) {
    _isLoading = loading;
    if (loading) {
      _errorMessage = null;
    }
    notifyListeners();
  }

  void clearError() {
    _errorMessage = null;
    notifyListeners();
  }
}
