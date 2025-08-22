/// Speaker database containing product specifications
///
/// This module contains the speaker catalog that would typically be
/// fetched from a product catalog API in production. Currently contains
/// hardcoded data for development and testing purposes.

import 'speaker_types.dart';

/// Comprehensive speaker database with all specifications
///
/// In production, this data would be fetched from an API endpoint
/// such as GET /api/v1/speakers or similar product catalog service
class SpeakerCatalog {
  /// All available speakers in the catalog
  ///
  /// TODO: Replace with API call to product catalog service
  static const Map<String, SpeakerModel> database = {
    'DM2C-LP': SpeakerModel(
      model: 'DM2C-LP',
      maxSpl: 97,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 16,
      hasHiZ: true,
      hiZTaps: [9],
      taps70V: [1.2, 2.3, 4.5, 9],
      taps100V: [2.3, 4.5, 9],
      longTermRms: 20,
      ppk: 40,
    ),
    'DM3C': SpeakerModel(
      model: 'DM3C',
      maxSpl: 98,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [25],
      taps70V: [3, 6, 12, 25],
      taps100V: [6, 12, 25],
      longTermRms: 30,
      ppk: 60,
    ),
    'DM3P': SpeakerModel(
      model: 'DM3P',
      maxSpl: 99,
      mountingType: 'pendant',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [25],
      taps70V: [3, 6, 12, 25],
      taps100V: [6, 12, 25],
      longTermRms: 30,
      ppk: 60,
    ),
    'DM3SE': SpeakerModel(
      model: 'DM3SE',
      maxSpl: 101,
      mountingType: 'surface',
      outdoorRated: true,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [25],
      taps70V: [3, 6, 12, 25],
      taps100V: [6, 12, 25],
      longTermRms: 30,
      ppk: 60,
    ),
    'DM5C': SpeakerModel(
      model: 'DM5C',
      maxSpl: 105,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [50],
      taps70V: [6, 12, 25, 50],
      taps100V: [12, 25, 50],
      longTermRms: 60,
      ppk: 120,
    ),
    'DM5P': SpeakerModel(
      model: 'DM5P',
      maxSpl: 105,
      mountingType: 'pendant',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [50],
      taps70V: [6, 12, 25, 50],
      taps100V: [12, 25, 50],
      longTermRms: 60,
      ppk: 120,
    ),
    'DM5SE': SpeakerModel(
      model: 'DM5SE',
      maxSpl: 107,
      mountingType: 'surface',
      outdoorRated: true,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [50],
      taps70V: [6, 12, 25, 50],
      taps100V: [12, 25, 50],
      longTermRms: 60,
      ppk: 120,
    ),
    'DM6C': SpeakerModel(
      model: 'DM6C',
      maxSpl: 109,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [100],
      taps70V: [12, 25, 50, 100],
      taps100V: [25, 50, 100],
      longTermRms: 120,
      ppk: 240,
    ),
    'DM6PE': SpeakerModel(
      model: 'DM6PE',
      maxSpl: 110,
      mountingType: 'pendant',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [100],
      taps70V: [12, 25, 50, 100],
      taps100V: [25, 50, 100],
      longTermRms: 120,
      ppk: 240,
    ),
    'DM6SE': SpeakerModel(
      model: 'DM6SE',
      maxSpl: 111,
      mountingType: 'surface',
      outdoorRated: true,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [100],
      taps70V: [12, 25, 50, 100],
      taps100V: [25, 50, 100],
      longTermRms: 120,
      ppk: 240,
    ),
    'DM8C': SpeakerModel(
      model: 'DM8C',
      maxSpl: 113,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [150],
      taps70V: [18, 37, 75, 150],
      taps100V: [37, 75, 150],
      longTermRms: 200,
      ppk: 400,
    ),
    'DM8SE': SpeakerModel(
      model: 'DM8SE',
      maxSpl: 115,
      mountingType: 'surface',
      outdoorRated: true,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [150],
      taps70V: [18, 37, 75, 150],
      taps100V: [37, 75, 150],
      longTermRms: 200,
      ppk: 400,
    ),
  };

  /// Get all speakers from the catalog
  static Map<String, SpeakerModel> getAllSpeakers() => database;

  /// Find speaker by model name
  static SpeakerModel? findByModel(String model) => database[model];

  /// Get speakers by mounting type
  static List<SpeakerModel> getByMountingType(String mountingType) {
    return database.values.where((speaker) => speaker.mountingType == mountingType).toList();
  }

  /// Get speakers by outdoor rating
  static List<SpeakerModel> getOutdoorRated(bool outdoorRated) {
    return database.values.where((speaker) => speaker.outdoorRated == outdoorRated).toList();
  }

  /// Get subwoofers
  static List<SpeakerModel> getSubwoofers() {
    return database.values.where((speaker) => speaker.isSubwoofer).toList();
  }

  /// Get speakers with Hi-Z capability
  static List<SpeakerModel> getHiZSpeakers() {
    return database.values.where((speaker) => speaker.hasHiZ).toList();
  }

  /// Get all available speaker models
  static List<String> getAllModels() => database.keys.toList();

  /// Check if speaker model exists in catalog
  static bool hasModel(String model) => database.containsKey(model);

  /// Get speaker count in catalog
  static int get speakerCount => database.length;

  /// Future API integration method
  ///
  /// This method would replace the static database above
  /// Example:
  /// ```dart
  /// final speakers = await SpeakerCatalog.fetchFromApi();
  /// ```
  static Future<Map<String, SpeakerModel>> fetchFromApi({String? apiEndpoint, Map<String, String>? headers}) async {
    // TODO: Implement actual API call
    // Example implementation:
    //
    // final response = await http.get(
    //   Uri.parse(apiEndpoint ?? 'https://api.bose.com/v1/speakers'),
    //   headers: headers ?? {'Content-Type': 'application/json'},
    // );
    //
    // if (response.statusCode == 200) {
    //   final data = jsonDecode(response.body) as Map<String, dynamic>;
    //   return data.map((key, value) => MapEntry(key, Speaker.fromJson(value)));
    // }
    //
    // throw Exception('Failed to fetch speakers: ${response.statusCode}');

    // For now, return the static database
    await Future.delayed(const Duration(milliseconds: 100)); // Simulate API delay
    return database;
  }
}
