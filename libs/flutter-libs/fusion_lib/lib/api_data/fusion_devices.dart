/// Unified Fusion Devices API
/// 
/// This module provides a unified interface to access all device catalogs
/// through a single FusionDevices class with convenient getter methods.

library fusion_devices;

import 'dart:convert';
import 'speakers/speaker_catalog.dart';
import 'amplifiers/amplifier_catalog.dart';
import 'devices/device_catalog.dart';
import 'controllers/controller_catalog.dart';
import 'endpoints/endpoint_catalog.dart';

// Export the types that users might need
export 'speakers/speaker_types.dart';
export 'amplifiers/amplifier_types.dart';
export 'devices/device_types.dart';
export 'controllers/controller_types.dart';
export 'endpoints/endpoint_types.dart';

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
  
  /// Get DSP devices as JSON string
  String getDevices() {
    final devices = DeviceCatalog.dspDevices.map((d) => d.toJson()).toList();
    return jsonEncode(devices);
  }

  /// Get all devices (both DSP and non-DSP) as JSON string
  String getAllDevices() {
    final devices = DeviceCatalog.devices.map((d) => d.toJson()).toList();
    return jsonEncode(devices);
  }

  /// Get all controllers as JSON string
  String getControllers() {
    final controllers = ControllerCatalog.controllers.map((c) => c.toJson()).toList();
    return jsonEncode(controllers);
  }

  /// Get all Bluetooth endpoints as JSON string
  String getBluetoothEndpoints() {
    final endpoints = EndpointCatalog.bluetoothEndpoints.map((e) => e.toJson()).toList();
    return jsonEncode(endpoints);
  }

  /// Get all XLR endpoints as JSON string
  String getXLREndpoints() {
    final endpoints = EndpointCatalog.xlrEndpoints.map((e) => e.toJson()).toList();
    return jsonEncode(endpoints);
  }

  /// Get all endpoints as JSON string
  String getAllEndpoints() {
    final endpoints = EndpointCatalog.getAllEndpoints().map((e) => e.toJson()).toList();
    return jsonEncode(endpoints);
  }
}

/// Global instance for easy access
final fusionDevices = FusionDevices();
