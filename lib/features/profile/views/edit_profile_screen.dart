import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/profile_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class EditProfileScreen extends ConsumerStatefulWidget {
  const EditProfileScreen({super.key});
  @override ConsumerState<EditProfileScreen> createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends ConsumerState<EditProfileScreen> {
  final _name = TextEditingController();
  final _phone = TextEditingController();
  final _email = TextEditingController();
  bool _initialised = false;

  @override
  void dispose() { _name.dispose(); _phone.dispose(); _email.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(profileViewModelProvider);
    final user = state.user;
    if (!_initialised && user != null) {
      _initialised = true;
      _name.text = user.fullName;
      _phone.text = user.phone ?? '';
      _email.text = user.email;
    }
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(backgroundColor: Colors.white, iconTheme: IconThemeData(color: appColors.navy), title: Text('Edit Profile', style: TextStyle(color: appColors.navy, fontWeight: FontWeight.w700))),
      body: state.isLoading && user == null ? const Center(child: CircularProgressIndicator()) : ListView(padding: const EdgeInsets.all(24), children: [
        TextField(controller: _name, decoration: const InputDecoration(labelText: 'Full name')),
        const SizedBox(height: 16),
        TextField(controller: _email, readOnly: true, decoration: const InputDecoration(labelText: 'Email')),
        const SizedBox(height: 16),
        TextField(controller: _phone, keyboardType: TextInputType.phone, decoration: const InputDecoration(labelText: 'Phone')),
        if (state.error != null) ...[const SizedBox(height: 12), Text(state.error!, style: TextStyle(color: appColors.danger))],
        const SizedBox(height: 24),
        ElevatedButton(onPressed: state.isSaving ? null : () async {
          final ok = await ref.read(profileViewModelProvider.notifier).save(fullName: _name.text, phone: _phone.text);
          if (!mounted) return;
          if (ok) { ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Profile updated successfully.'))); Navigator.of(context).pop(); }
        }, style: ElevatedButton.styleFrom(backgroundColor: appColors.amber, foregroundColor: appColors.navy, minimumSize: const Size.fromHeight(52), shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14))), child: state.isSaving ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2)) : const Text('Save Changes', style: TextStyle(fontWeight: FontWeight.w700))),
      ]),
    );
  }
}
