import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_lib/fusion_algorithms/shared/math_utils.dart';

void main() {
  group('Math Utils', () {
    test('roundToPrecision should work correctly', () {
      expect(roundToPrecision(3.14159, 2), equals(3.14));
      expect(roundToPrecision(3.14159, 3), equals(3.142));
      expect(roundToPrecision(3.14159, 0), equals(3.0));
      expect(roundToPrecision(3.99999, 2), equals(4.0));
    });

    test('round2 should round to 2 decimal places', () {
      expect(round2(3.14159), equals(3.14));
      expect(round2(2.999), equals(3.0));
      expect(round2(0.005), equals(0.01));
    });

    test('round1 should round to 1 decimal place', () {
      expect(round1(3.14159), equals(3.1));
      expect(round1(2.99), equals(3.0));
      expect(round1(0.05), equals(0.1));
    });

    test('calculateSplLossInverseSquare should calculate correctly', () {
      expect(calculateSplLossInverseSquare(1.0, 2.0), closeTo(-6.02, 0.1));
      expect(calculateSplLossInverseSquare(1.0, 1.0), equals(0.0));
      expect(calculateSplLossInverseSquare(2.0, 1.0), closeTo(6.02, 0.1));
    });

    test('calculateSurfaceMountDistance should handle angles correctly', () {
      expect(calculateSurfaceMountDistance(1.0), closeTo(3.86, 0.1));
      expect(calculateSurfaceMountDistance(2.0), closeTo(7.73, 0.1));
    });

    test('ensurePositiveDistance should handle edge cases', () {
      expect(ensurePositiveDistance(5.0), equals(5.0));
      expect(ensurePositiveDistance(-1.0), equals(FusionMathConstants.minimumDistanceMeters));
      expect(ensurePositiveDistance(0.0), equals(FusionMathConstants.minimumDistanceMeters));
    });

    test('calculatePowerAttenuationDb should calculate correctly', () {
      expect(calculatePowerAttenuationDb(50.0, 100.0), closeTo(-3.01, 0.1));
      expect(calculatePowerAttenuationDb(100.0, 100.0), equals(0.0));
      expect(calculatePowerAttenuationDb(200.0, 100.0), closeTo(3.01, 0.1));
      expect(calculatePowerAttenuationDb(0.0, 100.0), equals(double.negativeInfinity));
    });

    test('findMaximum should find maximum value', () {
      expect(findMaximum([1.0, 3.0, 2.0]), equals(3.0));
      expect(findMaximum([5.0]), equals(5.0));
      expect(findMaximum([-1.0, -3.0, -2.0]), equals(-1.0));
      expect(() => findMaximum([]), throwsArgumentError);
    });

    test('findClosestIndex should find closest value index', () {
      expect(findClosestIndex(2.5, [1.0, 2.0, 3.0, 4.0]), equals(1)); // Closest to 2.0
      expect(findClosestIndex(2.6, [1.0, 2.0, 3.0, 4.0]), equals(2)); // Closest to 3.0
      expect(findClosestIndex(0.5, [1.0, 2.0, 3.0]), equals(0));
      expect(() => findClosestIndex(1.0, []), throwsArgumentError);
    });

    test('angle conversions should work correctly', () {
      expect(degreesToRadians(90), closeTo(1.5708, 0.001));
      expect(degreesToRadians(180), closeTo(3.1416, 0.001));
      expect(degreesToRadians(0), equals(0.0));
      
      expect(radiansToDegrees(1.5708), closeTo(90.0, 0.1));
      expect(radiansToDegrees(3.1416), closeTo(180.0, 0.1));
      expect(radiansToDegrees(0), equals(0.0));
    });

    test('isApproximatelyEqual should handle floating point comparison', () {
      expect(isApproximatelyEqual(1.0, 1.0), isTrue);
      expect(isApproximatelyEqual(1.0, 1.1), isFalse);
      expect(isApproximatelyEqual(1.0, 1.001, tolerance: 0.01), isTrue);
      expect(isApproximatelyEqual(1.0, 1.05, tolerance: 0.01), isFalse);
    });

    test('clamp should constrain values to bounds', () {
      expect(clamp(5.0, 0.0, 10.0), equals(5.0));
      expect(clamp(-1.0, 0.0, 10.0), equals(0.0));
      expect(clamp(15.0, 0.0, 10.0), equals(10.0));
      expect(() => clamp(5.0, 10.0, 0.0), throwsArgumentError); // min > max
    });

    test('math constants should be available', () {
      expect(FusionMathConstants.pi, closeTo(3.14159, 0.001));
      expect(FusionMathConstants.referenceDistanceMeters, equals(1.0));
      expect(FusionMathConstants.surfaceMountAngleDegrees, equals(75.0));
      expect(FusionMathConstants.splCompensationDb, equals(3.0));
      expect(FusionMathConstants.minimumDistanceMeters, greaterThan(0));
    });

    test('error handling should work correctly', () {
      expect(() => roundToPrecision(1.0, -1), throwsArgumentError);
      expect(() => calculateSplLossInverseSquare(-1.0, 1.0), throwsArgumentError);
      expect(() => calculateSplLossInverseSquare(1.0, -1.0), throwsArgumentError);
      expect(calculatePowerAttenuationDb(-1.0, 100.0), equals(double.negativeInfinity));
      expect(calculatePowerAttenuationDb(100.0, -1.0), equals(double.negativeInfinity));
    });
  });
}
