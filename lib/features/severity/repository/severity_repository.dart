import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../../../core/constants/api_constants.dart';
import '../data/severity_prediction_model.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class SeverityRepository {
  SeverityRepository(this._client) : _dio = _client.dio;

  final ApiClient _client;
  final Dio _dio;

  Future<SeverityPrediction> predictSeverity({
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
    try {
      final response = await _dio.post(
        '${apiConstants.baseUrl}${apiConstants.severityPredict}',
        data: {
          'Date': date,
          'Time': time,
          'Day_of_week': dayOfWeek,
          'Area_accident_occured': subCity,
          'Age_band_of_driver': ageBandOfDriver,
          'Sex_of_driver': sexOfDriver,
          'Educational_level': educationalLevel,
          'Vehicle_driver_relation': vehicleDriverRelation,
          'Driving_experience': drivingExperience,
          'Type_of_vehicle': typeOfVehicle,
          'Owner_of_vehicle': ownerOfVehicle,
          'Service_year_of_vehicle': serviceYearOfVehicle,
          'Defect_of_vehicle': defectOfVehicle,
          'Lanes_or_Medians': lanesOrMedians,
          'Road_allignment': roadAllignment,
          'Types_of_Junction': typesOfJunction,
          'Road_surface_type': roadSurfaceType,
          'Road_surface_conditions': roadSurfaceConditions,
          'Light_conditions': lightConditions,
          'Type_of_collision': typeOfCollision,
          'Vehicle_movement': vehicleMovement,
          'Casualty_type': casualtyType,
          'Hour': hour,
          'Minute': minute,
          'Time_period': timePeriod,
        },
      );

      if (response.data is! Map<String, dynamic>) {
        throw Exception('The severity service returned an invalid response.');
      }

      return SeverityPrediction.fromJson(
        Map<String, dynamic>.from(response.data as Map),
      );
    } on DioException catch (e) {
      final data = e.response?.data;
      final detail = data is Map ? data['detail'] : null;
      throw Exception(
        detail?.toString() ?? e.message ?? 'Failed to predict accident severity.',
      );
    }
  }
}

final severityRepositoryProvider = Provider<SeverityRepository>((ref) {
  return SeverityRepository(ref.read(apiClientProvider));
});
