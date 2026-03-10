/// Amplifier Types
/// 
/// Defines the data models for amplifiers

/// Enum for amplifier operation modes
enum PowerMode {
  symmetrical,
  asymmetrical,
}

/// Power specification for a given mode
class PowerSpec {
  /// Power rating in watts (per channel for symmetrical, shareable for asymmetrical)
  final int watts;
  
  /// Description of power rating (e.g., "per channel", "shareable total")
  final String? channelInfo;
  
  /// Total amplifier capacity in watts (maximum power the amplifier can deliver)
  final int totalCapacity;

  const PowerSpec({
    required this.watts,
    required this.totalCapacity,
    this.channelInfo,
  });

  @override
  String toString() {
    return channelInfo != null 
        ? '$watts W ($channelInfo), Total Capacity: $totalCapacity W' 
        : '$watts W, Total Capacity: $totalCapacity W';
  }
}

/// Amplifier Model
class AmplifierModel {
  final String name;
  final int channels;  // Number of channels (4 for all current models)
  final PowerSpec symmetrical;
  final PowerSpec asymmetrical;

  const AmplifierModel({
    required this.name,
    required this.channels,
    required this.symmetrical,
    required this.asymmetrical,
  });

  /// Get power specification for a specific mode
  PowerSpec getPowerSpec(PowerMode mode) {
    return mode == PowerMode.symmetrical ? symmetrical : asymmetrical;
  }

  /// Convert to JSON map
  Map<String, dynamic> toJson() {
    return {
      'name': name,
      'channels': channels,
      'symmetrical': {
        'watts': symmetrical.watts,
        'channelInfo': symmetrical.channelInfo,
        'totalCapacity': symmetrical.totalCapacity,
      },
      'asymmetrical': {
        'watts': asymmetrical.watts,
        'channelInfo': asymmetrical.channelInfo,
        'totalCapacity': asymmetrical.totalCapacity,
      },
    };
  }

  @override
  String toString() {
    return '$name ($channels channels)\n'
           '  Symmetrical: $symmetrical\n'
           '  Asymmetrical: $asymmetrical';
  }
}