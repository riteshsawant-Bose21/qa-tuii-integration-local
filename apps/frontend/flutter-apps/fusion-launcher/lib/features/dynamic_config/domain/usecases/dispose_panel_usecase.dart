
import '../../../../core/service_locator.dart';
import '../repositories/panel_repository.dart';

class DisposePanelUseCase {
  final PanelRepository repository = serviceLocator<PanelRepository>();

  void call() {
    return repository.disposePanelServices();
  }
}
