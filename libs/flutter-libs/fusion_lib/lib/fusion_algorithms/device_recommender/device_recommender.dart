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

    // Step 1: Start with 4ch PowerSmart (as per spec)
    devices.addAll(_recommendAnalogDevices(totalAnalogInputs, totalAnalogOutputs, input.preferWallIo, input.preferDistributed));

    // Step 2: Handle network I/O (24 inputs/outputs per Fusion Mini)
    if (totalNetworkIO > 0) {
      final numMinis = (totalNetworkIO / 24.0).ceil();
      for (int i = 0; i < numMinis; i++) {
        // Use FM6 for network I/O handling (Fusion Mini devices)
        devices.add("FM6");
      }
    }

    return devices;
  }

  /// recommendAnalogDevices implements the core decision logic from specification
  /// with user preference options for wall I/O vs device upgrades
  static List<String> _recommendAnalogDevices(int inputs, int outputs, bool preferWallIO, bool preferDistributed) {
    final devices = <String>[];

    // Start with 4ch PowerSmart
    final powerSmart4ch = DeviceCatalog.powerSmart4ch;
    final powerSmart8ch = DeviceCatalog.powerSmart8ch;

    // Case 1: Both inputs and outputs fit in 4ch PowerSmart
    if (inputs <= powerSmart4ch.analogInputs && outputs <= powerSmart4ch.analogOutputs) {
      devices.add("4ch PowerSmart");
      return devices;
    }

    // Case 2: Either inputs or outputs exceed 4ch PowerSmart
    // Check if both can fit in 8ch PowerSmart first
    if (inputs <= powerSmart8ch.analogInputs && outputs <= powerSmart8ch.analogOutputs) {
      // Special case: At maximum 8ch capacity (8 inputs, 8 outputs)
      if (inputs == powerSmart8ch.analogInputs && outputs == powerSmart8ch.analogOutputs) {
        // Always use distributed FM6 + FM8Y for maximum capacity
        devices.add("FM6");
        devices.add("FM8Y");
        return devices;
      }

      // User preference: Wall I/O vs upgrading to 8ch PowerSmart
      if (preferWallIO) {
        // Prefer adding wall I/O to 4ch PowerSmart instead of upgrading
        devices.add("4ch PowerSmart");
        devices.add("Wall I/O");
        return devices;
      }

      // Default: upgrade to 8ch PowerSmart
      devices.add("8ch PowerSmart");
      return devices;
    }

    // Case 3: Outputs exceed 4ch but inputs fit in 4ch AND outputs exceed 8ch → use 4ch + Wall I/O
    if (inputs <= powerSmart4ch.analogInputs && outputs > powerSmart8ch.analogOutputs) {
      devices.add("4ch PowerSmart");
      devices.add("Wall I/O");
      return devices;
    }

    // Case 4: Inputs exceed 4ch but outputs fit in 4ch AND inputs exceed 8ch → use 4ch + Wall I/O
    if (outputs <= powerSmart4ch.analogOutputs && inputs > powerSmart8ch.analogInputs) {
      devices.add("4ch PowerSmart");
      devices.add("Wall I/O");
      return devices;
    }

    // Case 5: Either inputs or outputs exceed 8ch PowerSmart capacity → use FM6 + FM8Y
    if (inputs > powerSmart8ch.analogInputs || outputs > powerSmart8ch.analogOutputs) {
      devices.add("FM6");
      devices.add("FM8Y");
      return devices;
    }

    // Fallback to 8ch PowerSmart for any remaining cases
    devices.add("8ch PowerSmart");
    return devices;
  }
}
