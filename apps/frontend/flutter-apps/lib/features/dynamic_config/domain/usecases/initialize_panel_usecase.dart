
import '../../../../core/service_locator.dart';
import '../repositories/panel_repository.dart';

class InitializePanelUseCase {
  final PanelRepository repository = serviceLocator<PanelRepository>();

  Future<void> call() async{
    return await repository.initializePanelServices();
  }
}
