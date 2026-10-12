/// One message in the bell: an announcement written by the police in the dashboard,
/// or an automatic update about the user's own report.
class AppNotification {
  const AppNotification({
    required this.id,
    required this.title,
    required this.message,
    required this.category,
    required this.createdAt,
    required this.isRead,
    this.reportId,
  });

  final int id;
  final String title;
  final String message;

  /// announcement | safety_tip | road_alert | warning | report_update
  final String category;
  final DateTime createdAt;
  final bool isRead;
  final int? reportId;

  factory AppNotification.fromJson(Map<String, dynamic> json) {
    return AppNotification(
      id: (json['id'] as num?)?.toInt() ?? 0,
      title: json['title']?.toString() ?? '',
      message: json['message']?.toString() ?? '',
      category: json['category']?.toString() ?? 'announcement',
      reportId: (json['report_id'] as num?)?.toInt(),
      createdAt: _parseUtc(json['created_at']?.toString()),
      isRead: json['is_read'] == true,
    );
  }

  AppNotification copyWith({bool? isRead}) {
    return AppNotification(
      id: id,
      title: title,
      message: message,
      category: category,
      createdAt: createdAt,
      isRead: isRead ?? this.isRead,
      reportId: reportId,
    );
  }
}

/// The server sends UTC ("...Z"); show it in the phone's local time.
DateTime _parseUtc(String? raw) {
  if (raw == null || raw.isEmpty) return DateTime.now();

  final hasZone = RegExp(r'(Z|[+-]\d\d:?\d\d)$').hasMatch(raw);
  final parsed = DateTime.tryParse(hasZone ? raw : '${raw}Z');

  return (parsed ?? DateTime.now()).toLocal();
}
