import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../alerts/data/safety_repository.dart';

class PoliceState {
  const PoliceState({
    this.isLoading = false,
    this.error,
    this.reports = const [],
    this.authorities = const [],
  });

  final bool isLoading;
  final String? error;
  final List<Map<String, dynamic>> reports;
  final List<Map<String, dynamic>> authorities;

  PoliceState copyWith({
    bool? isLoading,
    String? error,
    List<Map<String, dynamic>>? reports,
    List<Map<String, dynamic>>? authorities,
  }) {
    return PoliceState(
      isLoading: isLoading ?? this.isLoading,
      error: error,
      reports: reports ?? this.reports,
      authorities: authorities ?? this.authorities,
    );
  }
}

class PoliceViewModel extends StateNotifier<PoliceState> {
  PoliceViewModel(this._repository) : super(const PoliceState());

  final SafetyRepository _repository;

  Future<List<Map<String, dynamic>>> loadMyReports() async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final reports = await _repository.myReports();
      state = state.copyWith(isLoading: false, reports: reports);
      return reports;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString().replaceFirst('Exception: ', ''),
      );
      rethrow;
    }
  }

  Future<List<Map<String, dynamic>>> loadAuthorities({
    required double latitude,
    required double longitude,
  }) async {
    return _repository.authorities(latitude: latitude, longitude: longitude);
  }
}

final policeViewModelProvider =
    StateNotifierProvider<PoliceViewModel, PoliceState>((ref) {
  return PoliceViewModel(ref.read(safetyRepositoryProvider));
});
