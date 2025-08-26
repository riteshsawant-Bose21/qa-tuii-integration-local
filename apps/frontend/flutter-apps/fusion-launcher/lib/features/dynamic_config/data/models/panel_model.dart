import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/panel_entity.dart';

class PanelModel {
  final String id;
  final String name;
  final String algorithmType;
  final List<AudioWidgetEntity> listOfAudioWidgets;

  PanelModel({
    required this.id,
    required this.name,
    required this.listOfAudioWidgets,
    required this.algorithmType,
  });

  PanelModel copyWith({
    String? id,
    String? name,
    String? algorithmType,
    List<AudioWidgetEntity>? listOfAudioWidgets,
  }) {
    return PanelModel(
      id: id ?? this.id,
      name: name ?? this.name,
      algorithmType: algorithmType ?? this.algorithmType,
      listOfAudioWidgets: listOfAudioWidgets ?? this.listOfAudioWidgets,
    );
  }

  PanelEntity toDomain() {
    return PanelEntity(
      id: id,
      name: name,
      listOfAudioWidgets: listOfAudioWidgets,
      algorithmType: algorithmType,
    );
  }

  factory PanelModel.fromDomain(PanelEntity panelEntity) {
    return PanelModel(
      id: panelEntity.id,
      name: panelEntity.name,
      algorithmType: panelEntity.algorithmType,
      listOfAudioWidgets: panelEntity.listOfAudioWidgets,
    );
  }
}
