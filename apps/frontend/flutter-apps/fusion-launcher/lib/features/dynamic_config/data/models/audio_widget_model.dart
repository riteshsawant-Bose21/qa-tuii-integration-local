import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/audio_widget_value.dart';

class AudioWidgetModel {
  final String id;
  final String name;
  final String parentPanelBlockName;
  final AudioWidgetType audioWidgetType;
  final String valueType;
  final AudioWidgetOrientation audioWidgetOrientation;
  final dynamic value;
  final dynamic minValue;
  final dynamic maxValue;
  final bool isWidgetDependentOnDimensions;
  final int? dimensionIndex;
  final bool isWidgetPhantomPower; //TODO: remove this as it is debug code for proto1 (phantom_power)

  AudioWidgetModel({
    required this.id,
    required this.parentPanelBlockName,
    required this.name,
    required this.audioWidgetType,
    required this.audioWidgetOrientation,
    required this.isWidgetDependentOnDimensions,
    required this.valueType,
    required this.value,
    this.maxValue,
    this.minValue,
    this.dimensionIndex,
    this.isWidgetPhantomPower = false, //TODO: remove this as it is debug code for proto1 (phantom_power)
  });

  AudioWidgetModel copyWith({
    String? id,
    String? name,
    String? parentPanelBlockName,
    AudioWidgetType? audioWidgetType,
    String? valueType,
    AudioWidgetOrientation? audioWidgetOrientation,
    dynamic value,
    dynamic minValue,
    dynamic maxValue,
    bool? isWidgetDependentOnDimensions,
    int? dimensionIndex,
    bool? isWidgetPhantomPower,
  }) {
    return AudioWidgetModel(
      id: id ?? this.id,
      name: name ?? this.name,
      parentPanelBlockName: parentPanelBlockName ?? this.parentPanelBlockName,
      audioWidgetType: audioWidgetType ?? this.audioWidgetType,
      valueType: valueType ?? this.valueType,
      audioWidgetOrientation: audioWidgetOrientation ?? this.audioWidgetOrientation,
      value: value ?? this.value,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      isWidgetDependentOnDimensions: isWidgetDependentOnDimensions ?? this.isWidgetDependentOnDimensions,
      dimensionIndex: dimensionIndex ?? this.dimensionIndex,
      isWidgetPhantomPower: isWidgetPhantomPower ?? this.isWidgetPhantomPower,
    );
  }

  AudioWidgetEntity toDomain() {
    return AudioWidgetEntity(
      id: id,
      name: name,
      parentPanelBlockName: parentPanelBlockName,
      audioWidgetType: audioWidgetType,
      audioWidgetOrientation: audioWidgetOrientation,
      isWidgetDependentOnDimensions: isWidgetDependentOnDimensions,
      value: AudioWidgetValue.from(value, valueType),
      minValue: minValue != null ? AudioWidgetValue.from(minValue, valueType) : null,
      maxValue: maxValue != null ? AudioWidgetValue.from(maxValue, valueType) : null,
      dimensionIndex: dimensionIndex,
      isWidgetPhantomPower: isWidgetPhantomPower,
    );
  }

  factory AudioWidgetModel.fromDomain(AudioWidgetEntity entity) {
    return AudioWidgetModel(
      id: entity.id,
      name: entity.name,
      parentPanelBlockName: entity.parentPanelBlockName,
      audioWidgetType: entity.audioWidgetType,
      audioWidgetOrientation: entity.audioWidgetOrientation,
      isWidgetDependentOnDimensions: entity.isWidgetDependentOnDimensions,
      valueType: entity.value.valueType,
      value: entity.value.value,
      minValue: entity.minValue?.value,
      maxValue: entity.maxValue?.value,
      dimensionIndex: entity.dimensionIndex,
      isWidgetPhantomPower: entity.isWidgetPhantomPower,
    );
  }
}
