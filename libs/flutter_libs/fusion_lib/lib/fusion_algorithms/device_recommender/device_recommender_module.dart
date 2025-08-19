/// Device Recommender Algorithm Module
/// 
/// This module provides DSP device recommendations for the Fusion system.
/// 
/// Usage:
/// ```dart
/// import 'package:fusion_lib/fusion_algorithms/device_recommender/device_recommender.dart';
/// 
/// final input = RecommendInput(
///   analogInputs: 6,
///   analogOutputs: 4,
///   networkInputs: 0,
///   networkOutputs: 0,
///   bluetoothInputs: 2,
/// );
/// 
/// final devices = DeviceRecommender.recommendDevices(input);
/// print('Recommended devices: $devices');
/// ```

library device_recommender_module;

export 'device_recommender.dart';
