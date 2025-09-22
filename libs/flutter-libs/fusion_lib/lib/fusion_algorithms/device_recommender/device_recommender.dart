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
/// 
/// Scaling Rules:
/// - Always start with 4ch PowerSmart
/// - Input Scaling: Switch to FM6 + PowerPure Amplifier for more inputs but fewer outputs
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

/// Analog-only input requirements for device recommendation
/// Separates line outputs from loudspeaker outputs for accurate matching
class AnalogRecommendInput {
  final int analogInputs;      // microphone, line, RCA, 3.5mm inputs
  final int lineOutputs;       // line-level analog outputs  
  final int loudspeakerOutputs; // amplified/powered outputs

  const AnalogRecommendInput({
    required this.analogInputs,
    required this.lineOutputs, 
    required this.loudspeakerOutputs,
  });

  /// Create from JSON
  factory AnalogRecommendInput.fromJson(Map<String, dynamic> json) {
    return AnalogRecommendInput(
      analogInputs: json['analog_inputs'] as int? ?? 0,
      lineOutputs: json['line_outputs'] as int? ?? 0,
      loudspeakerOutputs: json['loudspeaker_outputs'] as int? ?? 0,
    );
  }

  /// Convert to JSON
  Map<String, dynamic> toJson() {
    return {
      'analog_inputs': analogInputs,
      'line_outputs': lineOutputs,
      'loudspeaker_outputs': loudspeakerOutputs,
    };
  }

