/// Device Recommender Algorithm Module
/// 
/// This module provides DSP device recommendations for the Fusion system,
/// implementing smart device selection based on I/O requirements.
/// 
/// Available Inputs & Outputs:
/// - Analog Inputs: Microphone, Line, RCA, 3.5mm
/// - Network Inputs: AES67, Dante
/// - Analog Outputs: Speakers, Line outputs
/// - Network Outputs: AES67, Dante
/// - Wireless Inputs: Bluetooth
/// 
/// Device Capabilities:
/// - 4ch PowerSmart: Analog I/O: 8 (4 inputs, 4 speaker outputs), Network: 4 inputs + 4 outputs
/// - 8ch PowerSmart: Analog I/O: 16 (8 inputs, 8 speaker outputs), Network: 8 inputs + 8 outputs
/// - FM6: Analog I/O: 8 (4 inputs, 4 outputs), Network I/O: 0
/// - FM8Y: Analog I/O: 12 (4 inputs, 8 outputs), Network: 8 inputs + 8 outputs
/// - FusionConnect: Analog I/O: 48 (24 inputs, 24 outputs)
/// 
/// Scaling Rules:
/// - Always start with 4ch PowerSmart
/// - Input Scaling: Switch to FM6 + PowerPure Amplifier for more inputs but fewer outputs, use FM8Y for network I/O
/// - Equal Scaling: Use PowerSmart series only, scaling up as needed
/// - Output Scaling: Use PowerSmart series only, adding units as needed
/// 
/// IMPORTANT: FM series (FM6, FM8Y) are ONLY used in Input Scaling. 
/// Equal Scaling and Output Scaling must use PowerSmart series exclusively.

library device_recommender;

import 'dart:math' as math;
import '../../api_data/devices/devices.dart';

/// Input types enumeration
enum InputType {
  microphone,
  line,
  rca,
  mm35, // 3.5mm
  aes67,
  dante,
  bluetooth,
}

/// Output types enumeration  
enum DeviceOutputType {
  speakers,
  lineOutput,
  aes67,
  dante,
}

/// Input requirements for device recommendation
class RecommendInput {
  final int analogInputs;
  final int analogOutputs;
  final int networkInputs;
  final int networkOutputs;
  final int bluetoothInputs;

  const RecommendInput({
    required this.analogInputs,
    required this.analogOutputs,
    required this.networkInputs,
    required this.networkOutputs,
    required this.bluetoothInputs,
  });

  /// Create from JSON
  factory RecommendInput.fromJson(Map<String, dynamic> json) {
    return RecommendInput(
      analogInputs: json['analog_inputs'] as int? ?? 0,
      analogOutputs: json['analog_outputs'] as int? ?? 0,
      networkInputs: json['network_inputs'] as int? ?? 0,
      networkOutputs: json['network_outputs'] as int? ?? 0,
      bluetoothInputs: json['bluetooth_inputs'] as int? ?? 0,
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
    };
  }

  @override
  String toString() {
    return 'RecommendInput(analog: $analogInputs/$analogOutputs, '
           'network: $networkInputs/$networkOutputs, bluetooth: $bluetoothInputs)';
  }
}

/// Device Recommender Class
/// 
/// Implements DSP Device Recommendations based on new specifications:
/// - Always starts with 4ch PowerSmart
/// - Implements Input Scaling, Equal Scaling, and Output Scaling rules
/// - Handles analog, network, and wireless I/O requirements
class DeviceRecommender {
  /// Recommend devices based on I/O requirements
  static List<String> recommendDevices(RecommendInput input) {
    // Total inputs include analog + bluetooth
    final totalInputs = input.analogInputs + input.bluetoothInputs;
    final totalOutputs = input.analogOutputs;
    final totalNetworkInputs = input.networkInputs;
    final totalNetworkOutputs = input.networkOutputs;
    
    // Determine scaling pattern
    if (totalInputs > totalOutputs) {
      // Input Scaling: More inputs needed than outputs
      return _inputScaling(totalInputs, totalOutputs, totalNetworkInputs, totalNetworkOutputs);
    } else if (totalInputs == totalOutputs) {
      // Equal Scaling: Equal inputs and outputs
      return _equalScaling(totalInputs, totalOutputs, totalNetworkInputs, totalNetworkOutputs);
    } else {
      // Output Scaling: More outputs needed than inputs
      return _outputScaling(totalInputs, totalOutputs, totalNetworkInputs, totalNetworkOutputs);
    }
  }
  
