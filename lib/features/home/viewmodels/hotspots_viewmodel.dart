import 'dart:math';

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/network/api_client.dart';
import '../data/hotspot_repository.dart';

enum HotspotsStatus {
  loading,
  loaded,
  error,
}

enum HotspotFilter {
  all,
  highRisk,
  fatalOnly,
  byArea,
}

class HotspotsState {
  const HotspotsState({
    this.status = HotspotsStatus.loading,
    this.list = const [],
    this.filteredList = const [],
    this.searchQuery = '',
    this.filter = HotspotFilter.all,
    this.errorMessage,
    this.fullName = 'User',
  });

  final HotspotsStatus status;
  final List<Hotspot> list;
  final List<Hotspot> filteredList;
  final String searchQuery;
  final HotspotFilter filter;
  final String? errorMessage;
  final String fullName;

  HotspotsState copyWith({
    HotspotsStatus? status,
    List<Hotspot>? list,
    List<Hotspot>? filteredList,
    String? searchQuery,
    HotspotFilter? filter,
    String? errorMessage,
    bool clearError = false,
    String? fullName,
  }) {
    return HotspotsState(
      status: status ?? this.status,
      list: list ?? this.list,
      filteredList: filteredList ?? this.filteredList,
      searchQuery: searchQuery ?? this.searchQuery,
      filter: filter ?? this.filter,
      errorMessage:
          clearError ? null : errorMessage ?? this.errorMessage,
      fullName: fullName ?? this.fullName,
    );
  }
}

class Hotspot {
  const Hotspot({
    required this.id,
    required this.area,
    required this.junctionType,
    required this.accidents,
    required this.fatalities,
    required this.serious,
    required this.slight,
    required this.riskScore,
    required this.peakHour,
  });

  final int id;
  final String area;
  final String junctionType;
  final int accidents;
  final int fatalities;
  final int serious;
  final int slight;
  final double riskScore;
  final int peakHour;

  factory Hotspot.fromJson(Map<String, dynamic> json) {
    return Hotspot(
      id: _hotspotToInt(json['id']),
      area: json['area']?.toString() ?? 'Unknown area',
      junctionType: json['junction_type']?.toString() ?? 'Unknown',
      accidents: _hotspotToInt(json['accidents'] ?? json['accident_count']),
      fatalities: _hotspotToInt(json['fatalities'] ?? json['fatal_count']),
      serious: _hotspotToInt(json['serious_count'] ?? json['serious']),
      slight: _hotspotToInt(json['slight_count'] ?? json['injuries'] ?? json['slight']),
      riskScore: _hotspotToDouble(json['risk_score']),
      peakHour: _hotspotToInt(json['peak_hour']),
    );
  }
}

int _hotspotToInt(dynamic value) {
  if (value is int) {
    return value;
  }

  if (value is num) {
    return value.toInt();
  }

  return int.tryParse(value?.toString() ?? '') ?? 0;
}

double _hotspotToDouble(dynamic value) {
  if (value is double) {
    return value;
  }

  if (value is num) {
    return value.toDouble();
  }

  return double.tryParse(value?.toString() ?? '') ?? 0;
}

final hotspotRepositoryProvider = Provider<HotspotRepository>((ref) {
  return HotspotRepository(ref.read(apiClientProvider));
});

final hotspotsViewModelProvider =
    StateNotifierProvider<HotspotsViewModel, HotspotsState>((ref) {
  return HotspotsViewModel(
    ref.read(hotspotRepositoryProvider),
  );
});

class HotspotsViewModel extends StateNotifier<HotspotsState> {
  HotspotsViewModel(this._repository)
      : super(const HotspotsState());

  final HotspotRepository _repository;

