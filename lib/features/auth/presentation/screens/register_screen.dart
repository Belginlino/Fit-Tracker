import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/widgets/app_button.dart';
import 'package:fittrack/core/widgets/app_text_field.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import '../../data/auth_repository.dart';

import 'package:appwrite/appwrite.dart';
import 'package:fittrack/core/appwrite/appwrite_client.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleRegister() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final repo = ref.read(authRepositoryProvider);
      await repo.registerWithEmail(
        _emailController.text.trim(),
        _passwordController.text,
        _nameController.text.trim(),
      );
      if (mounted) {
        context.go('/onboarding');
      }
    } on AppwriteException catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = AppwriteClient.formatError(e);
        });
      }
    } catch (e) {
      if (mounted) {
        String msg = e.toString();
        if (msg.startsWith('Exception: ')) {
          msg = msg.substring(11);
        }
        setState(() {
          _errorMessage = msg;
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: Padding(
          padding: const EdgeInsets.only(left: 16, top: 8, bottom: 8),
          child: NeumorphicContainer(
            borderRadius: 12,
            child: IconButton(
              icon: const Icon(Icons.arrow_back_ios_new_rounded, size: 20),
              onPressed: () => context.pop(),
            ),
          ),
        ),
      ),
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28, vertical: 12),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  const Text(
                    'Create Account',
                    style: AppTypography.displayMedium,
                  ),
                  const SizedBox(height: 6),
                  const Text(
                    'Start tracking your workouts & visual transformation',
                    style: AppTypography.bodyMedium,
                  ),
                  const SizedBox(height: 24),
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
                    label: 'Full Name',
                    hint: 'Enter your full name',
                    controller: _nameController,
                    prefixIcon: const Icon(Icons.person_outline,
                        color: AppColors.textMuted, size: 20),
                    validator: (v) => (v == null || v.trim().isEmpty)
                        ? 'Please enter your name'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Email',
                    hint: 'Enter your email',
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    prefixIcon: const Icon(Icons.email_outlined,
                        color: AppColors.textMuted, size: 20),
                    validator: (v) => (v == null || !v.contains('@'))
                        ? 'Please enter a valid email'
                        : null,
                  ),
                  const SizedBox(height: 18),
                  AppTextField(
                    label: 'Password',
                    hint: 'At least 6 characters',
                    controller: _passwordController,
                    isPassword: true,
                    prefixIcon: const Icon(Icons.lock_outline,
                        color: AppColors.textMuted, size: 20),
                    validator: (v) => (v == null || v.length < 6)
                        ? 'Password must be at least 6 characters'
                        : null,
                  ),
                  const SizedBox(height: 32),
                  AppButton(
                    label: 'Sign Up',
                    isLoading: _isLoading,
                    onPressed: _handleRegister,
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
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
