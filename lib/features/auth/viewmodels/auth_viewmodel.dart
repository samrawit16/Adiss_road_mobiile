import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../repositories/auth_repository.dart';

/// True while a stored session token exists.
final sessionProvider = FutureProvider<bool>((ref) async {
  return ref.read(authRepositoryProvider).isLoggedIn();
});

enum AuthStatus { idle, loading, success, error }

class AuthState {
  final AuthStatus status;
  final String? error;

  const AuthState({this.status = AuthStatus.idle, this.error});
}

String _errorMessage(Object e, String fallback) {
  if (e is DioException) {
    final data = e.response?.data;
    if (data is Map && data['detail'] != null) {
      final detail = data['detail'];
      if (detail is List && detail.isNotEmpty) {
        final first = detail.first;
        if (first is Map && first['msg'] != null) return first['msg'].toString();
        return detail.first.toString();
      }
      return detail.toString();
    }
    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection and try again.';
    }
    return fallback;
  }
  return fallback;
}

class AuthViewModel extends StateNotifier<AuthState> {
  AuthViewModel(this._repo) : super(const AuthState());

  final AuthRepository _repo;

  Future<bool> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.register(
          fullName: fullName, email: email, phone: phone, password: password);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _errorMessage(e, 'Registration failed'));
      return false;
    }
  }

  Future<bool> verifyOtp(String email, String code) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.verifyOtp(email: email, code: code);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _errorMessage(e, 'Invalid code'));
      return false;
    }
  }

  Future<bool> resendOtp(String email) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.resendOtp(email: email);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _errorMessage(e, 'Could not resend code'));
      return false;
    }
  }

  Future<bool> login(String email, String password) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.login(email: email, password: password);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _errorMessage(e, 'Login failed'));
      return false;
    }
  }

  Future<bool> forgotPassword(String email) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.forgotPassword(email);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _errorMessage(e, 'Could not send reset code'));
      return false;
    }
  }

  Future<bool> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    state = const AuthState(status: AuthStatus.loading);
    try {
      await _repo.resetPassword(email: email, resetCode: resetCode, newPassword: newPassword);
      state = const AuthState(status: AuthStatus.success);
      return true;
    } catch (e) {
      state = AuthState(status: AuthStatus.error, error: _errorMessage(e, 'Could not reset password'));
      return false;
    }
  }

  Future<void> logout() async {
    await _repo.logout();
    state = const AuthState();
  }

  void reset() => state = const AuthState();
}

final authViewModelProvider =
    StateNotifierProvider<AuthViewModel, AuthState>((ref) =>
        AuthViewModel(ref.read(authRepositoryProvider)));