  Future<void> loadHotspots() async {
    state = state.copyWith(
      status: HotspotsStatus.loading,
      clearError: true,
    );

    try {
      final rawHotspots = await _repository.getHotspots();

      final hotspots = rawHotspots
          .map(Hotspot.fromJson)
          .toList();

      hotspots.sort(
        (a, b) => b.riskScore.compareTo(a.riskScore),
      );

      String fullName = state.fullName;

      try {
        fullName = await _repository.getFullName();
      } on UnauthorizedException {
        rethrow;
      } catch (_) {
        fullName = state.fullName;
      }

      final filtered = _applyCurrentFilters(
        hotspots,
        state.searchQuery,
        state.filter,
      );

      state = state.copyWith(
        status: HotspotsStatus.loaded,
        list: hotspots,
        filteredList: filtered,
        fullName: fullName,
        clearError: true,
      );
    } on UnauthorizedException {
      state = state.copyWith(
        status: HotspotsStatus.error,
        errorMessage:
            'Your session has expired. Please log in again.',
      );
    } catch (error) {
      state = state.copyWith(
        status: HotspotsStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  Future<void> refresh() async {
    try {
      final rawHotspots = await _repository.getHotspots();

      final hotspots = rawHotspots
          .map(Hotspot.fromJson)
          .toList();

      hotspots.sort(
        (a, b) => b.riskScore.compareTo(a.riskScore),
      );

      final filtered = _applyCurrentFilters(
        hotspots,
        state.searchQuery,
        state.filter,
      );

      state = state.copyWith(
        status: HotspotsStatus.loaded,
        list: hotspots,
        filteredList: filtered,
        clearError: true,
      );
    } on UnauthorizedException {
      state = state.copyWith(
        status: HotspotsStatus.error,
        errorMessage:
            'Your session has expired. Please log in again.',
      );
    } catch (error) {
      state = state.copyWith(
        status: HotspotsStatus.error,
        errorMessage: _cleanError(error),
      );
    }
  }

  void search(String query) {
    final filtered = _applyCurrentFilters(
      state.list,
      query,
      state.filter,
    );

    state = state.copyWith(
      searchQuery: query,
      filteredList: filtered,
    );
  }

  void applyFilter(HotspotFilter filter) {
    final filtered = _applyCurrentFilters(
      state.list,
      state.searchQuery,
      filter,
    );

    state = state.copyWith(
      filter: filter,
      filteredList: filtered,
    );
  }

  List<Hotspot> _applyCurrentFilters(
    List<Hotspot> hotspots,
    String query,
    HotspotFilter filter,
  ) {
    Iterable<Hotspot> result = hotspots;

    final normalizedQuery = query.trim().toLowerCase();

    if (normalizedQuery.isNotEmpty) {
      result = result.where(
        (hotspot) {
          final area = hotspot.area.toLowerCase();
          final junction = hotspot.junctionType.toLowerCase();

          return area.contains(normalizedQuery) ||
              junction.contains(normalizedQuery);
        },
      );
    }

    switch (filter) {
      case HotspotFilter.all:
        break;

      case HotspotFilter.highRisk:
        final threshold = highRiskThreshold(hotspots);

        result = result.where(
          (hotspot) => hotspot.riskScore >= threshold,
        );
        break;

      case HotspotFilter.fatalOnly:
        result = result.where(
          (hotspot) => hotspot.fatalities > 0,
        );
        break;

      case HotspotFilter.byArea:
        result = result.where(
          (hotspot) => hotspot.area.trim().isNotEmpty,
        );
        break;
    }

    return result.toList();
  }

  double highRiskThreshold([List<Hotspot>? hotspots]) {
    final source = hotspots ?? state.list;

    if (source.isEmpty) {
      return 0;
    }

    final scores = source
        .map((item) => item.riskScore)
        .toList()
      ..sort();

    final index = ((scores.length - 1) * 0.75).round();

    return scores[index];
  }

  double maxRiskScore() {
    if (state.list.isEmpty) {
      return 1;
    }

    return state.list
        .map((hotspot) => hotspot.riskScore)
        .reduce(max);
  }

  int totalAccidents() {
    return state.list.fold(
      0,
      (sum, hotspot) => sum + hotspot.accidents,
    );
  }

  int totalFatalities() {
    return state.list.fold(
      0,
      (sum, hotspot) => sum + hotspot.fatalities,
    );
  }

  int mostCommonPeakHour() {
    if (state.list.isEmpty) {
      return 0;
    }

    final counts = <int, int>{};

    for (final hotspot in state.list) {
      counts[hotspot.peakHour] =
          (counts[hotspot.peakHour] ?? 0) + 1;
    }

    return counts.entries
        .reduce(
          (a, b) => a.value >= b.value ? a : b,
        )
        .key;
  }

  String riskBand(Hotspot hotspot) {
    if (state.list.isEmpty) {
      return 'Medium';
    }

    final sortedScores = state.list
        .map((item) => item.riskScore)
        .toList()
      ..sort();

    final topTenIndex =
        ((sortedScores.length - 1) * 0.90).round();

    final bottomThirtyIndex =
        ((sortedScores.length - 1) * 0.30).round();

    final topTen = sortedScores[topTenIndex];
    final bottomThirty = sortedScores[bottomThirtyIndex];

    if (hotspot.riskScore >= topTen) {
      return 'High';
    }

    if (hotspot.riskScore <= bottomThirty) {
      return 'Low';
    }

    return 'Medium';
  }

  double riskProgress(Hotspot hotspot) {
    final maximum = maxRiskScore();

    if (maximum <= 0) {
      return 0;
    }

    final value = hotspot.riskScore / maximum;

    return value.clamp(0.0, 1.0);
  }

  String _cleanError(Object error) {
    final message = error.toString().replaceFirst(
          'Exception: ',
          '',
        );

    if (message.isEmpty) {
      return 'Something went wrong. Please try again.';
    }

    return message;
  }
}