import 'package:flutter/material.dart';
import '../../features/notifications/views/notifications_screen.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/splash/splash_screen.dart';
import '../../features/onboarding/onboarding_screen.dart';
import '../../features/auth/views/login_screen.dart';
import '../../features/auth/views/register_screen.dart';
import '../../features/auth/views/verify_screen.dart';
import '../../features/auth/views/forgot_password_screen.dart';
import '../../features/auth/views/reset_password_screen.dart';
import '../../features/home/views/main_shell.dart';
import '../../features/home/views/home_screen.dart';
import '../../features/alerts/views/alerts_screen.dart';
import '../../features/report/views/report_type_screen.dart';
import '../../features/report/views/report_form_screen.dart';
import '../../features/police/views/police_info_screen.dart';
import '../../features/police/views/police_report_screen.dart';
import '../../features/police/views/my_reports_screen.dart';
import '../../features/tips/views/tips_screen.dart';
import '../../features/profile/views/profile_screen.dart';
import '../../features/profile/views/edit_profile_screen.dart';
import '../../features/profile/views/settings_screen.dart';
import '../../features/severity/presentation/severity_test_screen.dart';
import '../../features/risk_map/views/risk_map_screen.dart';

class AppRouter {
  AppRouter();

  late final GoRouter router = GoRouter(
    initialLocation: '/splash',
    routes: [
      GoRoute(
        path: '/splash',
        builder: (_, __) => const SplashScreen(),
      ),
      GoRoute(
        path: '/onboarding',
        builder: (_, __) => const OnboardingScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (_, __) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (_, __) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/verify',
        builder: (_, state) {
          final email =
              state.uri.queryParameters['email'] ?? '';

          return VerifyScreen(
            email: email,
          );
        },
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (_, __) => const ForgotPasswordScreen(),
      ),
      GoRoute(
        path: '/reset-password',
        builder: (_, state) => ResetPasswordScreen(
          email: state.extra is String ? state.extra as String : '',
        ),
      ),
      ShellRoute(
        builder: (_, __, child) => MainShell(
          child: child,
        ),
        routes: [
          GoRoute(
            path: '/risk-map',
            builder: (_, __) => const RiskMapScreen(),
          ),
          GoRoute(
            path: '/severity',
            builder: (_, __) => const SeverityTestScreen(),
          ),
          GoRoute(
            path: '/home',
            builder: (_, __) => const HomeScreen(),
          ),
          GoRoute(
            path: '/report',
            builder: (_, __) => const ReportTypeScreen(),
          ),
          GoRoute(
            path: '/report/form',
            builder: (_, state) => ReportFormScreen(initialType: state.uri.queryParameters['type'] ?? 'road_accident'),
          ),
          GoRoute(
            path: '/alerts',
            builder: (_, __) => const AlertsScreen(),
          ),
          GoRoute(
            path: '/police',
            builder: (_, __) => const PoliceInfoScreen(),
          ),
          GoRoute(
            path: '/police/report',
            builder: (_, __) => const PoliceReportScreen(),
          ),
          GoRoute(
            path: '/police/my-reports',
            builder: (_, __) => const MyReportsScreen(),
          ),
          GoRoute(
            path: '/tips',
            builder: (_, __) => const TipsScreen(),
          ),
          GoRoute(
            path: '/notifications',
            builder: (_, __) => const NotificationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (_, __) => const ProfileScreen(),
          ),
          GoRoute(
            path: '/profile/edit',
            builder: (_, __) => const EditProfileScreen(),
          ),
          GoRoute(
            path: '/profile/settings',
            builder: (_, __) => const SettingsScreen(),
          ),
        ],
      ),
    ],
  );
}

final appRouterProvider = Provider<GoRouter>((ref) {
  return AppRouter().router;
});
