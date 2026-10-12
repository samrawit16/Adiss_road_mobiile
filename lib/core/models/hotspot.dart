class Hotspot {
  final int id;
  final String area;
  final String junctionType;
  final int accidents;
  final int fatalities;
  final int injuries;
  final double riskScore;
  final int peakHour;
  final String severity;

  Hotspot({
    required this.id,
    required this.area,
    required this.junctionType,
    required this.accidents,
    required this.fatalities,
    required this.injuries,
    required this.riskScore,
    required this.peakHour,
    required this.severity,
  });

  factory Hotspot.fromJson(Map<String, dynamic> j) {
    return Hotspot(
      id: j['id'] ?? 0,
      area: j['area'] ?? 'Unknown',
      junctionType: j['junction_type'] ?? 'Unknown',
      accidents: j['accidents'] ?? 0,
      fatalities: j['fatalities'] ?? 0,
      injuries: j['injuries'] ?? 0,
      riskScore: (j['risk_score'] as num?)?.toDouble() ?? 0,
      peakHour: j['peak_hour'] ?? 0,
      severity: j['severity'] ?? 'Unknown',
    );
  }
}