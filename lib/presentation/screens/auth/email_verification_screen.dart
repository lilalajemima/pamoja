import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../../core/theme/app_theme.dart';
import '../../../core/router/app_router.dart';
import '../../blocs/auth/auth_bloc.dart';
import 'dart:async';

class EmailVerificationScreen extends StatefulWidget {
  final String email;

  const EmailVerificationScreen({
    super.key,
    required this.email,
  });

  @override
  State<EmailVerificationScreen> createState() => _EmailVerificationScreenState();
}

class _EmailVerificationScreenState extends State<EmailVerificationScreen> {
  Timer? _timer;
  bool _isCheckingVerification = false;

  @override
  void initState() {
    super.initState();
    // Check verification status every 3 seconds
    _timer = Timer.periodic(const Duration(seconds: 3), (timer) {
      _checkEmailVerification();
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  Future<void> _checkEmailVerification() async {
    if (_isCheckingVerification) return;
    
    setState(() => _isCheckingVerification = true);

    try {
      final user = FirebaseAuth.instance.currentUser;
      await user?.reload();
      final currentUser = FirebaseAuth.instance.currentUser;

      if (currentUser != null && currentUser.emailVerified) {
        _timer?.cancel();
        if (mounted) {
          context.read<AuthBloc>().add(CheckAuthStatus());
        }
      }
    } catch (e) {
      // Ignore errors during check
    } finally {
      if (mounted) {
        setState(() => _isCheckingVerification = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Verify Email'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () {
            _timer?.cancel();
            context.read<AuthBloc>().add(LogoutRequested());
            context.go(AppRouter.login);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 120,
                height: 120,
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen,
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.mark_email_unread,
                  size: 60,
                  color: AppTheme.primaryGreen,
                ),
              ),
              const SizedBox(height: 32),
              Text(
                'Verify Your Email',
                style: Theme.of(context).textTheme.displayMedium,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              Text(
                'We\'ve sent a verification email to:',
                style: Theme.of(context).textTheme.bodyLarge,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Text(
                widget.email,
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      color: AppTheme.primaryGreen,
                      fontWeight: FontWeight.w600,
                    ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 32),
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppTheme.lightGreen.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(color: AppTheme.lightGreen),
                ),
                child: Column(
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.info_outline,
                          color: AppTheme.primaryGreen,
                          size: 20,
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Text(
                            'Please check your email and click the verification link to continue.',
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 32),
              if (_isCheckingVerification)
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      'Checking verification status...',
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            color: AppTheme.mediumGray,
                          ),
                    ),
                  ],
                )
              else
                Text(
                  'Waiting for email verification...',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        color: AppTheme.mediumGray,
                      ),
                ),
              const SizedBox(height: 48),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton.icon(
                  onPressed: () {
                    context.read<AuthBloc>().add(ResendVerificationEmail());
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text('Verification email sent!'),
                        backgroundColor: AppTheme.primaryGreen,
                      ),
                    );
                  },
                  icon: const Icon(Icons.email),
                  label: const Text('Resend Verification Email'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppTheme.primaryGreen,
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: () {
                  _timer?.cancel();
                  context.read<AuthBloc>().add(LogoutRequested());
                  context.go(AppRouter.login);
                },
                child: const Text(
                  'Back to Login',
                  style: TextStyle(
                    color: AppTheme.primaryGreen,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}