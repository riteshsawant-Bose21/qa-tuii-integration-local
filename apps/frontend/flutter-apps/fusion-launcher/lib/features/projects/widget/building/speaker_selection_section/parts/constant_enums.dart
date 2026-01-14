import 'package:flutter/material.dart';

enum SpeakerSelectionMode {
  select("Select"),
  suggest("Suggest");

  const SpeakerSelectionMode(this.displayName);
  final String displayName;
}

enum SpeakerColor {
  black("Black", Colors.black),
  white("White", Colors.white);

  const SpeakerColor(this.displayName, this.color);
  final String displayName;
  final Color color;

  static SpeakerColor getValueBasedOnKey(String key) {
    if (SpeakerColor.white.name == key) return SpeakerColor.white;
    if (SpeakerColor.black.name == key) return SpeakerColor.black;
    return SpeakerColor.black;
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
