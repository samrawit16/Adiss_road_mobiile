import 'package:flutter/foundation.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/localization/app_localizations.dart';
import '../data/notification_settings.dart';
import '../viewmodels/profile_viewmodel.dart';
import '../../biometric/viewmodels/biometric_controller.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class SettingsScreen extends ConsumerWidget {
  const SettingsScreen({super.key});
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final locale = ref.watch(localeControllerProvider);
    final l10n = appLocalizations.of(context);
    final notif = ref.watch(notificationSettingsProvider);
    final notifController = ref.read(notificationSettingsProvider.notifier);

    // Fingerprint login (only for the account that is signed in right now).
    final bio = ref.watch(biometricControllerProvider);
    final userEmail = ref.watch(profileViewModelProvider).user?.email.toLowerCase();
    final fingerprintOn = bio.enabled && bio.enrolledEmail != null && bio.enrolledEmail == userEmail;
    final canToggleFingerprint = !kIsWeb && bio.available && !bio.busy && userEmail != null;
    final fingerprintSubtitle = kIsWeb
        ? l10n.t('notOnWeb')
        : (!bio.available ? l10n.t('fingerprintUnavailable') : l10n.t('fingerprintDesc'));
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, iconTheme: IconThemeData(color: appColors.navy), title: Text(l10n.t('settings'), style: TextStyle(color: appColors.navy, fontWeight: FontWeight.w700))),
      body: ListView(padding: const EdgeInsets.all(24), children: [
        Text(l10n.t('language'), style: TextStyle(fontWeight: FontWeight.w800, color: appColors.navy)),
        RadioListTile<String>(value: 'en', groupValue: locale.languageCode, title: Text(l10n.t('english')), activeColor: appColors.amber, onChanged: (_) => ref.read(localeControllerProvider.notifier).setLocale(const Locale('en'))),
        RadioListTile<String>(value: 'am', groupValue: locale.languageCode, title: Text(l10n.t('amharic')), activeColor: appColors.amber, onChanged: (_) => ref.read(localeControllerProvider.notifier).setLocale(const Locale('am'))),
        const Divider(height: 32),
        Text(l10n.t('fingerprintLogin'), style: TextStyle(fontWeight: FontWeight.w800, color: appColors.navy)),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: appColors.amber,
          secondary: const Icon(Icons.fingerprint),
          title: Text(l10n.t('fingerprintLogin')),
          subtitle: Text(fingerprintSubtitle),
          value: fingerprintOn,
          onChanged: canToggleFingerprint
              ? (value) async {
                  final messenger = ScaffoldMessenger.of(context);
                  final error = await ref
                      .read(biometricControllerProvider.notifier)
                      .setEnabled(value, email: userEmail);
                  messenger.showSnackBar(
                    SnackBar(
                      content: Text(
                        error ??
                            (value
                                ? 'Fingerprint login is on. You can use it on the login screen.'
                                : 'Fingerprint login is off.'),
                      ),
                    ),
                  );
                }
              : null,
        ),
        const Divider(height: 32),
        Text(l10n.t('notifications'), style: TextStyle(fontWeight: FontWeight.w800, color: appColors.navy)),
        Padding(
          padding: const EdgeInsets.only(top: 4, bottom: 4),
          child: Text(l10n.t('notificationsHint'), style: TextStyle(color: appColors.textMuted, fontSize: 12)),
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: appColors.amber,
          title: Text(l10n.t('speedSound')),
          subtitle: Text(kIsWeb ? l10n.t('notOnWeb') : l10n.t('speedSoundDesc')),
          value: notif.speedSound && !kIsWeb,
          onChanged: kIsWeb ? null : notifController.setSpeedSound,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: appColors.amber,
          title: Text(l10n.t('vibration')),
          subtitle: Text(kIsWeb ? l10n.t('notOnWeb') : l10n.t('vibrationDesc')),
          value: notif.vibration && !kIsWeb,
          onChanged: kIsWeb ? null : notifController.setVibration,
        ),
        SwitchListTile(
          contentPadding: EdgeInsets.zero,
          activeColor: appColors.amber,
          title: Text(l10n.t('nearbyIncidents')),
          subtitle: Text(l10n.t('nearbyIncidentsDesc')),
          value: notif.nearbyAlerts,
          onChanged: notifController.setNearbyAlerts,
        ),
      ]),
    );
  }
}
