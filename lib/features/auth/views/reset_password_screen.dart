import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_theme.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key, this.email = ''});

  /// The account the code was sent to (passed from the forgot-password screen).
  final String email;

  @override
  ConsumerState<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends ConsumerState<ResetPasswordScreen> {
  final _token = TextEditingController();
  final _newPassword = TextEditingController();
  final _confirmPassword = TextEditingController();

  bool _obscureNew = true;
  bool _obscureConfirm = true;
  bool _busy = false;

  final Color brightNavy = const Color(0xFF244A96);
  final Color navy = const Color(0xFF173B82);
  final Color amber = const Color(0xFFFFB900);
  final Color background = const Color(0xFFF6F8FC);
  final Color border = const Color(0xFFE1E6EF);
  final Color muted = const Color(0xFF718096);

  int get _strengthScore {
    final password = _newPassword.text;
    var score = 0;

    if (password.length >= 8) score++;
    if (password.contains(RegExp(r'[A-Z]'))) score++;
    if (password.contains(RegExp(r'[0-9]'))) score++;
    if (password.contains(RegExp(r'[^A-Za-z0-9]'))) score++;

    return score;
  }

  String get _strengthLabel {
    switch (_strengthScore) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Strong';
      default:
        return '';
    }
  }

  Color get _strengthColor {
    switch (_strengthScore) {
      case 1:
        return appColors.danger;
      case 2:
        return Colors.orange;
      case 3:
        return Colors.amber;
      case 4:
        return appColors.success;
      default:
        return Colors.grey.shade300;
    }
  }

  bool get _passwordValid {
    return _newPassword.text.length >= 8 &&
        _newPassword.text.contains(RegExp(r'[A-Z]')) &&
        _newPassword.text.contains(RegExp(r'[0-9]')) &&
        _newPassword.text.contains(RegExp(r'[^A-Za-z0-9]'));
  }

  bool get _passwordsMatch {
    return _newPassword.text.isNotEmpty &&
        _newPassword.text == _confirmPassword.text;
  }

  bool get _canSubmit {
    return _token.text.trim().length == 6 &&
        _passwordValid &&
        _passwordsMatch;
  }

  @override
  void dispose() {
    _token.dispose();
    _newPassword.dispose();
    _confirmPassword.dispose();
    super.dispose();
  }

  Future<void> _resetPassword() async {
    if (!_canSubmit || _busy) return;

    // The email arrives from the previous screen; if it is missing (for example after a page
    // refresh on web) go back and ask for a new code.
    if (widget.email.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your email again to get a new code.')),
      );
      context.go('/forgot-password');
      return;
    }

    setState(() => _busy = true);

    final ok = await ref.read(authViewModelProvider.notifier).resetPassword(
          email: widget.email,
          resetCode: _token.text.trim(),
          newPassword: _newPassword.text,
        );

    if (!mounted) return;

    setState(() => _busy = false);

    if (!ok) {
      final message = ref.read(authViewModelProvider).error ??
          'Could not reset the password. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return Dialog(
          backgroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(26),
          ),
          child: Padding(
            padding: const EdgeInsets.fromLTRB(24, 28, 24, 22),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 74,
                  height: 74,
                  decoration: BoxDecoration(
                    color: appColors.success.withOpacity(0.12),
                    shape: BoxShape.circle,
                  ),
                  child: Container(
                    margin: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: appColors.success.withOpacity(0.12),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Icon(
                      Icons.check_rounded,
                      color: appColors.success,
                      size: 36,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  'Password changed!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: navy,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 9),
                Text(
                  'Your password has been successfully updated. You can now log in with your new password.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: muted,
                    fontSize: 13,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  width: double.infinity,
                  height: 50,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                      context.go('/login');
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: amber,
                      foregroundColor: navy,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                    child: const Text(
                      'Back to Log In',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: background,
      body: SafeArea(
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 14, 20, 0),
              child: Row(
                children: [
                  GestureDetector(
                    onTap: () => context.go('/forgot-password'),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.035),
                            blurRadius: 8,
                            offset: const Offset(0, 3),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: navy,
                        size: 21,
                      ),
                    ),
                  ),
                  const Spacer(),
                  Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 42,
                        height: 42,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'AAGuardian',
                        style: TextStyle(
                          color: navy,
                          fontSize: 19,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.3,
                        ),
                      ),
                    ],
                  ),
                  const Spacer(),
                  const SizedBox(width: 44),
                ],
              ),
            ),
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.fromLTRB(24, 34, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 84,
                      height: 84,
                      decoration: BoxDecoration(
                        color: amber.withOpacity(0.13),
                        shape: BoxShape.circle,
                      ),
                      child: Container(
                        margin: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: amber.withOpacity(0.12),
                              blurRadius: 14,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.lock_reset_rounded,
                          color: brightNavy,
                          size: 38,
                        ),
                      ),
                    ),
                    const SizedBox(height: 24),
                    Text(
                      'Create a new password',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.7,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'Enter the reset code we sent you and choose a strong new password for your AAGuardian account.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 28),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 22,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _fieldLabel('Reset code'),
                          const SizedBox(height: 9),
                          TextField(
                            controller: _token,
                            keyboardType: TextInputType.number,
                            textInputAction: TextInputAction.next,
                            maxLength: 6,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              hint: 'Enter 6-digit code',
                              icon: Icons.verified_outlined,
                            ).copyWith(
                              counterText: '',
                            ),
                          ),
                          const SizedBox(height: 18),
                          _fieldLabel('New password'),
                          const SizedBox(height: 9),
                          TextField(
                            controller: _newPassword,
                            obscureText: _obscureNew,
                            textInputAction: TextInputAction.next,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              hint: 'Create a new password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureNew = !_obscureNew;
                                  });
                                },
                                icon: Icon(
                                  _obscureNew
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: muted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 13),
                          if (_newPassword.text.isNotEmpty)
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: List.generate(
                                    4,
                                    (index) {
                                      final active =
                                          index < _strengthScore;

                                      return Expanded(
                                        child: AnimatedContainer(
                                          duration: const Duration(
                                            milliseconds: 200,
                                          ),
                                          height: 5,
                                          margin: EdgeInsets.only(
                                            right: index == 3 ? 0 : 5,
                                          ),
                                          decoration: BoxDecoration(
                                            color: active
                                                ? _strengthColor
                                                : const Color(0xFFE4E8EF),
                                            borderRadius:
                                                BorderRadius.circular(5),
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 7),
                                Row(
                                  children: [
                                    Text(
                                      _strengthLabel,
                                      style: TextStyle(
                                        color: _strengthColor,
                                        fontSize: 12,
                                        fontWeight: FontWeight.w700,
                                      ),
                                    ),
                                    const Spacer(),
                                    Text(
                                      '${_strengthScore}/4',
                                      style: TextStyle(
                                        color: muted,
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          const SizedBox(height: 18),
                          _fieldLabel('Confirm password'),
                          const SizedBox(height: 9),
                          TextField(
                            controller: _confirmPassword,
                            obscureText: _obscureConfirm,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) => setState(() {}),
                            decoration: _inputDecoration(
                              hint: 'Re-enter your new password',
                              icon: Icons.lock_outline_rounded,
                              suffix: IconButton(
                                onPressed: () {
                                  setState(() {
                                    _obscureConfirm = !_obscureConfirm;
                                  });
                                },
                                icon: Icon(
                                  _obscureConfirm
                                      ? Icons.visibility_off_outlined
                                      : Icons.visibility_outlined,
                                  color: muted,
                                  size: 20,
                                ),
                              ),
                            ),
                          ),
                          if (_confirmPassword.text.isNotEmpty) ...[
                            const SizedBox(height: 8),
                            Row(
                              children: [
                                Icon(
                                  _passwordsMatch
                                      ? Icons.check_circle_rounded
                                      : Icons.error_outline_rounded,
                                  color: _passwordsMatch
                                      ? appColors.success
                                      : appColors.danger,
                                  size: 16,
                                ),
                                const SizedBox(width: 6),
                                Text(
                                  _passwordsMatch
                                      ? 'Passwords match'
                                      : 'Passwords do not match',
                                  style: TextStyle(
                                    color: _passwordsMatch
                                        ? appColors.success
                                        : appColors.danger,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          const SizedBox(height: 20),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(14),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF7F9FC),
                              borderRadius: BorderRadius.circular(14),
                              border: Border.all(
                                color: border,
                              ),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  'Password requirements',
                                  style: TextStyle(
                                    color: navy,
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(height: 10),
                                _requirement(
                                  'At least 8 characters',
                                  _newPassword.text.length >= 8,
                                ),
                                _requirement(
                                  'One uppercase letter',
                                  _newPassword.text
                                      .contains(RegExp(r'[A-Z]')),
                                ),
                                _requirement(
                                  'One number',
                                  _newPassword.text
                                      .contains(RegExp(r'[0-9]')),
                                ),
                                _requirement(
                                  'One special character',
                                  _newPassword.text.contains(
                                    RegExp(r'[^A-Za-z0-9]'),
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 22),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed:
                                  (_canSubmit && !_busy) ? _resetPassword : null,
                              style: ElevatedButton.styleFrom(
                                backgroundColor: amber,
                                disabledBackgroundColor:
                                    const Color(0xFFDDE2EA),
                                foregroundColor: navy,
                                disabledForegroundColor:
                                    const Color(0xFF929AAA),
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(15),
                                ),
                              ),
                              child: Row(
                                mainAxisAlignment:
                                    MainAxisAlignment.center,
                                children: [
                                  Text(
                                    _busy ? 'Saving...' : 'Set New Password',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  const SizedBox(width: 8),
                                  Icon(
                                    _canSubmit
                                        ? Icons.check_rounded
                                        : Icons.arrow_forward_rounded,
                                    size: 19,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 20),
                    const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Color(0xFF8A95A6),
                          size: 15,
                        ),
                        SizedBox(width: 6),
                        Text(
                          'Your password is securely encrypted',
                          style: TextStyle(
                            color: Color(0xFF8A95A6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 24),
                    GestureDetector(
                      onTap: () => context.go('/login'),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.arrow_back_rounded,
                            color: brightNavy,
                            size: 17,
                          ),
                          SizedBox(width: 6),
                          Text(
                            'Back to Login',
                            style: TextStyle(
                              color: brightNavy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _fieldLabel(String text) {
    return Text(
      text,
      style: TextStyle(
        color: navy,
        fontSize: 13,
        fontWeight: FontWeight.w800,
      ),
    );
  }

  InputDecoration _inputDecoration({
    required String hint,
    required IconData icon,
    Widget? suffix,
  }) {
    return InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(
        color: Color(0xFFA5ADBA),
        fontSize: 13,
      ),
      prefixIcon: Icon(
        icon,
        color: brightNavy,
        size: 20,
      ),
      suffixIcon: suffix,
      filled: true,
      fillColor: const Color(0xFFF8FAFC),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 17,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: border,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: border,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: brightNavy,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _requirement(String text, bool valid) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 7),
      child: Row(
        children: [
          Icon(
            valid
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: valid
                ? appColors.success
                : const Color(0xFFA5ADBA),
            size: 16,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: valid ? appColors.success : muted,
              fontSize: 12,
              fontWeight: valid ? FontWeight.w600 : FontWeight.w400,
            ),
          ),
        ],
      ),
    );
  }
}