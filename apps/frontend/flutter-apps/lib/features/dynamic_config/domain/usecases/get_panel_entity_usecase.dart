
import 'package:fusion_design_tool_prototype/core/models/processing_block_entity.dart';

import '../../../../core/service_locator.dart';
import '../entities/panel_entity.dart';
import '../repositories/panel_repository.dart';

class GetPanelEntityUseCase {
  final PanelRepository repository = serviceLocator<PanelRepository>();

  Future<PanelEntity> call(ProcessingBlockEntity processingBloc) async {
    return await repository.getPanelEntity(processingBloc);
  }
}
