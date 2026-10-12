import 'dart:async';
import 'dart:typed_data';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../alerts/data/safety_repository.dart';

class ReportSubmitState {
  const ReportSubmitState({
    this.isSubmitting = false,
    this.error,
    this.submitted = false,
  });

  final bool isSubmitting;
  final String? error;
  final bool submitted;

  ReportSubmitState copyWith({
    bool? isSubmitting,
    String? error,
    bool clearError = false,
    bool? submitted,
  }) {
    return ReportSubmitState(
      isSubmitting: isSubmitting ?? this.isSubmitting,
      error: clearError ? null : (error ?? this.error),
      submitted: submitted ?? this.submitted,
    );
  }
}

class ReportViewModel extends StateNotifier<ReportSubmitState> {
  ReportViewModel(this._repository)
      : super(const ReportSubmitState());

  final SafetyRepository _repository;

  Future<void> submit({
    required String reportType,
    required String description,
    required String severity,
    required bool injuriesReported,
    required bool emergencyRequired,
    required double latitude,
    required double longitude,
    required double gpsAccuracyM,
    String? roadName,
    Uint8List? imageBytes,
    String? imageName,
    required DateTime occurredAt,
  }) async {
    state = state.copyWith(
      isSubmitting: true,
      submitted: false,
      clearError: true,
    );

    try {
      final evidence = <String>[];

      // ----------------------------------------------------------
      // Upload evidence if the user selected a photo
      // ----------------------------------------------------------

      if (imageBytes != null && imageName != null) {
        final evidenceUrl = await _repository
            .uploadEvidence(
              imageBytes,
              imageName,
            )
            .timeout(
              const Duration(seconds: 30),
              onTimeout: () {
                throw TimeoutException(
                  'Photo upload timed out. Please try again.',
                );
              },
            );

        evidence.add(evidenceUrl);
      }

      // ----------------------------------------------------------
      // Submit report to backend
      // ----------------------------------------------------------

      await _repository
          .submitReport(
            reportType: reportType,
            description: description,
            severity: severity,
            injuriesReported: injuriesReported,
            emergencyRequired: emergencyRequired,
            latitude: latitude,
            longitude: longitude,
            gpsAccuracyM: gpsAccuracyM,
            roadName: roadName,
            evidenceUrls: evidence,
            occurredAt: occurredAt,
          )
          .timeout(
            const Duration(seconds: 30),
            onTimeout: () {
              throw TimeoutException(
                'Report submission timed out. '
                'Please check your connection and try again.',
              );
            },
          );

      // ----------------------------------------------------------
      // SUCCESS
      // ----------------------------------------------------------

      state = state.copyWith(
        isSubmitting: false,
        submitted: true,
        clearError: true,
      );
    } catch (e) {
      String message;

      if (e is TimeoutException) {
        message = e.message ??
            'The request timed out. Please try again.';
      } else {
        message = e
            .toString()
            .replaceFirst('Exception: ', '');
      }

      state = state.copyWith(
        isSubmitting: false,
        submitted: false,
        error: message,
      );
    }
  }

  void clearState() {
    state = const ReportSubmitState();
  }
}

final reportViewModelProvider =
    StateNotifierProvider<ReportViewModel, ReportSubmitState>(
  (ref) {
    return ReportViewModel(
      ref.read(safetyRepositoryProvider),
    );
  },
);