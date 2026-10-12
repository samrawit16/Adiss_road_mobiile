import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../core/theme/app_theme.dart';
import '../data/notification_model.dart';
import '../viewmodels/notifications_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class NotificationsScreen extends ConsumerStatefulWidget {
  const NotificationsScreen({super.key});

  @override
  ConsumerState<NotificationsScreen> createState() =>
      _NotificationsScreenState();
}

class _NotificationsScreenState
    extends ConsumerState<NotificationsScreen> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (mounted) {
        ref.read(notificationsProvider.notifier).refresh();
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(notificationsProvider);
    final vm = ref.read(notificationsProvider.notifier);

    return Scaffold(
      backgroundColor: appColors.bgLight,
      appBar: AppBar(
        title: Text(
          'Notifications',
          style: TextStyle(
            color: appColors.navy,
            fontWeight: FontWeight.w800,
          ),
        ),
        actions: [
          if (state.unreadCount > 0)
            TextButton(
              onPressed: vm.markAllRead,
              child: const Text('Mark all read'),
            ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () => vm.refresh(),
        child: _body(state, vm),
      ),
    );
  }

  Widget _body(
    NotificationsState state,
    NotificationsViewModel vm,
  ) {
    if (state.items.isEmpty) {
      return ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(32, 120, 32, 32),
        children: [
          if (state.isLoading)
            const Center(child: CircularProgressIndicator())
          else if (state.error != null)
            _message(
              Icons.cloud_off_outlined,
              'Could not load notifications',
              state.error!,
            )
          else
            _message(
              Icons.notifications_none_rounded,
              'No notifications yet',
              'Messages from the police and updates about your reports will appear here.',
            ),
        ],
      );
    }

    return ListView.separated(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(16),
      itemCount: state.items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        return _tile(state.items[index], vm);
      },
    );
  }

  Widget _message(IconData icon, String title, String text) {
    return Column(
      children: [
        Icon(icon, size: 56, color: appColors.textMuted),
        const SizedBox(height: 14),
        Text(
          title,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: appColors.navy,
            fontSize: 17,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          text,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: appColors.textMuted,
            height: 1.45,
          ),
        ),
      ],
    );
  }

  Widget _tile(
    AppNotification n,
    NotificationsViewModel vm,
  ) {
    final style = _styleFor(n.category);

    return Material(
      color: n.isRead ? Colors.white : const Color(0xFFFFF8E1),
      borderRadius: BorderRadius.circular(16),
      child: InkWell(
        borderRadius: BorderRadius.circular(16),
        onTap: () {
          vm.markRead(n);

          if (n.reportId != null) {
            context.push('/police/my-reports');
          }
        },
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 20,
                backgroundColor: style.color.withOpacity(0.14),
                child: Icon(style.icon, color: style.color, size: 22),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            n.title,
                            style: TextStyle(
                              color: appColors.navy,
                              fontSize: 15,
                              fontWeight: n.isRead
                                  ? FontWeight.w600
                                  : FontWeight.w800,
                            ),
                          ),
                        ),
                        if (!n.isRead)
                          Container(
                            width: 9,
                            height: 9,
                            decoration: BoxDecoration(
                              color: appColors.amber,
                              shape: BoxShape.circle,
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      n.message,
                      style: const TextStyle(
                        color: Color(0xFF4A5568),
                        fontSize: 13.5,
                        height: 1.4,
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      '${_timeAgo(n.createdAt)} · ${style.label}',
                      style: TextStyle(
                        color: appColors.textMuted,
                        fontSize: 11.5,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  _CategoryStyle _styleFor(String category) {
    switch (category) {
      case 'safety_tip':
        return const _CategoryStyle(
          Icons.lightbulb_outline_rounded,
          Color(0xFF2E9E6B),
          'Safety tip',
        );
      case 'road_alert':
        return const _CategoryStyle(
          Icons.construction_rounded,
          Color(0xFFE8710A),
          'Road alert',
        );
      case 'warning':
        return const _CategoryStyle(
          Icons.warning_amber_rounded,
          Color(0xFFD93025),
          'Warning',
        );
      case 'report_update':
        return const _CategoryStyle(
          Icons.assignment_turned_in_outlined,
          Color(0xFF173B82),
          'Your report',
        );
      default:
        return const _CategoryStyle(
          Icons.campaign_outlined,
          Color(0xFF244A96),
          'Announcement',
        );
    }
  }

  String _timeAgo(DateTime time) {
    final diff = DateTime.now().difference(time);

    if (diff.inMinutes < 1) return 'Just now';
    if (diff.inMinutes < 60) return '${diff.inMinutes} min ago';
    if (diff.inHours < 24) return '${diff.inHours} h ago';
    if (diff.inDays < 7) return '${diff.inDays} d ago';

    const months = [
      'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
      'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
    ];

    return '${time.day} ${months[time.month - 1]} ${time.year}';
  }
}

class _CategoryStyle {
  const _CategoryStyle(this.icon, this.color, this.label);

  final IconData icon;
  final Color color;
  final String label;
}
