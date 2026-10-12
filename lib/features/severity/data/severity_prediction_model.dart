class SeverityPrediction {
  const SeverityPrediction({
    required this.predictedSeverity,
    required this.probabilities,
    required this.fatalProbability,
    required this.fatalThreshold,
    this.subCity,
    this.weather,
    this.isPeakHour = false,
    this.peakPeriod,
    this.peakMessage,
    this.lightConditions,
  });

  final String predictedSeverity;
  final Map<String, double> probabilities;
  final double fatalProbability;
  final double fatalThreshold;
  final String? subCity;
  final String? weather;
  final bool isPeakHour;
  final String? peakPeriod;
  final String? peakMessage;
  final String? lightConditions;

  /// No statics: the parsing helpers live on a parser instance below.
  factory SeverityPrediction.fromJson(Map<String, dynamic> json) {
    const parser = _SeverityPredictionParser();
    final rawProbabilities = json['probabilities'];
    final probabilities = <String, double>{};

    if (rawProbabilities is Map) {
      rawProbabilities.forEach((key, value) {
        if (value is num) {
          probabilities[key.toString()] = value.toDouble();
        }
      });
    }

    final rawPeak = json['is_peak_hour'] ?? json['peak_hour'];
    final isPeak = rawPeak == true || rawPeak?.toString().toLowerCase() == 'true';

    return SeverityPrediction(
      predictedSeverity: json['predicted_severity']?.toString() ?? 'Unknown',
      probabilities: probabilities,
      fatalProbability: parser.number(json['fatal_probability']),
      fatalThreshold: parser.number(json['fatal_threshold'], fallback: 0.25),
      subCity: parser.string(json['sub_city'] ?? json['area_accident_occured']),
      weather: parser.string(json['weather'] ?? json['weather_conditions'] ?? json['Weather_conditions']),
      isPeakHour: isPeak,
      peakPeriod: parser.string(json['peak_period']),
      peakMessage: parser.string(json['peak_message']),
      lightConditions: parser.string(json['light_conditions'] ?? json['Light_conditions']),
    );
  }

  double probabilityFor(String severity) {
    final exact = probabilities[severity];
    if (exact != null) return exact;

    final key = probabilities.keys.firstWhere(
      (k) => k.toLowerCase() == severity.toLowerCase(),
      orElse: () => '',
    );
    return key.isEmpty ? 0.0 : probabilities[key] ?? 0.0;
  }

  double get fatalPercentage => fatalProbability * 100;
  double get seriousPercentage => probabilityFor('Serious Injury') * 100;
  double get slightPercentage => probabilityFor('Slight Injury') * 100;
}

/// No statics: JSON parsing helpers live on this small instance.
class _SeverityPredictionParser {
  const _SeverityPredictionParser();

  double number(dynamic value, {double fallback = 0.0}) {
    return value is num ? value.toDouble() : fallback;
  }

  String? string(dynamic value) {
    final result = value?.toString().trim();
    return result == null || result.isEmpty ? null : result;
  }
}
