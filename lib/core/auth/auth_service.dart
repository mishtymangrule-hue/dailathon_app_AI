import 'package:flutter/foundation.dart';

/// Simple in-memory auth service.
/// Replace with real JWT / OAuth logic when ready.
class AuthService extends ChangeNotifier {
  AuthService._();

  static final AuthService instance = AuthService._();

  bool _loggedIn = false;
  String _displayName = '';
  String _role = '';
  bool _loading = false;

  bool get isLoggedIn => _loggedIn;
  String get displayName => _displayName;
  String get role => _role;
  bool get loading => _loading;

  /// Dummy login — always succeeds after a short delay.
  Future<void> login({
    required String username,
    required String password,
  }) async {
    _loading = true;
    notifyListeners();
    await Future<void>.delayed(const Duration(milliseconds: 900));
    _loggedIn = true;
    _displayName = 'Rahul Sharma';
    _role = 'CRM Executive';
    _loading = false;
    notifyListeners();
  }

  void logout() {
    _loggedIn = false;
    _displayName = '';
    _role = '';
    notifyListeners();
  }
}
