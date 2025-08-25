import 'package:fusion_lib/models/fusion_models.dart';

import '../../../../core/service_locator.dart';
import '../entities/panel_entity.dart';
import '../repositories/panel_repository.dart';

class GetPanelEntityUseCase {
  final PanelRepository repository = serviceLocator<PanelRepository>();

  Future<PanelEntity> call(ProcessingBlockEntity processingBloc) async {
    return await repository.getPanelEntity(processingBloc);
  }
}