  @override
  String toString() {
    return 'AnalogRecommendInput(inputs: $analogInputs, line: $lineOutputs, speakers: $loudspeakerOutputs)';
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

  /// Recommend devices based on analog I/O requirements only
  /// Follows exact scaling rules: always start with 4ch PowerSmart, then apply scaling patterns
  static List<String> recommendAnalogDevices(AnalogRecommendInput input) {
    // Total inputs and outputs for comparison
    final totalInputs = input.analogInputs;
    final totalOutputs = input.lineOutputs + input.loudspeakerOutputs;
    
    // STEP 1: Always start with 4ch PowerSmart and check if it satisfies requirements
    final powerSmart4ch = DeviceCatalog.powerSmart4ch;
    if (totalInputs <= powerSmart4ch.analogInputs && 
        input.lineOutputs <= powerSmart4ch.lineOutputs &&
        input.loudspeakerOutputs <= powerSmart4ch.loudspeakerOutputs) {
      return ['4ch PowerSmart'];
    }
    
    // STEP 2: Apply scaling rules based on input/output ratio
    // Special rule: If line outputs are needed and total I/O is very large, prefer input scaling
    if (input.lineOutputs > 4 && (totalInputs + totalOutputs) > 16) {
      return _inputScalingAnalog(input);
    }
    
    if (totalInputs > totalOutputs) {
      // INPUT SCALING: More inputs than outputs → Switch to FM6 + PowerPure Amplifier
      return _inputScalingAnalog(input);
    } else if (totalInputs == totalOutputs) {
      // EQUAL SCALING: Equal inputs and outputs → PowerSmart series scaling
      return _equalScalingAnalog(input);
    } else {
      // OUTPUT SCALING: More outputs than inputs → PowerSmart series scaling
      return _outputScalingAnalog(input);
    }
  }
  
  /// Input Scaling: Switch to FM6 + PowerPure Amplifier, add more FM6 units as needed
  static List<String> _inputScalingAnalog(AnalogRecommendInput input) {
    final selected = <String>[];
    final fm6 = DeviceCatalog.fm6;
    final powerPure = DeviceCatalog.powerPureAmplifier;
    
    var remainingInputs = input.analogInputs;
    var remainingLineOutputs = input.lineOutputs;
    var remainingLoudspeakerOutputs = input.loudspeakerOutputs;
    
    // Add FM6 units to cover inputs and line outputs
    while (remainingInputs > 0 || remainingLineOutputs > 0) {
      selected.add('FM6');
      remainingInputs = math.max(0, remainingInputs - fm6.analogInputs);
      remainingLineOutputs = math.max(0, remainingLineOutputs - fm6.lineOutputs);
    }
    
    // Add PowerPure Amplifiers to cover loudspeaker outputs
    while (remainingLoudspeakerOutputs > 0) {
      selected.add('PowerPure Amplifier');
      remainingLoudspeakerOutputs = math.max(0, remainingLoudspeakerOutputs - powerPure.loudspeakerOutputs);
    }
    
    return selected;
  }
  
  /// Equal Scaling: PowerSmart series only, scale 4ch -> 8ch -> add 4ch -> replace with 2x8ch
  static List<String> _equalScalingAnalog(AnalogRecommendInput input) {
    final powerSmart4ch = DeviceCatalog.powerSmart4ch;
    final powerSmart8ch = DeviceCatalog.powerSmart8ch;
    
    // Check if 8ch PowerSmart can handle it
    if (input.analogInputs <= powerSmart8ch.analogInputs && 
        input.lineOutputs <= powerSmart8ch.lineOutputs &&
        input.loudspeakerOutputs <= powerSmart8ch.loudspeakerOutputs) {
      
      // Special rule: For mixed significant line/loudspeaker outputs, prefer scaling up
      if (input.lineOutputs >= 4 && input.loudspeakerOutputs >= 4) {
        return ['8ch PowerSmart', '4ch PowerSmart'];
      }
      
      return ['8ch PowerSmart'];
    }
    
    // Need more than 8ch - try 8ch + 4ch first
    var remainingInputs = math.max(0, input.analogInputs - powerSmart8ch.analogInputs);
    var remainingLineOutputs = math.max(0, input.lineOutputs - powerSmart8ch.lineOutputs);
    var remainingLoudspeakerOutputs = math.max(0, input.loudspeakerOutputs - powerSmart8ch.loudspeakerOutputs);
    
    // Check if 8ch + 4ch can handle it
    if (remainingInputs <= powerSmart4ch.analogInputs && 
        remainingLineOutputs <= powerSmart4ch.lineOutputs &&
        remainingLoudspeakerOutputs <= powerSmart4ch.loudspeakerOutputs) {
      return ['8ch PowerSmart', '4ch PowerSmart'];
    }
    
    // Check if 2x8ch would be better
    if (input.analogInputs <= powerSmart8ch.analogInputs * 2 && 
        input.lineOutputs <= powerSmart8ch.lineOutputs * 2 &&
        input.loudspeakerOutputs <= powerSmart8ch.loudspeakerOutputs * 2) {
      return ['8ch PowerSmart', '8ch PowerSmart'];
    }
    
    // For larger requirements, keep adding units
    var selected = <String>['8ch PowerSmart'];
    remainingInputs = math.max(0, input.analogInputs - powerSmart8ch.analogInputs);
    remainingLineOutputs = math.max(0, input.lineOutputs - powerSmart8ch.lineOutputs);
    remainingLoudspeakerOutputs = math.max(0, input.loudspeakerOutputs - powerSmart8ch.loudspeakerOutputs);
    
    while (remainingInputs > 0 || remainingLineOutputs > 0 || remainingLoudspeakerOutputs > 0) {
      // Try to add another 8ch if it makes sense
      if (remainingInputs > powerSmart4ch.analogInputs || 
          remainingLineOutputs > powerSmart4ch.lineOutputs ||
          remainingLoudspeakerOutputs > powerSmart4ch.loudspeakerOutputs) {
        selected.add('8ch PowerSmart');
        remainingInputs = math.max(0, remainingInputs - powerSmart8ch.analogInputs);
        remainingLineOutputs = math.max(0, remainingLineOutputs - powerSmart8ch.lineOutputs);
        remainingLoudspeakerOutputs = math.max(0, remainingLoudspeakerOutputs - powerSmart8ch.loudspeakerOutputs);
      } else {
        // Add 4ch for remaining small amounts
        selected.add('4ch PowerSmart');
        remainingInputs = math.max(0, remainingInputs - powerSmart4ch.analogInputs);
        remainingLineOutputs = math.max(0, remainingLineOutputs - powerSmart4ch.lineOutputs);
        remainingLoudspeakerOutputs = math.max(0, remainingLoudspeakerOutputs - powerSmart4ch.loudspeakerOutputs);
      }
    }
    
    return selected;
  }
  
  /// Output Scaling: PowerSmart series only, same pattern as Equal Scaling
  static List<String> _outputScalingAnalog(AnalogRecommendInput input) {
    // Output scaling follows same pattern as equal scaling - use PowerSmart series only
    return _equalScalingAnalog(input);
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
