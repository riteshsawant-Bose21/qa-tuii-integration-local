import 'package:fusion_lib/models/project_entities/listening_area_model.dart';

enum FusionCountries {
  india,
  usa,
  china,
  singapore;

  static FusionCountries? fromJson(String? json) {
    try {
      return FusionCountries.values.firstWhereOrNull((e) => e.name == json);
    } catch (e) {
      return null;
    }
  }

  // toJson.
  String toJson() => name;
}
