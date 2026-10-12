import 'dart:async';

import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:geolocator/geolocator.dart';

import '../../profile/data/notification_settings.dart';
import '../data/safety_model.dart';
import '../data/safety_repository.dart';

class LiveSafetyViewModel extends ChangeNotifier {
  LiveSafetyViewModel({
    required SafetyRepository repository,
  }) : _repository = repository;

  final SafetyRepository _repository;

  final AudioPlayer _player = AudioPlayer();

  StreamSubscription<Position>? _positionSubscription;

  Position? _lastPosition;

  DateTime? _lastContextAt;
  DateTime? _lastAlertsAt;

  bool _contextBusy = false;
  bool _alertsBusy = false;

  bool _warningLogged = false;
  bool _vibrated = false;
  DateTime? _nextEventAttemptAt;

  // What the user allowed in Settings > Notifications.
  NotificationSettings _settings = const NotificationSettings();

  /// The alarm sound only exists in the phone app (audio is disabled on web).
  bool get soundEnabled => _settings.speedSound && !kIsWeb;

  bool get nearbyAlertsEnabled => _settings.nearbyAlerts;

  void applySettings(NotificationSettings next) {
    if (_disposed) return;

    final nearbyChanged = _settings.nearbyAlerts != next.nearbyAlerts;
    final soundTurnedOff = _settings.speedSound && !next.speedSound;

    _settings = next;

    if (soundTurnedOff && !kIsWeb) {
      unawaited(_stopWarning());
    }

    if (nearbyChanged) {
      if (next.nearbyAlerts) {
        // Load them again on the next GPS update.
        _lastAlertsAt = null;
      } else {
        nearbyAlerts = [];
      }
    }

    _safeNotify();
  }

  bool _disposed = false;

  bool isMonitoring = false;
  bool locationEnabled = false;
  bool permissionDenied = false;
  bool isLoading = false;

  String? errorMessage;

  double speedKmh = 0;

  SafetyContext? context;

  List<Map<String, dynamic>> nearbyAlerts = [];

  bool get isSpeeding {
    final limit = context?.speedLimitKmh;

    if (limit == null) {
      return false;
    }

    return speedKmh > limit;
  }

  // ---------------------------------------------------------------------------
  // START MONITORING
  // ---------------------------------------------------------------------------

