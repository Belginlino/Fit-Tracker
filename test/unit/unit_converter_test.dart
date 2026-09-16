import 'package:flutter_test/flutter_test.dart';
import 'package:fittrack/core/utils/unit_converter.dart';

void main() {
  group('UnitConverter Tests', () {
    test('converts kg to lbs accurately', () {
      final lbs = UnitConverter.kgToLbs(70.0);
      expect(lbs, closeTo(154.32, 0.05));
    });

    test('converts lbs to kg accurately', () {
      final kg = UnitConverter.lbsToKg(154.32);
      expect(kg, closeTo(70.0, 0.05));
    });

    test('converts cm to inches accurately', () {
      final inches = UnitConverter.cmToInches(180.0);
      expect(inches, closeTo(70.86, 0.05));
    });

    test('formats weight string with unit label', () {
      expect(UnitConverter.formatWeight(74.2), equals('74.2 kg'));
      expect(UnitConverter.formatWeight(74.2, unit: WeightUnit.lbs), contains('lbs'));
    });
  });
}
