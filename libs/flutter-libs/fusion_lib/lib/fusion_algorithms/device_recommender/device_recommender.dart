/// Device Recommender Algorithm Module
/// 
/// This module provides DSP device recommendations for the Fusion system,
/// implementing smart device selection based on I/O requirements.
/// 
/// Key Features:
/// - Automatic device selection (Mini, Wall Plate, Amps)
/// - I/O affinity optimization (processing close to source/destination)
/// - Minimum processor requirement analysis
/// - Distributed vs centralized processing recommendations
/// - Support for analog, network, and Bluetooth inputs

library device_recommender;

import '../../api_data/devices/devices.dart';

/// Input requirements for device recommendation
class RecommendInput {
  final int analogInputs;
  final int analogOutputs;
  final int networkInputs;
  final int networkOutputs;
  final int bluetoothInputs;
  final bool preferWallIo;       // true = prefer adding wall I/O over upgrading to larger devices (e.g., 4ch + Wall I/O vs 8ch PowerSmart)
  final bool preferDistributed;  // true = prefer distributed processing (FM6+FM8Y) over single large device (reserved for future use)

  const RecommendInput({
    required this.analogInputs,
    required this.analogOutputs,
    required this.networkInputs,
    required this.networkOutputs,
    required this.bluetoothInputs,
    this.preferWallIo = false,
    this.preferDistributed = false,
  });

  /// Create from JSON
  factory RecommendInput.fromJson(Map<String, dynamic> json) {
    return RecommendInput(
      analogInputs: json['analog_inputs'] as int? ?? 0,
      analogOutputs: json['analog_outputs'] as int? ?? 0,
      networkInputs: json['network_inputs'] as int? ?? 0,
      networkOutputs: json['network_outputs'] as int? ?? 0,
      bluetoothInputs: json['bluetooth_inputs'] as int? ?? 0,
      preferWallIo: json['prefer_wall_io'] as bool? ?? false,
      preferDistributed: json['prefer_distributed'] as bool? ?? false,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'analog_inputs': analogInputs,
      'analog_outputs': analogOutputs,
      'network_inputs': networkInputs,
      'network_outputs': networkOutputs,
      'bluetooth_inputs': bluetoothInputs,
      'prefer_wall_io': preferWallIo,
      'prefer_distributed': preferDistributed,
    };
  }

  @override
  String toString() {
    return 'RecommendInput(analog: $analogInputs/$analogOutputs, '
           'network: $networkInputs/$networkOutputs, bluetooth: $bluetoothInputs, '
           'preferWallIo: $preferWallIo, preferDistributed: $preferDistributed)';
  }
}

/// Device Recommender Class
/// 
/// Implements DSP Device Recommendations (Fusion Mini, Wall Plate, Amps)
/// Based on the specification's fundamental rules:
/// - Provide input processing as close to input as possible, output processing close to output (I/O Affinity)
/// - Each DSP device has enough processing power for local I/Os
/// - Use smallest processor(s) possible
/// - Try distributed/selective forwarding over centralized processing
/// Note: "Mini" in the specification refers to Fusion Mini devices (FM6, FM8Y)
class DeviceRecommender {
  /// Recommend devices based on I/O requirements
  static List<String> recommendDevices(RecommendInput input) {
    final devices = <String>[];

    // Total analog inputs = analog + bluetooth (as per spec)
    final totalAnalogInputs = input.analogInputs + input.bluetoothInputs;
    final totalAnalogOutputs = input.analogOutputs;
    final totalNetworkIO = input.networkInputs + input.networkOutputs;

    // Step 1: Find optimal device(s) that can handle both analog and network I/O
    final optimalDevice = DeviceCatalog.findOptimalDevice(
      analogInputs: totalAnalogInputs,
      analogOutputs: totalAnalogOutputs,
      networkIO: totalNetworkIO,
      preferSmaller: true,
    );

    if (optimalDevice != null) {
      // Check for special cases based on device and user preferences
      devices.addAll(_handleSpecialCases(optimalDevice, totalAnalogInputs, totalAnalogOutputs, input.preferWallIo, input.preferDistributed));
      return devices;
    }

    // Step 2: Handle analog I/O requirements first
    devices.addAll(_recommendAnalogDevices(totalAnalogInputs, totalAnalogOutputs, input.preferWallIo, input.preferDistributed));

    // Step 3: Check if selected devices can handle network I/O, if not add more
    if (totalNetworkIO > 0) {
      int providedNetworkIO = 0;
      for (final deviceName in devices) {
        final device = DeviceCatalog.findByName(deviceName);
        if (device != null) {
          providedNetworkIO += device.networkIO;
        }
      }
      
      if (providedNetworkIO < totalNetworkIO) {
        final remainingNetworkIO = totalNetworkIO - providedNetworkIO;
        devices.addAll(_recommendNetworkDevices(remainingNetworkIO));
      }
    }

    return devices;
  }

