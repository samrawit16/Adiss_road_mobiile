class SafetyContext {
  const SafetyContext({
    required this.latitude,
    required this.longitude,
    required this.speedKmh,
    required this.roadName,
    required this.highwayType,
    required this.speedLimitKmh,
    required this.speedLimitSource,
    required this.speedWarning,
    required this.safetyMessage,
  });

  final double latitude;
  final double longitude;
  final double speedKmh;
  final String? roadName;
  final String? highwayType;
  final double? speedLimitKmh;
  final String? speedLimitSource;
  final String? speedWarning;
  final String safetyMessage;

  bool get speeding =>
      speedLimitKmh != null && speedKmh > speedLimitKmh!;

  factory SafetyContext.fromJson(Map<String, dynamic> json, double speed) {
    final limit = (json['speed_limit_kmh'] as num?)?.toDouble();
    return SafetyContext(
      latitude: (json['latitude'] as num).toDouble(),
      longitude: (json['longitude'] as num).toDouble(),
      speedKmh: speed,
      roadName: json['road_name'] as String?,
      highwayType: json['highway_type'] as String?,
      speedLimitKmh: limit,
      speedLimitSource: json['speed_limit_source'] as String?,
      speedWarning: json['speed_warning'] as String?,
      safetyMessage: json['safety_message'] as String? ??
          'Stay alert and follow the road signs and local traffic rules.',
    );
  }
}