  /// Input Scaling: More inputs but fewer outputs
  /// Switch to FM6 + PowerPure Amplifier, add more FM6 units if needed
  static List<String> _inputScaling(int inputs, int outputs, int networkInputs, int networkOutputs) {
    final devices = <String>[];
    
    // Check if 4ch PowerSmart can handle it
    final powerSmart4ch = DeviceCatalog.powerSmart4ch;
    if (inputs <= powerSmart4ch.analogInputs && 
        outputs <= powerSmart4ch.analogOutputs &&
        networkInputs <= powerSmart4ch.networkInputs &&
        networkOutputs <= powerSmart4ch.networkOutputs) {
      devices.add("4ch PowerSmart");
      return devices;
    }
    
    // Switch to FM6 + PowerPure Amplifier pattern
    final fm6 = DeviceCatalog.fm6;
    final powerPure = DeviceCatalog.powerPureAmplifier;
    
    int remainingInputs = inputs;
    int remainingOutputs = outputs;
    int remainingNetworkInputs = networkInputs;
    int remainingNetworkOutputs = networkOutputs;
    
    // Start with FM6 + PowerPure combination
    while (remainingInputs > 0 || remainingOutputs > 0) {
      if (remainingInputs > 0) {
        devices.add("FM6");
        remainingInputs -= fm6.analogInputs;
      }
      
      if (remainingOutputs > 0) {
        devices.add("PowerPure Amplifier");
        remainingOutputs -= powerPure.analogOutputs;
      }
    }
    
    // Handle network I/O with FM8Y if needed
    if (remainingNetworkInputs > 0 || remainingNetworkOutputs > 0) {
      final fm8y = DeviceCatalog.fm8y;
      while (remainingNetworkInputs > 0 || remainingNetworkOutputs > 0) {
        devices.add("FM8Y");
        remainingNetworkInputs -= fm8y.networkInputs;
        remainingNetworkOutputs -= fm8y.networkOutputs;
      }
    }
    
    return devices;
  }
  
  /// Equal Scaling: Equal inputs and outputs
  /// Start with 4ch PowerSmart, scale to 8ch, then add more units
  /// Only use PowerSmart series (no FM series)
  static List<String> _equalScaling(int inputs, int outputs, int networkInputs, int networkOutputs) {
    final devices = <String>[];
    
    final powerSmart4ch = DeviceCatalog.powerSmart4ch;
    final powerSmart8ch = DeviceCatalog.powerSmart8ch;
    
    // Check if 4ch PowerSmart can handle it
    if (inputs <= powerSmart4ch.analogInputs && 
        outputs <= powerSmart4ch.analogOutputs &&
        networkInputs <= powerSmart4ch.networkInputs &&
        networkOutputs <= powerSmart4ch.networkOutputs) {
      devices.add("4ch PowerSmart");
      return devices;
    }
    
    // Check if 8ch PowerSmart can handle it
    if (inputs <= powerSmart8ch.analogInputs && 
        outputs <= powerSmart8ch.analogOutputs &&
        networkInputs <= powerSmart8ch.networkInputs &&
        networkOutputs <= powerSmart8ch.networkOutputs) {
      devices.add("8ch PowerSmart");
      return devices;
    }
    
    // Need multiple units - start with 8ch, then add more PowerSmart units as needed
    int remainingInputs = inputs;
    int remainingOutputs = outputs;
    int remainingNetworkInputs = networkInputs;
    int remainingNetworkOutputs = networkOutputs;
    
    // Add PowerSmart units until all requirements are met
    while (remainingInputs > 0 || remainingOutputs > 0 || remainingNetworkInputs > 0 || remainingNetworkOutputs > 0) {
      // Try to fit remaining requirements in a 4ch unit
      if (remainingInputs <= powerSmart4ch.analogInputs && 
          remainingOutputs <= powerSmart4ch.analogOutputs &&
          remainingNetworkInputs <= powerSmart4ch.networkInputs &&
          remainingNetworkOutputs <= powerSmart4ch.networkOutputs) {
        devices.add("4ch PowerSmart");
        break;
      } else {
        // Use 8ch PowerSmart for larger requirements
        devices.add("8ch PowerSmart");
        remainingInputs = math.max(0, remainingInputs - powerSmart8ch.analogInputs);
        remainingOutputs = math.max(0, remainingOutputs - powerSmart8ch.analogOutputs);
        remainingNetworkInputs = math.max(0, remainingNetworkInputs - powerSmart8ch.networkInputs);
        remainingNetworkOutputs = math.max(0, remainingNetworkOutputs - powerSmart8ch.networkOutputs);
      }
    }
    
    return devices;
  }
  
