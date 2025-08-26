
import '../../../../core/service_locator.dart';
import '../entities/audio_widget_entity.dart';
import '../entities/audio_widget_value.dart';
import '../repositories/panel_repository.dart';

class SendWidgetDataUseCase {
  final PanelRepository repository = serviceLocator<PanelRepository>();

  Future<AudioWidgetEntity> call(
    AudioWidgetEntity widget,
    AudioWidgetValue newValue,
  ) async {
    return await repository.sendWidgetData(widget, newValue);
  }
}
