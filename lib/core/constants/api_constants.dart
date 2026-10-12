import 'package:flutter/foundation.dart';


class ApiConstants {
  ApiConstants();

  /// The deployed backend.
  final String prodBaseUrl = 'https://adiss-road-backend.onrender.com/api/v1';

  /// Kept for local development (pass --dart-define=API_URL=... to use it).
  final String devBaseUrl = 'http://127.0.0.1:8001/api/v1';

  /// The Android emulator's own "127.0.0.1" is the emulator, not your computer;
  /// 10.0.2.2 is how it reaches the host machine.
  final String androidEmulatorBaseUrl = 'http://10.0.2.2:8001/api/v1';

  final String _apiUrlOverride = const String.fromEnvironment('API_URL');

  /// Pass --dart-define=API_URL=http://<your-computer-LAN-IP>:8001/api/v1
  /// to test on a physical phone.
  String get baseUrl {
    if (_apiUrlOverride.isNotEmpty) return _apiUrlOverride;
    // Only debug runs (emulator/simulator) should hit the local machine.
    if (!kIsWeb &&
        defaultTargetPlatform == TargetPlatform.android &&
        kDebugMode) {
      return androidEmulatorBaseUrl;
    }
    return prodBaseUrl;
  }

  // Authentication
  final String register = '/auth/register';
  final String verifyOtp = '/auth/verify';
  final String login = '/auth/login';
  final String refresh = '/auth/refresh';
  final String forgotPassword = '/auth/forgot-password';
  final String resetPassword = '/auth/reset-password';
  final String resendOtp = '/auth/resend-otp';

  // User
  final String me = '/users/me';

  // Hotspots
  final String hotspots = '/hotspots';

  // Accident Severity ML
  final String severityPredict = '/severity/predict';


  final String safetyContext = '/safety/context';
  final String safetyEvents = '/safety/events';
  final String safetyAlerts = '/safety/alerts';
  final String safetyAuthorities = '/safety/authorities';
  final String safetyEvidence = '/safety/evidence';
  final String accidentReports = '/safety/accident-reports';

  
  final String notifications = '/notifications';

  
  final String biometricEnroll = '/auth/biometric/enroll';
  final String biometricChallenge = '/auth/biometric/challenge';
  final String biometricVerify = '/auth/biometric/verify';

 
  final String profile = '/users/me';
  final String profileImage = '/users/me/profile-image';

  // Reports (legacy compatibility)
  final String reports = '/reports';
}


final ApiConstants apiConstants = ApiConstants();
