import 'package:fusion_launcher/core/models/processing_block_entity.dart';

import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/audio_widget_value.dart';
import '../../domain/entities/panel_entity.dart';

abstract class PanelBlocEvent {}

class InitializePanel extends PanelBlocEvent {
  final ProcessingBlockEntity processingBloc;
  InitializePanel(this.processingBloc);
}

class DisposePanel extends PanelBlocEvent {
  DisposePanel();
}

class GetAllWidgetsValueInAPanel extends PanelBlocEvent {
  final PanelEntity panel;
  GetAllWidgetsValueInAPanel(this.panel);
}

class UpdateServerWithAudioWidgetValue extends PanelBlocEvent {
  final AudioWidgetEntity audioWidget;
  final AudioWidgetValue newValue;
  UpdateServerWithAudioWidgetValue(this.newValue, this.audioWidget);
}

class UpdateUIWithNewAudioWidgetValue extends PanelBlocEvent {
  final String audioWidgetID;
  final AudioWidgetValue newValue;
  UpdateUIWithNewAudioWidgetValue(
    this.audioWidgetID,
    this.newValue,
  );
}
