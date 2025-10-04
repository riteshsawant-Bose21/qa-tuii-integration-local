/// Amplifier catalog containing product specifications
///
/// This module contains the amplifier catalog that would typically be
/// fetched from an amplifier specifications API in production. Currently
/// contains hardcoded data for development and testing purposes.

import 'amplifier_types.dart';

/// Amplifier catalog with all available PSX models
class AmpCatalog {
  /// All available amplifiers in the catalog
  ///
  /// TODO: Replace with API call to amplifier specifications service
  static final List<AmpModel> models = [
    // PowerPure series
    // const AmpModel(series: 'Power Pure', name: 'PP-4150', channels: 4, peakPerChannel: 150.0, imageUrl: 'assets/images/amplifier_img.webp', price: 999.0),
    // const AmpModel(series: 'Power Pure', name: 'PP-8300', channels: 8, peakPerChannel: 300.0, imageUrl: 'assets/images/amplifier_img.webp', price: 1499.0),
    // const AmpModel(series: 'Power Pure', name: 'PP-41500', channels: 4, peakPerChannel: 1500.0, imageUrl: 'assets/images/amplifier_img.webp', price: 1999.0),
    // PowerSmart series
    // const AmpModel(
    //   series: 'Power Smart',
    //   name: 'PSM-4150',
    //   channels: 4,
    //   peakPerChannel: 150.0,
    //   imageUrl: 'assets/images/amplifier_img.webp',
    //   price: 999.0,
    // ), // 600W total
    // const AmpModel(
    //   series: 'Power Smart',
    //   name: 'PSM-4300',
    //   channels: 4,
    //   peakPerChannel: 300.0,
    //   imageUrl: 'assets/images/amplifier_img.webp',
    //   price: 1499.0,
    // ), // 1200W total
    // const AmpModel(
    //   series: 'Power Smart',
    //   name: 'PSM-4600',
    //   channels: 4,
    //   peakPerChannel: 600.0,
    //   imageUrl: 'assets/images/amplifier_img.webp',
    //   price: 1999.0,
    // ), // 2400W total
    // const AmpModel(
    //   series: 'Power Smart',
    //   name: 'PSM-8300',
    //   channels: 8,
    //   peakPerChannel: 300.0,
    //   imageUrl: 'assets/images/amplifier_img.webp',
    //   price: 2499.0,
    // ), // 2400W total
    // const AmpModel(
    //   series: 'Power Smart',
    //   name: 'PSM-8600',
    //   channels: 8,
    //   peakPerChannel: 600.0,
    //   imageUrl: 'assets/images/amplifier_img.webp',
    //   price: 2999.0,
    // ), // 4800W total
    // const AmpModel(
    //   series: 'Power Smart',
    //   name: 'PSM-41500',
    //   channels: 4,
    //   peakPerChannel: 1500.0,
    //   imageUrl: 'assets/images/amplifier_img.webp',
    //   price: 3999.0,
    // ), // 6000W total
    // PowershareX series - Enhanced with detailed power specifications from official specs
    AmpModel(
      series: 'PowershareX', 
      name: 'PSX1204D', 
      channels: 4, 
      peakPerChannel: 300.0, // Legacy field for backward compatibility
      imageUrl: 'assets/images/amplifier_img.webp', 
      price: 2499.0,
      powerSpecs: const PowerSpecs(
        // Rated power per channel (symmetrical)
        ratedPowerPerChannel2Ohm: 400.0,   // @ 2Ω from spec table
        ratedPowerPerChannel4Ohm: 600.0,   // @ 4Ω from spec table
        ratedPowerPerChannel8Ohm: 600.0,   // @ 8Ω from spec table
        ratedPowerPerChannel70V: 1600.0,   // @ 70V from spec table
        ratedPowerPerChannel100V: 1600.0,  // @ 100V from spec table
        
        // Peak power per channel (symmetrical) 
        peakPowerPerChannel2Ohm: 600.0,    // Peak @ 2Ω
        peakPowerPerChannel4Ohm: 600.0,    // Peak @ 4Ω
        peakPowerPerChannel8Ohm: 600.0,    // Peak @ 8Ω
        peakPowerPerChannel70V: 2200.0,    // Peak @ 70V
        peakPowerPerChannel100V: 2200.0,   // Peak @ 100V
        
        // Asymmetrical peak power (total power sharing)
        asymmetricalPeakPower2Ohm: 1600.0,  // From asymmetrical spec table
        asymmetricalPeakPower4Ohm: 2200.0,  // From asymmetrical spec table
        asymmetricalPeakPower8Ohm: 2200.0,  // From asymmetrical spec table - KEY CONSTRAINT
        asymmetricalPeakPower70V: 2200.0,   // From asymmetrical spec table
        asymmetricalPeakPower100V: 2200.0,  // From asymmetrical spec table
      ),
    ), // PSX1204D: 1200W symmetrical, 2200W asymmetrical max
    AmpModel(
      series: 'PowershareX', 
      name: 'PSX2404D', 
      channels: 4, 
      peakPerChannel: 600.0, // Legacy field for backward compatibility
      imageUrl: 'assets/images/amplifier_img.webp', 
      price: 3499.0,
      powerSpecs: const PowerSpecs(
        // Rated power per channel (symmetrical) 
        ratedPowerPerChannel2Ohm: 800.0,   // @ 2Ω from spec table
        ratedPowerPerChannel4Ohm: 1200.0,  // @ 4Ω from spec table
        ratedPowerPerChannel8Ohm: 1200.0,  // @ 8Ω from spec table
        ratedPowerPerChannel70V: 1700.0,   // @ 70V from spec table
        ratedPowerPerChannel100V: 1500.0,  // @ 100V from spec table
        
        // Peak power per channel (symmetrical)
        peakPowerPerChannel2Ohm: 1200.0,   // Peak @ 2Ω
        peakPowerPerChannel4Ohm: 1200.0,   // Peak @ 4Ω
        peakPowerPerChannel8Ohm: 1200.0,   // Peak @ 8Ω
        peakPowerPerChannel70V: 3400.0,    // Peak @ 70V
        peakPowerPerChannel100V: 3000.0,   // Peak @ 100V
        
        // Asymmetrical peak power (total power sharing)
        asymmetricalPeakPower2Ohm: 3700.0,  // From asymmetrical spec table
        asymmetricalPeakPower4Ohm: 2500.0,  // From asymmetrical spec table
        asymmetricalPeakPower8Ohm: 3000.0,  // From asymmetrical spec table - KEY CONSTRAINT
        asymmetricalPeakPower70V: 3400.0,   // From asymmetrical spec table
        asymmetricalPeakPower100V: 3000.0,  // From asymmetrical spec table
      ),
    ), // PSX2404D: 2400W symmetrical, 3000W asymmetrical max
    AmpModel(
      series: 'PowershareX', 
      name: 'PSX4804D', 
      channels: 4, 
      peakPerChannel: 1200.0, // Legacy field for backward compatibility
      imageUrl: 'assets/images/amplifier_img.webp', 
      price: 4499.0,
      powerSpecs: const PowerSpecs(
        // Rated power per channel (symmetrical)
        ratedPowerPerChannel2Ohm: 1500.0,  // @ 2Ω from spec table  
        ratedPowerPerChannel4Ohm: 2400.0,  // @ 4Ω from spec table
        ratedPowerPerChannel8Ohm: 2400.0,  // @ 8Ω from spec table
        ratedPowerPerChannel70V: 2100.0,   // @ 70V from spec table
        ratedPowerPerChannel100V: 2200.0,  // @ 100V from spec table
        
        // Peak power per channel (symmetrical)
        peakPowerPerChannel2Ohm: 3000.0,   // Peak @ 2Ω
        peakPowerPerChannel4Ohm: 3000.0,   // Peak @ 4Ω
        peakPowerPerChannel8Ohm: 2500.0,   // Peak @ 8Ω  
        peakPowerPerChannel70V: 4200.0,    // Peak @ 70V
        peakPowerPerChannel100V: 4400.0,   // Peak @ 100V
        
        // Asymmetrical peak power (total power sharing)
        asymmetricalPeakPower2Ohm: 4100.0,  // From asymmetrical spec table
        asymmetricalPeakPower4Ohm: 4800.0,  // From asymmetrical spec table
        asymmetricalPeakPower8Ohm: 2500.0,  // From asymmetrical spec table
        asymmetricalPeakPower70V: 4200.0,   // From asymmetrical spec table
        asymmetricalPeakPower100V: 4400.0,  // From asymmetrical spec table - KEY CONSTRAINT
      ),
    ), // PSX4804D: 4800W symmetrical, 4400W asymmetrical max
  ];

