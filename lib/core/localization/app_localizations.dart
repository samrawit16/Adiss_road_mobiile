import 'package:flutter/material.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class AppLocalizations {
  AppLocalizations(this.locale);
  final Locale locale;

  /// No statics: an instance getter exposes the supported locales.
  List<Locale> get supportedLocales => const [Locale('en'), Locale('am')];

  final Map<String, Map<String, String>> _values =
      <String, Map<String, String>>{
    'home': {'en': 'Home', 'am': 'መነሻ'},
    'alerts': {'en': 'Alerts', 'am': 'ማሳወቂያዎች'},
    'report': {'en': 'Report', 'am': 'ሪፖርት'},
    'police': {'en': 'Police', 'am': 'ፖሊስ'},
    'profile': {'en': 'Profile', 'am': 'መገለጫ'},
    'settings': {'en': 'Settings', 'am': 'ቅንብሮች'},
    'language': {'en': 'Language', 'am': 'ቋንቋ'},
    'english': {'en': 'English', 'am': 'እንግሊዝኛ'},
    'amharic': {'en': 'Amharic', 'am': 'አማርኛ'},
    'liveRoadSafety': {'en': 'Live Road Safety', 'am': 'የቀጥታ የመንገድ ደህንነት'},
    'nearbyAuthorities': {'en': 'Nearby Authorities', 'am': 'በአቅራቢያ ያሉ ባለሥልጣናት'},
    'myReports': {'en': 'My Reports', 'am': 'ሪፖርቶቼ'},
    'editProfile': {'en': 'Edit Profile', 'am': 'መገለጫ አርትዕ'},
    'saveChanges': {'en': 'Save Changes', 'am': 'ለውጦችን አስቀምጥ'},
    'notifications': {'en': 'Notifications', 'am': 'ማሳወቂያዎች'},
    'privacy': {'en': 'Privacy & Security', 'am': 'ግላዊነት እና ደህንነት'},
    'logout': {'en': 'Log Out', 'am': 'ውጣ'},
    'speedSound': {'en': 'Speed warning sound', 'am': 'የፍጥነት ማስጠንቀቂያ ድምጽ'},
    'speedSoundDesc': {'en': 'Play an alarm while you are over the road speed limit.', 'am': 'ከመንገዱ የፍጥነት ገደብ ሲያልፉ ማንቂያ ድምጽ ያሰማል።'},
    'vibration': {'en': 'Vibration', 'am': 'ንዝረት'},
    'vibrationDesc': {'en': 'Vibrate when you go over the speed limit.', 'am': 'ከፍጥነት ገደቡ ሲያልፉ ስልኩ ይንቀጠቀጣል።'},
    'nearbyIncidents': {'en': 'Nearby incident alerts', 'am': 'በአቅራቢያ ያሉ የአደጋ ማሳወቂያዎች'},
    'nearbyIncidentsDesc': {'en': 'Show crashes and hazards reported by other people near you while GPS safety is on.', 'am': 'GPS ደህንነት ሲበራ በአቅራቢያዎ ሌሎች ሰዎች ያሳወቋቸውን አደጋዎችና አደገኛ ሁኔታዎች ያሳያል።'},
    'fingerprintLogin': {'en': 'Fingerprint login', 'am': 'በጣት አሻራ መግቢያ'},
    'fingerprintDesc': {'en': 'Sign in with your fingerprint instead of typing your password. Your fingerprint never leaves your phone.', 'am': 'የይለፍ ቃል ከመጻፍ ይልቅ በጣት አሻራዎ ይግቡ። የጣት አሻራዎ ከስልክዎ አይወጣም።'},
    'fingerprintUnavailable': {'en': 'Add a fingerprint in your phone settings first.', 'am': 'መጀመሪያ በስልክዎ ቅንብሮች ውስጥ የጣት አሻራ ያስገቡ።'},
    'notOnWeb': {'en': 'Not available in the web version.', 'am': 'በድር ስሪት ውስጥ አይገኝም።'},
    'notificationsHint': {'en': 'These warnings work while Live Road Safety (GPS safety) is turned on.', 'am': 'እነዚህ ማስጠንቀቂያዎች የሚሰሩት የቀጥታ የመንገድ ደህንነት (GPS ደህንነት) ሲበራ ነው።'},
  };

  String t(String key) => _values[key]?[locale.languageCode] ?? _values[key]?['en'] ?? key;

  /// No statics: views get the localizations through this instance method.
  AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;
}

class AppLocalizationsDelegate extends LocalizationsDelegate<AppLocalizations> {
  const AppLocalizationsDelegate();

  /// No statics: the supported locales live on this delegate instance.
  List<Locale> get supportedLocales => const [Locale('en'), Locale('am')];

  @override bool isSupported(Locale locale) =>
      supportedLocales.any((x) => x.languageCode == locale.languageCode);
  @override Future<AppLocalizations> load(Locale locale) async => AppLocalizations(locale);
  @override bool shouldReload(covariant LocalizationsDelegate<AppLocalizations> old) => false;

  /// No statics: views call this instance method on the delegate.
  AppLocalizations of(BuildContext context) => Localizations.of<AppLocalizations>(context, AppLocalizations)!;
}

/// No statics: views resolve the localizations through this locator instance
/// instead of a static class member.
class AppLocalizationsLocator {
  AppLocalizations of(BuildContext context) =>
      Localizations.of<AppLocalizations>(context, AppLocalizations)!;
}

/// The single locator instance used across the app (injected, not static).
final AppLocalizationsLocator appLocalizations = AppLocalizationsLocator();

class LocaleController extends StateNotifier<Locale> {
  LocaleController() : super(const Locale('en')) { _load(); }
  final FlutterSecureStorage _storage = FlutterSecureStorage();

  Future<void> _load() async {
    final value = await _storage.read(key: 'app_locale');
    if (value == 'am' || value == 'en') state = Locale(value!);
  }

  Future<void> setLocale(Locale locale) async {
    if (!AppLocalizations(const Locale('en'))
        .supportedLocales
        .any((x) => x.languageCode == locale.languageCode)) {
      return;
    }
    state = locale;
    await _storage.write(key: 'app_locale', value: locale.languageCode);
  }
}

final localeControllerProvider = StateNotifierProvider<LocaleController, Locale>((ref) => LocaleController());
