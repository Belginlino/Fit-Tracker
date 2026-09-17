import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:fittrack/app/theme/app_colors.dart';
import 'package:fittrack/app/theme/app_typography.dart';
import 'package:fittrack/core/services/pin_service.dart';
import 'package:fittrack/core/widgets/neumorphic_container.dart';
import 'package:fittrack/features/auth/data/auth_repository.dart';

class PinLockScreen extends ConsumerStatefulWidget {
  const PinLockScreen({super.key});

  @override
  ConsumerState<PinLockScreen> createState() => _PinLockScreenState();
}

class _PinLockScreenState extends ConsumerState<PinLockScreen>
    with SingleTickerProviderStateMixin {
  String _enteredPin = '';
  String? _errorMessage;
  late AnimationController _shakeController;
  late Animation<double> _shakeAnimation;

  @override
  void initState() {
    super.initState();
    _shakeController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 400),
    );
    _shakeAnimation = Tween<double>(begin: 0.0, end: 12.0)
        .chain(CurveTween(curve: Curves.elasticIn))
        .animate(_shakeController);
  }

  @override
  void dispose() {
    _shakeController.dispose();
    super.dispose();
  }

  void _onDigitPressed(String digit) {
    if (_enteredPin.length >= 4) return;

    HapticFeedback.lightImpact();
    setState(() {
      _errorMessage = null;
      _enteredPin += digit;
    });

    if (_enteredPin.length == 4) {
      _verifyPin();
    }
  }

  void _onDeletePressed() {
    if (_enteredPin.isEmpty) return;
    HapticFeedback.selectionClick();
    setState(() {
      _enteredPin = _enteredPin.substring(0, _enteredPin.length - 1);
      _errorMessage = null;
    });
  }

  void _verifyPin() {
    final pinService = ref.read(pinServiceProvider.notifier);
    final isValid = pinService.verifyPin(_enteredPin);

    if (isValid) {
      HapticFeedback.mediumImpact();
      if (mounted) {
        context.go('/home');
      }
    } else {
      HapticFeedback.heavyImpact();
      _shakeController.forward(from: 0.0);
      setState(() {
        _errorMessage = 'Incorrect PIN. Please try again.';
        _enteredPin = '';
      });
    }
  }

  Future<void> _signOutAndLoginWithPassword() async {
    final shouldLogout = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.cardBackground,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Use Password Instead?'),
        content: const Text(
            'This will sign you out so you can sign in with your email and password.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancel',
                style: TextStyle(color: AppColors.textSecondary)),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Sign Out',
                style: TextStyle(color: AppColors.primary)),
          ),
        ],
      ),
    );

    if (shouldLogout == true && mounted) {
      await ref.read(authRepositoryProvider).signOut();
      ref.read(pinServiceProvider.notifier).unlockApp();
      if (mounted) {
        context.go('/login');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(currentUserProfileProvider);
    final userName = (user?.name != null && user!.name.isNotEmpty)
        ? user.name
        : (user?.email != null && user!.email.isNotEmpty)
            ? user.email.split('@').first
            : 'Athlete';

    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: Column(
          children: [
            const Spacer(flex: 2),

            // Lock Icon
            const NeumorphicContainer(
              width: 76,
              height: 76,
              shape: BoxShape.circle,
              child: Icon(Icons.lock_rounded, color: AppColors.primary, size: 36),
            ),
            const SizedBox(height: 24),

            // Heading & Welcome
            Text(
              'Welcome Back, $userName',
              style: AppTypography.displayMedium.copyWith(fontSize: 22),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter your 4-digit PIN to unlock',
              style: AppTypography.bodyMedium,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 32),

            // PIN Dot Indicators
            AnimatedBuilder(
              animation: _shakeAnimation,
              builder: (context, child) {
                final offset = _shakeController.isAnimating
                    ? (_shakeAnimation.value *
                        ((_shakeController.value * 8).floor() % 2 == 0 ? 1 : -1))
                    : 0.0;
                return Transform.translate(
                  offset: Offset(offset, 0),
                  child: child,
                );
              },
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: List.generate(4, (index) {
                  final isFilled = index < _enteredPin.length;
                  return Container(
                    margin: const EdgeInsets.symmetric(horizontal: 12),
                    child: NeumorphicContainer(
                      width: 20,
                      height: 20,
                      shape: BoxShape.circle,
                      style: isFilled
                          ? NeumorphicStyle.inset
                          : NeumorphicStyle.flat,
                      child: Center(
                        child: AnimatedContainer(
                          duration: const Duration(milliseconds: 200),
                          width: isFilled ? 12 : 0,
                          height: isFilled ? 12 : 0,
                          decoration: const BoxDecoration(
                            color: AppColors.primary,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ),
                    ),
                  );
                }),
              ),
            ),

            // Error Message
            SizedBox(
              height: 40,
              child: Center(
                child: _errorMessage != null
                    ? Text(
                        _errorMessage!,
                        style: const TextStyle(
                          color: AppColors.error,
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                        ),
                      )
                    : null,
              ),
            ),

            const Spacer(flex: 1),

            // Keypad (3x4)
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 48),
              child: Column(
                children: [
                  _buildKeypadRow(['1', '2', '3']),
                  const SizedBox(height: 20),
                  _buildKeypadRow(['4', '5', '6']),
                  const SizedBox(height: 20),
                  _buildKeypadRow(['7', '8', '9']),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Empty / Action
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: TextButton(
                          onPressed: () {
                            setState(() {
                              _enteredPin = '';
                              _errorMessage = null;
                            });
                          },
                          child: const Text('Clear',
                              style: TextStyle(
                                  color: AppColors.textSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w600)),
                        ),
                      ),
                      // '0' Key
                      _buildKeypadButton('0'),
                      // Backspace
                      SizedBox(
                        width: 68,
                        height: 68,
                        child: GestureDetector(
                          onTap: _onDeletePressed,
                          child: const NeumorphicContainer(
                            shape: BoxShape.circle,
                            child: Icon(Icons.backspace_outlined,
                                color: AppColors.textPrimary, size: 22),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            const Spacer(flex: 2),

            // Fallback: Login with password
            TextButton(
              onPressed: _signOutAndLoginWithPassword,
              child: Text(
                'Log in with password instead',
                style: AppTypography.bodySmall.copyWith(
                  color: AppColors.primary,
                  decoration: TextDecoration.underline,
                ),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildKeypadRow(List<String> keys) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: keys.map((key) => _buildKeypadButton(key)).toList(),
    );
  }

  Widget _buildKeypadButton(String digit) {
    return SizedBox(
      width: 68,
      height: 68,
      child: GestureDetector(
        onTap: () => _onDigitPressed(digit),
        child: NeumorphicContainer(
          shape: BoxShape.circle,
          child: Center(
            child: Text(
              digit,
              style: AppTypography.titleLarge.copyWith(
                fontSize: 24,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