  /// Output Scaling: More outputs but current inputs are sufficient
  /// Start with 4ch PowerSmart, scale to 8ch, then add more units
  /// Only use PowerSmart series (no FM series)
  static List<String> _outputScaling(int inputs, int outputs, int networkInputs, int networkOutputs) {
    final devices = <String>[];
    
    final powerSmart4ch = DeviceCatalog.powerSmart4ch;
    final powerSmart8ch = DeviceCatalog.powerSmart8ch;
    
    // Check if 4ch PowerSmart can handle it
    if (inputs <= powerSmart4ch.analogInputs && 
        outputs <= powerSmart4ch.analogOutputs &&
        networkInputs <= powerSmart4ch.networkInputs &&
        networkOutputs <= powerSmart4ch.networkOutputs) {
      devices.add("4ch PowerSmart");
      return devices;
    }
    
    // Check if 8ch PowerSmart can handle it
    if (inputs <= powerSmart8ch.analogInputs && 
        outputs <= powerSmart8ch.analogOutputs &&
        networkInputs <= powerSmart8ch.networkInputs &&
        networkOutputs <= powerSmart8ch.networkOutputs) {
      devices.add("8ch PowerSmart");
      return devices;
    }
    
    // Need multiple units for outputs - focus on PowerSmart series only
    int remainingInputs = inputs;
    int remainingOutputs = outputs;
    int remainingNetworkInputs = networkInputs;
    int remainingNetworkOutputs = networkOutputs;
    
    // Add PowerSmart units until all requirements are met
    while (remainingOutputs > 0 || remainingInputs > 0 || remainingNetworkInputs > 0 || remainingNetworkOutputs > 0) {
      // Try to fit remaining requirements in a 4ch unit
      if (remainingOutputs <= powerSmart4ch.analogOutputs &&
          remainingInputs <= powerSmart4ch.analogInputs &&
          remainingNetworkInputs <= powerSmart4ch.networkInputs &&
          remainingNetworkOutputs <= powerSmart4ch.networkOutputs) {
        devices.add("4ch PowerSmart");
        break;
      } else {
        // Use 8ch PowerSmart for larger requirements
        devices.add("8ch PowerSmart");
        remainingInputs = math.max(0, remainingInputs - powerSmart8ch.analogInputs);
        remainingOutputs = math.max(0, remainingOutputs - powerSmart8ch.analogOutputs);
        remainingNetworkInputs = math.max(0, remainingNetworkInputs - powerSmart8ch.networkInputs);
        remainingNetworkOutputs = math.max(0, remainingNetworkOutputs - powerSmart8ch.networkOutputs);
      }
    }
    
    return devices;
  }
}
