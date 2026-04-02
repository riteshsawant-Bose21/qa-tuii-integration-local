enum FusionCountries {
  india,
  usa,
  china,
  singapore;

  static FusionCountries? fromJson(String? json) {
    try {
      return FusionCountries.values.firstWhere((e) => e.name == json);
    } catch (e) {
      return null;
    }
  }

  // toJson.
  String toJson() => name;
}
