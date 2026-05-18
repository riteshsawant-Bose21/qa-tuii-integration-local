import 'dart:convert';

import 'package:fusion_lib/fusion_lib.dart';

class FusionEventService {
  final FusionNetworkClient networkClient;

  FusionEventService({required this.networkClient});

  Future<ResponseCallback<bool>> syncScheduledEvents({
    required String vip,
    required List<CreateScheduleTaskDto> events,
  }) async {
    try {
      /// if events is empty, we can skip syncing and return success immediately
      if (events.isEmpty) {
        return ResponseCallback<bool>.success(true);
      }

      /// get all existing tasks from the fusion server
      final ResponseCallback<List<CreateScheduleTaskDto>> listResponse = await getAllEventList(vip: vip);

      if (!listResponse.success) {
        return ResponseCallback<bool>.failure(listResponse.message);
      }

      final List<String> existingIds = (listResponse.data ?? <CreateScheduleTaskDto>[]).map((e) => e.id).toList();

      /// filter events that are not yet on the server
      final List<CreateScheduleTaskDto> eventsToSync = events.where((CreateScheduleTaskDto e) => !existingIds.contains(e.id)).toList();

      if (eventsToSync.isEmpty) {
        return ResponseCallback<bool>.success(true);
      }

      /// upload missing events sequentially one by one
      for (final CreateScheduleTaskDto event in eventsToSync) {
        final ResponseCallback<CreateScheduleTaskDto> result = await createEvent(vip: vip, event: event);
        if (!result.success) {
          return ResponseCallback<bool>.failure(result.message);
        }
      }

      return ResponseCallback<bool>.success(true);
    } catch (e) {
      return ResponseCallback<bool>.failure(e.toString());
    }
  }

  /// GET /tasks — fetch all scheduled tasks/events from the fusion server
  Future<ResponseCallback<List<CreateScheduleTaskDto>>> getAllEventList({
    required String vip,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.get(
        api: FusionApiEndpoint.tasks,
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success && response.data != null) {
        if (response.data is Map<String, dynamic> && !response.data.containsKey('tasks')) {
          return ResponseCallback<List<CreateScheduleTaskDto>>.success([]);
        }

        final List<dynamic> list = response.data is String ? jsonDecode(response.data) : response.data as List<dynamic>;
        final List<CreateScheduleTaskDto> events = list.map((dynamic e) => CreateScheduleTaskDto.fromJson(e as Map<String, dynamic>)).toList();
        return ResponseCallback<List<CreateScheduleTaskDto>>.success(events);
      } else {
        return ResponseCallback<List<CreateScheduleTaskDto>>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<List<CreateScheduleTaskDto>>.failure(e.toString());
    }
  }

  /// POST /tasks — create a new scheduled task/event
  Future<ResponseCallback<CreateScheduleTaskDto>> createEvent({
    required String vip,
    required CreateScheduleTaskDto event,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.tasks,
        data: event.toJson(),
        baseUrlToOverride: vip,
        isSecure: false,
      );

      if (response.success && response.data != null) {
        // final CreateScheduleTaskDto created = CreateScheduleTaskDto.fromJson(response.data as Map<String, dynamic>);
        return ResponseCallback<CreateScheduleTaskDto>.success(event);
      } else {
        return ResponseCallback<CreateScheduleTaskDto>.failure(response.message);
      }
    } catch (e) {
      return ResponseCallback<CreateScheduleTaskDto>.failure(e.toString());
    }
  }

  /// PUT /events/activate/:id — trigger/recall an event by id
  Future<ResponseCallback<bool>> activateEvent({
    required String vip,
    required String eventId,
  }) async {
    try {
      final ResponseCallback<dynamic> response = await networkClient.post(
        api: FusionApiEndpoint.snapshotsActivate,
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
