enum SpeakerSelectionMode {
  select("Select"),
  suggest("Suggest");

  const SpeakerSelectionMode(this.displayName);
  final String displayName;
}

enum SpeakerColor {
  black("Black"),
  white("White");

  const SpeakerColor(this.displayName);
  final String displayName;

  String get jsonAssetKey {
    switch (this) {
      case SpeakerColor.black:
        return 'black';
      case SpeakerColor.white:
        return 'white';
    }
  }
}

enum SpeakerSortOption {
  nameAsc("Name (A-Z)"),
  nameDesc("Name (Z-A)");

  const SpeakerSortOption(this.displayName);
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

  static ListeningHeightOption getOptionByValue(double height) {
    switch (height) {
      case 3.0:
        return ListeningHeightOption.sitting;
      case 6.0:
        return ListeningHeightOption.standing;
      default:
        return ListeningHeightOption.custom;
    }
  }
}
