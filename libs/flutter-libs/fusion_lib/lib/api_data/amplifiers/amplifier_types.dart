/// Amplifier specifications and data types for API integration
///
/// This module contains amplifier data structures that would typically
/// be fetched from an amplifier specifications API in production.

/// Power specifications for different impedance and voltage configurations
class PowerSpecs {
  // Symmetrical ratings (per channel)
  final double ratedPowerPerChannel2Ohm;   // @ 2Ω
  final double ratedPowerPerChannel4Ohm;   // @ 4Ω  
  final double ratedPowerPerChannel8Ohm;   // @ 8Ω
  final double ratedPowerPerChannel70V;    // @ 70V
  final double ratedPowerPerChannel100V;   // @ 100V
  
  // Peak symmetrical power per channel
  final double peakPowerPerChannel2Ohm;    // Peak @ 2Ω
  final double peakPowerPerChannel4Ohm;    // Peak @ 4Ω
  final double peakPowerPerChannel8Ohm;    // Peak @ 8Ω
  final double peakPowerPerChannel70V;     // Peak @ 70V
  final double peakPowerPerChannel100V;    // Peak @ 100V
  
  // Asymmetrical ratings (total power available for power sharing)
  final double asymmetricalPeakPower2Ohm;  // Total asymmetrical peak @ 2Ω
  final double asymmetricalPeakPower4Ohm;  // Total asymmetrical peak @ 4Ω
  final double asymmetricalPeakPower8Ohm;  // Total asymmetrical peak @ 8Ω
  final double asymmetricalPeakPower70V;   // Total asymmetrical peak @ 70V
  final double asymmetricalPeakPower100V;  // Total asymmetrical peak @ 100V

  const PowerSpecs({
    required this.ratedPowerPerChannel2Ohm,
    required this.ratedPowerPerChannel4Ohm,
    required this.ratedPowerPerChannel8Ohm,
    required this.ratedPowerPerChannel70V,
    required this.ratedPowerPerChannel100V,
    required this.peakPowerPerChannel2Ohm,
    required this.peakPowerPerChannel4Ohm,
    required this.peakPowerPerChannel8Ohm,
    required this.peakPowerPerChannel70V,
    required this.peakPowerPerChannel100V,
    required this.asymmetricalPeakPower2Ohm,
    required this.asymmetricalPeakPower4Ohm,
    required this.asymmetricalPeakPower8Ohm,
    required this.asymmetricalPeakPower70V,
    required this.asymmetricalPeakPower100V,
  });

  /// Get asymmetrical peak power for a given impedance/voltage
  double getAsymmetricalPeakPower({double? impedance, double? voltage}) {
    if (voltage != null) {
      if (voltage >= 100) return asymmetricalPeakPower100V;
      if (voltage >= 70) return asymmetricalPeakPower70V;
    }
    
    if (impedance != null) {
      if (impedance <= 2.5) return asymmetricalPeakPower2Ohm;
      if (impedance <= 3.0) return asymmetricalPeakPower4Ohm;
      return asymmetricalPeakPower8Ohm;
    }
    
    // Default to 8Ω if no specific impedance/voltage specified
    return asymmetricalPeakPower8Ohm;
  }

  /// Get peak power per channel for a given impedance/voltage
  double getPeakPowerPerChannel({double? impedance, double? voltage}) {
    if (voltage != null) {
      if (voltage >= 100) return peakPowerPerChannel100V;
      if (voltage >= 70) return peakPowerPerChannel70V;
    }
    
    if (impedance != null) {
      if (impedance <= 2.5) return peakPowerPerChannel2Ohm;
      if (impedance <= 3.0) return peakPowerPerChannel4Ohm;
      return peakPowerPerChannel8Ohm;
    }
    
    // Default to 8Ω if no specific impedance/voltage specified
    return peakPowerPerChannel8Ohm;
  }
}

/// Amplifier model specifications
class AmpModel {
  final String name;
  final int channels;
  final double peakPerChannel; // Legacy field - will be replaced by powerSpecs
  final String imageUrl;
  final String series;
  final double price;
  final PowerSpecs? powerSpecs; // Enhanced power specifications

  const AmpModel({
    required this.name,
    required this.channels,
    required this.peakPerChannel,
    required this.imageUrl,
    required this.series,
    this.price = 0.0,
    this.powerSpecs,
  });

  double get totalCapacity => channels * peakPerChannel;
  
  /// Get asymmetrical peak power for specific impedance/voltage configuration
  double getAsymmetricalPeakPower({double? impedance, double? voltage}) {
    if (powerSpecs != null) {
      return powerSpecs!.getAsymmetricalPeakPower(impedance: impedance, voltage: voltage);
    }
    // Fallback to legacy calculation
    return totalCapacity;
  }
  
  /// Get peak power per channel for specific impedance/voltage configuration  
  double getPeakPowerPerChannel({double? impedance, double? voltage}) {
    if (powerSpecs != null) {
      return powerSpecs!.getPeakPowerPerChannel(impedance: impedance, voltage: voltage);
    }
    // Fallback to legacy value
    return peakPerChannel;
  }

  Map<String, dynamic> toJson() => {
    'name': name,
    'channels': channels,
    'peak_per_channel': peakPerChannel,
    'total_capacity': totalCapacity,
    'image_url': imageUrl,
    'series': series,
    'price': price
  };

  factory AmpModel.fromJson(Map<String, dynamic> json) => AmpModel(
    name: json['name'] ?? '',
    channels: json['channels'] ?? 4,
    peakPerChannel: (json['peak_per_channel'] ?? 600.0).toDouble(),
    imageUrl: json['image_url'] ?? '',
    series: json['series'] ?? '',
    price: json['price'] ?? 0.0,
  );

  @override
  String toString() => '$name (${peakPerChannel.toInt()}W × ${channels}ch)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is AmpModel && other.name == name && other.channels == channels && other.peakPerChannel == peakPerChannel;
  }

  @override
  int get hashCode => name.hashCode ^ channels.hashCode ^ peakPerChannel.hashCode;
}

/// Assignment: one amplifier and the circuits assigned to it.
class Assignment2 {
  final AmpModel amp;
  final List<AmpCircuit> loads;
  // Add debug fields if needed
  Assignment2({required this.amp, required this.loads});
}

/// CircuitCalc: internal wrapper for circuit calculations
class CircuitCalc {
  final AmpCircuit base;
  double ppkTotal;
  double offsetDB;
  List<String> errors;

  CircuitCalc({required this.base, this.ppkTotal = 0, this.offsetDB = 0, List<String>? errors}) : errors = errors ?? [];
}

/// AmpCircuit: minimal stub for circuit data (renamed to avoid conflict with amp_matching_types.dart)
class AmpCircuit {
  final String model;
  final int speakerCount;
  final String mode;
  final double? tapWatts;
  final double? impedance;
  final double? offsetDB;

  AmpCircuit({
    required this.model,
    required this.speakerCount,
    required this.mode,
    this.tapWatts,
    this.impedance,
    this.offsetDB,
  });
}
