import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class SettingsProvider extends ChangeNotifier {
  final AuthService _authService = AuthService();
  bool _notificationsEnabled = true;
  bool _isLoading = false;
  String? _errorMessage;

  bool get notificationsEnabled => _notificationsEnabled;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  SettingsProvider() {
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final profile = await _authService.getUserProfile(user.uid);
      if (profile != null) {
        _notificationsEnabled = profile.notificationsEnabled;
        notifyListeners();
      }
    }
  }

  Future<void> toggleNotifications(bool value) async {
    _setLoading(true);

    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      final result = await _authService.updateUserProfile(user.uid, {
        'notificationsEnabled': value,
      });

      if (result['success']) {
        _notificationsEnabled = value;
      } else {
        _errorMessage = result['error'];
      }
    }

    _setLoading(false);
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
