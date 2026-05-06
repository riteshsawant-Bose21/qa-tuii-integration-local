import 'package:bloc/bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/service/event/fusion_event_service.dart';
import 'package:meta/meta.dart';

import '../../../../core/service_locator.dart';

part 'fusion_events_sync_view_model_state.dart';

class FusionEventsSyncViewModel extends Cubit<FusionEventsSyncViewModelState> {
  FusionEventsSyncViewModel({required this.fusionEventService}) : super(FusionEventsSyncViewModelInitial());

  final FusionEventService fusionEventService;

  Future<ResponseCallback<bool>> syncAllFusionEvents() async {
    try {
      final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
      final List<CreateScheduleTaskDto> allEvents = projectViewModel.getScheduledEventsDto();
      if (allEvents.isEmpty) {
        return ResponseCallback<bool>.success(true);
      }
      final ResponseCallback<bool> response = await fusionEventService.syncScheduledEvents(
        vip: projectViewModel.virtualIP ?? "",
        events: allEvents,
      );

      if (response.success) {
        return ResponseCallback<bool>.success(true);
      } else {
        return ResponseCallback<bool>.failure(response.message);
      }
    } catch (ex) {
      FusionLogger.log(tag: LogTag.network, message: "Error syncing fusion events: $ex");
      return ResponseCallback<bool>.failure("Error syncing fusion events: $ex");
    }
  }
}
