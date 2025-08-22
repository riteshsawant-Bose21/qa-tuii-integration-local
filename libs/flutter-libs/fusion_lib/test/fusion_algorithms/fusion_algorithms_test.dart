/// Fusion Algorithms Test Suite
/// 
/// Comprehensive tests for all fusion algorithms including:
/// - SPL Calculations
/// - Tap Settings
/// - Circuiting
/// - Device Recommendations
/// - Shared Utilities

library fusion_algorithms_test;

import 'package:flutter_test/flutter_test.dart';

// Import all test modules
import 'spl_calculation/spl_calculation_test.dart' as spl_tests;
import 'spl_calculation/spl_helpers_test.dart' as spl_helpers_tests;
import 'tap_setting/tap_calculation_test.dart' as tap_tests;
import 'circuiting/circuiting_calculation_test.dart' as circuiting_tests;
import 'device_recommender/device_recommender_test.dart' as device_tests;
import 'shared/math_utils_test.dart' as math_tests;

void main() {
  group('Fusion Algorithms Test Suite', () {
    group('Math Utils Tests', math_tests.main);
    group('SPL Calculation Tests', spl_tests.main);
    group('SPL Helpers Tests', spl_helpers_tests.main);
    group('Tap Setting Tests', tap_tests.main);
    group('Circuiting Tests', circuiting_tests.main);
    group('Device Recommender Tests', device_tests.main);
  });
}
