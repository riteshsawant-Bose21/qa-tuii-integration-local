/// Amplifier specifications and data types for API integration
/// 
/// This module contains amplifier data structures that would typically
/// be fetched from an amplifier specifications API in production.

/// Amplifier model specifications
class AmpModel {
  final String name;
  final int channels;
  final double peakPerChannel;

  const AmpModel({
    required this.name,
    required this.channels,
    required this.peakPerChannel,
  });

  double get totalCapacity => channels * peakPerChannel;

  Map<String, dynamic> toJson() => {
    'name': name,
    'channels': channels,
    'peak_per_channel': peakPerChannel,
    'total_capacity': totalCapacity,
  };

  factory AmpModel.fromJson(Map<String, dynamic> json) => AmpModel(
    name: json['name'] ?? '',
    channels: json['channels'] ?? 4,
    peakPerChannel: (json['peak_per_channel'] ?? 600.0).toDouble(),
  );

  @override
  String toString() => '$name (${peakPerChannel.toInt()}W × ${channels}ch)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmpModel &&
        other.name == name &&
        other.channels == channels &&
        other.peakPerChannel == peakPerChannel;
  }

  @override
  int get hashCode =>
      name.hashCode ^ channels.hashCode ^ peakPerChannel.hashCode;
}

/// Assignment: one amplifier and the circuits assigned to it.
class Assignment {
  final AmpModel amp;
  final List<Circuit> loads;
  // Add debug fields if needed
  Assignment({required this.amp, required this.loads});
}

/// CircuitCalc: internal wrapper for circuit calculations
class CircuitCalc {
  final Circuit base;
  double ppkTotal;
  double offsetDB;
  List<String> errors;

  CircuitCalc({required this.base, this.ppkTotal = 0, this.offsetDB = 0, List<String>? errors})
      : errors = errors ?? [];
}

/// Circuit: minimal stub, expand as needed to match Go struct
class Circuit {
  final String model;
  final int speakerCount;
  final String mode;
  final double? tapWatts;
  final double? impedance;
  final double? offsetDB;

  Circuit({
    required this.model,
    required this.speakerCount,
    required this.mode,
    this.tapWatts,
    this.impedance,
    this.offsetDB,
  });
}
