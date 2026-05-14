
import '../../../../core/service_locator.dart';
import '../repositories/panel_repository.dart';

class ClearAudioSettingsUseCase {
  final PanelRepository repository = serviceLocator<PanelRepository>();

  Future<bool> call() async {
    return await repository.clearAudioSettings();
  }
}
