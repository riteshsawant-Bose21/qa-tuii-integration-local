/// Common mathematical utilities and constants shared across fusion algorithms
/// This consolidates mathematical functions used by multiple algorithms

import 'dart:math' as math;

/// Mathematical constants used across algorithms
class FusionMathConstants {
  static const double pi = math.pi;
  static const double ln10 = math.ln10;
  
  /// Reference distance for SPL calculations (meters)
  static const double referenceDistanceMeters = 1.0;
  
  /// Reference angle for surface mount calculations (degrees)
  static const double surfaceMountAngleDegrees = 75.0;
  
  /// SPL compensation factor (dB)
  static const double splCompensationDb = 3.0;
  
  /// Minimum distance to avoid mathematical errors (meters)
  static const double minimumDistanceMeters = 1e-6;
}

/// Precision rounding utility with flexible decimal places
/// 
/// This replaces both round2() and roundToDecimalPlaces() functions
/// with a single, more flexible implementation.
double roundToPrecision(double value, int decimalPlaces) {
  if (decimalPlaces < 0) {
    throw ArgumentError('decimalPlaces must be non-negative');
  }
  
  final factor = math.pow(10, decimalPlaces);
  return (value * factor).round() / factor;
}

/// Convenience function for 2-decimal precision (most common case)
double round2(double value) => roundToPrecision(value, 2);

/// Convenience function for 1-decimal precision (power ratings)
double round1(double value) => roundToPrecision(value, 1);

/// Calculate SPL loss using inverse square law
/// 
/// This is the core SPL calculation used by both algorithms
double calculateSplLossInverseSquare(double referenceDistance, double currentDistance) {
  if (referenceDistance <= 0 || currentDistance <= 0) {
    throw ArgumentError('Distances must be positive for SPL loss calculation');
  }
  
  return 20 * math.log(referenceDistance / currentDistance) / FusionMathConstants.ln10;
}

/// Calculate distance for surface mounting using angle compensation
/// 
/// Used by SPL calculation for surface-mounted speakers
double calculateSurfaceMountDistance(double heightDifference) {
  const angleRadians = FusionMathConstants.surfaceMountAngleDegrees * math.pi / 180;
  final denom = math.cos(angleRadians);
  
  if (denom == 0) {
    throw StateError('Invalid calculation: division by zero in surface mount distance');
  }
  
  return heightDifference / denom;
}

/// Ensure distance is positive to avoid mathematical errors
/// 
/// Replaces zero/negative distances with a safe minimum value
double ensurePositiveDistance(double distance) {
  return distance <= 0 ? FusionMathConstants.minimumDistanceMeters : distance;
}

/// Calculate power-based attenuation in dB
/// 
/// Used by tap setting algorithm for power attenuation calculations
double calculatePowerAttenuationDb(double powerWatts, double referencePowerWatts) {
  if (powerWatts <= 0 || referencePowerWatts <= 0) {
    return double.negativeInfinity;
  }
  
  return 10 * math.log(powerWatts / referencePowerWatts) / FusionMathConstants.ln10;
}

/// Find maximum value in a list of numbers
/// 
/// Used by tap setting algorithm to find reference distance
double findMaximum(List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError('Cannot find maximum of empty list');
  }
  
  return values.reduce(math.max);
}

/// Find the index of the value closest to target
/// 
/// Used by tap setting algorithm to find best matching tap
int findClosestIndex(double target, List<double> values) {
  if (values.isEmpty) {
    throw ArgumentError('Cannot find closest in empty list');
  }
  
  int bestIndex = 0;
  double bestDifference = (values[0] - target).abs();
  
  for (int i = 1; i < values.length; i++) {
    if (values[i].isInfinite && values[i].isNegative) {
      continue; // Skip negative infinity values
    }
    
    final difference = (values[i] - target).abs();
    if (difference < bestDifference) {
      bestDifference = difference;
      bestIndex = i;
    }
  }
  
  return bestIndex;
}

/// Convert degrees to radians
double degreesToRadians(double degrees) => degrees * math.pi / 180;

/// Convert radians to degrees
double radiansToDegrees(double radians) => radians * 180 / math.pi;

/// Check if a value is within a tolerance of another value
bool isApproximatelyEqual(double a, double b, {double tolerance = 1e-10}) {
  return (a - b).abs() < tolerance;
}

/// Clamp a value between min and max bounds
double clamp(double value, double min, double max) {
  if (min > max) {
    throw ArgumentError('min cannot be greater than max');
  }
  return math.max(min, math.min(max, value));
}
