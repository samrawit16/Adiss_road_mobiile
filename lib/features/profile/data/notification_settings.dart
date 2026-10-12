import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// What the app is allowed to do to warn the driver while "GPS safety" is on.
class NotificationSettings {
  const NotificationSettings({
    this.speedSound = true,
    this.vibration = true,
    this.nearbyAlerts = true,
  });

  /// Repeating alarm while the speed is above the road's limit.
  final bool speedSound;

  /// Vibrate once when the speed goes above the limit.
  final bool vibration;

  /// Show crashes and hazards other people reported near the user.
  final bool nearbyAlerts;

  NotificationSettings copyWith({
    bool? speedSound,
    bool? vibration,
    bool? nearbyAlerts,
  }) {
    return NotificationSettings(
      speedSound: speedSound ?? this.speedSound,
      vibration: vibration ?? this.vibration,
      nearbyAlerts: nearbyAlerts ?? this.nearbyAlerts,
    );
  }
}

class NotificationSettingsController
    extends StateNotifier<NotificationSettings> {
  NotificationSettingsController()
      : super(const NotificationSettings()) {
    _load();
  }

  final FlutterSecureStorage _storage = FlutterSecureStorage();

  final String _soundKey = 'notif_speed_sound';
  final String _vibrationKey = 'notif_vibration';
  final String _nearbyKey = 'notif_nearby_alerts';

  // Everything is ON until the user turns it off.
  Future<void> _load() async {
    try {
      final sound = await _storage.read(key: _soundKey);
      final vibration = await _storage.read(key: _vibrationKey);
      final nearby = await _storage.read(key: _nearbyKey);

      state = NotificationSettings(
        speedSound: sound != 'false',
        vibration: vibration != 'false',
        nearbyAlerts: nearby != 'false',
      );
    } catch (_) {
      // Keep the defaults if storage is unavailable.
    }
  }

  Future<void> setSpeedSound(bool value) async {
    state = state.copyWith(speedSound: value);
    await _save(_soundKey, value);
  }

  Future<void> setVibration(bool value) async {
    state = state.copyWith(vibration: value);
    await _save(_vibrationKey, value);
  }

  Future<void> setNearbyAlerts(bool value) async {
    state = state.copyWith(nearbyAlerts: value);
    await _save(_nearbyKey, value);
  }

  Future<void> _save(String key, bool value) async {
    try {
      await _storage.write(key: key, value: value.toString());
    } catch (_) {
      // The switch still works for this session even if it cannot be saved.
    }
  }
}

final notificationSettingsProvider = StateNotifierProvider<
    NotificationSettingsController, NotificationSettings>(
  (ref) => NotificationSettingsController(),
);
