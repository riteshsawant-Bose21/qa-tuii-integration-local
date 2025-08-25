/// Speaker database containing product specifications
/// 
/// This module contains the speaker catalog that would typically be
/// fetched from a product catalog API in production. Currently contains
/// hardcoded data for development and testing purposes.

import 'speaker_types.dart';


class SpeakerCatalog {
  static const Map<String, Speaker> database = {
    'DM2C-LP': Speaker(
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
    'DM3C': Speaker(
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
    'DM3P': Speaker(
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
    'DM3SE': Speaker(
      model: 'DM3SE',
      maxSpl: 99,
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
    'DM5C': Speaker(
      model: 'DM5C',
      maxSpl: 105,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [50],
      taps70V: [3, 6, 12, 25, 50],
      taps100V: [6, 12, 25, 50],
      longTermRms: 60,
      ppk: 120,
    ),
    'DM5P': Speaker(
      model: 'DM5P',
      maxSpl: 105,
      mountingType: 'pendant',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [50],
      taps70V: [3, 6, 12, 25, 50],
      taps100V: [6, 12, 25, 50],
      longTermRms: 60,
      ppk: 120,
    ),
    'DM5SE': Speaker(
      model: 'DM5SE',
      maxSpl: 105,
      mountingType: 'surface',
      outdoorRated: true,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [50],
      taps70V: [3, 6, 12, 25, 50],
      taps100V: [6, 12, 25, 50],
      longTermRms: 60,
      ppk: 120,
    ),
    'DM6C': Speaker(
      model: 'DM6C',
      maxSpl: 110,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [80],
      taps70V: [2.5, 5, 10, 20, 40, 80],
      taps100V: [5, 10, 20, 40, 80],
      longTermRms: 125,
      ppk: 250,
    ),
    'DM6PE': Speaker(
      model: 'DM6PE',
      maxSpl: 110,
      mountingType: 'pendant',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [80],
      taps70V: [2.5, 5, 10, 20, 40, 80],
      taps100V: [5, 10, 20, 40, 80],
      longTermRms: 125,
      ppk: 250,
    ),
    'DM6SE': Speaker(
      model: 'DM6SE',
      maxSpl: 110,
      mountingType: 'surface',
      outdoorRated: true,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [80],
      taps70V: [2.5, 5, 10, 20, 40, 80],
      taps100V: [5, 10, 20, 40, 80],
      longTermRms: 125,
      ppk: 250,
    ),
    'DM8C': Speaker(
      model: 'DM8C',
      maxSpl: 111,
      mountingType: 'ceiling',
      outdoorRated: false,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [80],
      taps70V: [2.5, 5, 10, 20, 40, 80],
      taps100V: [5, 10, 20, 40, 80],
      longTermRms: 150,
      ppk: 300,
    ),
    'DM8SE': Speaker(
      model: 'DM8SE',
      maxSpl: 113,
      mountingType: 'surface',
      outdoorRated: true,
      isSubwoofer: false,
      nominalOhms: 8,
      hasHiZ: true,
      hiZTaps: [80],
      taps70V: [2.5, 5, 10, 20, 40, 80],
      taps100V: [5, 10, 20, 40, 80],
      longTermRms: 150,
      ppk: 300,
    ),
  };

  /// Get all speakers from the catalog
  static Map<String, Speaker> getAllSpeakers() => database;

  /// Find speaker by model name
  static Speaker? findByModel(String model) => database[model];

  /// Get speakers by mounting type
  static List<Speaker> getByMountingType(String mountingType) {
    return database.values
        .where((speaker) => speaker.mountingType == mountingType)
        .toList();
  }

  /// Get speakers by outdoor rating
  static List<Speaker> getOutdoorRated(bool outdoorRated) {
    return database.values
        .where((speaker) => speaker.outdoorRated == outdoorRated)
        .toList();
  }

  /// Get subwoofers
  static List<Speaker> getSubwoofers() {
    return database.values
        .where((speaker) => speaker.isSubwoofer)
        .toList();
  }

  /// Get speakers with Hi-Z capability
  static List<Speaker> getHiZSpeakers() {
    return database.values
        .where((speaker) => speaker.hasHiZ)
        .toList();
  }

  /// Get all available speaker models
  static List<String> getAllModels() => database.keys.toList();

  /// Check if speaker model exists in catalog
  static bool hasModel(String model) => database.containsKey(model);

  /// Get speaker count in catalog
  static int get speakerCount => database.length;


}
