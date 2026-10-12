import 'package:dio/dio.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../viewmodels/auth_viewmodel.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _name = TextEditingController();
  final _email = TextEditingController();
  final _phone = TextEditingController();
  final _password = TextEditingController();
  final _confirm = TextEditingController();

  bool _obscure1 = true;
  bool _obscure2 = true;
  bool _loading = false;
  String? _error;

  bool get _lenOk => _password.text.length >= 8;

  bool get _upperOk => _password.text.contains(RegExp(r'[A-Z]'));

  bool get _numOk => _password.text.contains(RegExp(r'[0-9]'));

  bool get _specialOk =>
      _password.text.contains(RegExp(r'[!@#$%^&*(),.?":{}|<>]'));

  bool get _phoneOk {
    final phone = _phone.text.trim();
    return RegExp(r'^[79][0-9]{8}$').hasMatch(phone);
  }

  bool get _emailOk {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(_email.text.trim());
  }

  bool get _nameOk {
    return _name.text.trim().length >= 2;
  }

  bool get _passwordsMatch {
    return _password.text.isNotEmpty &&
        _password.text == _confirm.text;
  }

  bool get _canRegister {
    return _nameOk &&
        _emailOk &&
        _phoneOk &&
        _lenOk &&
        _upperOk &&
        _numOk &&
        _specialOk &&
        _passwordsMatch &&
        !_loading;
  }

  @override
  void dispose() {
    _name.dispose();
    _email.dispose();
    _phone.dispose();
    _password.dispose();
    _confirm.dispose();
    super.dispose();
  }

  InputDecoration _decoration(
    String label,
    String hint, {
    Widget? suffix,
    Widget? prefix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      hintStyle: TextStyle(
        color: appColors.textMuted,
        fontSize: 13,
      ),
      labelStyle: TextStyle(
        color: appColors.textMuted,
        fontSize: 12,
      ),
      filled: true,
      fillColor: appColors.navyDark,
      prefixIcon: prefix,
      suffixIcon: suffix,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: appColors.navyLight,
        ),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: appColors.navyLight,
        ),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide(
          color: appColors.amber,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _register() async {
    if (!_canRegister) return;

    FocusScope.of(context).unfocus();

    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final name = _name.text.trim();
      final email = _email.text.trim().toLowerCase();
      final phone = _phone.text.trim();
      final password = _password.text;

      final success = await ref.read(authViewModelProvider.notifier).register(
        fullName: name,
        email: email,
        phone: phone,
        password: password,
      );

      if (!mounted) return;
      if (!success) {
        setState(() {
          _error = ref.read(authViewModelProvider).error ?? 'Registration failed';
        });
        return;
      }

      context.go(
        '/verify?email=${Uri.encodeComponent(email)}',
      );
    } on DioException catch (e) {
      if (!mounted) return;

      String message = 'Could not connect to the server.';

      if (e.response?.data is Map) {
        final data = e.response!.data as Map;

        if (data['detail'] is String) {
          message = data['detail'];
        } else if (data['message'] is String) {
          message = data['message'];
        } else if (data['detail'] is List &&
            (data['detail'] as List).isNotEmpty) {
          final first = (data['detail'] as List).first;

          if (first is Map && first['msg'] is String) {
            message = first['msg'];
          }
        }
      } else if (e.message != null &&
          e.message!.trim().isNotEmpty) {
        message = e.message!;
      }

      setState(() {
        _error = message;
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Something went wrong. Please try again.';
        _loading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: appColors.navyDark,
      body: Stack(
        children: [
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.47,
            child: Image.asset(
              'assets/images/adiss.png',
              fit: BoxFit.cover,
              alignment: Alignment.topCenter,
              errorBuilder: (_, __, ___) {
                return Container(
                  color: appColors.navy,
                );
              },
            ),
          ),
          Positioned(
            top: 0,
            left: 0,
            right: 0,
            height: screenHeight * 0.50,
            child: IgnorePointer(
              child: Container(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [
                      Colors.black.withOpacity(0.05),
                      Colors.black.withOpacity(0.05),
                      appColors.navyDark.withOpacity(0.10),
                      appColors.navyDark.withOpacity(0.55),
                      appColors.navyDark.withOpacity(0.96),
                      appColors.navyDark,
                    ],
                    stops: const [
                      0.00,
                      0.30,
                      0.48,
                      0.68,
                      0.88,
                      1.00,
                    ],
                  ),
                ),
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 50,
                        height: 50,
                        fit: BoxFit.contain,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'AAGuardian',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 22,
                          fontWeight: FontWeight.w700,
                          letterSpacing: 0.2,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 8,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                      ),
                      const Spacer(),
                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () => context.go('/login'),
                        child: const Padding(
                          padding: EdgeInsets.all(8),
                          child: Text(
                            'Cancel',
                            style: TextStyle(
                              color: Colors.white70,
                              fontSize: 14,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 130),
                  const Text(
                    'Create your account',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 29,
                      fontWeight: FontWeight.w800,
                      height: 1.1,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 8,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Join AAGuardian and help build safer roads\n'
                    'for everyone in Addis Ababa.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.4,
                      shadows: [
                        Shadow(
                          color: Colors.black54,
                          blurRadius: 6,
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                  TextField(
                    controller: _name,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    textCapitalization: TextCapitalization.words,
                    onChanged: (_) {
                      setState(() {
                        _error = null;
                      });
                    },
                    decoration: _decoration(
                      'Full name',
                      'e.g. Samrawit Yisak',
                      prefix: Icon(
                        Icons.person_outline,
                        color: appColors.amber,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _email,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    keyboardType: TextInputType.emailAddress,
                    onChanged: (_) {
                      setState(() {
                        _error = null;
                      });
                    },
                    decoration: _decoration(
                      'Email address',
                      'samri@email.com',
                      prefix: Icon(
                        Icons.mail_outline,
                        color: appColors.amber,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    height: 64,
                    decoration: BoxDecoration(
                      color: appColors.navyDark,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: _phoneOk
                            ? appColors.amber
                            : appColors.navyLight,
                        width: _phoneOk ? 1.5 : 1,
                      ),
                    ),
                    child: Row(
                      children: [
                        const SizedBox(width: 14),
                        Icon(
                          Icons.phone_outlined,
                          color: appColors.amber,
                          size: 22,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: TextField(
                            controller: _phone,
                            keyboardType: TextInputType.phone,
                            maxLength: 9,
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                            onChanged: (_) {
                              setState(() {
                                _error = null;
                              });
                            },
                            decoration: InputDecoration(
                              counterText: '',
                              border: InputBorder.none,
                              hintText: '9XX XXX XXX',
                              hintStyle: TextStyle(
                                color: appColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                          ),
                        ),
                        if (_phoneOk)
                          Padding(
                            padding: EdgeInsets.only(right: 14),
                            child: Icon(
                              Icons.check_circle,
                              color: appColors.amber,
                              size: 19,
                            ),
                          ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _password,
                    obscureText: _obscure1,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    onChanged: (_) {
                      setState(() {
                        _error = null;
                      });
                    },
                    decoration: _decoration(
                      'Password',
                      'Create a strong password',
                      prefix: Icon(
                        Icons.lock_outline,
                        color: appColors.amber,
                        size: 22,
                      ),
                      suffix: IconButton(
                        icon: Icon(
                          _obscure1
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: appColors.textMuted,
                          size: 21,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure1 = !_obscure1;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  TextField(
                    controller: _confirm,
                    obscureText: _obscure2,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                    onChanged: (_) {
                      setState(() {
                        _error = null;
                      });
                    },
                    decoration: _decoration(
                      'Confirm password',
                      'Re-enter your password',
                      prefix: Icon(
                        Icons.lock_outline,
                        color: appColors.amber,
                        size: 22,
                      ),
                      suffix: IconButton(
                        icon: Icon(
                          _obscure2
                              ? Icons.visibility_off_outlined
                              : Icons.visibility_outlined,
                          color: appColors.textMuted,
                          size: 21,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscure2 = !_obscure2;
                          });
                        },
                      ),
                    ),
                  ),
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(15),
                    decoration: BoxDecoration(
                      color: appColors.navy,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: appColors.navyLight.withOpacity(0.65),
                      ),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            Icon(
                              Icons.shield_outlined,
                              color: appColors.amber,
                              size: 19,
                            ),
                            SizedBox(width: 8),
                            Text(
                              'Password must include:',
                              style: TextStyle(
                                color: Colors.white,
                                fontWeight: FontWeight.w700,
                                fontSize: 13,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 9),
                        _req('At least 8 characters', _lenOk),
                        _req('One uppercase letter', _upperOk),
                        _req('One number', _numOk),
                        _req(
                          'One special character',
                          _specialOk,
                        ),
                      ],
                    ),
                  ),
                  if (_error != null) ...[
                    const SizedBox(height: 12),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.symmetric(
                        horizontal: 13,
                        vertical: 11,
                      ),
                      decoration: BoxDecoration(
                        color: const Color(0xFF7A2144).withOpacity(0.30),
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(
                          color: const Color(0xFFE5395F).withOpacity(0.55),
                        ),
                      ),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Icon(
                            Icons.error_outline_rounded,
                            color: Color(0xFFFF6B81),
                            size: 18,
                          ),
                          const SizedBox(width: 9),
                          Expanded(
                            child: Text(
                              _error!,
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                height: 1.4,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                  const SizedBox(height: 20),
                  Container(
                    width: double.infinity,
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(14),
                      boxShadow: [
                        BoxShadow(
                          color: appColors.amber.withOpacity(0.16),
                          blurRadius: 7,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: ElevatedButton(
                      onPressed: _canRegister ? _register : null,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: appColors.amber,
                        disabledBackgroundColor:
                            appColors.navyLight,
                        disabledForegroundColor:
                            appColors.textMuted,
                        foregroundColor: appColors.navyDark,
                        padding: const EdgeInsets.symmetric(
                          vertical: 16,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        elevation: 0,
                      ),
                      child: _loading
                          ? SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                strokeWidth: 2.5,
                                color: appColors.navyDark,
                              ),
                            )
                          : const Row(
                              mainAxisAlignment:
                                  MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Create Account',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                SizedBox(width: 7),
                                Icon(
                                  Icons.arrow_forward,
                                  size: 19,
                                ),
                              ],
                            ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Already have an account? ',
                        style: TextStyle(
                          color: appColors.textMuted,
                          fontSize: 13,
                        ),
                      ),
                      GestureDetector(
                        onTap: _loading
                            ? null
                            : () => context.go('/login'),
                        child: Text(
                          'Log In',
                          style: TextStyle(
                            color: appColors.amber,
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.verified_user_outlined,
                        color: appColors.amber,
                        size: 14,
                      ),
                      SizedBox(width: 6),
                      Text(
                        'Your data is encrypted and secure',
                        style: TextStyle(
                          color: appColors.textMuted,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 26),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _req(String text, bool ok) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          Icon(
            ok
                ? Icons.check_circle_rounded
                : Icons.radio_button_unchecked_rounded,
            color: ok
                ? appColors.amber
                : appColors.textMuted,
            size: 15,
          ),
          const SizedBox(width: 8),
          Text(
            text,
            style: TextStyle(
              color: ok ? Colors.white : Colors.white70,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}