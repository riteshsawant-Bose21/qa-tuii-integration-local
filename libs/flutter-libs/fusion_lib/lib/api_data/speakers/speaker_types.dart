/// Speaker specifications and data types for API integration
///
/// This module contains speaker data structures that would typically
/// be fetched from a product catalog API in production.

/// Comprehensive speaker specification containing all necessary information
/// for SPL calculations, tap settings, and power calculations
class SpeakerModel {
  final String model;
  final double maxSpl;
  final String mountingType; // "surface", "ceiling", "pendant"
  final bool outdoorRated;
  final bool isSubwoofer;
  final double nominalOhms;
  final bool hasHiZ;
  final List<double> hiZTaps;
  final List<double> taps70V;
  final List<double> taps100V;
  final double longTermRms; // RMS power rating for long-term use
  final double ppk; // Peak power rating
  final String imageUrl; // URL to product image
  final double price; // Price in USD

  const SpeakerModel({
    required this.model,
    required this.maxSpl,
    required this.mountingType,
    required this.outdoorRated,
    required this.isSubwoofer,
    required this.nominalOhms,
    required this.hasHiZ,
    required this.hiZTaps,
    required this.taps70V,
    required this.taps100V,
    required this.longTermRms,
    required this.ppk,
    required this.imageUrl,
    required this.price,
  });

  Map<String, dynamic> toJson() => {
    'model': model,
    'max_spl': maxSpl,
    'mounting_type': mountingType,
    'outdoor_rated': outdoorRated,
    'is_subwoofer': isSubwoofer,
    'nominal_ohms': nominalOhms,
    'has_hi_z': hasHiZ,
    'hi_z_taps': hiZTaps,
    'taps_70v': taps70V,
    'taps_100v': taps100V,
    'long_term_rms': longTermRms,
    'ppk': ppk,
    'image_url': imageUrl,
    'price': price,
  };

  factory SpeakerModel.fromJson(Map<String, dynamic> json) => SpeakerModel(
    model: json['model'] ?? '',
    maxSpl: (json['max_spl'] ?? 0.0).toDouble(),
    mountingType: json['mounting_type'] ?? '',
    outdoorRated: json['outdoor_rated'] ?? false,
    isSubwoofer: json['is_subwoofer'] ?? false,
    nominalOhms: (json['nominal_ohms'] ?? 8.0).toDouble(),
    hasHiZ: json['has_hi_z'] ?? false,
    hiZTaps: (json['hi_z_taps'] as List<dynamic>?)?.cast<double>() ?? [],
    taps70V: (json['taps_70v'] as List<dynamic>?)?.cast<double>() ?? [],
    taps100V: (json['taps_100v'] as List<dynamic>?)?.cast<double>() ?? [],
    longTermRms: (json['long_term_rms'] ?? 0.0).toDouble(),
    ppk: (json['ppk'] ?? 0.0).toDouble(),
    imageUrl: json['image_url'] ?? '',
    price: (json['price'] ?? 0.0).toDouble(),
  );

  @override
  String toString() => '$model ($maxSpl dB SPL)';

  @override
  bool operator ==(Object other) {
    if (identical(this, other)) return true;
    return other is SpeakerModel && other.model == model;
  }

  @override
  int get hashCode => model.hashCode;
}
