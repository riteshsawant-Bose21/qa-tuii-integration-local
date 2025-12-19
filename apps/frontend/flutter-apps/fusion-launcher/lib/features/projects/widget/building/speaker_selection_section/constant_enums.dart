enum SpeakerSelectionMode {
  select("Select"),
  suggest("Suggest");

  const SpeakerSelectionMode(this.displayName);
  final String displayName;
}

enum SpeakerMountingType {
  surface("Surface"),
  ceiling("Ceiling"),
  pendant("Pendant");

  const SpeakerMountingType(this.displayName);
  final String displayName;
}

enum SpeakerLowFrequency {
  vocal("Vocal"),
  fullRange("Full Range"),
  extended("Extended"),
  subwoofer("Subwoofer");

  const SpeakerLowFrequency(this.displayName);
  final String displayName;
}

enum SpeakerColor {
  black("Black"),
  white("White");

  const SpeakerColor(this.displayName);
  final String displayName;
}

enum SpeakerWiring {
  hiZ("Hi-Z"),
  loZ("Lo-Z");

  const SpeakerWiring(this.displayName);
  final String displayName;
}

enum SpeakerSortOption {
  nameAsc("Name (A-Z)"),
  nameDesc("Name (Z-A)");

  const SpeakerSortOption(this.displayName);
  final String displayName;
}

enum VenueOptions {
  indoor("Indoor"),
  indoorOutdoor("Indoor + Outdoor");

  const VenueOptions(this.displayName);
  final String displayName;
}

enum ListeningHeightOption {
  sitting("Sitting"),
  standing("Standing"),
  custom("Custom");

  const ListeningHeightOption(this.displayName);
  final String displayName;

  static double? getValue(ListeningHeightOption option) {
    switch (option) {
      case ListeningHeightOption.sitting:
        return 3.0;
      case ListeningHeightOption.standing:
        return 6.0;
      case ListeningHeightOption.custom:
        return 1.0;
    }
  }
}

enum SpeakerSplRangeOptions {
  backgroundMusic("Background Music"),
  paging("Paging"),
  foregroundMusic("Foreground Music"),
  moderateLiveSoundReinforcement("Moderate live sound reinforcement"),
  highSplLiveSoundReinforcement("High-SPL live sound reinforcement");

  const SpeakerSplRangeOptions(this.displayName);
  final String displayName;

  Map<String, double> get splRangeValues {
    switch (this) {
      case SpeakerSplRangeOptions.backgroundMusic:
        return <String, double>{"min": 60.0, "max": 70.0};
      case SpeakerSplRangeOptions.paging:
        return <String, double>{"min": 70.0, "max": 80.0};
      case SpeakerSplRangeOptions.foregroundMusic:
        return <String, double>{"min": 75.0, "max": 90.0};
      case SpeakerSplRangeOptions.moderateLiveSoundReinforcement:
        return <String, double>{"min": 90.0, "max": 100.0};
      case SpeakerSplRangeOptions.highSplLiveSoundReinforcement:
        return <String, double>{"min": 100.0, "max": 120.0};
    }
  }

  static SpeakerSplRangeOptions getSplRange(double minSPL, double maxSPL) {
    if (minSPL == 60.0 && maxSPL == 70.0) {
      return SpeakerSplRangeOptions.backgroundMusic;
    } else if (minSPL == 70.0 && maxSPL == 80.0) {
      return SpeakerSplRangeOptions.paging;
    } else if (minSPL == 75.0 && maxSPL == 90.0) {
      return SpeakerSplRangeOptions.foregroundMusic;
    } else if (minSPL == 90.0 && maxSPL == 100.0) {
      return SpeakerSplRangeOptions.moderateLiveSoundReinforcement;
    } else if (minSPL == 100.0 && maxSPL == 120.0) {
      return SpeakerSplRangeOptions.highSplLiveSoundReinforcement;
    } else {
      return SpeakerSplRangeOptions.backgroundMusic;
    }
  }
}
