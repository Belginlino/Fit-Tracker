import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';

class PinState {
  final bool isPinEnabled;
  final bool isUnlocked;
  final bool hasPinSet;

  const PinState({
    required this.isPinEnabled,
    required this.isUnlocked,
    required this.hasPinSet,
  });

  PinState copyWith({
    bool? isPinEnabled,
    bool? isUnlocked,
    bool? hasPinSet,
  }) {
    return PinState(
      isPinEnabled: isPinEnabled ?? this.isPinEnabled,
      isUnlocked: isUnlocked ?? this.isUnlocked,
      hasPinSet: hasPinSet ?? this.hasPinSet,
    );
  }
}

class PinService extends StateNotifier<PinState> {
  static const String _keyPinEnabled = 'fittrack_pin_enabled';
  static const String _keyPinCode = 'fittrack_pin_code';

  SharedPreferences? _prefs;

  PinService()
      : super(const PinState(
          isPinEnabled: false,
          isUnlocked: false,
          hasPinSet: false,
        )) {
    _loadInitialState();
  }

  Future<void> _loadInitialState() async {
    _prefs = await SharedPreferences.getInstance();
    final enabled = _prefs?.getBool(_keyPinEnabled) ?? false;
    final pin = _prefs?.getString(_keyPinCode);
    final hasPin = pin != null && pin.length == 4;

    state = PinState(
      isPinEnabled: enabled && hasPin,
      isUnlocked: !(enabled && hasPin), // Auto-unlocked if PIN is not enabled
      hasPinSet: hasPin,
    );
  }

  Future<void> enablePin(String pin) async {
    if (pin.length != 4) return;
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setString(_keyPinCode, pin);
    await _prefs!.setBool(_keyPinEnabled, true);

    state = state.copyWith(
      isPinEnabled: true,
      hasPinSet: true,
      isUnlocked: true,
    );
  }

  Future<void> disablePin() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.setBool(_keyPinEnabled, false);

    state = state.copyWith(
      isPinEnabled: false,
      isUnlocked: true,
    );
  }

  Future<void> removePin() async {
    _prefs ??= await SharedPreferences.getInstance();
    await _prefs!.remove(_keyPinCode);
    await _prefs!.setBool(_keyPinEnabled, false);

    state = state.copyWith(
      isPinEnabled: false,
      hasPinSet: false,
      isUnlocked: true,
    );
  }

  bool verifyPin(String enteredPin) {
    if (_prefs == null) return false;
    final savedPin = _prefs!.getString(_keyPinCode);
    if (savedPin == null) return false;
    final isValid = savedPin == enteredPin;
    if (isValid) {
      state = state.copyWith(isUnlocked: true);
    }
    return isValid;
  }

  void lockApp() {
    if (state.isPinEnabled) {
      state = state.copyWith(isUnlocked: false);
    }
  }

  void unlockApp() {
    state = state.copyWith(isUnlocked: true);
  }
}

final pinServiceProvider = StateNotifierProvider<PinService, PinState>((ref) {
  return PinService();
});
