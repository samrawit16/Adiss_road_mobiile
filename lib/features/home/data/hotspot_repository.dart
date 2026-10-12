
import 'package:dio/dio.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class UnauthorizedException implements Exception {
  const UnauthorizedException();

  @override
  String toString() => 'Session expired. Please log in again.';
}

class HotspotRepository {
  HotspotRepository(this._client)
      : _dio = _client.dio,
        _storage = const FlutterSecureStorage();

  final ApiClient _client;

  final Dio _dio;
  final FlutterSecureStorage _storage;

  Future<List<Map<String, dynamic>>> getHotspots() async {
    final token = await _storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      throw const UnauthorizedException();
    }

    try {
      final response = await _dio.get(
        '${apiConstants.baseUrl}${apiConstants.hotspots}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _parseHotspots(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return _refreshAndRetryHotspots(token);
      }

      throw _friendlyDioException(error);
    }
  }

  Future<List<Map<String, dynamic>>> _refreshAndRetryHotspots(
    String oldAccessToken,
  ) async {
    final refreshToken =
        await _storage.read(key: 'refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      await _clearTokens();
      throw const UnauthorizedException();
    }

    try {
      final response = await _dio.post(
        '${apiConstants.baseUrl}${apiConstants.refresh}',
        data: {
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        await _clearTokens();
        throw const UnauthorizedException();
      }

      final newAccessToken =
          data['access_token']?.toString();

      final newRefreshToken =
          data['refresh_token']?.toString();

      if (newAccessToken == null ||
          newAccessToken.isEmpty) {
        await _clearTokens();
        throw const UnauthorizedException();
      }

      await _storage.write(
        key: 'access_token',
        value: newAccessToken,
      );

      if (newRefreshToken != null &&
          newRefreshToken.isNotEmpty) {
        await _storage.write(
          key: 'refresh_token',
          value: newRefreshToken,
        );
      }

      final retryResponse = await _dio.get(
        '${apiConstants.baseUrl}${apiConstants.hotspots}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $newAccessToken',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _parseHotspots(retryResponse.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _clearTokens();
        throw const UnauthorizedException();
      }

      throw _friendlyDioException(error);
    }
  }

  Future<String> getFullName() async {
    final token = await _storage.read(key: 'access_token');

    if (token == null || token.isEmpty) {
      throw const UnauthorizedException();
    }

    try {
      final response = await _dio.get(
        '${apiConstants.baseUrl}${apiConstants.me}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $token',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _extractFullName(response.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        return _refreshAndRetryUser(token);
      }

      throw _friendlyDioException(error);
    }
  }

  Future<String> _refreshAndRetryUser(
    String oldAccessToken,
  ) async {
    final refreshToken =
        await _storage.read(key: 'refresh_token');

    if (refreshToken == null || refreshToken.isEmpty) {
      await _clearTokens();
      throw const UnauthorizedException();
    }

    try {
      final response = await _dio.post(
        '${apiConstants.baseUrl}${apiConstants.refresh}',
        data: {
          'refresh_token': refreshToken,
        },
        options: Options(
          headers: {
            'Content-Type': 'application/json',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      final data = response.data;

      if (data is! Map<String, dynamic>) {
        await _clearTokens();
        throw const UnauthorizedException();
      }

      final newAccessToken =
          data['access_token']?.toString();

      final newRefreshToken =
          data['refresh_token']?.toString();

      if (newAccessToken == null ||
          newAccessToken.isEmpty) {
        await _clearTokens();
        throw const UnauthorizedException();
      }

      await _storage.write(
        key: 'access_token',
        value: newAccessToken,
      );

      if (newRefreshToken != null &&
          newRefreshToken.isNotEmpty) {
        await _storage.write(
          key: 'refresh_token',
          value: newRefreshToken,
        );
      }

      final retryResponse = await _dio.get(
        '${apiConstants.baseUrl}${apiConstants.me}',
        options: Options(
          headers: {
            'Authorization': 'Bearer $newAccessToken',
            'Accept': 'application/json',
          },
          connectTimeout: const Duration(seconds: 30),
          receiveTimeout: const Duration(seconds: 30),
        ),
      );

      return _extractFullName(retryResponse.data);
    } on DioException catch (error) {
      if (error.response?.statusCode == 401) {
        await _clearTokens();
        throw const UnauthorizedException();
      }

      throw _friendlyDioException(error);
    }
  }

  List<Map<String, dynamic>> _parseHotspots(
    dynamic data,
  ) {
    if (data is! List) {
      throw Exception(
        'The server returned an unexpected hotspot response.',
      );
    }

    return data
        .whereType<Map>()
        .map(
          (item) => Map<String, dynamic>.from(item),
        )
        .toList();
  }

  String _extractFullName(dynamic data) {
    if (data is! Map) {
      return 'User';
    }

    final map = Map<String, dynamic>.from(data);

    final fullName =
        map['full_name']?.toString().trim();

    if (fullName != null && fullName.isNotEmpty) {
      return fullName;
    }

    final firstName =
        map['first_name']?.toString().trim() ?? '';

    final lastName =
        map['last_name']?.toString().trim() ?? '';

    final combined =
        '$firstName $lastName'.trim();

    if (combined.isNotEmpty) {
      return combined;
    }

    final name =
        map['name']?.toString().trim();

    if (name != null && name.isNotEmpty) {
      return name;
    }

    return 'User';
  }

  Exception _friendlyDioException(
    DioException error,
  ) {
    switch (error.type) {
      case DioExceptionType.connectionTimeout:
        return Exception(
          'Unable to connect to the server. '
          'Please check your connection and try again.',
        );

      case DioExceptionType.receiveTimeout:
        return Exception(
          'The server is taking too long to respond. '
          'Please try again.',
        );

      case DioExceptionType.sendTimeout:
        return Exception(
          'The request took too long to send. '
          'Please try again.',
        );

      case DioExceptionType.connectionError:
        return Exception(
          'Unable to reach the server. '
          'Please check that the backend is running.',
        );

      default:
        final statusCode =
            error.response?.statusCode;

        if (statusCode != null) {
          return Exception(
            'Server error ($statusCode). '
            'Please try again.',
          );
        }

        return Exception(
          'Something went wrong. Please try again.',
        );
    }
  }

  Future<void> _clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }
}