  Future<void> startMonitoring() async {
    if (_disposed) return;

    if (isMonitoring || isLoading) {
      return;
    }

    isLoading = true;
    errorMessage = null;

    _safeNotify();

    try {
      var permission = await Geolocator.checkPermission();

      if (_disposed) return;

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (_disposed) return;

      if (permission == LocationPermission.denied) {
        permissionDenied = true;
        locationEnabled = false;
        errorMessage =
            'Location permission was denied. Please allow location access in Chrome.';
        return;
      }

      if (permission == LocationPermission.deniedForever) {
        permissionDenied = true;
        locationEnabled = false;
        errorMessage =
            'Location permission is blocked. Allow location access for this site in Chrome.';
        return;
      }

      permissionDenied = false;
      locationEnabled = true;
      isMonitoring = true;

      _safeNotify();

      // -----------------------------------------------------------------------
      // Get first GPS position immediately.
      // -----------------------------------------------------------------------

      try {
        final position = await Geolocator.getCurrentPosition(
          locationSettings: const LocationSettings(
            accuracy: LocationAccuracy.best,
          ),
        );

        if (_disposed || !isMonitoring) {
          return;
        }

        unawaited(_onPosition(position));
      } catch (e) {
        if (_disposed || !isMonitoring) {
          return;
        }

        errorMessage =
            'Waiting for the first GPS position: $e';

        _safeNotify();
      }

      if (_disposed || !isMonitoring) {
        return;
      }

      // -----------------------------------------------------------------------
      // Continue receiving GPS updates.
      // -----------------------------------------------------------------------

      _positionSubscription =
          Geolocator.getPositionStream(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.best,
          distanceFilter: 5,
        ),
      ).listen(
        (position) {
          if (_disposed || !isMonitoring) {
            return;
          }

          unawaited(_onPosition(position));
        },
        onError: (Object error) {
          if (_disposed || !isMonitoring) {
            return;
          }

          errorMessage =
              'GPS update failed: $error';

          _safeNotify();
        },
      );
    } finally {
      if (!_disposed) {
        isLoading = false;
        _safeNotify();
      }
    }
  }

  // ---------------------------------------------------------------------------
  // STOP MONITORING
  // ---------------------------------------------------------------------------

  Future<void> stopMonitoring() async {
    if (_disposed) {
      return;
    }

    isMonitoring = false;

    await _positionSubscription?.cancel();

    if (_disposed) {
      return;
    }

    _positionSubscription = null;

    // Do not let an audio problem affect GPS monitoring.
    await _stopWarning();

    if (_disposed) {
      return;
    }

    speedKmh = 0;

    context = null;
    nearbyAlerts = [];

    _lastPosition = null;

    _lastContextAt = null;
    _lastAlertsAt = null;

    _contextBusy = false;
    _alertsBusy = false;

    _warningLogged = false;
    _vibrated = false;

    errorMessage = null;

    _safeNotify();
  }

  // ---------------------------------------------------------------------------
  // GPS POSITION
  // ---------------------------------------------------------------------------

  Future<void> _onPosition(
    Position position,
  ) async {
    if (_disposed || !isMonitoring) {
      return;
    }

    // -------------------------------------------------------------------------
    // 1. Calculate speed immediately.
    // -------------------------------------------------------------------------

    final measuredSpeed =
        position.speed.isFinite &&
                position.speed >= 0
            ? position.speed * 3.6
            : null;

    double nextSpeed = measuredSpeed ?? 0;

    // If GPS does not provide speed, calculate it from positions.
    if (measuredSpeed == null &&
        _lastPosition != null) {
      final previous = _lastPosition!;

      final seconds =
          position.timestamp
                  .difference(previous.timestamp)
                  .inMilliseconds /
              1000;

      if (seconds > 0) {
        final meters =
            Geolocator.distanceBetween(
          previous.latitude,
          previous.longitude,
          position.latitude,
          position.longitude,
        );

        nextSpeed =
            (meters / seconds) * 3.6;
      }
    }

    _lastPosition = position;

    speedKmh =
        nextSpeed.clamp(0, 300).toDouble();

    // Show speed immediately.
    _safeNotify();

    if (_disposed || !isMonitoring) {
      return;
    }

    final now = DateTime.now();

    // -------------------------------------------------------------------------
    // 2. Road context.
    // -------------------------------------------------------------------------

    final refreshContext =
        _lastContextAt == null ||
            now
                    .difference(_lastContextAt!)
                    .inSeconds >=
                10;

    if (refreshContext && !_contextBusy) {
      _contextBusy = true;
      _lastContextAt = now;

      unawaited(
        _loadRoadContext(position),
      );
    }

    // -------------------------------------------------------------------------
    // 3. Nearby alerts.
    // -------------------------------------------------------------------------

    final refreshAlerts = _settings.nearbyAlerts &&
        (_lastAlertsAt == null ||
            now.difference(_lastAlertsAt!).inSeconds >= 10);

    if (refreshAlerts && !_alertsBusy) {
      _alertsBusy = true;
      _lastAlertsAt = now;

      unawaited(
        _loadNearbyAlerts(position),
      );
    }

    // -------------------------------------------------------------------------
    // 4. Speed warning.
    // -------------------------------------------------------------------------

    await _updateSpeedWarning(position);
  }

  // ---------------------------------------------------------------------------
  // ROAD CONTEXT
  // ---------------------------------------------------------------------------

  Future<void> _loadRoadContext(
    Position position,
  ) async {
    try {
      final result =
          await _repository.getContext(
        latitude: position.latitude,
        longitude: position.longitude,
        speedKmh: speedKmh,
      );

      if (_disposed || !isMonitoring) {
        return;
      }

      context = result;

      errorMessage = null;

      _safeNotify();

      if (_disposed || !isMonitoring) {
        return;
      }

      await _updateSpeedWarning(position);
    } catch (e) {
      if (_disposed || !isMonitoring) {
        return;
      }

      /*
       * Keep the previous road context if one already exists.
       */
      if (context == null) {
        errorMessage =
            e.toString().replaceFirst(
                  'Exception: ',
                  '',
                );
      }

      _safeNotify();
    } finally {
      _contextBusy = false;
    }
  }

  // ---------------------------------------------------------------------------
  // NEARBY ALERTS
  // ---------------------------------------------------------------------------

  Future<void> _loadNearbyAlerts(
    Position position,
  ) async {
    try {
      final alerts =
          await _repository.nearbyAlerts(
        latitude: position.latitude,
        longitude: position.longitude,
      );

      if (_disposed || !isMonitoring) {
        return;
      }

      nearbyAlerts = _settings.nearbyAlerts ? alerts : [];

      _safeNotify();
    } catch (_) {
      // Keep previous alerts if refresh fails.
    } finally {
      _alertsBusy = false;
    }
  }

  // ---------------------------------------------------------------------------
  // SPEED WARNING
  // ---------------------------------------------------------------------------

  Future<void> _updateSpeedWarning(
    Position position,
  ) async {
    if (_disposed || !isMonitoring) {
      return;
    }

    final limit =
        context?.speedLimitKmh;

    /*
     * IMPORTANT:
     *
     * If the backend has not provided a speed limit,
     * do not touch the audio player.
     */
    if (limit == null) {
      _warningLogged = false;
      _vibrated = false;
      return;
    }

    final speeding =
        speedKmh > limit;

    if (speeding) {
      final retryAt = _nextEventAttemptAt;
      final mayLog = retryAt == null || DateTime.now().isAfter(retryAt);

      if (!_warningLogged && mayLog) {
        _warningLogged = true;

        unawaited(_logSpeedEvent(position, limit));
      }

      /*
       * Audio is completely disabled on Web.
       *
       * Chrome audio was causing the LiveSafetyViewModel
       * to continue using an already disposed AudioPlayer.
       */
      if (!kIsWeb && !_disposed) {
        if (_settings.speedSound) {
          await _startWarning();
        } else {
          await _stopWarning();
        }
      }

      // One short vibration each time the driver goes over the limit.
      if (_settings.vibration && !_vibrated) {
        _vibrated = true;
        unawaited(HapticFeedback.vibrate());
      }
    } else {
      _warningLogged = false;
      _vibrated = false;

      if (!kIsWeb && !_disposed) {
        await _stopWarning();
      }
    }

    if (!_disposed) {
      _safeNotify();
    }
  }

  // ---------------------------------------------------------------------------
  // SPEED EVENT LOGGING
  // ---------------------------------------------------------------------------

  Future<void> _logSpeedEvent(
    Position position,
    double limit,
  ) async {
    final sent = await _repository.recordUnsafeSpeed(
      latitude: position.latitude,
      longitude: position.longitude,
      speedKmh: speedKmh,
      speedLimitKmh: limit,
    );

    if (sent) {
      _nextEventAttemptAt = null;
      return;
    }

    // Not stored (offline, expired session...). Allow another attempt shortly
    // instead of waiting for the driver to slow down and speed up again.
    if (!_disposed) {
      _warningLogged = false;
      _nextEventAttemptAt =
          DateTime.now().add(const Duration(seconds: 20));
    }
  }

  // ---------------------------------------------------------------------------
  // AUDIO
  // ---------------------------------------------------------------------------

  Future<void> _startWarning() async {
    if (_disposed || kIsWeb) {
      return;
    }

    try {
      if (_player.state ==
          PlayerState.playing) {
        return;
      }

      await _player.setReleaseMode(
        ReleaseMode.loop,
      );

      if (_disposed) {
        return;
      }

      await _player.play(
        AssetSource(
          'sounds/speed_alert.wav',
        ),
      );
    } catch (e) {
      /*
       * Audio must NEVER stop GPS monitoring.
       */
      debugPrint(
        'Speed warning audio error: $e',
      );
    }
  }

  Future<void> _stopWarning() async {
    /*
     * Web audio is disabled.
     */
    if (kIsWeb || _disposed) {
      return;
    }

    try {
      if (_player.state ==
              PlayerState.playing ||
          _player.state ==
              PlayerState.paused) {
        await _player.stop();
      }
    } catch (e) {
      debugPrint(
        'Speed warning stop error: $e',
      );
    }
  }

  // ---------------------------------------------------------------------------
  // SAFE NOTIFY
  // ---------------------------------------------------------------------------

  void _safeNotify() {
    if (_disposed) {
      return;
    }

    notifyListeners();
  }

  // ---------------------------------------------------------------------------
  // DISPOSE
  // ---------------------------------------------------------------------------

  @override
  void dispose() {
    if (_disposed) {
      return;
    }

    _disposed = true;
    isMonitoring = false;

    _positionSubscription?.cancel();
    _positionSubscription = null;

    /*
     * AudioPlayer is not needed on Flutter Web.
     */
    if (!kIsWeb) {
      try {
        unawaited(
          _player.stop().catchError(
            (_) {},
          ),
        );
      } catch (_) {}

      try {
        _player.dispose();
      } catch (_) {}
    }

    super.dispose();
  }
}

// -----------------------------------------------------------------------------
// PROVIDER
// -----------------------------------------------------------------------------

// Not autoDispose: GPS safety keeps running while the user moves between screens and stops
// only when they press Stop or log out.
final liveSafetyProvider =
    ChangeNotifierProvider<
        LiveSafetyViewModel>(
  (ref) {
    /*
     * IMPORTANT:
     *
     * DO NOT call:
     *
     * ref.onDispose(vm.dispose);
     *
     * autoDispose already disposes the ChangeNotifier.
     */

    final vm = LiveSafetyViewModel(
      repository: ref.read(
        safetyRepositoryProvider,
      ),
    );

    // Follow the switches in Settings > Notifications without restarting monitoring.
    vm.applySettings(ref.read(notificationSettingsProvider));

    ref.listen<NotificationSettings>(
      notificationSettingsProvider,
      (previous, next) => vm.applySettings(next),
    );

    return vm;
  },
);