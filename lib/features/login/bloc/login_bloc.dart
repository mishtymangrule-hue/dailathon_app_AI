import 'package:equatable/equatable.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:timber/timber.dart';

part 'login_event.dart';
part 'login_state.dart';

/// LoginBloc manages user authentication and session persistence.
/// Session tokens are stored securely using FlutterSecureStorage.
class LoginBloc extends Bloc<LoginEvent, LoginState> {

  LoginBloc() : super(const LoginInitial()) {
    on<LoginSubmitted>(_onLoginSubmitted);
    on<LogoutRequested>(_onLogoutRequested);
    on<SessionRestored>(_onSessionRestored);
  }
  static const String _tokenKey = 'session_token';
  static const String _userKey = 'session_user';

  final _secureStorage = const FlutterSecureStorage(
    aOptions: AndroidOptions(
      keyCipherAlgorithm: KeyCipherAlgorithm.RSA_ECB_OAEPwithSHA_256andMGF1Padding,
      storageCipherAlgorithm: StorageCipherAlgorithm.AES_GCM_NoPadding,
      encryptedSharedPreferences: true,  // API 23+ only
    ),
  );

  Future<void> _onLoginSubmitted(
    LoginSubmitted event,
    Emitter<LoginState> emit,
  ) async {
    emit(const LoginLoading());

    try {
      // TODO: Call authentication API with event.username and event.password
      // For demo, accept any non-empty credentials
      if (event.username.isNotEmpty && event.password.isNotEmpty) {
        // Mock token response from API
        const token = 'demo_token_123_${DateTime.now}';
        
        // Persist session token securely
        await _persistSession(token, event.username);
        
        emit(LoginSuccess(token: token, username: event.username));
      } else {
        emit(const LoginFailure(error: 'Invalid credentials'));
      }
    } catch (e) {
      Timber.e('Login failed: $e');
      emit(LoginFailure(error: e.toString()));
    }
  }

  Future<void> _onLogoutRequested(
    LogoutRequested event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // Clear stored session token
      await _clearSession();
      emit(const LoginInitial());
    } catch (e) {
      Timber.e('Logout failed: $e');
      emit(LoginFailure(error: 'Logout failed: $e'));
    }
  }

  Future<void> _onSessionRestored(
    SessionRestored event,
    Emitter<LoginState> emit,
  ) async {
    try {
      // Try to restore session from secure storage
      final storedToken = await _getStoredToken();
      final storedUser = await _getStoredUser();

      if (storedToken != null && storedToken.isNotEmpty) {
        // TODO: Validate token with backend (check expiration, etc.)
        emit(LoginSuccess(token: storedToken, username: storedUser ?? 'User'));
        Timber.d('Session restored from secure storage');
      } else {
        emit(const LoginInitial());
      }
    } catch (e) {
      Timber.e('Session restore failed: $e');
      emit(const LoginInitial());
    }
  }

  /// Persist session token securely using FlutterSecureStorage.
  /// Never store tokens in plain SharedPreferences!
  Future<void> _persistSession(String token, String username) async {
    try {
      await _secureStorage.write(key: _tokenKey, value: token);
      await _secureStorage.write(key: _userKey, value: username);
      Timber.v('Session token persisted securely');
    } catch (e) {
      Timber.e('Error persisting session: $e');
      rethrow;
    }
  }

  /// Retrieve stored session token from secure storage.
  Future<String?> _getStoredToken() async {
    try {
      return await _secureStorage.read(key: _tokenKey);
    } catch (e) {
      Timber.e('Error retrieving stored token: $e');
      return null;
    }
  }

  /// Retrieve stored username from secure storage.
  Future<String?> _getStoredUser() async {
    try {
      return await _secureStorage.read(key: _userKey);
    } catch (e) {
      Timber.e('Error retrieving stored user: $e');
      return null;
    }
  }

  /// Clear stored session token and user data.
  Future<void> _clearSession() async {
    try {
      await _secureStorage.delete(key: _tokenKey);
      await _secureStorage.delete(key: _userKey);
      Timber.v('Session cleared from secure storage');
    } catch (e) {
      Timber.e('Error clearing session: $e');
      rethrow;
    }
  }

  /// Public method to manually clear session (useful for logout)
  Future<void> clearSession() async => _clearSession();
}
