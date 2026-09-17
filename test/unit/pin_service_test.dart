import 'package:flutter_test/flutter_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:fittrack/core/services/pin_service.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  setUp(() {
    SharedPreferences.setMockInitialValues({});
  });

  group('PinService Tests', () {
    test('initially has PIN disabled and unlocked', () async {
      final pinService = PinService();
      await Future.delayed(const Duration(milliseconds: 50));

      expect(pinService.state.isPinEnabled, false);
      expect(pinService.state.isUnlocked, true);
      expect(pinService.state.hasPinSet, false);
    });

    test('enabling PIN sets state and persists correctly', () async {
      final pinService = PinService();
      await Future.delayed(const Duration(milliseconds: 50));

      await pinService.enablePin('1234');

      expect(pinService.state.isPinEnabled, true);
      expect(pinService.state.hasPinSet, true);
      expect(pinService.state.isUnlocked, true);

      // Verify correct PIN
      expect(pinService.verifyPin('1234'), true);
      // Verify wrong PIN
      expect(pinService.verifyPin('9999'), false);
    });

    test('locking and unlocking app with PIN', () async {
      final pinService = PinService();
      await Future.delayed(const Duration(milliseconds: 50));

      await pinService.enablePin('4321');
      pinService.lockApp();
      expect(pinService.state.isUnlocked, false);

      final verified = pinService.verifyPin('4321');
      expect(verified, true);
      expect(pinService.state.isUnlocked, true);
    });

    test('disabling PIN marks isPinEnabled false', () async {
      final pinService = PinService();
      await Future.delayed(const Duration(milliseconds: 50));

      await pinService.enablePin('5678');
      expect(pinService.state.isPinEnabled, true);

      await pinService.disablePin();
      expect(pinService.state.isPinEnabled, false);
      expect(pinService.state.isUnlocked, true);
    });
  });
}
