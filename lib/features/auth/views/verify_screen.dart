import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';

class VerifyScreen extends ConsumerStatefulWidget {
  const VerifyScreen({
    super.key,
    required this.email,
  });

  final String email;

  @override
  ConsumerState<VerifyScreen> createState() => _VerifyScreenState();
}

class _VerifyScreenState extends ConsumerState<VerifyScreen> {
  final _codeController = TextEditingController();
  final _focusNode = FocusNode();

  Timer? _timer;
  int _resendIn = 42;

  final Color brightNavy = const Color(0xFF244A96);
  final Color navy = const Color(0xFF173B82);
  final Color amber = const Color(0xFFFFB900);
  final Color background = const Color(0xFFF6F8FC);
  final Color border = const Color(0xFFE1E6EF);
  final Color muted = const Color(0xFF718096);

  @override
  void initState() {
    super.initState();
    _startResendTimer();

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        _focusNode.requestFocus();
      }
    });
  }

  void _startResendTimer() {
    _timer?.cancel();

    setState(() {
      _resendIn = 42;
    });

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (timer) {
        if (!mounted) {
          timer.cancel();
          return;
        }

        if (_resendIn <= 1) {
          timer.cancel();
          setState(() {
            _resendIn = 0;
          });
        } else {
          setState(() {
            _resendIn--;
          });
        }
      },
    );
  }

  Future<void> _resendCode() async {
    if (_resendIn != 0) return;

    final success = await ref
        .read(authViewModelProvider.notifier)
        .resendOtp(widget.email);

    if (!mounted) return;

    if (success) {
      _codeController.clear();
      _startResendTimer();
    }
  }

  Future<void> _verify() async {
    final code = _codeController.text.trim();

    if (code.length != 6) {
      return;
    }

    final success = await ref
        .read(authViewModelProvider.notifier)
        .verifyOtp(widget.email, code);

    if (success && mounted) {
      // Verification alone does not create an access token.
      // Send the user to login so the backend can issue tokens normally.
      context.go('/login');
    }
  }

  String _maskedEmail() {
    final email = widget.email;
    final atIndex = email.indexOf('@');

    if (atIndex <= 0) {
      return email;
    }

    final username = email.substring(0, atIndex);
    final domain = email.substring(atIndex);

    if (username.length <= 2) {
      return '${username[0]}•••$domain';
    }

    return '${username.substring(0, 2)}•••$domain';
  }

  @override
  void dispose() {
    _timer?.cancel();
    _codeController.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final auth = ref.watch(authViewModelProvider);

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
                    onTap: () => context.pop(),
                    child: Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(
                          color: border,
                        ),
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
                padding: const EdgeInsets.fromLTRB(24, 38, 24, 28),
                child: Column(
                  children: [
                    Container(
                      width: 82,
                      height: 82,
                      decoration: BoxDecoration(
                        color: amber.withOpacity(0.12),
                        shape: BoxShape.circle,
                      ),
                      child: Icon(
                        Icons.mark_email_read_rounded,
                        color: amber,
                        size: 40,
                      ),
                    ),
                    const SizedBox(height: 26),
                    Text(
                      'Verify your account',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: navy,
                        fontSize: 28,
                        fontWeight: FontWeight.w800,
                        letterSpacing: -0.6,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      'We sent a 6-digit verification code to',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      _maskedEmail(),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: brightNavy,
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    const SizedBox(height: 30),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(22),
                        border: Border.all(
                          color: border,
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withOpacity(0.045),
                            blurRadius: 20,
                            offset: const Offset(0, 8),
                          ),
                        ],
                      ),
                      child: Column(
                        children: [
                          Text(
                            'Enter verification code',
                            style: TextStyle(
                              color: navy,
                              fontSize: 14,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 18),
                          Stack(
                            children: [
                              Positioned(
                                left: 0,
                                top: 0,
                                child: SizedBox(
                                  width: 1,
                                  height: 1,
                                  child: Opacity(
                                    opacity: 0,
                                    child: TextField(
                                      controller: _codeController,
                                      focusNode: _focusNode,
                                      keyboardType: TextInputType.number,
                                      maxLength: 6,
                                      onChanged: (value) {
                                        setState(() {});

                                        if (value.length == 6) {
                                          _verify();
                                        }
                                      },
                                    ),
                                  ),
                                ),
                              ),
                              GestureDetector(
                                onTap: () {
                                  _focusNode.requestFocus();
                                },
                                child: Row(
                                  mainAxisAlignment:
                                      MainAxisAlignment.spaceBetween,
                                  children: List.generate(
                                    6,
                                    (index) {
                                      final hasValue =
                                          _codeController.text.length > index;

                                      final value = hasValue
                                          ? _codeController.text[index]
                                          : '';

                                      final active =
                                          _codeController.text.length == index;

                                      return AnimatedContainer(
                                        duration:
                                            const Duration(milliseconds: 180),
                                        width: 43,
                                        height: 56,
                                        alignment: Alignment.center,
                                        decoration: BoxDecoration(
                                          color: active
                                              ? const Color(0xFFF4F7FF)
                                              : const Color(0xFFF8FAFC),
                                          borderRadius:
                                              BorderRadius.circular(13),
                                          border: Border.all(
                                            color: active
                                                ? amber
                                                : hasValue
                                                    ? const Color(0xFFB9C5D8)
                                                    : border,
                                            width: active ? 1.7 : 1,
                                          ),
                                        ),
                                        child: Text(
                                          value,
                                          style: TextStyle(
                                            color: navy,
                                            fontSize: 22,
                                            fontWeight: FontWeight.w800,
                                          ),
                                        ),
                                      );
                                    },
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Text(
                                "Didn't receive the code? ",
                                style: TextStyle(
                                  color: muted,
                                  fontSize: 13,
                                ),
                              ),
                              GestureDetector(
                                onTap: _resendIn == 0 ? _resendCode : null,
                                child: Text(
                                  _resendIn > 0
                                      ? 'Resend in 0:${_resendIn.toString().padLeft(2, '0')}'
                                      : 'Resend code',
                                  style: TextStyle(
                                    color: _resendIn == 0
                                        ? brightNavy
                                        : const Color(0xFF9BA5B4),
                                    fontSize: 13,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                    ),
                    if (auth.status == AuthStatus.error && auth.error != null) ...[
                      Container(
                        width: double.infinity,
                        margin: const EdgeInsets.only(bottom: 16),
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                        decoration: BoxDecoration(
                          color: const Color(0xFFFFF2F2),
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: const Color(0xFFFFD0D0)),
                        ),
                        child: Text(
                          auth.error!,
                          textAlign: TextAlign.center,
                          style: const TextStyle(
                            color: Color(0xFFB42318),
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                    const SizedBox(height: 24),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton(
                        onPressed:
                            auth.status == AuthStatus.loading ||
                                    _codeController.text.length != 6
                                ? null
                                : _verify,
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
                        child: auth.status == AuthStatus.loading
                            ? SizedBox(
                                width: 21,
                                height: 21,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2.4,
                                  color: navy,
                                ),
                              )
                            : const Text(
                                'Verify Account',
                                style: TextStyle(
                                  fontSize: 15,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                      ),
                    ),
                    const SizedBox(height: 18),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.verified_user_outlined,
                          color: Colors.grey.shade500,
                          size: 15,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Your verification is secure',
                          style: TextStyle(
                            color: Color(0xFF8A95A6),
                            fontSize: 11,
                          ),
                        ),
                      ],
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
}