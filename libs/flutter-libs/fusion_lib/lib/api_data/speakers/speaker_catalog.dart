/// Speaker database containing product specifications
///
/// This module contains the speaker catalog that would typically be
/// fetched from a product catalog API in production. Currently contains
/// hardcoded data for development and testing purposes.

import 'speaker_types.dart';

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
      imageUrl: 'assets/images/speakers/DesignMax_DM2C-LP_white.png',
      price: 189.99,
      color: 'white',
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
      imageUrl: 'assets/images/speakers/freespace_designmax_1.png',
      price: 249.99,
      color: 'black',
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
      imageUrl: 'assets/images/speakers/DM_pendant.png',
      price: 279.99,
      color: 'black',
    ),
    'DM3SE': SpeakerModel(
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
      imageUrl: 'assets/images/speakers/designmax_dm8se.png',
      price: 329.99,
      color: 'black',
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
      taps70V: [3, 6, 12, 25, 50],
      taps100V: [6, 12, 25, 50],
      longTermRms: 60,
      ppk: 120,
      imageUrl: 'assets/images/speakers/freespace_designmax_1.png',
      price: 399.99,
      color: 'black',
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
      taps70V: [3, 6, 12, 25, 50],
      taps100V: [6, 12, 25, 50],
      longTermRms: 60,
      ppk: 120,
      imageUrl: 'assets/images/speakers/dm5p_white.png',
      price: 429.99,
      color: 'white',
    ),
    'DM5SE': SpeakerModel(
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
      imageUrl: 'assets/images/speakers/DM5SE_white.png',
      price: 479.99,
      color: 'white',
    ),
    'DM6C': SpeakerModel(
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
      imageUrl: 'assets/images/speakers/DM6C_white.png',
      price: 549.99,
      color: 'white',
    ),
    'DM6PE': SpeakerModel(
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
      imageUrl: 'assets/images/speakers/dm6pe_white.png',
      price: 599.99,
      color: 'white',
    ),
    'DM6SE': SpeakerModel(
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
      imageUrl: 'assets/images/speakers/DM6se_white.png',
      price: 649.99,
      color: 'white',
    ),
    'DM8C': SpeakerModel(
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
      imageUrl: 'assets/images/speakers/DM8C_white.png',
      price: 749.99,
      color: 'white',
    ),
    'DM8SE': SpeakerModel(
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
      imageUrl: 'assets/images/speakers/designmax_dm8se.png',
      price: 899.99,
      color: 'black',
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
}
