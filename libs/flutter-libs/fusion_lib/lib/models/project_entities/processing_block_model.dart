import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class ProcessingBlockModel {
  /// Input processing blocks
  /// "agc","gate","compressor","ducker", "tone_control","peq","gain"
  ///
  /// Zones processing blocks
  /// "gate", "compressor", "tone_control", "graphic_eq", "feedback_elimination", "peq", "delay", "gain"
  ///
  /// Mixes processing blocks
  /// "agc", "gate", "compressor", "ducker", "tone_control", "peq", "gain"
  ///
  /// Output processing blocks
  /// "peq", "gain", "delay", "limiter"

  static final delay = ProcessingBlockModel(
    name: 'Delay',
    algorithmId: "delay",
  );
  static final limiter = ProcessingBlockModel(
    name: 'Limiter',
    algorithmId: "limiter",
  );
  static final feedbackSuppression = ProcessingBlockModel(
    name: 'Feedback Suppression',
    algorithmId: "feedback_suppression",
  );
  static final gate = ProcessingBlockModel(
    name: 'Gate',
    algorithmId: "gate",
  );
  static final ducker = ProcessingBlockModel(
    name: 'Ducker',
    algorithmId: "ducker",
  );
  static final toneControl = ProcessingBlockModel(
    name: 'Tone Control',
    algorithmId: "tone_control",
  );
  static final graphicEq = ProcessingBlockModel(
    name: 'Graphic EQ',
    algorithmId: "graphic_eq",
  );

  static final compressor = ProcessingBlockModel(
    name: 'Compressor',
    algorithmId: "compressor",
  );
  static final agc = ProcessingBlockModel(
    name: 'AGC',
    algorithmId: "agc",
  );
  static final gain = ProcessingBlockModel(
    name: 'Gain',
    algorithmId: "gain",
  );
  static final peq = ProcessingBlockModel(
    name: 'PEQ',
    algorithmId: "peq",
    properties: [
      for (int i = 0; i < 3; i++) ...[
        PropertySetting(name: "type", value: "peq", dimension: i),
        PropertySetting(name: "frequency", value: 1000, dimension: i),
        PropertySetting(name: "gain", value: 0.0, dimension: i),
        PropertySetting(name: "q", value: 1.0, dimension: i),
        PropertySetting(name: "bypass", value: false, dimension: i),
      ],
    ],
  );

  static final List<ProcessingBlockModel> sourceBlocks = <ProcessingBlockModel>[
    delay,
    agc,
    compressor,
    limiter,
    gate,
    graphicEq,
    peq,
    toneControl,
    // feedbackSuppression,
    gain,
  ];

  static final List<ProcessingBlockModel> zoneBlocks = <ProcessingBlockModel>[
    delay,
    agc,
    compressor,
    limiter,
    graphicEq,
    peq,
    toneControl,
    // ProcessingBlockModel(
    //   name: 'Feedback Suppression',
    //   algorithmId: "feedback_suppression",
    // ),
    gain,
  ];

  static final List<ProcessingBlockModel> zoneUserBlocks = <ProcessingBlockModel>[
    toneControl,
    gain,
  ];

  static final List<ProcessingBlockModel> userZoneBlocks = <ProcessingBlockModel>[
    gain,
  ];

  static final List<ProcessingBlockModel> mixBlocks = <ProcessingBlockModel>[
    ProcessingBlockModel(
      name: 'AGC',
      algorithmId: "agc",
    ),
    ProcessingBlockModel(
      name: 'Gate',
      algorithmId: "gate",
    ),
    ProcessingBlockModel(
      name: 'Compressor',
      algorithmId: "compressor",
    ),
    ProcessingBlockModel(
      name: 'Ducker',
      algorithmId: "ducker",
    ),
    ProcessingBlockModel(
      name: 'Tone Control',
      algorithmId: "tone_control",
    ),
    peq,
    ProcessingBlockModel(
      name: 'Gain',
      algorithmId: "gain",
    ),
  ];

  static final List<ProcessingBlockModel> circuitBlocks = <ProcessingBlockModel>[
    ProcessingBlockModel(
      name: 'Delay',
      algorithmId: "delay",
    ),
    ProcessingBlockModel(
      name: 'Compressor',
      algorithmId: "compressor",
    ),
    ProcessingBlockModel(
      name: 'Limiter',
      algorithmId: "limiter",
    ),
    ProcessingBlockModel(
      name: 'Graphic EQ',
      algorithmId: "graphic_eq",
    ),
    peq,
    ProcessingBlockModel(
      name: 'Tone Control',
      algorithmId: "tone_control",
    ),
    ProcessingBlockModel(
      name: 'Feedback Suppression',
      algorithmId: "feedback_suppression",
    ),
    ProcessingBlockModel(
      name: 'Gain',
      algorithmId: "gain",
    ),
  ];

  final String name;
  final String id;
  final String algorithmId;
  List<PropertySetting> properties;
  final bool isforUser;

  ProcessingBlockModel({
    required this.name,
    String? id,
    this.isforUser = false,
    required this.algorithmId,
    List<PropertySetting>? properties,
  }) : properties = properties ?? <PropertySetting>[],
       id = id ?? "${algorithmId.toUpperCase().replaceAll('_', '')}${FusionUtils.shortStringUUID()}";

  IconData get icon {
    return _iconNameMap[algorithmId] ?? Icons.memory;
  }

  String get iconAsset {
    return "packages/fusion_lib/lib/${_algoIconMap[algorithmId] ?? 'assets/icons/processing_blocks/pb_1.png'}";
  }

  ProcessingBlockModel copyWith({
    String? name,
    String? id,
    bool? isForUser,
    String? algorithmId,
    List<PropertySetting>? properties,
  }) {
    return ProcessingBlockModel(
      name: name ?? this.name,
      id: id ?? this.id,
      isforUser: isForUser ?? this.isforUser,
      algorithmId: algorithmId ?? this.algorithmId,
      properties: properties ?? this.properties,
    );
  }

  ProcessingBlockModel updateProperties(List<PropertySetting> newProperties) {
    properties = newProperties;
    return this;
  }

  ProcessingBlockModel updateProperty(PropertySetting newProperty) {
    final int index = properties.indexWhere((PropertySetting p) => p.name == newProperty.name && p.dimension == newProperty.dimension);
    if (index != -1) {
      properties[index] = newProperty;
    } else {
      properties.add(newProperty);
    }
    return this;
  }

  ProcessingBlockModel addProperty(PropertySetting property) {
    properties.removeWhere((PropertySetting p) => p.name == property.name && p.dimension == property.dimension);
    properties.add(property);
    return this;
  }

  ProcessingBlockModel removeProperty(PropertySetting property) {
    properties.removeWhere((PropertySetting p) => p.name == property.name && p.dimension == property.dimension);
    return this;
  }

  ProcessingBlockModel clone() {
    return ProcessingBlockModel(
      name: name,
      algorithmId: algorithmId,
      isforUser: isforUser,
      properties: properties.map((val) => val.copyWith()).toList(),
    );
  }

  ProcessingBlockModel copyProperties({required ProcessingBlockModel model}) {
    return ProcessingBlockModel(
      id: id,
      name: name,
      isforUser: isforUser,
      algorithmId: algorithmId,
      properties: model.properties,
    );
  }

  factory ProcessingBlockModel.fromJson(Map<String, dynamic> json) {
    return ProcessingBlockModel(
      name: json['name'] as String,
      id: json['id'] as String,
      algorithmId: json['algorithmId'] as String,
      isforUser: json['isForUser'] as bool? ?? false,
      properties: (json['properties'] != null && json['properties'] is List<dynamic>)
          ? (json['properties'] as List<dynamic>).map((dynamic e) => PropertySetting.fromJson(e as Map<String, dynamic>)).toList()
          : <PropertySetting>[],
    );
  }

  Map<String, dynamic> toJson() {
    return <String, dynamic>{
      'name': name,
      'id': id,
      'algorithmId': algorithmId,
      'isForUser': isforUser,
      'properties': properties.map((PropertySetting e) => e.toJson()).toList(),
    };
  }

  /// Lookup table for JSON “iconName” (e.g. algorithmId) → const IconData
  static const Map<String, IconData> _iconNameMap = <String, IconData>{
    'gain': Icons.volume_up,
    'peq': Icons.equalizer,
    'compressor': Icons.compress,
    'ducker': Icons.volume_down,
    'agc': Icons.auto_fix_high,
    'gate': Icons.fence,
    'tone_control': Icons.tune,
    'graphic_eq': Icons.equalizer,
    'delay': Icons.timer,
    'limiter': Icons.stop,
  };

  /// Lookup table for JSON “iconName” (e.g. algorithmId) → const IconData
  static const Map<String, String> _algoIconMap = <String, String>{
    'gain': 'assets/icons/processing_blocks/pb_1.png',
    'peq': 'assets/icons/processing_blocks/pb_2.png',
    'compressor': 'assets/icons/processing_blocks/pb_3.png',
    'ducker': 'assets/icons/processing_blocks/pb_4.png',
    'agc': 'assets/icons/processing_blocks/pb_5.png',
    'gate': 'assets/icons/processing_blocks/pb_1.png',
    'tone_control': 'assets/icons/processing_blocks/pb_2.png',
    'graphic_eq': 'assets/icons/processing_blocks/pb_3.png',
    'delay': 'assets/icons/processing_blocks/pb_4.png',
    'limiter': 'assets/icons/processing_blocks/pb_5.png',
  };
}