  /// Get amplifiers sorted by power (ascending)
  static List<AmpModel> get sortedByPower {
    final sorted = List<AmpModel>.from(models);
    sorted.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));
    return sorted;
  }

  /// Get all 4-channel amplifiers
  static List<AmpModel> get fourChannelModels => models.where((amp) => amp.channels == 4).toList();

  /// Get all 8-channel amplifiers
  static List<AmpModel> get eightChannelModels => models.where((amp) => amp.channels == 8).toList();

  /// Find amplifier by name
  static AmpModel? findByName(String name) {
    try {
      return models.firstWhere((amp) => amp.name == name);
    } catch (e) {
      return null;
    }
  }

  /// Find amplifiers by power and channel specifications
  static List<AmpModel> findByPowerAndChannels(double power, int channels) {
    return models.where((amp) => amp.peakPerChannel == power && amp.channels == channels).toList();
  }

  /// Get amplifiers by channel count
  static List<AmpModel> getByChannels(int channels) {
    return models.where((amp) => amp.channels == channels).toList();
  }

  /// Get amplifiers by minimum power requirement
  static List<AmpModel> getByMinimumPower(double minPower) {
    return models.where((amp) => amp.peakPerChannel >= minPower).toList();
  }

  /// Get amplifiers within power range
  static List<AmpModel> getByPowerRange(double minPower, double maxPower) {
    return models.where((amp) => amp.peakPerChannel >= minPower && amp.peakPerChannel <= maxPower).toList();
  }

  /// Get all available amplifier names
  static List<String> getAllNames() => models.map((amp) => amp.name).toList();

  /// Check if amplifier model exists in catalog
  static bool hasModel(String name) => models.any((amp) => amp.name == name);

  /// Get amplifier count in catalog
  static int get amplifierCount => models.length;

  /// Get unique power ratings available
  static List<double> getUniquePowerRatings() {
    final powers = models.map((amp) => amp.peakPerChannel).toSet().toList();
    powers.sort();
    return powers;
  }

  /// Get unique channel configurations available
  static List<int> getUniqueChannelCounts() {
    final channels = models.map((amp) => amp.channels).toSet().toList();
    channels.sort();
    return channels;
  }
}