  /// Handle special cases for device selection based on user preferences
  static List<String> _handleSpecialCases(DeviceSpec optimalDevice, int inputs, int outputs, bool preferWallIO, bool preferDistributed) {
    final devices = <String>[];

    // Special case: At maximum capacity of largest single device, prefer distributed processing
    if (optimalDevice.name == "8ch PowerSmart" && 
        inputs == optimalDevice.analogInputs && 
        outputs == optimalDevice.analogOutputs) {
      // Find optimal distributed solution using device specs
      final distributedDevices = _findOptimalDistributedDevices(inputs, outputs);
      devices.addAll(distributedDevices);
      return devices;
    }

    // Check user preference for wall I/O vs device upgrade
    if (preferWallIO && optimalDevice.name == "8ch PowerSmart") {
      final powerSmart4ch = DeviceCatalog.powerSmart4ch;
      final powerSmart8ch = DeviceCatalog.powerSmart8ch;
      // If requirements exceed 4ch PowerSmart capacity but fit in 8ch PowerSmart,
      // user prefers Wall I/O expansion over device upgrade
      if ((inputs > powerSmart4ch.analogInputs || outputs > powerSmart4ch.analogOutputs) &&
          (inputs <= powerSmart8ch.analogInputs && outputs <= powerSmart8ch.analogOutputs)) {
        devices.add("4ch PowerSmart");
        devices.add("Wall I/O");
        return devices;
      }
    }

    // Use the optimal single device
    devices.add(optimalDevice.name);
    return devices;
  }

  /// Recommend network I/O devices based on requirements
  static List<String> _recommendNetworkDevices(int totalNetworkIO) {
    final devices = <String>[];
    final fusionMiniDevices = DeviceCatalog.getFusionMiniDevices();
    
    // Sort by network I/O capacity (descending) to use most capable devices first
    fusionMiniDevices.sort((a, b) => b.networkIO.compareTo(a.networkIO));
    
    int remainingNetworkIO = totalNetworkIO;
    
    for (final device in fusionMiniDevices) {
      while (remainingNetworkIO > 0 && device.canHandleNetworkIO(remainingNetworkIO >= device.networkIO ? device.networkIO : remainingNetworkIO)) {
        devices.add(device.name);
        remainingNetworkIO -= device.networkIO;
        if (remainingNetworkIO <= 0) break;
      }
      if (remainingNetworkIO <= 0) break;
    }
    
    return devices;
  }

