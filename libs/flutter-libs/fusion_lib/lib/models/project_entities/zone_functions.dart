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

  bool get hasScenes {
    switch (this) {
      case ZoneFunctionsType.sourceSelect:
      case ZoneFunctionsType.sourceSelectWithPriority:
        return false;
      case ZoneFunctionsType.sourceMix:
      case ZoneFunctionsType.sourceMixWithPriority:
      case ZoneFunctionsType.miniMatrix:
      case ZoneFunctionsType.miniMatrixWithPriority:
        return true;
    }
  }

  bool get hasSourceMixSettings {
    switch (this) {
      case ZoneFunctionsType.sourceSelect:
      case ZoneFunctionsType.sourceSelectWithPriority:
      case ZoneFunctionsType.miniMatrix:
      case ZoneFunctionsType.miniMatrixWithPriority:
        return false;
      case ZoneFunctionsType.sourceMix:
      case ZoneFunctionsType.sourceMixWithPriority:
        return true;
    }
  }

  bool get hasMatrixSettings {
    switch (this) {
      case ZoneFunctionsType.sourceSelect:
      case ZoneFunctionsType.sourceSelectWithPriority:
      case ZoneFunctionsType.sourceMix:
      case ZoneFunctionsType.sourceMixWithPriority:
        return false;
      case ZoneFunctionsType.miniMatrix:
      case ZoneFunctionsType.miniMatrixWithPriority:
        return true;
    }
  }
}

class ZoneFunctions {
  final String id;
  final String name;
  final ZoneFunctionsType type;
  final bool hasPriority;
  final List<MixSettings>? mixSettings;
  final MatrixMixer? matrixMixer;
  final List<MixScene> mixScenes;
  final String? selectedMixSceneId;
  final String? selectedSourceId;

  ZoneFunctions({
    String? id,
    required this.name,
    required this.type,
    required this.hasPriority,
    this.mixSettings,
    this.matrixMixer,
    this.selectedMixSceneId,
    this.mixScenes = const [],
    this.selectedSourceId,
  }) : id = id ?? "FUNC${FusionUtils.shortStringUUID()}";

  ZoneFunctions copyWith({
    String? id,
    String? name,
    ZoneFunctionsType? type,
    bool? hasPriority,
    List<MixSettings>? mixSettings,
    MatrixMixer? matrixMixer,
    List<MixScene>? mixScenes,
    String? selectedMixSceneId,
    String? selectedSourceId,
  }) {
    return ZoneFunctions(
      id: id ?? this.id,
      name: name ?? this.name,
      type: type ?? this.type,
      hasPriority: hasPriority ?? this.hasPriority,
      mixSettings: mixSettings ?? this.mixSettings,
      matrixMixer: matrixMixer ?? this.matrixMixer,
      mixScenes: mixScenes ?? this.mixScenes,
      selectedMixSceneId: selectedMixSceneId ?? this.selectedMixSceneId,
      selectedSourceId: selectedSourceId ?? this.selectedSourceId,
    );
  }

  //to json
  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'type': type.name,
      'hasPriority': hasPriority,
      "mixSettings": mixSettings?.map((e) => e.toJson()).toList(),
      "matrixMixer": matrixMixer?.toJson(),
      'mixScenes': mixScenes.map((e) => e.toJson()).toList(),
      'selectedMixSceneId': selectedMixSceneId,
      'selectedSourceId': selectedSourceId,
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
      mixSettings: json['mixSettings'] != null ? (json['mixSettings'] as List).map((e) => MixSettings.fromJson(e)).toList() : null,
      matrixMixer: json['matrixMixer'] != null
          ? json['matrixMixer']['type'] == SignalType.mono.name
                ? MonoMatrixMixer.fromJson(json['matrixMixer'])
                : StereoMatrixMixer.fromJson(json['matrixMixer'])
          : null,
      mixScenes: ((json['mixScenes']??[]) as List).map((e) {
        if (e['type'] == MixSceneType.source.name) {
          return SourceMixScene.fromJson(e);
        } else {
          return MatrixMixScene.fromJson(e);
        }
      }).toList(),
      selectedMixSceneId: json['selectedMixSceneId'],
      selectedSourceId: json['selectedSourceId'],
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
