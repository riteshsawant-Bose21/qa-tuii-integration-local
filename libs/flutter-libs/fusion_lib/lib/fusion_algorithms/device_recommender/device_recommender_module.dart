/// Device Recommender Algorithm Module
/// 
/// This module provides DSP device recommendations for the Fusion system
/// based on the new scaling rules and device specifications.
/// 
/// Available Inputs & Outputs:
/// - Analog Inputs: Microphone, Line, RCA, 3.5mm
/// - Network Inputs: AES67, Dante
/// - Analog Outputs: Speakers, Line outputs
/// - Network Outputs: AES67, Dante
/// - Wireless Inputs: Bluetooth
/// 
/// Device Capabilities:
/// - 4ch PowerSmart: 4 analog I/O + 4 network inputs + 4 network outputs
/// - 8ch PowerSmart: 8 analog I/O + 8 network inputs + 8 network outputs
/// - FM6: 4 analog I/O (no network)
/// - FM8Y: 4 analog inputs, 8 analog outputs + 8 network inputs + 8 network outputs
/// - FusionConnect: 24 analog I/O (no network)
/// - PowerPure Amplifier: 4 analog outputs only
/// 
/// Scaling Rules:
/// 1. Input Scaling: More inputs than outputs → FM6 + PowerPure Amplifier
/// 2. Equal Scaling: Equal I/O → PowerSmart series scaling
/// 3. Output Scaling: More outputs than inputs → PowerSmart series scaling
/// 
/// Usage:
/// ```dart
/// import 'package:fusion_lib/fusion_algorithms/device_recommender/device_recommender.dart';
/// 
/// final input = RecommendInput(
///   analogInputs: 6,
///   analogOutputs: 4,
///   networkInputs: 2,
///   networkOutputs: 2,
///   bluetoothInputs: 1,
/// );
/// 
/// final devices = DeviceRecommender.recommendDevices(input);
/// print('Recommended devices: $devices');
/// ```

library device_recommender_module;

export 'device_recommender.dart';
