import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../severity/repository/severity_repository.dart';
import '../../severity/data/severity_prediction_model.dart';

class RiskPredictionState {
  const RiskPredictionState({this.isLoading = false, this.error, this.result});

  final bool isLoading;
  final String? error;
  final SeverityPrediction? result;

  RiskPredictionState copyWith({
    bool? isLoading,
    String? error,
    SeverityPrediction? result,
  }) {
    return RiskPredictionState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      result: result ?? this.result,
    );
  }
}

class RiskMapViewModel extends StateNotifier<RiskPredictionState> {
  RiskMapViewModel(this._repository) : super(const RiskPredictionState());

  final SeverityRepository _repository;

  Future<void> predict({
    required Map<String, String> inputs,
  }) async {
    state = state.copyWith(isLoading: true, error: null, result: null);
    try {
      final result = await _repository.predictSeverity(
        date: inputs['date']!,
        time: inputs['time']!,
        dayOfWeek: inputs['dayOfWeek']!,
        subCity: inputs['subCity']!,
        ageBandOfDriver: inputs['ageBandOfDriver']!,
        sexOfDriver: inputs['sexOfDriver']!,
        educationalLevel: inputs['educationalLevel']!,
        vehicleDriverRelation: inputs['vehicleDriverRelation']!,
        drivingExperience: inputs['drivingExperience']!,
        typeOfVehicle: inputs['typeOfVehicle']!,
        ownerOfVehicle: inputs['ownerOfVehicle']!,
        serviceYearOfVehicle: inputs['serviceYearOfVehicle']!,
        defectOfVehicle: inputs['defectOfVehicle']!,
        lanesOrMedians: inputs['lanesOrMedians']!,
        roadAllignment: inputs['roadAllignment']!,
        typesOfJunction: inputs['typesOfJunction']!,
        roadSurfaceType: inputs['roadSurfaceType']!,
        roadSurfaceConditions: inputs['roadSurfaceConditions']!,
        lightConditions: inputs['lightConditions']!,
        typeOfCollision: inputs['typeOfCollision']!,
        vehicleMovement: inputs['vehicleMovement']!,
        casualtyType: inputs['casualtyType']!,
        hour: int.parse(inputs['hour']!),
        minute: int.parse(inputs['minute']!),
        timePeriod: inputs['timePeriod']!,
      );
      state = state.copyWith(isLoading: false, result: result);
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
    }
  }
}

final riskMapViewModelProvider =
    StateNotifierProvider<RiskMapViewModel, RiskPredictionState>((ref) {
  return RiskMapViewModel(ref.read(severityRepositoryProvider));
});
