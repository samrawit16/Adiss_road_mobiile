import 'dart:typed_data';
import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/models/user.dart';
import '../../../core/network/api_client.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class ProfileRepository {
  ProfileRepository(this._client) : _dio = _client.dio;
  final ApiClient _client;
  final Dio _dio;

  Future<User> getMe() async {
    final response = await _dio.get(apiConstants.profile);
    return User.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<User> updateMe({required String fullName, required String phone}) async {
    final response = await _dio.patch(apiConstants.profile, data: {
      'full_name': fullName.trim(),
      'phone': phone.trim(),
    });
    return User.fromJson(Map<String, dynamic>.from(response.data as Map));
  }

  Future<String> uploadProfileImage(Uint8List bytes, String filename) async {
    final response = await _dio.post(
      apiConstants.profileImage,
      data: FormData.fromMap({
        'file': MultipartFile.fromBytes(bytes, filename: filename),
      }),
    );
    return response.data['profile_image_url'].toString();
  }
}

final profileRepositoryProvider = Provider<ProfileRepository>((ref) => ProfileRepository(ref.read(apiClientProvider)));