  /// Find optimal combination of devices for distributed processing
  static List<String> _findOptimalDistributedDevices(int inputs, int outputs) {
    final devices = <String>[];
    final availableDevices = DeviceCatalog.getAllDevices();
    
    // Filter devices that have both inputs and outputs (for distributed processing)
    final distributedCapableDevices = availableDevices
        .where((device) => device.analogInputs > 0 && device.analogOutputs > 0)
        .toList();
    
    // Sort by total analog I/O capacity (descending)
    distributedCapableDevices.sort((a, b) => b.totalAnalogIO.compareTo(a.totalAnalogIO));
    
    int remainingInputs = inputs;
    int remainingOutputs = outputs;
    
    // Try to find optimal combination
    for (final device in distributedCapableDevices) {
      if (remainingInputs <= 0 && remainingOutputs <= 0) break;
      
      // Check if this device can contribute to the solution
      if (device.analogInputs > 0 && remainingInputs > 0) {
        devices.add(device.name);
        remainingInputs -= device.analogInputs;
        remainingOutputs -= device.analogOutputs;
      } else if (device.analogOutputs > 0 && remainingOutputs > 0) {
        devices.add(device.name);
        remainingInputs -= device.analogInputs;
        remainingOutputs -= device.analogOutputs;
      }
    }
    
    // If still not enough capacity, add input-only devices
    if (remainingInputs > 0) {
      final inputOnlyDevices = availableDevices
          .where((device) => device.analogInputs > 0 && device.analogOutputs == 0)
          .toList();
      
      inputOnlyDevices.sort((a, b) => b.analogInputs.compareTo(a.analogInputs));
      
      for (final device in inputOnlyDevices) {
        if (remainingInputs <= 0) break;
        devices.add(device.name);
        remainingInputs -= device.analogInputs;
      }
    }
    
    return devices;
  }

  /// Recommend analog devices using device specs instead of hardcoded logic
  static List<String> _recommendAnalogDevices(int inputs, int outputs, bool preferWallIO, bool preferDistributed) {
    final devices = <String>[];

    // Get all devices and sort by total analog I/O capacity (ascending)
    final availableDevices = DeviceCatalog.getAllDevices();
    final analogCapableDevices = availableDevices
        .where((device) => device.analogInputs > 0 || device.analogOutputs > 0)
        .toList();
    
    // Sort by total analog I/O capacity (smallest first)
    analogCapableDevices.sort((a, b) => a.totalAnalogIO.compareTo(b.totalAnalogIO));

    // Case 1: Try to find a single device that can handle all requirements
    final singleDevice = DeviceCatalog.findOptimalDevice(
      analogInputs: inputs,
      analogOutputs: outputs,
      networkIO: 0,
      preferSmaller: true,
    );

    if (singleDevice != null) {
      // Special case: At maximum capacity of largest single device, prefer distributed processing
      if (singleDevice.name == "8ch PowerSmart" && 
          inputs == singleDevice.analogInputs && 
          outputs == singleDevice.analogOutputs) {
        // Find optimal distributed solution using device specs
        final distributedDevices = _findOptimalDistributedDevices(inputs, outputs);
        devices.addAll(distributedDevices);
        return devices;
      }

      // Check user preference for wall I/O vs device upgrade
      if (preferWallIO && singleDevice.name == "8ch PowerSmart") {
        final powerSmart4ch = DeviceCatalog.powerSmart4ch;
        final powerSmart8ch = DeviceCatalog.powerSmart8ch;
        // If requirements exceed 4ch PowerSmart capacity but fit in 8ch PowerSmart,
        // user prefers Wall I/O expansion over device upgrade
        if ((inputs > powerSmart4ch.analogInputs || outputs > powerSmart4ch.analogOutputs) &&
            (inputs <= powerSmart8ch.analogInputs && outputs <= powerSmart8ch.analogOutputs)) {
          devices.add("4ch PowerSmart");
          devices.add("Wall I/O");
          return devices;
        }
      }

      // Use the optimal single device
      devices.add(singleDevice.name);
      return devices;
    }

    // Case 2: No single device can handle all requirements
    // Check if requirements exceed largest single device capacity
    final largestDevice = analogCapableDevices.last; // Largest by total analog I/O
    
    if (inputs > largestDevice.analogInputs || outputs > largestDevice.analogOutputs) {
      // Use distributed processing with optimal device combination
      if (preferDistributed || (inputs > DeviceCatalog.powerSmart8ch.analogInputs || outputs > DeviceCatalog.powerSmart8ch.analogOutputs)) {
        final distributedDevices = _findOptimalDistributedDevices(inputs, outputs);
        devices.addAll(distributedDevices);
        return devices;
      }

      // Fallback to PowerSmart + Wall I/O
      devices.add("4ch PowerSmart");
      devices.add("Wall I/O");
      return devices;
    }

    // Case 3: Fallback to largest available device
    devices.add(largestDevice.name);
    return devices;
  }
}
