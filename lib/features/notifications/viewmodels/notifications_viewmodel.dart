import 'dart:async';
import 'dart:math' as math;

import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/notification_model.dart';
import '../data/notification_repository.dart';

class NotificationsState {
  const NotificationsState({
    this.items = const [],
    this.unreadCount = 0,
    this.isLoading = false,
    this.error,
  });

  final List<AppNotification> items;
  final int unreadCount;
  final bool isLoading;
  final String? error;

  NotificationsState copyWith({
    List<AppNotification>? items,
    int? unreadCount,
    bool? isLoading,
    String? error,
    bool clearError = false,
  }) {
    return NotificationsState(
      items: items ?? this.items,
      unreadCount: unreadCount ?? this.unreadCount,
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : error ?? this.error,
    );
  }
}

/// Keeps the bell counter up to date: it asks the server every 30 seconds
/// (and whenever the notifications screen opens or is pulled down).
class NotificationsViewModel extends StateNotifier<NotificationsState> {
  NotificationsViewModel(this._repo)
      : super(const NotificationsState()) {
    _timer = Timer.periodic(
      const Duration(seconds: 30),
      (_) => refresh(silent: true),
    );
  }

  final NotificationRepository _repo;

  Timer? _timer;
  bool _busy = false;

  Future<void> refresh({bool silent = false}) async {
    if (_busy || !mounted) return;

    _busy = true;

    if (!silent) {
      state = state.copyWith(isLoading: true, clearError: true);
    }

    try {
      final page = await _repo.fetch();

      if (!mounted) return;

      state = state.copyWith(
        items: page.items,
        unreadCount: page.unreadCount,
        isLoading: false,
        clearError: true,
      );
    } catch (e) {
      if (!mounted) return;

      // A background refresh never shows an error: the bell keeps its last count.
      state = state.copyWith(
        isLoading: false,
        error: silent ? state.error : _clean(e),
      );
    } finally {
      _busy = false;
    }
  }

  Future<void> markRead(AppNotification notification) async {
    if (notification.isRead) return;

    state = state.copyWith(
      items: [
        for (final item in state.items)
          item.id == notification.id
              ? item.copyWith(isRead: true)
              : item,
      ],
      unreadCount: math.max(0, state.unreadCount - 1),
    );

    try {
      final unread = await _repo.markRead(notification.id);

      if (mounted) {
        state = state.copyWith(unreadCount: unread);
      }
    } catch (_) {
      // The next refresh corrects the counter if this failed.
    }
  }

  Future<void> markAllRead() async {
    state = state.copyWith(
      items: [
        for (final item in state.items) item.copyWith(isRead: true),
      ],
      unreadCount: 0,
    );

    try {
      final unread = await _repo.markAllRead();

      if (mounted) {
        state = state.copyWith(unreadCount: unread);
      }
    } catch (_) {
      // The next refresh corrects the counter if this failed.
    }
  }

  String _clean(Object e) {
    final text = e.toString().replaceFirst('Exception: ', '');
    return text.contains('DioException')
        ? 'Could not load notifications. Check your connection and pull down to retry.'
        : text;
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }
}

final notificationsProvider =
    StateNotifierProvider<NotificationsViewModel, NotificationsState>(
  (ref) => NotificationsViewModel(
    ref.read(notificationRepositoryProvider),
  ),
);
