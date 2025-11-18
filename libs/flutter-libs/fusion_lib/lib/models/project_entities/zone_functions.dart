import 'package:fusion_lib/fusion_lib.dart';

enum ZoneFunctionsType {
  sourceSelect,
  sourceSelectWithPriority,
  sourceMix,
  sourceMixWithPriority,
  miniMatrix,
  miniMatrixWithPriority,
}

extension ZoneFunctionsTypeList on ZoneFunctionsType {
  String get displayName {
    switch (this) {
      case ZoneFunctionsType.sourceSelect:
        return 'Source Select';
      case ZoneFunctionsType.sourceSelectWithPriority:
        return 'Source Select + Priority Override';
      case ZoneFunctionsType.sourceMix:
        return 'Source Mix';
      case ZoneFunctionsType.sourceMixWithPriority:
        return 'Source Mix + Priority Override';
      case ZoneFunctionsType.miniMatrix:
        return 'Mini Matrix';
      case ZoneFunctionsType.miniMatrixWithPriority:
        return 'Mini Matrix With Priority';
    }
  }
}

class ZoneFunctions {
  final String id;
  final String name;
  final ZoneFunctionsType type;
  final bool hasPriority;

  ZoneFunctions({
    String? id,
    required this.name,
    required this.type,
    required this.hasPriority,
  }) : id = id ?? "FUNC${FusionUtils.shortStringUUID()}";

  ZoneFunctions copyWith({
    String? id,
    String? name,
    ZoneFunctionsType? type,
    bool? hasPriority,
  }) {
    return ZoneFunctions(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      hasPriority: hasPriority ?? this.hasPriority,
    );
  }

  //to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'hasPriority': hasPriority,
    };
  }

  //from json
  factory ZoneFunctions.fromJson(Map<String, dynamic> json) {
    return ZoneFunctions(
      id: json['id'],
      name: json['name'],
      type: ZoneFunctionsType.values.firstWhere(
        (e) => e.name == json['type'],
      ),
      hasPriority: json['hasPriority'],
    );
  }
}

ZoneFunctions getNewZoneFunction({required ZoneFunctionsType type, String? name}) {
  switch (type) {
    case ZoneFunctionsType.sourceSelect:
      return ZoneFunctions(
        name: name ?? "Source Select",
        type: type,
        hasPriority: false,
      );
    case ZoneFunctionsType.sourceSelectWithPriority:
      return ZoneFunctions(
        name: name ?? "Source Select With Priority",
        type: type,
        hasPriority: true,
      );
    case ZoneFunctionsType.sourceMix:
      return ZoneFunctions(
        name: name ?? "Source mix",
        type: type,
        hasPriority: false,
      );
    case ZoneFunctionsType.sourceMixWithPriority:
      return ZoneFunctions(
        name: name ?? "Source Mix With Priority",
        type: type,
        hasPriority: true,
      );
    case ZoneFunctionsType.miniMatrix:
      return ZoneFunctions(
        name: name ?? "Mini Matrix",
        type: type,
        hasPriority: false,
      );
    case ZoneFunctionsType.miniMatrixWithPriority:
      return ZoneFunctions(
        name: name ?? "Mini Matrix With Priority",
        type: type,
        hasPriority: true,
      );
  }
}
