import 'package:equatable/equatable.dart';

import 'audio_widget_value.dart';

enum AudioWidgetOrientation {
  horizontal,
  vertical,
}

enum AudioWidgetType {
  meter,
  gainFader,
  toggleButton,
  unknown,
}

class AudioWidgetEntity extends Equatable {
  final String id;
  final String name;
  final String parentPanelBlockName;
  final AudioWidgetType audioWidgetType;
  final AudioWidgetOrientation audioWidgetOrientation;
  final AudioWidgetValue value;
  final AudioWidgetValue? minValue;
  final AudioWidgetValue? maxValue;
  final bool isWidgetDependentOnDimensions;
  final int? dimensionIndex;
  final bool isWidgetPhantomPower;

  const AudioWidgetEntity({
    required this.id,
    required this.name,
    required this.parentPanelBlockName,
    required this.audioWidgetType,
    required this.audioWidgetOrientation,
    required this.isWidgetDependentOnDimensions,
    required this.value,
    this.minValue,
    this.maxValue,
    this.dimensionIndex,
    this.isWidgetPhantomPower = false,
  });

  AudioWidgetEntity copyWith({
    String? id,
    String? name,
    String? parentPanelBlockName,
    AudioWidgetType? audioWidgetType,
    AudioWidgetOrientation? audioWidgetOrientation,
    AudioWidgetValue? value,
    AudioWidgetValue? minValue,
    AudioWidgetValue? maxValue,
    bool? isWidgetDependentOnDimensions,
    int? dimensionIndex,
    bool? isWidgetPhantomPower,
  }) {
    //log each update request
    return AudioWidgetEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      parentPanelBlockName: parentPanelBlockName ?? this.parentPanelBlockName,
      audioWidgetType: audioWidgetType ?? this.audioWidgetType,
      audioWidgetOrientation: audioWidgetOrientation ?? this.audioWidgetOrientation,
      value: value ?? this.value,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      isWidgetDependentOnDimensions: isWidgetDependentOnDimensions ?? this.isWidgetDependentOnDimensions,
      dimensionIndex: dimensionIndex ?? this.dimensionIndex,
      isWidgetPhantomPower: isWidgetPhantomPower ?? this.isWidgetPhantomPower,
    );
  }

  @override
  List<Object?> get props {
    return <Object?>[
      id,
      name,
      parentPanelBlockName,
      audioWidgetType,
      value,
      audioWidgetOrientation,
      minValue,
      maxValue,
      isWidgetDependentOnDimensions,
      dimensionIndex,
      isWidgetPhantomPower,
    ];
  }

  //impment to string
  @override
  String toString() {
    return 'AudioWidgetEntity(id: $id, name: $name, parentPanelBlockName: $parentPanelBlockName, audioWidgetType: $audioWidgetType, audioWidgetOrientation: $audioWidgetOrientation, value: $value, minValue: $minValue, maxValue: $maxValue, isWidgetDependentOnDimensions: $isWidgetDependentOnDimensions, dimensionIndex: $dimensionIndex, isWidgetPhantomPower: $isWidgetPhantomPower)';
  }
}
