import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/severity_prediction_model.dart';
import '../repository/severity_repository.dart';

class SeverityState {
  const SeverityState({
    this.isLoading = false,
    this.prediction,
    this.error,
  });

  final bool isLoading;
  final SeverityPrediction? prediction;
  final String? error;

  SeverityState copyWith({
    bool? isLoading,
    SeverityPrediction? prediction,
    String? error,
    bool clearPrediction = false,
    bool clearError = false,
  }) {
    return SeverityState(
      isLoading: isLoading ?? this.isLoading,
      prediction: clearPrediction ? null : prediction ?? this.prediction,
      error: clearError ? null : error ?? this.error,
    );
  }
}

class SeverityViewModel extends StateNotifier<SeverityState> {
  SeverityViewModel(this._repository) : super(const SeverityState());

  final SeverityRepository _repository;

  Future<void> predictSeverity({
    required String date,
    required String time,
    required String dayOfWeek,
    required String subCity,
    required String ageBandOfDriver,
    required String sexOfDriver,
    required String educationalLevel,
    required String vehicleDriverRelation,
    required String drivingExperience,
    required String typeOfVehicle,
    required String ownerOfVehicle,
    required String serviceYearOfVehicle,
    required String defectOfVehicle,
    required String lanesOrMedians,
    required String roadAllignment,
    required String typesOfJunction,
    required String roadSurfaceType,
    required String roadSurfaceConditions,
    required String lightConditions,
    required String typeOfCollision,
    required String vehicleMovement,
    required String casualtyType,
    required int hour,
    required int minute,
    required String timePeriod,
  }) async {
    state = state.copyWith(isLoading: true, clearError: true);

    try {
      final result = await _repository.predictSeverity(
        date: date,
        time: time,
        dayOfWeek: dayOfWeek,
        subCity: subCity,
        ageBandOfDriver: ageBandOfDriver,
        sexOfDriver: sexOfDriver,
        educationalLevel: educationalLevel,
        vehicleDriverRelation: vehicleDriverRelation,
        drivingExperience: drivingExperience,
        typeOfVehicle: typeOfVehicle,
        ownerOfVehicle: ownerOfVehicle,
        serviceYearOfVehicle: serviceYearOfVehicle,
        defectOfVehicle: defectOfVehicle,
        lanesOrMedians: lanesOrMedians,
        roadAllignment: roadAllignment,
        typesOfJunction: typesOfJunction,
        roadSurfaceType: roadSurfaceType,
        roadSurfaceConditions: roadSurfaceConditions,
        lightConditions: lightConditions,
        typeOfCollision: typeOfCollision,
        vehicleMovement: vehicleMovement,
        casualtyType: casualtyType,
        hour: hour,
        minute: minute,
        timePeriod: timePeriod,
      );

      state = SeverityState(isLoading: false, prediction: result);
    } catch (e) {
      state = SeverityState(isLoading: false, error: e.toString());
    }
  }

  void clear() => state = const SeverityState();
}

// severityRepositoryProvider lives in severity_repository.dart

final severityViewModelProvider =
    StateNotifierProvider<SeverityViewModel, SeverityState>((ref) {
  return SeverityViewModel(ref.read(severityRepositoryProvider));
});
