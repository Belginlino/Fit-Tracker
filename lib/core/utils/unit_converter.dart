enum WeightUnit { kg, lbs }

enum DistanceUnit { cm, inches }

class UnitConverter {
  UnitConverter._();

  static const double kgToLbsFactor = 2.20462;
  static const double cmToInchesFactor = 0.393701;

  // Weight conversions
  static double kgToLbs(double kg) => kg * kgToLbsFactor;
  static double lbsToKg(double lbs) => lbs / kgToLbsFactor;

  // Distance/Length conversions
  static double cmToInches(double cm) => cm * cmToInchesFactor;
  static double inchesToCm(double inches) => inches / cmToInchesFactor;

  static String formatWeight(double weightInKg,
      {WeightUnit unit = WeightUnit.kg, int precision = 1}) {
    if (unit == WeightUnit.lbs) {
      final val = kgToLbs(weightInKg);
      return '${val.toStringAsFixed(precision)} lbs';
    }
    return '${weightInKg.toStringAsFixed(precision)} kg';
  }

  static String formatMeasurement(double valueInCm,
      {DistanceUnit unit = DistanceUnit.cm, int precision = 1}) {
    if (unit == DistanceUnit.inches) {
      final val = cmToInches(valueInCm);
      return '${val.toStringAsFixed(precision)} in';
    }
    return '${valueInCm.toStringAsFixed(precision)} cm';
  }
}
