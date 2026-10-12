import 'package:flutter/material.dart';
import '../../../core/constants/api_constants.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../core/theme/app_theme.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../biometric/data/biometric_repository.dart';

/// The single instance for this file (injected, not static).
final ApiConstants apiConstants = ApiConstants();

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _email = TextEditingController();
  final _password = TextEditingController();

  bool _obscure = true;
  bool _rememberMe = false;
  bool _loading = false;
  bool _fingerprintReady = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _checkFingerprint();
  }

  /// Show the fingerprint button only when this phone can use it and it was turned on.
  Future<void> _checkFingerprint() async {
    final repo = ref.read(biometricRepositoryProvider);
    final ready = await repo.isAvailable() && await repo.isEnabledOnDevice();

    if (mounted) setState(() => _fingerprintReady = ready);
  }

  Future<void> _fingerprintLogin() async {
    setState(() {
      _loading = true;
      _error = null;
    });

    try {
      final ok = await ref.read(biometricRepositoryProvider).login();

      if (!mounted) return;

      if (ok) {
        context.go('/home');
        return;
      }

      // The user cancelled the fingerprint prompt.
      setState(() => _loading = false);
    } on BiometricException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message;
      });

      _checkFingerprint();
    }
  }

  @override
  void dispose() {
    _email.dispose();
    _password.dispose();
    super.dispose();
  }

 Future<void> _login() async {
  final email = _email.text.trim();
  final password = _password.text;

  if (email.isEmpty || password.isEmpty) {
    setState(() {
      _error = 'Enter your email and password';
    });
    return;
  }

  setState(() {
    _loading = true;
    _error = null;
  });

  try {
    final ok = await ref.read(authViewModelProvider.notifier).login(email, password);
    if (!mounted) return;
    if (ok) {
      context.go('/home');
    } else {
      setState(() {
        _error = ref.read(authViewModelProvider).error ?? 'Login failed';
      });
    }
  } catch (e) {
    if (!mounted) return;
    setState(() {
      _error = 'DEBUG: $e';
    });
  } finally {
    if (mounted) {
      setState(() {
        _loading = false;
      });
    }
  }
}

  InputDecoration _decoration(
    String label,
    String hint, {
    Widget? prefix,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      labelStyle: TextStyle(
        color: appColors.textMuted,
        fontSize: 12,
      ),
      hintText: hint,
      hintStyle: TextStyle(
        color: appColors.textMuted,
        fontSize: 13,
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
          width: 1.6,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appColors.navyDark,
      body: Stack(
        children: [
          SizedBox(
            height: MediaQuery.of(context).size.height * 0.55,
            width: double.infinity,
            child: ShaderMask(
              shaderCallback: (rect) => LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withOpacity(0.18),
                  appColors.navyDark.withOpacity(0.48),
                  appColors.navyDark,
                ],
                stops: const [0.0, 0.58, 1.0],
              ).createShader(rect),
              blendMode: BlendMode.srcOver,
              child: Image.asset(
                'assets/images/hero_addis.png',
                fit: BoxFit.cover,
                alignment: Alignment.topCenter,
                errorBuilder: (_, __, ___) {
                  return Container(
                    color: appColors.navy,
                  );
                },
              ),
            ),
          ),
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const SizedBox(height: 10),

                  Row(
                    children: [
                      Image.asset(
                        'assets/images/logo.png',
                        width: 44,
                        height: 44,
                        fit: BoxFit.contain,
                        errorBuilder: (_, __, ___) {
                          return Icon(
                            Icons.shield_rounded,
                            color: appColors.amber,
                            size: 44,
                          );
                        },
                      ),
                      const SizedBox(width: 10),
                      const Text(
                        'AAGuardian',
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 23,
                          fontWeight: FontWeight.w800,
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
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 7,
                        ),
                        decoration: BoxDecoration(
                          color: Colors.black.withOpacity(0.32),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Colors.white.withOpacity(0.16),
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.location_on_outlined,
                              color: appColors.amber,
                              size: 15,
                            ),
                            SizedBox(width: 5),
                            Text(
                              'Addis Ababa',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 92),

                  const Text(
                    'Safer roads',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.05,
                      letterSpacing: -0.7,
                      shadows: [
                        Shadow(
                          color: Colors.black45,
                          blurRadius: 10,
                          offset: Offset(0, 2),
                        ),
                      ],
                    ),
                  ),

                  Text(
                    'for a brighter\nAddis Ababa',
                    style: TextStyle(
                      color: appColors.amber,
                      fontSize: 34,
                      fontWeight: FontWeight.w800,
                      height: 1.15,
                      letterSpacing: -0.7,
                    ),
                  ),

                  const SizedBox(height: 6),

                  Container(
                    width: 56,
                    height: 4,
                    decoration: BoxDecoration(
                      color: appColors.amber,
                      borderRadius: BorderRadius.circular(2),
                      boxShadow: [
                        BoxShadow(
                          color: appColors.amber.withOpacity(0.55),
                          blurRadius: 8,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 13),

                  const Text(
                    'Get real-time alerts, report hazards,\nand help make our roads safer together.',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      height: 1.45,
                    ),
                  ),

                  const SizedBox(height: 26),

                  Container(
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                        colors: [
                          appColors.navy.withOpacity(0.96),
                          appColors.navyDark.withOpacity(0.99),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(26),
                      border: Border.all(
                        color: appColors.amber.withOpacity(0.24),
                        width: 1.2,
                      ),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.45),
                          blurRadius: 24,
                          offset: const Offset(0, 10),
                        ),
                        BoxShadow(
                          color: appColors.amber.withOpacity(0.07),
                          blurRadius: 30,
                        ),
                      ],
                    ),
                    child: Column(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: appColors.navyDark,
                            borderRadius: BorderRadius.circular(16),
                            border: Border.all(
                              color: appColors.navyLight.withOpacity(0.5),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: _tab(
                                  'Log In',
                                  true,
                                ),
                              ),
                              Expanded(
                                child: GestureDetector(
                                  onTap: () => context.go('/register'),
                                  child: _tab(
                                    'Create Account',
                                    false,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),

                        const SizedBox(height: 20),

                        TextField(
                          controller: _email,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          keyboardType: TextInputType.emailAddress,
                          textInputAction: TextInputAction.next,
                          onChanged: (_) {
                            if (_error != null) {
                              setState(() {
                                _error = null;
                              });
                            } else {
                              setState(() {});
                            }
                          },
                          decoration: _decoration(
                            'Email address',
                            'samri@gmail.com',
                            prefix: Icon(
                              Icons.mail_outline_rounded,
                              color: appColors.amber,
                              size: 20,
                            ),
                            suffix: _email.text.isEmpty
                                ? null
                                : IconButton(
                                    icon: Icon(
                                      Icons.close_rounded,
                                      color: appColors.textMuted,
                                      size: 18,
                                    ),
                                    onPressed: () {
                                      setState(() {
                                        _email.clear();
                                      });
                                    },
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        TextField(
                          controller: _password,
                          obscureText: _obscure,
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 14,
                          ),
                          textInputAction: TextInputAction.done,
                          onSubmitted: (_) {
                            if (!_loading) {
                              _login();
                            }
                          },
                          decoration: _decoration(
                            'Password',
                            '••••••••••',
                            prefix: Icon(
                              Icons.lock_outline_rounded,
                              color: appColors.amber,
                              size: 20,
                            ),
                            suffix: IconButton(
                              icon: Icon(
                                _obscure
                                    ? Icons.visibility_off_outlined
                                    : Icons.visibility_outlined,
                                color: appColors.textMuted,
                                size: 20,
                              ),
                              onPressed: () {
                                setState(() {
                                  _obscure = !_obscure;
                                });
                              },
                            ),
                          ),
                        ),

                        const SizedBox(height: 9),

                        Row(
                          children: [
                            SizedBox(
                              width: 24,
                              height: 24,
                              child: Checkbox(
                                value: _rememberMe,
                                onChanged: (value) {
                                  setState(() {
                                    _rememberMe = value ?? false;
                                  });
                                },
                                activeColor: appColors.amber,
                                checkColor: appColors.navyDark,
                                side: BorderSide(
                                  color: appColors.textMuted,
                                  width: 1.3,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(5),
                                ),
                              ),
                            ),
                            const SizedBox(width: 8),
                            const Text(
                              'Remember me',
                              style: TextStyle(
                                color: Colors.white70,
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                            const Spacer(),
                            TextButton(
                              onPressed: () {
                                context.push('/forgot-password');
                              },
                              style: TextButton.styleFrom(
                                padding: EdgeInsets.zero,
                                minimumSize: const Size(0, 0),
                                tapTargetSize:
                                    MaterialTapTargetSize.shrinkWrap,
                              ),
                              child: Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: appColors.amber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        if (_error != null) ...[
                          const SizedBox(height: 2),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.redAccent.withOpacity(0.10),
                              borderRadius: BorderRadius.circular(10),
                              border: Border.all(
                                color: Colors.redAccent.withOpacity(0.25),
                              ),
                            ),
                            child: Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                const Icon(
                                  Icons.error_outline_rounded,
                                  color: Colors.redAccent,
                                  size: 18,
                                ),
                                const SizedBox(width: 8),
                                Expanded(
                                  child: Text(
                                    _error!,
                                    style: const TextStyle(
                                      color: Colors.redAccent,
                                      fontSize: 13,
                                      height: 1.35,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],

                        const SizedBox(height: 14),

                        SizedBox(
                          width: double.infinity,
                          height: 52,
                          child: ElevatedButton(
                            onPressed: _loading ? null : _login,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: appColors.amber,
                              foregroundColor: appColors.navyDark,
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
                                      color: appColors.navyDark,
                                      strokeWidth: 2.4,
                                    ),
                                  )
                                : const Text(
                                    'Log In',
                                    style: TextStyle(
                                      fontSize: 15.5,
                                      fontWeight: FontWeight.w800,
                                      letterSpacing: 0.2,
                                    ),
                                  ),
                          ),
                        ),

                        const SizedBox(height: 14),

                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              "Don't have an account? ",
                              style: TextStyle(
                                color: appColors.textMuted,
                                fontSize: 13,
                              ),
                            ),
                            GestureDetector(
                              onTap: () => context.go('/register'),
                              child: Text(
                                'Sign up',
                                style: TextStyle(
                                  color: appColors.amber,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ),
                          ],
                        ),

                        const SizedBox(height: 12),

                        if (_fingerprintReady)
                          SizedBox(
                            width: double.infinity,
                            height: 52,
                            child: OutlinedButton.icon(
                              onPressed: _fingerprintLogin,
                              style: OutlinedButton.styleFrom(
                                side: BorderSide(
                                  color: appColors.navyLight,
                                ),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(14),
                                ),
                              ),
                              icon: Icon(
                                Icons.fingerprint_rounded,
                                color: appColors.amber,
                              ),
                              label: Text(
                                'Log in with fingerprint',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
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
    );
  }

  Widget _tab(String label, bool active) {
    return Container(
      height: 40,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? appColors.amber : Colors.transparent,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: active ? appColors.navyDark : appColors.textMuted,
          fontSize: 13.5,
          fontWeight: FontWeight.w700,
        ),
      ),
    );
  }
}
