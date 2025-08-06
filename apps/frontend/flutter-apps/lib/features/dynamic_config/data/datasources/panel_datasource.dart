import '../../../../core/models/processing_block_entity.dart';
import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/audio_widget_value.dart';
import '../../domain/entities/panel_entity.dart';

abstract class PanelDataSource {
  Future<PanelEntity> fetchPanelData(PanelEntity panelEntity);

  Future<dynamic> getCurrentValueForBlock(
    String blockId,
    String blockName,
  );

  Future<AudioWidgetEntity> sendWidgetData(AudioWidgetEntity audioWidgetEntity, AudioWidgetValue updatedValue);

  Future<bool> resetFusion();

  Stream<Map<String, dynamic>> getMeterStream();

  Future<PanelEntity> getPanelEntity(ProcessingBlockEntity processingBloc);

  Future<void> connectMeteringStream();

  void disconnectMeteringStream();
}
