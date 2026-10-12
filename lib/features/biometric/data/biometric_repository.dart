import 'package:dio/dio.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:local_auth/local_auth.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'biometric_crypto.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

/// A message that is safe to show to the user.
class BiometricException implements Exception {
  const BiometricException(this.message);

  final String message;

  @override
  String toString() => message;
}

/// Fingerprint sign-in.
///
/// Turning it on: confirm the fingerprint -> create a device key pair -> send the PUBLIC key
/// to the backend -> keep the private key (and the account email) in secure storage.
/// Signing in: confirm the fingerprint -> ask the backend for a one-time challenge ->
/// sign it with the private key -> the backend verifies the signature and returns tokens.
class BiometricRepository {
  BiometricRepository(this._client) : _dio = _client.dio;

  final ApiClient _client;
  final Dio _dio;

  final FlutterSecureStorage _storage = FlutterSecureStorage();
  final String _emailKey = 'bio_email';
  final String _privateKeyKey = 'bio_private_key';

  final LocalAuthentication _auth = LocalAuthentication();

  // ---------------------------------------------------------------------------
  // status
  // ---------------------------------------------------------------------------

  /// The phone has biometric hardware and at least one fingerprint/face is enrolled.
  Future<bool> isAvailable() async {
    if (kIsWeb) return false;

    try {
      if (!await _auth.isDeviceSupported()) return false;
      if (!await _auth.canCheckBiometrics) return false;

      final types = await _auth.getAvailableBiometrics();
      return types.isNotEmpty;
    } catch (_) {
      return false;
    }
  }

  Future<String?> enrolledEmail() => _storage.read(key: _emailKey);

  /// Fingerprint login was set up on this phone (a private key is stored).
  Future<bool> isEnabledOnDevice() async {
    final email = await _storage.read(key: _emailKey);
    final key = await _storage.read(key: _privateKeyKey);

    return email != null && email.isNotEmpty && key != null && key.isNotEmpty;
  }

  // ---------------------------------------------------------------------------
  // turn on / off (Profile > Settings)
  // ---------------------------------------------------------------------------

  Future<void> enable({required String email}) async {
    if (!await isAvailable()) {
      throw const BiometricException(
        'No fingerprint is set up on this phone. Add one in your phone settings first.',
      );
    }

    final confirmed = await _prompt(
      'Confirm your fingerprint to turn on fingerprint login',
    );

    if (!confirmed) {
      throw const BiometricException(
        'Fingerprint was not confirmed, so fingerprint login was not turned on.',
      );
    }

    final pair = biometricCrypto.generate();

    try {
      await _dio.post(
        apiConstants.biometricEnroll,
        data: {'public_key_pem': pair.publicKeyPem},
      );
    } on DioException catch (e) {
      throw BiometricException(
        _serverMessage(e, 'Could not turn on fingerprint login. Please try again.'),
      );
    }

    await _storage.write(key: _emailKey, value: email.trim().toLowerCase());
    await _storage.write(key: _privateKeyKey, value: pair.privateKeyHex);
  }

  Future<void> disable() async {
    try {
      await _dio.delete(apiConstants.biometricEnroll);
    } on DioException {
      // Even if the server cannot be reached the key on this phone is removed below,
      // so the old server key can no longer be used from here.
    }

    await clearLocal();
  }

  Future<void> clearLocal() async {
    await _storage.delete(key: _emailKey);
    await _storage.delete(key: _privateKeyKey);
  }

  // ---------------------------------------------------------------------------
  // sign in (Login screen)
  // ---------------------------------------------------------------------------

  /// Returns true when signed in, false when the user cancelled the fingerprint prompt.
  /// Throws [BiometricException] with a message to show on failure.
  Future<bool> login() async {
    final email = await _storage.read(key: _emailKey);
    final privateKey = await _storage.read(key: _privateKeyKey);

    if (email == null || privateKey == null) {
      throw const BiometricException(
        'Fingerprint login is not set up on this phone. Sign in with your password, '
        'then turn it on in Profile > Settings.',
      );
    }

    final confirmed = await _prompt('Use your fingerprint to sign in');
    if (!confirmed) return false;

    try {
      final challenge = await _dio.post(
        apiConstants.biometricChallenge,
        data: {'email': email},
      );

      final nonce = challenge.data['nonce'] as String?;

      if (nonce == null || nonce.isEmpty) {
        throw const BiometricException('Sign-in failed. Please use your password.');
      }

      final signature = biometricCrypto.sign(privateKey, nonce);

      final verify = await _dio.post(
        apiConstants.biometricVerify,
        data: {'email': email, 'nonce': nonce, 'signature': signature},
      );

      final access = verify.data['access_token'] as String?;
      final refresh = verify.data['refresh_token'] as String?;

      if (access == null || refresh == null) {
        throw const BiometricException('Sign-in failed. Please use your password.');
      }

      await _client.saveTokens(access: access, refresh: refresh);

      return true;
    } on DioException catch (e) {
      final code = _serverCode(e);

      if (code == 'BIOMETRIC_UNAVAILABLE' ||
          code == 'BIOMETRIC_BAD_SIGNATURE' ||
          code == 'BIOMETRIC_KEY') {
        // The server no longer trusts this phone's key: forget it so the button disappears.
        await clearLocal();

        throw const BiometricException(
          'Fingerprint login is no longer valid for this account. Sign in with your '
          'password and turn it on again in Profile > Settings.',
        );
      }

      throw BiometricException(
        _serverMessage(e, 'Could not sign in with your fingerprint. Please try again.'),
      );
    }
  }

  // ---------------------------------------------------------------------------
  // helpers
  // ---------------------------------------------------------------------------

  Future<bool> _prompt(String reason) async {
    try {
      return await _auth.authenticate(
        localizedReason: reason,
        options: const AuthenticationOptions(
          biometricOnly: true,
          stickyAuth: true,
        ),
      );
    } on PlatformException catch (e) {
      throw BiometricException(_platformMessage(e));
    }
  }

  String _platformMessage(PlatformException e) {
    switch (e.code) {
      case 'NotEnrolled':
        return 'No fingerprint is set up on this phone. Add one in your phone settings first.';
      case 'NotAvailable':
        return 'Fingerprint is not available on this phone.';
      case 'PasscodeNotSet':
        return 'Set a screen lock on your phone first.';
      case 'LockedOut':
        return 'Too many wrong attempts. Please wait a moment and try again.';
      case 'PermanentlyLockedOut':
        return 'Fingerprint is locked. Unlock your phone with your PIN, then try again.';
      default:
        return 'Fingerprint check failed. Please try again.';
    }
  }

  String? _serverCode(DioException e) {
    final data = e.response?.data;
    if (data is Map && data['code'] != null) return data['code'].toString();
    return null;
  }

  String _serverMessage(DioException e, String fallback) {
    final data = e.response?.data;

    if (data is Map && data['detail'] is String) {
      return data['detail'] as String;
    }

    if (e.type == DioExceptionType.connectionError ||
        e.type == DioExceptionType.connectionTimeout) {
      return 'Could not reach the server. Check your connection and try again.';
    }

    return fallback;
  }
}

final biometricRepositoryProvider = Provider<BiometricRepository>(
  (ref) => BiometricRepository(ref.read(apiClientProvider)),
);
