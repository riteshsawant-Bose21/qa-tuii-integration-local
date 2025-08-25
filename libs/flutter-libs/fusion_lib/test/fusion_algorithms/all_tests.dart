import 'package:flutter_test/flutter_test.dart';

// Import individual test files
import 'spl_calculation/spl_calculation_test.dart' as spl_calc;
import 'spl_calculation/spl_helpers_test.dart' as spl_helpers;
import 'tap_setting/tap_calculation_test.dart' as tap_calc;
import 'circuiting/circuiting_calculation_test.dart' as circuiting;
import 'device_recommender/device_recommender_test.dart' as device_rec;
import 'shared/math_utils_test.dart' as math_utils;

void main() {
  group('Fusion Algorithms Test Suite', () {
    group('Math Utilities', () {
      math_utils.main();
    });
    
    group('SPL Calculations', () {
      spl_calc.main();
    });
    
    group('SPL Helpers', () {
      spl_helpers.main();
    });
    
    group('Tap Settings', () {
      tap_calc.main();
    });
    
    group('Circuit Design', () {
      circuiting.main();
    });
    
    group('Device Recommendations', () {
      device_rec.main();
    });
  });
}
