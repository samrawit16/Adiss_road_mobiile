import 'package:dio/dio.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../core/constants/api_constants.dart';
import '../../../core/network/api_client.dart';
import 'notification_model.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class NotificationsPage {
  const NotificationsPage({
    required this.items,
    required this.unreadCount,
  });

  final List<AppNotification> items;
  final int unreadCount;
}

class NotificationRepository {
  NotificationRepository(ApiClient client) : _dio = client.dio;

  final Dio _dio;

  Future<NotificationsPage> fetch() async {
    final response = await _dio
        .get(apiConstants.notifications)
        .timeout(const Duration(seconds: 15));

    final data = response.data;

    if (data is! Map) {
      throw Exception('Unexpected response from the server.');
    }

    final raw = data['items'];

    final items = raw is List
        ? raw
            .whereType<Map>()
            .map(
              (e) => AppNotification.fromJson(
                Map<String, dynamic>.from(e),
              ),
            )
            .toList()
        : <AppNotification>[];

    return NotificationsPage(
      items: items,
      unreadCount: (data['unread_count'] as num?)?.toInt() ?? 0,
    );
  }

  /// Returns the new unread count.
  Future<int> markRead(int id) async {
    final response = await _dio
        .post('${apiConstants.notifications}/$id/read')
        .timeout(const Duration(seconds: 15));

    return _unread(response.data);
  }

  Future<int> markAllRead() async {
    final response = await _dio
        .post('${apiConstants.notifications}/read-all')
        .timeout(const Duration(seconds: 15));

    return _unread(response.data);
  }

  int _unread(dynamic data) {
    if (data is Map) {
      return (data['unread_count'] as num?)?.toInt() ?? 0;
    }
    return 0;
  }
}

final notificationRepositoryProvider =
    Provider<NotificationRepository>(
  (ref) => NotificationRepository(ref.read(apiClientProvider)),
);
