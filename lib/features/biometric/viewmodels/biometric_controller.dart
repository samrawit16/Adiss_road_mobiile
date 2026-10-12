import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../data/biometric_repository.dart';

class BiometricState {
  const BiometricState({
    this.available = false,
    this.enabled = false,
    this.enrolledEmail,
    this.busy = false,
  });

  /// The phone has a fingerprint/biometric sensor with something enrolled.
  final bool available;

  /// Fingerprint login is set up on this phone.
  final bool enabled;

  /// Which account it was set up for.
  final String? enrolledEmail;

  final bool busy;

  BiometricState copyWith({bool? busy}) {
    return BiometricState(
      available: available,
      enabled: enabled,
      enrolledEmail: enrolledEmail,
      busy: busy ?? this.busy,
    );
  }
}

class BiometricController extends StateNotifier<BiometricState> {
  BiometricController(this._repo) : super(const BiometricState()) {
    refresh();
  }

  final BiometricRepository _repo;

  Future<void> refresh() async {
    final available = await _repo.isAvailable();
    final email = await _repo.enrolledEmail();
    final enabled = await _repo.isEnabledOnDevice();

    if (!mounted) return;

    state = BiometricState(
      available: available,
      enabled: enabled,
      enrolledEmail: email,
    );
  }

  /// Returns null on success, or a message to show to the user.
  Future<String?> setEnabled(bool on, {required String email}) async {
    state = state.copyWith(busy: true);

    try {
      if (on) {
        await _repo.enable(email: email);
      } else {
        await _repo.disable();
      }

      await refresh();
      return null;
    } on BiometricException catch (e) {
      await refresh();
      return e.message;
    } catch (_) {
      await refresh();
      return 'Something went wrong. Please try again.';
    }
  }
}

final biometricControllerProvider =
    StateNotifierProvider<BiometricController, BiometricState>(
  (ref) => BiometricController(ref.read(biometricRepositoryProvider)),
);
