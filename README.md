# Adiss Road Flutter (AAGuardian)

Road-safety Flutter client using MVVM + Riverpod. It talks to `Adiss_road_backend`
(FastAPI). Everything citizens submit here appears on the police dashboard:

| In the app                         | Backend endpoint                 | Shows up on the dashboard        |
|------------------------------------|----------------------------------|----------------------------------|
| Submit report (+ optional photo, road/place) | `POST /safety/accident-reports`, `POST /safety/evidence` | Reports, Map, Overview |
| Live speed monitoring over the limit | `POST /safety/events`          | Analytics > Behaviour events     |
| My Reports                         | `GET /safety/accident-reports`   | status set by police is shown here |

## Run

Start the backend first (`uvicorn app.main:app --port 8001` in `Adiss_road_backend`),
then:

```bash
flutter clean
flutter pub get
flutter run -d chrome                       # web: uses http://127.0.0.1:8001
flutter run -d emulator-5554                # Android emulator: uses http://10.0.2.2:8001
```

Physical phone (same Wi-Fi as your computer). Start the backend with
`--host 0.0.0.0`, then pass your computer's LAN IP:

```bash
flutter run --dart-define=API_URL=http://192.168.1.20:8001/api/v1
```

Debug builds allow plain `http://`; release builds must use `https://`.

## Fingerprint login

- **Turn it on:** Profile > Settings > *Fingerprint login*. You confirm your fingerprint once; the
  app creates a device key (ECDSA P-256). Only the PUBLIC key is sent to the backend. The private
  key stays in the phone's secure storage.
- **Use it:** after you turned it on, the login screen shows *Sign in with fingerprint*. The app asks
  the backend for a one-time challenge, signs it with the device key and the backend returns the
  tokens. No password is sent.
- **Turn it off:** the same switch in Settings (the backend forgets the key).
- **Needs:** a real phone or emulator with a fingerprint enrolled in the phone settings. Not
  available on web. Android emulator: Extended controls (...) > Fingerprint > Touch sensor.
- **Setup already done in this project:** `local_auth` and `pointycastle` in `pubspec.yaml`,
  `USE_BIOMETRIC` permission, `FlutterFragmentActivity` and an AppCompat launch theme on Android,
  `NSFaceIDUsageDescription` on iOS. Run `flutter pub get` once.

## Notifications (Profile > Settings)

While Live Road Safety (GPS safety) is on, the app can warn the driver. Each warning has a
real switch, saved on the phone:

| Switch                 | What it does                                                   |
|------------------------|----------------------------------------------------------------|
| Speed warning sound    | Repeating alarm while over the road's speed limit (phone app only; not on web) |
| Vibration              | One vibration each time the speed goes over the limit (phone app only) |
| Nearby incident alerts | Shows crashes/hazards reported by other users near you          |

These are in-app warnings. The app does not send push notifications while it is closed.

## Notes

- Road or place: the report form fills it in from GPS when it opens (tap the GPS button to
  detect again). If the map has no name for that road, type it. The reporter's text is what
  the police see. An emergency report can be sent without a name, because its exact GPS
  position is always included.
- Speed events: up to 10 km/h over the posted limit is logged as
  `speed_limit_warning`, more than that as `unsafe_speed`. A failed upload is retried
  after 20 seconds instead of being dropped.
- Registration and password reset email a 6-digit code. With no SMTP settings in the
  backend `.env`, the code is printed in the backend console instead.
