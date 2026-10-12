import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../viewmodels/auth_viewmodel.dart';
import '../../../core/theme/app_theme.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  bool _sending = false;

  final Color brightNavy = const Color(0xFF244A96);
  final Color navy = const Color(0xFF173B82);
  final Color amber = const Color(0xFFFFB900);
  final Color background = const Color(0xFFF6F8FC);
  final Color border = const Color(0xFFE1E6EF);
  final Color muted = const Color(0xFF718096);

  bool get _emailValid {
    return RegExp(
      r'^[^@\s]+@[^@\s]+\.[^@\s]+$',
    ).hasMatch(_emailController.text.trim());
  }

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  Future<void> _sendResetCode() async {
    if (!_emailValid || _sending) return;

    final email = _emailController.text.trim();

    setState(() => _sending = true);

    // Ask the backend to email the 6-digit code. Only continue if it accepted the request.
    final ok = await ref
        .read(authViewModelProvider.notifier)
        .forgotPassword(email);

    if (!mounted) return;

    setState(() => _sending = false);

    if (!ok) {
      final message = ref.read(authViewModelProvider).error ??
          'Could not send the reset code. Please try again.';

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message)),
      );
      return;
    }

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text(
          'If this email has an account, a 6-digit code was sent. Check your inbox and spam folder.',
        ),
      ),
    );

    context.go('/reset-password', extra: email);
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
                    onTap: () => context.go('/login'),
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
                padding: const EdgeInsets.fromLTRB(24, 44, 24, 30),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    Container(
                      width: 86,
                      height: 86,
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
                              blurRadius: 12,
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
                    const SizedBox(height: 26),
                    Text(
                      'Forgot your password?',
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
                      'No worries. Enter the email address linked to your account and we’ll send you a code to reset your password.',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: muted,
                        fontSize: 14,
                        height: 1.55,
                      ),
                    ),
                    const SizedBox(height: 32),
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
                          Text(
                            'Email address',
                            style: TextStyle(
                              color: navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          const SizedBox(height: 9),
                          TextField(
                            controller: _emailController,
                            keyboardType: TextInputType.emailAddress,
                            textInputAction: TextInputAction.done,
                            onChanged: (_) {
                              setState(() {});
                            },
                            onSubmitted: (_) => _sendResetCode(),
                            decoration: InputDecoration(
                              hintText: 'samrawit@email.com',
                              hintStyle: const TextStyle(
                                color: Color(0xFFA5ADBA),
                                fontSize: 14,
                              ),
                              prefixIcon: Icon(
                                Icons.email_outlined,
                                color: brightNavy,
                                size: 21,
                              ),
                              suffixIcon: _emailController.text.isNotEmpty
                                  ? IconButton(
                                      onPressed: () {
                                        setState(() {
                                          _emailController.clear();
                                        });
                                      },
                                      icon: Icon(
                                        Icons.close_rounded,
                                        color: muted,
                                        size: 19,
                                      ),
                                    )
                                  : null,
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
                            ),
                          ),
                          const SizedBox(height: 20),
                          SizedBox(
                            width: double.infinity,
                            height: 54,
                            child: ElevatedButton(
                              onPressed: (_emailValid && !_sending)
                                  ? _sendResetCode
                                  : null,
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
                                    _sending ? 'Sending code...' : 'Send Reset Code',
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                  SizedBox(width: 8),
                                  Icon(
                                    Icons.arrow_forward_rounded,
                                    size: 19,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 22),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.shield_outlined,
                          color: Colors.grey.shade500,
                          size: 16,
                        ),
                        const SizedBox(width: 6),
                        const Text(
                          'Your account information stays secure',
                          style: TextStyle(
                            color: Color(0xFF8A95A6),
                            fontSize: 11,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 28),
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
}