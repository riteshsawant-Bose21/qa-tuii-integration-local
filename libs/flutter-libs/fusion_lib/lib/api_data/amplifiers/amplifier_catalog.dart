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
  static const List<AmpModel> models = [
    AmpModel(name: 'PSX1204D', channels: 4, peakPerChannel: 600.0),
    AmpModel(name: 'PSX1208D', channels: 8, peakPerChannel: 600.0),
    AmpModel(name: 'PSX2404D', channels: 4, peakPerChannel: 1200.0),
    AmpModel(name: 'PSX2408D', channels: 8, peakPerChannel: 1200.0),
    AmpModel(name: 'PSX4804D', channels: 4, peakPerChannel: 2400.0),
    AmpModel(name: 'PSX4808D', channels: 8, peakPerChannel: 2400.0),
  ];

  /// Get amplifiers sorted by power (ascending)
  static List<AmpModel> get sortedByPower {
    final sorted = List<AmpModel>.from(models);
    sorted.sort((a, b) => a.peakPerChannel.compareTo(b.peakPerChannel));
    return sorted;
  }

  /// Get all 4-channel amplifiers
  static List<AmpModel> get fourChannelModels => 
      models.where((amp) => amp.channels == 4).toList();

  /// Get all 8-channel amplifiers
  static List<AmpModel> get eightChannelModels => 
      models.where((amp) => amp.channels == 8).toList();

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
    return models.where((amp) => 
        amp.peakPerChannel == power && amp.channels == channels).toList();
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
    return models.where((amp) => 
        amp.peakPerChannel >= minPower && amp.peakPerChannel <= maxPower).toList();
  }

  /// Get all available amplifier names
  static List<String> getAllNames() => models.map((amp) => amp.name).toList();

  /// Check if amplifier model exists in catalog
  static bool hasModel(String name) => 
      models.any((amp) => amp.name == name);

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

  /// Future API integration method
  /// 
  /// This method would replace the static models list above
  /// Example: 
  /// ```dart
  /// final amplifiers = await AmpCatalog.fetchFromApi();
  /// ```
  static Future<List<AmpModel>> fetchFromApi({
    String? apiEndpoint,
    Map<String, String>? headers,
  }) async {
    // TODO: Implement actual API call
    // Example implementation:
    // 
    // final response = await http.get(
    //   Uri.parse(apiEndpoint ?? 'https://api.bose.com/v1/amplifiers'),
    //   headers: headers ?? {'Content-Type': 'application/json'},
    // );
    
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body) as List<dynamic>;
    //   return data.map((json) => AmpModel.fromJson(json)).toList();
    // }
    
    // throw Exception('Failed to fetch amplifiers: ${response.statusCode}');
    
    // For now, return the static models
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate API delay
    return models;
  }

}
