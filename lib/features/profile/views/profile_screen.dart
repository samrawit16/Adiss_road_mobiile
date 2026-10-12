import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/constants/api_constants.dart';
import '../../../core/localization/app_localizations.dart';
import '../../auth/viewmodels/auth_viewmodel.dart';
import '../../alerts/data/safety_repository.dart';
import '../../alerts/viewmodels/live_safety_viewmodel.dart';
import '../../notifications/viewmodels/notifications_viewmodel.dart';
import '../viewmodels/profile_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class ProfileScreen extends ConsumerStatefulWidget {
  const ProfileScreen({super.key});
  @override ConsumerState<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends ConsumerState<ProfileScreen> {
  int _reportCount = 0;
  bool _reportsLoading = true;
  final _picker = ImagePicker();

  @override
  void initState() {
    super.initState();
    Future.microtask(() {
      ref.read(profileViewModelProvider.notifier).load();
      _loadReportCount();
    });
  }

  Future<void> _loadReportCount() async {
    try {
      final reports = await ref.read(safetyRepositoryProvider).myReports();
      if (mounted) setState(() => _reportCount = reports.length);
    } catch (_) {}
    if (mounted) setState(() => _reportsLoading = false);
  }

  Future<void> _pickImage() async {
    final file = await _picker.pickImage(source: ImageSource.gallery, imageQuality: 85, maxWidth: 1200);
    if (file == null) return;
    final bytes = await file.readAsBytes();
    await ref.read(profileViewModelProvider.notifier).uploadImage(bytes, file.name);
  }

  String _imageUrl(String path) {
    if (path.startsWith('http://') || path.startsWith('https://')) return path;
    return '${apiConstants.baseUrl.replaceFirst('/api/v1', '')}$path';
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final user = state.user;
    final l10n = appLocalizations.of(context);
    return Scaffold(
      backgroundColor: appColors.bgLight,
      appBar: AppBar(title: Text(l10n.t('profile'), style: TextStyle(color: appColors.navy, fontWeight: FontWeight.w800))),
      body: RefreshIndicator(
        onRefresh: () async { await ref.read(profileViewModelProvider.notifier).load(); await _loadReportCount(); },
        child: ListView(padding: const EdgeInsets.all(16), children: [
          Card(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(children: [
              GestureDetector(
                onTap: state.isSaving ? null : _pickImage,
                child: Stack(children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: appColors.amber,
                    backgroundImage: user?.profileImageUrl == null ? null : NetworkImage(_imageUrl(user!.profileImageUrl!)),
                    child: user?.profileImageUrl == null ? const Icon(Icons.person, size: 44, color: Colors.white) : null,
                  ),
                  Positioned(right: 0, bottom: 0, child: CircleAvatar(radius: 15, backgroundColor: appColors.navy, child: const Icon(Icons.camera_alt, size: 15, color: Colors.white))),
                ]),
              ),
              const SizedBox(height: 10),
              if (state.isLoading && user == null) const CircularProgressIndicator() else Text(user?.fullName.isNotEmpty == true ? user!.fullName : 'User', style: const TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
              if (user != null) Text(user.email, style: TextStyle(color: appColors.textMuted)),
              if (user?.phone != null) Text(user!.phone!, style: TextStyle(color: appColors.textMuted)),
              if (state.error != null) Padding(padding: const EdgeInsets.only(top: 8), child: Text(state.error!, style: TextStyle(color: appColors.danger))),
              const SizedBox(height: 16),
              Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                _stat(_reportsLoading ? '—' : '$_reportCount', 'Reports'),
                _stat(user?.isVerified == true ? 'Yes' : 'No', 'Verified'),
                _stat(user?.createdAt?.year.toString() ?? '—', 'Since'),
              ]),
            ]),
          )),
          const SizedBox(height: 16),
          Card(color: Colors.white, shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(18)), child: Column(children: [
            _menu(context, Icons.person_outline, l10n.t('editProfile'), '/profile/edit'),
            _menu(context, Icons.notifications_none, l10n.t('notifications'), '/profile/settings'),
            _menu(context, Icons.language, l10n.t('language'), '/profile/settings'),
            _menu(context, Icons.lock_outline, l10n.t('privacy'), '/profile/settings'),
          ])),
          const SizedBox(height: 16),
          SizedBox(width: double.infinity, child: OutlinedButton.icon(onPressed: () async { await ref.read(authViewModelProvider.notifier).logout(); ref.invalidate(liveSafetyProvider); ref.invalidate(notificationsProvider); ref.invalidate(profileViewModelProvider); if (context.mounted) context.go('/login'); }, icon: Icon(Icons.logout, color: appColors.danger), label: Text(l10n.t('logout'), style: TextStyle(color: appColors.danger)), style: OutlinedButton.styleFrom(side: BorderSide(color: appColors.danger), minimumSize: const Size.fromHeight(48), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))))),
        ]),
      ),
    );
  }

  Widget _menu(BuildContext context, IconData icon, String title, String route) => ListTile(leading: Icon(icon, color: appColors.navy), title: Text(title), trailing: Icon(Icons.chevron_right, color: appColors.textMuted), onTap: () => context.go(route));
  Widget _stat(String value, String label) => Column(children: [Text(value, style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, color: appColors.navy)), Text(label, style: TextStyle(color: appColors.textMuted, fontSize: 12))]);
}
