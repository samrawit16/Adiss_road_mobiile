import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

import '../constants/api_constants.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

/// Central dio client: attaches JWT, persists tokens,
/// auto-refreshes once on 401.
///
/// No statics — an instance is provided through Riverpod
/// (see [apiClientProvider]) and injected into repositories.
class ApiClient {
  ApiClient({FlutterSecureStorage? storage})
      : _storage = storage ??
            const FlutterSecureStorage(
              aOptions: AndroidOptions(
                encryptedSharedPreferences: true,
              ),
            );

  final FlutterSecureStorage _storage;

  late final Dio dio = Dio(
    BaseOptions(
      baseUrl: apiConstants.baseUrl,
      connectTimeout: const Duration(seconds: 30),
      receiveTimeout: const Duration(seconds: 30),
      sendTimeout: const Duration(seconds: 30),
      headers: {
        'Content-Type': 'application/json',
        'Accept': 'application/json',
      },
    ),
  )..interceptors.add(_authInterceptor());

  Future<String?> get accessToken => _storage.read(key: 'access_token');

  Future<String?> get refreshToken => _storage.read(key: 'refresh_token');

  Future<void> saveTokens({
    required String access,
    required String refresh,
  }) async {
    await _storage.write(key: 'access_token', value: access);
    await _storage.write(key: 'refresh_token', value: refresh);
  }

  Future<void> clearTokens() async {
    await _storage.delete(key: 'access_token');
    await _storage.delete(key: 'refresh_token');
  }

  Future<bool> get hasSession async {
    final token = await accessToken;
    return token != null && token.isNotEmpty;
  }

  Interceptor _authInterceptor() {
    return InterceptorsWrapper(
      onRequest: (options, handler) async {
        final token = await accessToken;

        if (token != null && token.isNotEmpty) {
          options.headers['Authorization'] = 'Bearer $token';
        }

        handler.next(options);
      },
      onError: (error, handler) async {
        if (error.response?.statusCode != 401) {
          handler.next(error);
          return;
        }

        final request = error.requestOptions;

        if (request.extra['retried_after_refresh'] == true) {
          handler.next(error);
          return;
        }

        final refresh = await refreshToken;

        if (refresh == null || refresh.isEmpty) {
          await clearTokens();
          handler.next(error);
          return;
        }

        try {
          final refreshDio = Dio(
            BaseOptions(
              baseUrl: apiConstants.baseUrl,
              connectTimeout: const Duration(seconds: 30),
              receiveTimeout: const Duration(seconds: 30),
              sendTimeout: const Duration(seconds: 30),
              headers: {
                'Content-Type': 'application/json',
                'Accept': 'application/json',
              },
            ),
          );

          final response = await refreshDio.post(
            apiConstants.refresh,
            data: {'refresh_token': refresh},
          );

          final newAccessToken =
              response.data['access_token'] as String?;
          final newRefreshToken =
              response.data['refresh_token'] as String?;

          if (newAccessToken == null ||
              newAccessToken.isEmpty ||
              newRefreshToken == null ||
              newRefreshToken.isEmpty) {
            await clearTokens();
            handler.next(error);
            return;
          }

          await saveTokens(
            access: newAccessToken,
            refresh: newRefreshToken,
          );

          request.extra['retried_after_refresh'] = true;
          request.headers['Authorization'] =
              'Bearer $newAccessToken';

          handler.resolve(await dio.fetch(request));
        } catch (_) {
          await clearTokens();
          handler.next(error);
        }
      },
    );
  }
}

final apiClientProvider = Provider<ApiClient>((ref) => ApiClient());
