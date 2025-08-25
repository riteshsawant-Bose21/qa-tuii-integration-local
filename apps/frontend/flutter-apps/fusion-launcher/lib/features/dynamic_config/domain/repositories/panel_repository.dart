import 'package:fusion_lib/models/fusion_models.dart';

import '../entities/audio_widget_entity.dart';
import '../entities/audio_widget_value.dart';
import '../entities/panel_entity.dart';

abstract class PanelRepository {
  Future<void> initializePanelServices();
  void disposePanelServices();

  Future<AudioWidgetEntity> sendWidgetData(
    AudioWidgetEntity audioWidget,
    AudioWidgetValue newValue,
  );

  Future<PanelEntity> getPanelData(
    PanelEntity panel,
  );

  Stream<Map<String, dynamic>> getMeterStream();

  Future<bool> resetFusion();

  Future<PanelEntity> getPanelEntity(ProcessingBlockModel processingBloc);
}
