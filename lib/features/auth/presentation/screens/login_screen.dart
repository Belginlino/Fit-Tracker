import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import '../../data/auth_repository.dart';

import 'package:fittrack/core/services/pin_service.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      final user = await repo.signInWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
      );
      if (mounted) {
        if (!user.hasCompletedOnboarding) {
          context.go('/onboarding');
        } else {
          // If PIN is enabled, verify or mark unlocked
          final pinState = ref.read(pinServiceProvider);
          if (pinState.isPinEnabled) {
            context.go('/pin-lock');
          } else {
            context.go('/home');
          }
        }
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _togglePinProtection(bool enable) async {
    final pinNotifier = ref.read(pinServiceProvider.notifier);
    if (!enable) {
      await pinNotifier.disablePin();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('PIN protection disabled.'),
            backgroundColor: AppColors.textSecondary,
          ),
        );
      }
      return;
    }

    // Prompt user to set a 4-digit PIN
    final pinController = TextEditingController();
    final confirmController = TextEditingController();
    String? pinError;

    await showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          backgroundColor: AppColors.cardBackground,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
          title: const Row(
            children: [
              Icon(Icons.shield_outlined, color: AppColors.primary),
              SizedBox(width: 8),
              Text('Set 4-Digit PIN', style: TextStyle(fontSize: 18)),
            ],
          ),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Text(
                'Create a 4-digit security PIN for rapid app access and protection.',
                style: AppTypography.bodySmall,
              ),
              const SizedBox(height: 16),
              AppTextField(
                label: 'Enter 4-digit PIN',
                hint: '••••',
                controller: pinController,
                keyboardType: TextInputType.number,
                isPassword: true,
                maxLength: 4,
              ),
              const SizedBox(height: 12),
              AppTextField(
                label: 'Confirm PIN',
                hint: '••••',
                controller: confirmController,
                keyboardType: TextInputType.number,
                isPassword: true,
                maxLength: 4,
              ),
              if (pinError != null) ...[
                const SizedBox(height: 8),
                Text(
                  pinError!,
                  style: const TextStyle(color: AppColors.error, fontSize: 12),
                ),
              ],
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(ctx).pop(),
              child: const Text('Cancel',
                  style: TextStyle(color: AppColors.textSecondary)),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () async {
                final pin = pinController.text.trim();
                final confirm = confirmController.text.trim();
                if (pin.length != 4 || int.tryParse(pin) == null) {
                  setDialogState(() => pinError = 'PIN must be exactly 4 digits');
                  return;
                }
                if (pin != confirm) {
                  setDialogState(() => pinError = 'PINs do not match');
                  return;
                }

                await pinNotifier.enablePin(pin);
                if (ctx.mounted) Navigator.of(ctx).pop();
                if (mounted) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('PIN protection enabled! ✓'),
                      backgroundColor: AppColors.success,
                    ),
                  );
                }
              },
              child: const Text('Save PIN'),
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 24),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const SizedBox(height: 20),
                  const Text(
                    'Welcome Back',
                    textAlign: TextAlign.center,
                    style: AppTypography.displayMedium,
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    'Sign in to continue your journey.',
                    textAlign: TextAlign.center,
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 48),
                  if (_errorMessage != null) ...[
                    NeumorphicContainer(
                      padding: const EdgeInsets.all(16),
                      style: NeumorphicStyle.inset,
                      child: Row(
                        children: [
                          const Icon(Icons.error_outline,
                              color: AppColors.error, size: 20),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Text(
                              _errorMessage!,
                              style: const TextStyle(
                                  color: AppColors.error, fontSize: 13),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 24),
                  ],
                  AppTextField(
                    label: 'Email Address',
                    hint: 'athlete@example.com',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppColors.textMuted, size: 20),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Please enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 20),
                  AppTextField(
                    label: 'Password',
                    hint: '••••••••',
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textMuted, size: 20),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 16),

                  // PIN Protection Settings Card (User can enable/disable PIN lock right in login)
                  Consumer(
                    builder: (context, ref, child) {
                      final pinState = ref.watch(pinServiceProvider);
                      return NeumorphicContainer(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 12),
                        borderRadius: 14,
                        child: Row(
                          children: [
                            const NeumorphicContainer(
                              shape: BoxShape.circle,
                              padding: EdgeInsets.all(8),
                              child: Icon(Icons.pin_rounded,
                                  color: AppColors.primary, size: 20),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  const Text(
                                    'PIN Protection',
                                    style: TextStyle(
                                      fontWeight: FontWeight.w700,
                                      fontSize: 14,
                                      color: AppColors.textPrimary,
                                    ),
                                  ),
                                  Text(
                                    pinState.isPinEnabled
                                        ? '4-digit PIN is active'
                                        : 'Quick PIN lock disabled',
                                    style: AppTypography.bodySmall
                                        .copyWith(fontSize: 11),
                                  ),
                                ],
                              ),
                            ),
                            Switch.adaptive(
                              value: pinState.isPinEnabled,
                              activeTrackColor: AppColors.primary,
                              onChanged: (val) => _togglePinProtection(val),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 16),

                  Align(
                    alignment: Alignment.centerRight,
                    child: TextButton(
                      onPressed: () {},
                      child: Text(
                        'Forgot Password?',
                        style: AppTypography.bodySmall.copyWith(
                          color: AppColors.primary,
                          decoration: TextDecoration.underline,
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  AppButton(
                    label: 'Sign In',
                    isLoading: _isLoading,
                    onPressed: _handleLogin,
                  ),
                  Consumer(
                    builder: (context, ref, child) {
                      final pinState = ref.watch(pinServiceProvider);
                      final currentUser = ref.watch(currentUserProfileProvider);
                      if (pinState.isPinEnabled && currentUser != null) {
                        return Padding(
                          padding: const EdgeInsets.only(top: 14),
                          child: AppButton(
                            label: 'Unlock with PIN',
                            type: AppButtonType.outline,
                            onPressed: () => context.go('/pin-lock'),
                          ),
                        );
                      }
                      return const SizedBox.shrink();
                    },
                  ),
                  const SizedBox(height: 32),
                  const Center(
                    child: Text(
                      'or continue with',
                      style: AppTypography.bodySmall,
                    ),
                  ),
                  const SizedBox(height: 20),
                  const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      NeumorphicContainer(
                        width: 50,
                        height: 50,
                        shape: BoxShape.circle,
                        child: Icon(Icons.g_mobiledata_rounded,
                            size: 36, color: AppColors.textSecondary),
                      ),
                      SizedBox(width: 20),
                      NeumorphicContainer(
                        width: 50,
                        height: 50,
                        shape: BoxShape.circle,
                        child: Icon(Icons.apple,
                            size: 24, color: AppColors.textSecondary),
                      ),
                    ],
                  ),
                  const SizedBox(height: 48),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Text(
                        "Don't have an account? ",
                        style: AppTypography.bodyMedium,
                      ),
                      GestureDetector(
                        onTap: () => context.push('/register'),
                        child: Text(
                          'Sign Up',
                          style: AppTypography.labelLarge
                              .copyWith(color: AppColors.primary),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
