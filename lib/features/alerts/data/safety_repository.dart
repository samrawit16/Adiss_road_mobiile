import 'dart:async';
import 'dart:typed_data';

import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'safety_model.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class SafetyRepository {
  SafetyRepository(this._client)
      : _dio = _client.dio;

  final ApiClient _client;
  final Dio _dio;

  // ============================================================
  // LIVE ROAD SAFETY - ROAD CONTEXT
  // ============================================================

  Future<SafetyContext> getContext({
    required double latitude,
    required double longitude,
    required double speedKmh,
  }) async {
    try {
      final response = await _dio
          .post(
            apiConstants.safetyContext,
            data: {
              'latitude': latitude,
              'longitude': longitude,
              'activity': 'driving',
              'speed_kmh': speedKmh,
              'phone_use': false,
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.data is! Map) {
        throw Exception(
          'Invalid road safety response from server.',
        );
      }

      return SafetyContext.fromJson(
        Map<String, dynamic>.from(
          response.data as Map,
        ),
        speedKmh,
      );
    } on DioException catch (e) {
      throw Exception(
        _dioErrorMessage(
          e,
          'Could not fetch road information',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Road information request timed out.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // RECORD UNSAFE SPEED
  // ============================================================

  /// Returns true when the backend stored the event, so the caller can retry
  /// instead of silently losing it (the police dashboard is fed by these).
  Future<bool> recordUnsafeSpeed({
    required double latitude,
    required double longitude,
    required double speedKmh,
    required double speedLimitKmh,
  }) async {
    // Up to 10 km/h over the posted limit is a warning; beyond that is unsafe.
    final eventType = (speedKmh - speedLimitKmh) > 10
        ? 'unsafe_speed'
        : 'speed_limit_warning';

    try {
      await _dio
          .post(
            apiConstants.safetyEvents,
            data: {
              'latitude': latitude,
              'longitude': longitude,
              'activity': 'driving',
              'speed_kmh': speedKmh,
              'phone_use': false,
              'event_type': eventType,
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );
      return true;
    } catch (_) {
      // The local speed warning must continue even when
      // event logging fails.
      return false;
    }
  }

  // ============================================================
  // UPLOAD REPORT EVIDENCE
  // ============================================================

  Future<String> uploadEvidence(
    Uint8List bytes,
    String filename,
  ) async {
    try {
      final form =
          FormData.fromMap({
        'file': MultipartFile.fromBytes(
          bytes,
          filename: filename,
        ),
      });

      final response = await _dio
          .post(
            apiConstants.safetyEvidence,
            data: form,
          )
          .timeout(
            const Duration(seconds: 30),
          );

      if (response.data is! Map) {
        throw Exception(
          'Invalid response from evidence upload.',
        );
      }

      final data =
          Map<String, dynamic>.from(
        response.data as Map,
      );

      final evidenceUrl =
          data['evidence_url'];

      if (evidenceUrl == null ||
          evidenceUrl.toString().isEmpty) {
        throw Exception(
          'Evidence was uploaded but no evidence URL was returned.',
        );
      }

      return evidenceUrl.toString();
    } on DioException catch (e) {
      throw Exception(
        _dioErrorMessage(
          e,
          'Could not upload the evidence',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Evidence upload timed out. Please check your connection and try again.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // SUBMIT REPORT
  // ============================================================

  Future<Map<String, dynamic>> submitReport({
    required String reportType,
    required String description,
    required String severity,
    required bool injuriesReported,
    required bool emergencyRequired,
    required double latitude,
    required double longitude,
    required double? gpsAccuracyM,
    required List<String> evidenceUrls,
    required DateTime occurredAt,
    String? roadName,
  }) async {
    try {
      final response = await _dio
          .post(
            apiConstants.accidentReports,
            data: {
              'report_type': reportType,
              'description':
                  description.isEmpty
                      ? null
                      : description,
              'severity': severity,
              'injuries_reported':
                  injuriesReported,
              'emergency_required':
                  emergencyRequired,
              'latitude': latitude,
              'longitude': longitude,
              'gps_accuracy_m':
                  gpsAccuracyM,
              // Road or place: detected from GPS, or typed by the reporter.
              'road_name':
                  (roadName == null || roadName.trim().isEmpty)
                      ? null
                      : roadName.trim(),
              'occurred_at':
                  occurredAt
                      .toUtc()
                      .toIso8601String(),
              'evidence_urls':
                  evidenceUrls,
            },
          )
          .timeout(
            const Duration(seconds: 30),
          );

      if (response.data is! Map) {
        throw Exception(
          'Invalid response from report submission.',
        );
      }

      return Map<String, dynamic>.from(
        response.data as Map,
      );
    } on DioException catch (e) {
      throw Exception(
        _dioErrorMessage(
          e,
          'Could not submit the report',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Report submission timed out. Please check your connection and try again.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // NEARBY ROAD ALERTS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      nearbyAlerts({
    required double latitude,
    required double longitude,
  }) async {
    try {
      final response = await _dio
          .get(
            apiConstants.safetyAlerts,
            queryParameters: {
              'latitude': latitude,
              'longitude': longitude,
            },
          )
          .timeout(
            const Duration(seconds: 10),
          );

      if (response.data is! List) {
        throw Exception(
          'Invalid nearby alerts response from server.',
        );
      }

      return (response.data as List)
          .map(
            (e) =>
                Map<String, dynamic>.from(
              e as Map,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _dioErrorMessage(
          e,
          'Could not fetch nearby alerts',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Nearby alerts request timed out.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // MY REPORTS
  // ============================================================

  Future<List<Map<String, dynamic>>>
      myReports() async {
    try {
      final response = await _dio
          .get(
            apiConstants.accidentReports,
          )
          .timeout(
            const Duration(seconds: 30),
          );

      if (response.data is! List) {
        throw Exception(
          'Invalid reports response from server.',
        );
      }

      return (response.data as List)
          .map(
            (e) =>
                Map<String, dynamic>.from(
              e as Map,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _dioErrorMessage(
          e,
          'Could not load your reports',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Loading reports timed out. Please try again.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // AUTHORITIES
  // ============================================================

  Future<List<Map<String, dynamic>>>
      authorities({
    required double latitude,
    required double longitude,
    String? type,
  }) async {
    try {
      final response = await _dio
          .get(
            apiConstants.safetyAuthorities,
            queryParameters: {
              'latitude': latitude,
              'longitude': longitude,
              if (type != null)
                'authority_type': type,
            },
          )
          .timeout(
            const Duration(seconds: 15),
          );

      if (response.data is! List) {
        throw Exception(
          'Invalid authorities response from server.',
        );
      }

      return (response.data as List)
          .map(
            (e) =>
                Map<String, dynamic>.from(
              e as Map,
            ),
          )
          .toList();
    } on DioException catch (e) {
      throw Exception(
        _dioErrorMessage(
          e,
          'Could not load nearby authorities',
        ),
      );
    } on TimeoutException {
      throw Exception(
        'Authorities request timed out.',
      );
    } catch (e) {
      throw Exception(
        e.toString().replaceFirst(
              'Exception: ',
              '',
            ),
      );
    }
  }

  // ============================================================
  // MEDIA URL
  // ============================================================

  String resolveMediaUrl(String path) {
    if (path.startsWith('http://') ||
        path.startsWith('https://')) {
      return path;
    }

    final base =
        apiConstants.baseUrl.replaceFirst(
      '/api/v1',
      '',
    );

    return '$base$path';
  }

  // ============================================================
  // DIO ERROR MESSAGE
  // ============================================================

  String _dioErrorMessage(
    DioException error,
    String defaultMessage,
  ) {
    // ----------------------------------------------------------
    // Server returned an HTTP response
    // ----------------------------------------------------------

    if (error.response != null) {
      final statusCode =
          error.response?.statusCode;

      final data =
          error.response?.data;

      if (data is Map) {
        final detail =
            data['detail'];

        if (detail != null &&
            detail.toString().isNotEmpty) {
          return '$defaultMessage: ${detail.toString()}';
        }

        final message =
            data['message'];

        if (message != null &&
            message.toString().isNotEmpty) {
          return '$defaultMessage: ${message.toString()}';
        }
      }

      return '$defaultMessage (HTTP $statusCode).';
    }

    // ----------------------------------------------------------
    // Connection timeout
    // ----------------------------------------------------------

    if (error.type ==
            DioExceptionType.connectionTimeout ||
        error.type ==
            DioExceptionType.receiveTimeout ||
        error.type ==
            DioExceptionType.sendTimeout) {
      return '$defaultMessage: connection timed out.';
    }

    // ----------------------------------------------------------
    // Cannot connect to backend
    // ----------------------------------------------------------

    if (error.type ==
        DioExceptionType.connectionError) {
      return '$defaultMessage: cannot connect to the server.';
    }

    return '$defaultMessage.';
  }
}

// ================================================================
// PROVIDER
// ================================================================

final safetyRepositoryProvider =
    Provider<SafetyRepository>(
  (ref) {
    return SafetyRepository(
      ref.read(apiClientProvider),
    );
  },
);