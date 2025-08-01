
import '../../../../core/service_locator.dart';
import '../entities/panel_entity.dart';
import '../repositories/panel_repository.dart';

class GetPanelDataUseCase {
  final PanelRepository repository = serviceLocator<PanelRepository>();

  Future<PanelEntity> call(
    PanelEntity panel,
  ) async {
    return await repository.getPanelData(panel);
  }
}
