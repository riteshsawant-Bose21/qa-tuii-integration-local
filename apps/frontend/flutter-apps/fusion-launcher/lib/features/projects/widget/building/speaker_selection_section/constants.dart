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
