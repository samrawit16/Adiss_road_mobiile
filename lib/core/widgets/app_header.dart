import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/alerts/viewmodels/live_safety_viewmodel.dart';
import '../../features/notifications/viewmodels/notifications_viewmodel.dart';
import '../../features/profile/viewmodels/profile_viewmodel.dart';
import '../constants/api_constants.dart';
import '../theme/app_theme.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

/// Top bar shown on every screen after login: logo, GPS-safety indicator,
/// notification bell with an unread counter, and the user's profile picture
/// (or the first letter of their name when no picture was uploaded).
class AppHeader extends ConsumerStatefulWidget {
  const AppHeader({super.key});

  @override
  ConsumerState<AppHeader> createState() => _AppHeaderState();
}

class _AppHeaderState extends ConsumerState<AppHeader> {
  @override
  void initState() {
    super.initState();

    Future.microtask(() {
      if (!mounted) return;

      // A fresh start after login: never show the previous account's picture.
      final profile = ref.read(profileViewModelProvider.notifier);
      profile.reset();
      profile.load();

      ref.read(notificationsProvider.notifier).refresh();
    });
  }

  String _imageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) {
      return path;
    }

    return '${apiConstants.baseUrl.replaceFirst('/api/v1', '')}$path';
  }

  String _initial(String? name) {
    final text = (name ?? '').trim();

    if (text.isEmpty) return '';

    return String.fromCharCodes([text.runes.first]).toUpperCase();
  }

  void _openNotifications() {
    final path = GoRouterState.of(context).uri.path;

    if (path.startsWith('/notifications')) return;

    context.push('/notifications');
  }

  @override
  Widget build(BuildContext context) {
    final profile = ref.watch(profileViewModelProvider);

    final unread = ref.watch(
      notificationsProvider.select((s) => s.unreadCount),
    );

    final gpsOn = ref.watch(
      liveSafetyProvider.select((vm) => vm.isMonitoring),
    );

    final user = profile.user;
    final imagePath = user?.profileImageUrl;

    final String? imageUrl =
        (imagePath != null && imagePath.isNotEmpty)
            ? _imageUrl(imagePath)
            : null;

    final initial = _initial(user?.fullName);

    return Container(
      color: appColors.navyDark,
      padding: const EdgeInsets.fromLTRB(16, 8, 10, 8),
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: appColors.navyCard,
              borderRadius: BorderRadius.circular(12),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.asset(
                'assets/images/logo.png',
                fit: BoxFit.contain,
                errorBuilder: (context, error, stackTrace) {
                  return Icon(
                    Icons.shield_rounded,
                    color: appColors.amber,
                    size: 24,
                  );
                },
              ),
            ),
          ),
          const SizedBox(width: 10),
          const Expanded(
            child: Text(
              'AAGuardian',
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: Colors.white,
                fontSize: 19,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
          if (gpsOn)
            Tooltip(
              message: 'GPS safety is on',
              child: GestureDetector(
                onTap: () => context.go('/alerts'),
                child: Container(
                  width: 30,
                  height: 30,
                  margin: const EdgeInsets.only(right: 2),
                  decoration: BoxDecoration(
                    color: const Color(0xFF66BB6A).withOpacity(0.18),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.gps_fixed,
                    size: 17,
                    color: Color(0xFF66BB6A),
                  ),
                ),
              ),
            ),
          Stack(
            clipBehavior: Clip.none,
            children: [
              IconButton(
                tooltip: 'Notifications',
                onPressed: _openNotifications,
                icon: const Icon(
                  Icons.notifications_none_rounded,
                  color: Colors.white,
                  size: 27,
                ),
              ),
              if (unread > 0)
                Positioned(
                  right: 3,
                  top: 3,
                  child: IgnorePointer(
                    child: Container(
                      constraints: const BoxConstraints(
                        minWidth: 18,
                        minHeight: 18,
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 5),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: appColors.amber,
                        borderRadius: BorderRadius.circular(9),
                        border: Border.all(
                          color: appColors.navyDark,
                          width: 1.5,
                        ),
                      ),
                      child: Text(
                        unread > 9 ? '9+' : '$unread',
                        style: TextStyle(
                          color: appColors.navyDark,
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(width: 2),
          GestureDetector(
            onTap: () => context.go('/profile'),
            child: CircleAvatar(
              radius: 20,
              backgroundColor: appColors.amber,
              foregroundImage:
                  imageUrl != null ? NetworkImage(imageUrl) : null,
              onForegroundImageError:
                  imageUrl != null ? (error, stackTrace) {} : null,
              child: initial.isEmpty
                  ? Icon(
                      Icons.person,
                      color: appColors.navyDark,
                      size: 22,
                    )
                  : Text(
                      initial,
                      style: TextStyle(
                        color: appColors.navyDark,
                        fontWeight: FontWeight.w800,
                        fontSize: 16,
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }
}
