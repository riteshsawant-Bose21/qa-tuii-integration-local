import '../../../../core/models/processing_block_entity.dart';
import '../../../../core/service_locator.dart';
import '../../domain/entities/audio_widget_entity.dart';
import '../../domain/entities/audio_widget_value.dart';
import '../../domain/entities/panel_entity.dart';
import '../../domain/repositories/panel_repository.dart';
import '../datasources/panel_datasource.dart';

class PanelRepositoryImpl implements PanelRepository {
  final PanelDataSource panelDataSource = serviceLocator<PanelDataSource>();

  @override
  Future<void> initializePanelServices() {
   return panelDataSource.connectMeteringStream();
  }

  @override
  void disposePanelServices() {
    panelDataSource.disconnectMeteringStream();
  }

  @override
  Future<PanelEntity> getPanelData(PanelEntity panelEntity) async {
    return panelDataSource.fetchPanelData(panelEntity);
  }

  @override
  Stream<Map<String, dynamic>> getMeterStream() async* {
    yield* panelDataSource.getMeterStream();
  }

  @override
  Future<bool> resetFusion() async {
    return panelDataSource.resetFusion();
  }

  @override
  Future<AudioWidgetEntity> sendWidgetData(AudioWidgetEntity audioWidgetEntity, AudioWidgetValue updatedValue) async {
    return panelDataSource.sendWidgetData(
      audioWidgetEntity,
      updatedValue,
    );
  }

  @override
  Future<PanelEntity> getPanelEntity(ProcessingBlockEntity processingBloc) async {
    return panelDataSource.getPanelEntity(processingBloc);
  }
}
