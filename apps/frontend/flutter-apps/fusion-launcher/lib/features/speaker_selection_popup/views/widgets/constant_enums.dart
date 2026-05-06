import 'package:flutter/material.dart';

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
  nameDesc("Name (Z-A)"),
  priceLowToHigh("Price: Low to High"),
  priceHighToLow("Price: High to Low"),
  maxSplHighToLow("Max SPL: High to Low"),
  maxSplLowToHigh("Max SPL: Low to High"),
  powerHandlingHighToLow("Power: High to Low"),
  powerHandlingLowToHigh("Power: Low to High");

  const SpeakerSortOption(this.displayName);
  final String displayName;
}
