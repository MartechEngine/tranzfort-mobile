import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../core/theme/app_theme.dart';
import '../../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final TextEditingController _phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const SizedBox(height: 80),
              const Icon(
                LucideIcons.truck,
                size: 48,
                color: AppTheme.primaryBlue,
              ),
              const SizedBox(height: 24),
              Text(
                'Welcome to tranZfort',
                style: Theme.of(context).textTheme.displayLarge,
              ),
              const SizedBox(height: 8),
              Text(
                'India\'s free truck load discovery platform',
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: AppTheme.textSecondary,
                    ),
              ),
              const SizedBox(height: 48),
              Text(
                'Mobile Number',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontSize: 16,
                    ),
              ),
              const SizedBox(height: 8),
              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                enabled: authState.status != AuthStatus.loading,
                decoration: InputDecoration(
                  hintText: 'Enter your 10-digit mobile number',
                  prefixText: '+91 ',
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(8),
                    borderSide: const BorderSide(
                      color: AppTheme.primaryBlue,
                      width: 2,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton(
                onPressed: authState.status == AuthStatus.loading
                    ? null
                    : () async {
                        if (_phoneController.text.length == 10) {
                          await ref.read(authProvider.notifier).sendOtp(_phoneController.text);
                          if (!mounted) return;
                          
                          if (ref.read(authProvider).status == AuthStatus.error) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              SnackBar(content: Text(ref.read(authProvider).errorMessage ?? 'Error sending OTP')),
                            );
                          } else {
                            GoRouter.of(context).push('/otp', extra: _phoneController.text);
                          }
                        } else {
                          ScaffoldMessenger.of(context).showSnackBar(
                            const SnackBar(content: Text('Please enter a valid 10-digit number')),
                          );
                        }
                      },
                child: authState.status == AuthStatus.loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Send OTP'),
              ),
              const Spacer(),
              Center(
                child: Text(
                  'By continuing, you agree to our Terms & Conditions',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }

  @override
  void dispose() {
    _phoneController.dispose();
    super.dispose();
  }
}
