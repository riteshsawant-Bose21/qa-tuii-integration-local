/// DSP device catalog containing product specifications
/// 
/// This module contains the DSP device catalog that would typically be
/// contains hardcoded data for development and testing purposes.

import 'device_types.dart';

/// DSP Device catalog with all available Fusion devices
class DeviceCatalog {
  static const List<DeviceSpec> devices = [
    DeviceSpec(
      name: "4ch PowerSmart", 
      analogInputs: 4, 
      analogOutputs: 4, 
      networkIO: 0,
      imageUrl: 'assets/images/bose_dsp.png'
    ),
    DeviceSpec(
      name: "8ch PowerSmart", 
      analogInputs: 8, 
      analogOutputs: 8, 
      networkIO: 0,
      imageUrl: 'assets/images/bose_dsp.png'
    ),
    DeviceSpec(
      name: "FM6", 
      analogInputs: 6, 
      analogOutputs: 0, 
      networkIO: 24, // Fusion Mini - 6 analog inputs + network I/O (24 limit)
      imageUrl: 'assets/images/bose_dsp.png'
    ),
    DeviceSpec(
      name: "FM8Y", 
      analogInputs: 8, 
      analogOutputs: 8, 
      networkIO: 24, // Fusion Mini - 8 analog ins/outs + network I/O (24 limit)
      imageUrl: 'assets/images/bose_dsp.png'
    ),
  ];

  /// Quick access to specific devices
  static DeviceSpec get powerSmart4ch => devices[0];
  static DeviceSpec get powerSmart8ch => devices[1];
  static DeviceSpec get fm6 => devices[2];
  static DeviceSpec get fm8y => devices[3];

  /// Get all devices from the catalog
  static List<DeviceSpec> getAllDevices() => devices;

  /// Find device by name
  static DeviceSpec? findByName(String name) {
    try {
      return devices.firstWhere((device) => device.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Get devices that can handle specific analog I/O requirements
  static List<DeviceSpec> getByAnalogCapacity({
    required int inputs,
    required int outputs,
  }) {
    return devices
        .where((device) => device.canHandle(inputs: inputs, outputs: outputs))
        .toList();
  }

  /// Get devices with network I/O capability
  static List<DeviceSpec> getNetworkCapableDevices() {
    return devices.where((device) => device.networkIO > 0).toList();
  }

  /// Get devices by network I/O capacity
  static List<DeviceSpec> getByNetworkCapacity(int minNetworkIO) {
    return devices
        .where((device) => device.canHandleNetworkIO(minNetworkIO))
        .toList();
  }

  /// Get PowerSmart series devices
  static List<DeviceSpec> getPowerSmartDevices() {
    return devices
        .where((device) => device.name.contains("PowerSmart"))
        .toList();
  }

  /// Get Fusion Mini series devices
  static List<DeviceSpec> getFusionMiniDevices() {
    return devices
        .where((device) => device.name.startsWith("FM"))
        .toList();
  }

  /// Get devices sorted by total analog I/O capacity
  static List<DeviceSpec> getSortedByAnalogCapacity() {
    final sorted = List<DeviceSpec>.from(devices);
    sorted.sort((a, b) => a.totalAnalogIO.compareTo(b.totalAnalogIO));
    return sorted;
  }

  /// Get devices sorted by network I/O capacity
  static List<DeviceSpec> getSortedByNetworkCapacity() {
    final sorted = List<DeviceSpec>.from(devices);
    sorted.sort((a, b) => a.networkIO.compareTo(b.networkIO));
    return sorted;
  }

  /// Find optimal device for given requirements
  static DeviceSpec? findOptimalDevice({
    required int analogInputs,
    required int analogOutputs,
    int networkIO = 0,
    bool preferSmaller = true, // true = prefer smaller devices, false = prefer larger
  }) {
    final candidates = devices.where((device) =>
        device.canHandle(inputs: analogInputs, outputs: analogOutputs) &&
        device.canHandleNetworkIO(networkIO)).toList();

    if (candidates.isEmpty) return null;

    if (preferSmaller) {
      // Sort by total capacity (smallest first)
      candidates.sort((a, b) => 
          (a.totalAnalogIO + a.networkIO).compareTo(b.totalAnalogIO + b.networkIO));
    } else {
      // Sort by total capacity (largest first)
      candidates.sort((a, b) => 
          (b.totalAnalogIO + b.networkIO).compareTo(a.totalAnalogIO + a.networkIO));
    }

    return candidates.first;
  }

  /// Get all available device names
  static List<String> getAllNames() => devices.map((device) => device.name).toList();

  /// Check if device model exists in catalog
  static bool hasDevice(String name) => 
      devices.any((device) => device.name == name);

  /// Get device count in catalog
  static int get deviceCount => devices.length;

  /// Get unique analog input configurations available
  static List<int> getUniqueAnalogInputs() {
    final inputs = devices.map((device) => device.analogInputs).toSet().toList();
    inputs.sort();
    return inputs;
  }

  /// Get unique analog output configurations available
  static List<int> getUniqueAnalogOutputs() {
    final outputs = devices.map((device) => device.analogOutputs).toSet().toList();
    outputs.sort();
    return outputs;
  }

  /// Get unique network I/O configurations available
  static List<int> getUniqueNetworkIO() {
    final networkIO = devices.map((device) => device.networkIO).toSet().toList();
    networkIO.sort();
    return networkIO;
  }
}
