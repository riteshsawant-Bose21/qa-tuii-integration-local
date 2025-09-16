/// Device catalog containing product specifications
/// 
/// This module contains the device catalog that would typically be
/// contains hardcoded data for development and testing purposes.

import 'device_types.dart';

/// Device catalog with all available Fusion devices
class DeviceCatalog {
  /// List of DSP devices
  static const List<DeviceSpec> dspDevices = [
    DeviceSpec(
      name: "4ch PowerSmart", 
      analogInputs: 4, 
      analogOutputs: 4, 
      networkInputs: 4,
      networkOutputs: 4,
      imageUrl: 'assets/images/bose_dsp.png',
      price: 100.0,
    ),
    DeviceSpec(
      name: "8ch PowerSmart", 
      analogInputs: 8, 
      analogOutputs: 8, 
      networkInputs: 8,
      networkOutputs: 8,
      imageUrl: 'assets/images/bose_dsp.png',
      price: 200.0,
    ),
    DeviceSpec(
      name: "FM6", 
      analogInputs: 4, 
      analogOutputs: 4, 
      networkInputs: 0,
      networkOutputs: 0,
      imageUrl: 'assets/images/bose_dsp.png',
      price: 300.0,
    ),
    DeviceSpec(
      name: "FM8Y", 
      analogInputs: 4, 
      analogOutputs: 8, 
      networkInputs: 8,
      networkOutputs: 8,
      imageUrl: 'assets/images/bose_dsp.png',
      price: 400.0,
    ),
  ];

  /// List of non-DSP devices (amplifiers, network devices, etc.)
  static const List<DeviceSpec> otherDevices = [
    DeviceSpec(
      name: "FusionConnect", 
      analogInputs: 24, 
      analogOutputs: 24, 
      networkInputs: 0,
      networkOutputs: 0,
      imageUrl: 'assets/images/bose_dsp.png',
      price: 150.0,
    ),
    DeviceSpec(
      name: "PowerPure Amplifier", 
      analogInputs: 0, 
      analogOutputs: 4, 
      networkInputs: 0,
      networkOutputs: 0,
      imageUrl: 'assets/images/bose_dsp.png',
      price: 200.0,
    ),
  ];

  /// All devices combined
  static List<DeviceSpec> get devices => [...dspDevices, ...otherDevices];

  /// Quick access to specific devices
  static DeviceSpec get powerSmart4ch => dspDevices[0];
  static DeviceSpec get powerSmart8ch => dspDevices[1];
  static DeviceSpec get fm6 => dspDevices[2];
  static DeviceSpec get fm8y => dspDevices[3];
  static DeviceSpec get fusionConnect => otherDevices[0];
  static DeviceSpec get powerPureAmplifier => otherDevices[1];

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
    return devices.where((device) => device.totalNetworkIO > 0).toList();
  }

  /// Get devices by network I/O capacity
  static List<DeviceSpec> getByNetworkCapacity({required int networkInputs, required int networkOutputs}) {
    return devices
        .where((device) => device.canHandleNetworkIO(inputs: networkInputs, outputs: networkOutputs))
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
    sorted.sort((a, b) => a.totalNetworkIO.compareTo(b.totalNetworkIO));
    return sorted;
  }

  /// Find optimal device for given requirements
  static DeviceSpec? findOptimalDevice({
    required int analogInputs,
    required int analogOutputs,
    int networkInputs = 0,
    int networkOutputs = 0,
    bool preferSmaller = true, // true = prefer smaller devices, false = prefer larger
  }) {
    final candidates = devices.where((device) =>
        device.canHandle(inputs: analogInputs, outputs: analogOutputs) &&
        device.canHandleNetworkIO(inputs: networkInputs, outputs: networkOutputs)).toList();

    if (candidates.isEmpty) return null;

    if (preferSmaller) {
      // Sort by total capacity (smallest first)
      candidates.sort((a, b) => 
          (a.totalAnalogIO + a.totalNetworkIO).compareTo(b.totalAnalogIO + b.totalNetworkIO));
    } else {
      // Sort by total capacity (largest first)
      candidates.sort((a, b) => 
          (b.totalAnalogIO + b.totalNetworkIO).compareTo(a.totalAnalogIO + a.totalNetworkIO));
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

  /// Get unique network input configurations available
  static List<int> getUniqueNetworkInputs() {
    final networkInputs = devices.map((device) => device.networkInputs).toSet().toList();
    networkInputs.sort();
    return networkInputs;
  }

  /// Get unique network output configurations available
  static List<int> getUniqueNetworkOutputs() {
    final networkOutputs = devices.map((device) => device.networkOutputs).toSet().toList();
    networkOutputs.sort();
    return networkOutputs;
  }
}
