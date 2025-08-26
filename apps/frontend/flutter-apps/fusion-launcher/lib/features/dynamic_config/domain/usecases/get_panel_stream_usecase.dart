
import '../../../../core/service_locator.dart';
import '../repositories/panel_repository.dart';

class GetPanelStreamUseCase {
  final PanelRepository repository = serviceLocator<PanelRepository>();

  Stream<Map<String, dynamic>> call() {
    return repository.getMeterStream();
  }
}
