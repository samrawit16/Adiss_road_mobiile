import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../../../core/widgets/app_header.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class MainShell extends StatelessWidget {
  const MainShell({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).uri.toString();
    var index = 0;
    if (location.startsWith('/alerts')) index = 1;
    if (location.startsWith('/report')) index = 2;
    if (location.startsWith('/police') || location.startsWith('/tips')) index = 3;
    if (location.startsWith('/profile')) index = 4;
    final l10n = appLocalizations.of(context);

    return Scaffold(
      body: SafeArea(
        top: true,
        bottom: false,
        child: Column(
          children: [
            const AppHeader(),
            Expanded(child: child),
          ],
        ),
      ),
      bottomNavigationBar: NavigationBar(
        backgroundColor: Colors.white,
        indicatorColor: appColors.amber.withOpacity(.2),
        selectedIndex: index,
        onDestinationSelected: (i) {
          switch (i) {
            case 0: context.go('/home');
            case 1: context.go('/alerts');
            case 2: context.go('/report');
            case 3: context.go('/police');
            case 4: context.go('/profile');
          }
        },
        destinations: [
          NavigationDestination(icon: const Icon(Icons.map_outlined), selectedIcon: const Icon(Icons.map), label: l10n.t('home')),
          NavigationDestination(icon: const Icon(Icons.notifications_none), selectedIcon: const Icon(Icons.notifications), label: l10n.t('alerts')),
          NavigationDestination(icon: Icon(Icons.add_circle, color: appColors.amber, size: 32), label: l10n.t('report')),
          NavigationDestination(icon: const Icon(Icons.shield_outlined), selectedIcon: const Icon(Icons.shield), label: l10n.t('police')),
          NavigationDestination(icon: const Icon(Icons.person_outline), selectedIcon: const Icon(Icons.person), label: l10n.t('profile')),
        ],
      ),
    );
  }
}
