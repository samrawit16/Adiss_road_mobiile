
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class AuthRepository {
  AuthRepository(this._client) : _dio = _client.dio;

  final ApiClient _client;
  final Dio _dio;

  /// True when a stored access token exists.
  Future<bool> isLoggedIn() => _client.hasSession;

  Future<void> register({
    required String fullName,
    required String email,
    required String phone,
    required String password,
  }) async {
    try {
      await _dio.post(
        apiConstants.register,
        data: {
          'full_name': fullName.trim(),
          'email': email.trim().toLowerCase(),
          'phone': phone.trim(),
          'password': password,
        },
      );
    } on DioException catch (e) {
      // Show the actual FastAPI validation/error message.
      if (e.response != null) {
        final data = e.response!.data;

        if (data is Map && data['detail'] != null) {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: data['detail'].toString(),
            type: e.type,
          );
        }
      }

      rethrow;
    }
  }

  Future<void> verifyOtp({
    required String email,
    required String code,
  }) async {
    try {
      await _dio.post(
        apiConstants.verifyOtp,
        data: {
          'email': email.trim().toLowerCase(),
          'otp_code': code.trim(),
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;

        if (data is Map && data['detail'] != null) {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: data['detail'].toString(),
            type: e.type,
          );
        }
      }

      rethrow;
    }
  }

  Future<void> resendOtp({
    required String email,
  }) async {
    try {
      await _dio.post(
        apiConstants.resendOtp,
        data: {
          'email': email.trim().toLowerCase(),
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;

        if (data is Map && data['detail'] != null) {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: data['detail'].toString(),
            type: e.type,
          );
        }
      }

      rethrow;
    }
  }

  Future<void> login({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _dio.post(
        apiConstants.login,
        data: {
          'email': email.trim().toLowerCase(),
          'password': password,
        },
      );

      final accessToken = response.data['access_token'] as String?;
      final refreshToken = response.data['refresh_token'] as String?;

      if (accessToken == null || refreshToken == null) {
        throw Exception('Login response did not contain valid tokens.');
      }

      await _client.saveTokens(
        access: accessToken,
        refresh: refreshToken,
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;

        if (data is Map && data['detail'] != null) {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: data['detail'].toString(),
            type: e.type,
          );
        }
      }

      rethrow;
    }
  }

  Future<void> forgotPassword(String email) async {
    try {
      await _dio.post(
        apiConstants.forgotPassword,
        data: {
          'email': email.trim().toLowerCase(),
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;

        if (data is Map && data['detail'] != null) {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: data['detail'].toString(),
            type: e.type,
          );
        }
      }

      rethrow;
    }
  }

  Future<void> resetPassword({
    required String email,
    required String resetCode,
    required String newPassword,
  }) async {
    try {
      await _dio.post(
        apiConstants.resetPassword,
        data: {
          'email': email.trim().toLowerCase(),
          'token': resetCode.trim(),
          'new_password': newPassword,
        },
      );
    } on DioException catch (e) {
      if (e.response != null) {
        final data = e.response!.data;

        if (data is Map && data['detail'] != null) {
          throw DioException(
            requestOptions: e.requestOptions,
            response: e.response,
            error: data['detail'].toString(),
            type: e.type,
          );
        }
      }

      rethrow;
    }
  }

  Future<void> logout() async {
    final refreshToken = await _client.refreshToken;

    try {
      if (refreshToken != null && refreshToken.isNotEmpty) {
        await _dio.post(
          '/auth/logout',
          data: {
            'refresh_token': refreshToken,
          },
        );
      }
    } catch (_) {
      // Logging out must always succeed locally, even when offline or when the
      // server cannot be reached; the tokens are discarded below regardless.
    } finally {
      await _client.clearTokens();
    }
  }
}

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  return AuthRepository(ref.read(apiClientProvider));
});
