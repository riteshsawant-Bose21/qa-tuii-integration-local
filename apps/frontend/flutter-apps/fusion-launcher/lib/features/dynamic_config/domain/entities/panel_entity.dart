import 'package:equatable/equatable.dart';

import 'audio_widget_entity.dart';

class PanelEntity extends Equatable {
  final String id;
  final String name;
  final String algorithmType;
  final List<AudioWidgetEntity> listOfAudioWidgets;

  const PanelEntity({
    required this.id,
    required this.name,
    required this.listOfAudioWidgets,
    required this.algorithmType,
  });

  PanelEntity copyWith({
    String? id,
    String? name,
    List<AudioWidgetEntity>? listOfAudioWidgets,
    String? algorithmType,
  }) {
    return PanelEntity(
      id: id ?? this.id,
      name: name ?? this.name,
      listOfAudioWidgets: listOfAudioWidgets ?? this.listOfAudioWidgets,
      algorithmType: algorithmType ?? this.algorithmType,
    );
  }

  List<AudioWidgetEntity> getMeters() {
    return listOfAudioWidgets.where((AudioWidgetEntity element) => element.audioWidgetType == AudioWidgetType.meter).toList();
  }

  List<AudioWidgetEntity> getButtons() {
    return listOfAudioWidgets.where((AudioWidgetEntity element) => element.audioWidgetType == AudioWidgetType.toggleButton).toList();
  }

  List<AudioWidgetEntity> getFaders() {
    return listOfAudioWidgets.where((AudioWidgetEntity element) => element.audioWidgetType == AudioWidgetType.gainFader).toList();
  }

  @override
  List<Object?> get props {
    return <Object?>[name, algorithmType, listOfAudioWidgets];
  }
}
