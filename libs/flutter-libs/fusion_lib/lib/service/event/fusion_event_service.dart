//using future.wait

import 'package:fusion_lib/fusion_lib.dart';

class FusionEventService {
  final FusionNetworkClient networkClient;

  FusionEventService({required this.networkClient});

  Future<ResponseCallback<bool>> syncScheduledEvents({
    required String vip,
    required List<CreateScheduleTaskDto> events,
  }) async {
    try {
      //get list of tasks from fusion server, if all are already synced return true, if not sync the ones that are not synced

      return ResponseCallback.success(true);
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }

  /// PUT /events/activate/:id — trigger/recall an event by id
  Future<ResponseCallback<bool>> activateEvent({
    required String vip,
    required String eventId,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.tasks,
        additionalPath: eventId,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback<bool>.success(true);
      } else {
        return ResponseCallback<bool>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }

  /// POST /tasks/:id/enable — enable an event/task by id
  Future<ResponseCallback<bool>> enableEvent({
    required String vip,
    required String eventId,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.tasks,
        additionalPath: '$eventId/enable',
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback<bool>.success(true);
      } else {
        return ResponseCallback<bool>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }

  /// POST /tasks/:id/disable — disable an event/task by id
  Future<ResponseCallback<bool>> disableEvent({
    required String vip,
    required String eventId,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.tasks,
        additionalPath: '$eventId/disable',
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success) {
        return ResponseCallback<bool>.success(true);
      } else {
        return ResponseCallback<bool>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }
}
