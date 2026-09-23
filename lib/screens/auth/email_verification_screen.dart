import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import '../../services/auth_service.dart';
import '../../theme/app_theme.dart';
import '../../widgets/rently_logo.dart';
import 'auth_wrapper.dart';

class EmailVerificationScreen extends StatefulWidget {
  final User user;

  const EmailVerificationScreen({super.key, required this.user});

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  final AuthService _authService = AuthService();
  bool _isChecking = false;
  bool _isResending = false;
  String? _message;
  bool _isError = false;

  Future<void> _checkEmailVerified() async {
    setState(() {
      _isChecking = true;
      _message = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser;
      if (currentUser != null) {
        await currentUser.reload();
        final refreshedUser = FirebaseAuth.instance.currentUser;
        if (refreshedUser != null && refreshedUser.emailVerified) {
          if (!mounted) return;
          // Successfully verified, re-route via AuthWrapper
          Navigator.of(context).pushAndRemoveUntil(
            MaterialPageRoute(builder: (_) => const AuthWrapper()),
            (route) => false,
          );
          return;
        }
      }

      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = 'Email is not verified yet. Please check your inbox and click the verification link.';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = 'Error verifying email: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isChecking = false);
      }
    }
  }

  Future<void> _resendVerificationEmail() async {
    setState(() {
      _isResending = true;
      _message = null;
    });

    try {
      final currentUser = FirebaseAuth.instance.currentUser ?? widget.user;
      await currentUser.sendEmailVerification();
      if (!mounted) return;
      setState(() {
        _isError = false;
        _message = 'Verification email sent! Please check your inbox (and spam folder).';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _isError = true;
        _message = 'Failed to resend email: $e';
      });
    } finally {
      if (mounted) {
        setState(() => _isResending = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final email = widget.user.email ?? 'your email address';

    return Scaffold(
      backgroundColor: GenXPalette.whippedCream,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Center(
                  child: RentlyLogo.mark(size: 64, borderRadius: 18),
                ),
                const SizedBox(height: 28),

                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: GenXPalette.midnightBlue.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Center(
                    child: Icon(
                      Icons.mark_email_unread_outlined,
                      size: 42,
                      color: GenXPalette.midnightBlue,
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                const Text(
                  'Verify Your Email',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.w900,
                    color: GenXPalette.textDark,
                    letterSpacing: -0.4,
                  ),
                ),
                const SizedBox(height: 10),

                Text(
                  'We have sent a verification email to:\n$email\n\nPlease check your inbox and click the verification link before proceeding.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: GenXPalette.textMuted,
                    fontSize: 14,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 24),

                if (_message != null) ...[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: _isError ? Colors.red.shade50 : Colors.green.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: _isError ? Colors.red.shade200 : Colors.green.shade200,
                      ),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          _isError ? Icons.error_outline_rounded : Icons.check_circle_outline_rounded,
                          color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                          size: 20,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            _message!,
                            style: TextStyle(
                              color: _isError ? Colors.red.shade700 : Colors.green.shade700,
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 20),
                ],

                ElevatedButton(
                  onPressed: _isChecking ? null : _checkEmailVerified,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: GenXPalette.midnightBlue,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isChecking
                      ? const SizedBox(
                          height: 20,
                          width: 20,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text(
                          'I Have Verified My Email',
                          style: TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                        ),
                ),
                const SizedBox(height: 12),

                OutlinedButton(
                  onPressed: _isResending ? null : _resendVerificationEmail,
                  style: OutlinedButton.styleFrom(
                    foregroundColor: GenXPalette.midnightBlue,
                    side: const BorderSide(color: GenXPalette.midnightBlue),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                  ),
                  child: _isResending
                      ? const SizedBox(
                          height: 18,
                          width: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: GenXPalette.midnightBlue),
                        )
                      : const Text(
                          'Resend Verification Link',
                          style: TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                        ),
                ),
                const SizedBox(height: 20),

                TextButton(
                  onPressed: () async {
                    await _authService.signOut();
                    if (!context.mounted) return;
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(builder: (_) => const AuthWrapper()),
                      (route) => false,
                    );
                  },
                  child: const Text(
                    'Sign Out & Use Different Account',
                    style: TextStyle(
                      color: GenXPalette.textMuted,
                      fontWeight: FontWeight.w600,
                      fontSize: 13.5,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
