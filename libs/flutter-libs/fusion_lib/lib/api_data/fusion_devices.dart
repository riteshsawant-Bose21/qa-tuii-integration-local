/// Unified Fusion Devices API
/// 
/// This module provides a unified interface to access all device catalogs
/// through a single FusionDevices class with convenient getter methods.

library fusion_devices;

import 'dart:convert';
import 'speakers/speaker_catalog.dart';
import 'amplifiers/amplifier_catalog.dart';
import 'devices/device_catalog.dart';

// Export the types that users might need
export 'speakers/speaker_types.dart';
export 'amplifiers/amplifier_types.dart';
export 'devices/device_types.dart';

/// Unified interface for accessing all Fusion device catalogs
class FusionDevices {
  static final FusionDevices _instance = FusionDevices._internal();
  
  factory FusionDevices() {
    return _instance;
  }
  
  FusionDevices._internal();
  
  /// Get all speakers as JSON string
  String getSpeakers() {
    final speakers = SpeakerCatalog.database.values.map((s) => s.toJson()).toList();
    return jsonEncode(speakers);
  }
  
  /// Get all amplifiers as JSON string
  String getAmplifiers() {
    final amps = AmpCatalog.models.map((a) => a.toJson()).toList();
    return jsonEncode(amps);
  }
  
  /// Get all DSP devices as JSON string
  String getDevices() {
    final devices = DeviceCatalog.devices.map((d) => d.toJson()).toList();
    return jsonEncode(devices);
  }
}

/// Global instance for easy access
final fusionDevices = FusionDevices();
