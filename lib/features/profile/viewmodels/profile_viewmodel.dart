import 'dart:typed_data';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/models/user.dart';
import '../data/profile_repository.dart';

class ProfileState {
  const ProfileState({this.user, this.isLoading = false, this.isSaving = false, this.error});
  final User? user;
  final bool isLoading;
  final bool isSaving;
  final String? error;

  ProfileState copyWith({User? user, bool? isLoading, bool? isSaving, String? error, bool clearError = false}) => ProfileState(
    user: user ?? this.user,
    isLoading: isLoading ?? this.isLoading,
    isSaving: isSaving ?? this.isSaving,
    error: clearError ? null : error ?? this.error,
  );
}

class ProfileViewModel extends StateNotifier<ProfileState> {
  ProfileViewModel(this._repo) : super(const ProfileState());
  final ProfileRepository _repo;

  /// Forget the previous account (used after log out / before a new session).
  void reset() => state = const ProfileState();

  Future<void> load() async {
    state = state.copyWith(isLoading: true, clearError: true);
    try {
      final user = await _repo.getMe();
      state = state.copyWith(user: user, isLoading: false, clearError: true);
    } catch (e) {
      state = state.copyWith(isLoading: false, error: _clean(e));
    }
  }

  Future<bool> save({required String fullName, required String phone}) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final user = await _repo.updateMe(fullName: fullName, phone: phone);
      state = state.copyWith(user: user, isSaving: false, clearError: true);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _clean(e));
      return false;
    }
  }

  Future<bool> uploadImage(Uint8List bytes, String filename) async {
    state = state.copyWith(isSaving: true, clearError: true);
    try {
      final path = await _repo.uploadProfileImage(bytes, filename);
      final current = state.user;
      if (current != null) state = state.copyWith(user: current.copyWith(profileImageUrl: path), isSaving: false, clearError: true);
      else await load();
      state = state.copyWith(isSaving: false);
      return true;
    } catch (e) {
      state = state.copyWith(isSaving: false, error: _clean(e));
      return false;
    }
  }

  String _clean(Object e) => e.toString().replaceFirst('Exception: ', '');
}

final profileViewModelProvider = StateNotifierProvider<ProfileViewModel, ProfileState>((ref) => ProfileViewModel(ref.read(profileRepositoryProvider)));
