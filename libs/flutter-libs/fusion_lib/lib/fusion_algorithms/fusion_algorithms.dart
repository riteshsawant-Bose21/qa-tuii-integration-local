/// Fusion Algorithms Library
/// 
/// This library contains algorithms for audio system design and configuration,
/// including SPL calculations, speaker recommendations, tap setting calculations,
/// and system optimization.
/// 
/// Data structures (speakers, amplifiers, devices) are now located in the
/// separate API data module for better organization and API integration.

library fusion_algorithms;

// API Data exports (centralized data structures)
export '../api_data/api_data.dart';

// SPL Calculation exports
export 'spl_calculation/spl_calculation.dart';
export 'spl_calculation/spl_types.dart';
export 'spl_calculation/spl_constants.dart';
export 'spl_calculation/spl_helpers.dart';

// Tap Setting exports
export 'tap_setting/tap_calculation.dart';
export 'tap_setting/tap_types.dart';
export 'tap_setting/tap_helpers.dart' hide calculateSplLoss;

// Circuiting exports
export 'circuiting/circuiting_calculation.dart';
export 'circuiting/circuiting_types.dart';
export 'circuiting/circuiting_helpers.dart';

// Device Recommender exports
export 'device_recommender/device_recommender.dart';

// Shared utilities exports
export 'shared/math_utils.dart';
export 'shared/validation_utils.dart';
export 'shared/shared.dart';
