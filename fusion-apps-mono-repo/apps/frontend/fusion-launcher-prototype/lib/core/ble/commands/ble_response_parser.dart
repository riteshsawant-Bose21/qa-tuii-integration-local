import 'dart:convert';

import 'package:fusion_design_tool_prototype/core/logger/logger.dart';

import '../../models/response_callback.dart';
import 'ble_command_store.dart';

class BleResponseParser {
  static final BleResponseParser _instance = BleResponseParser._internal();

  BleResponseParser._internal();

  factory BleResponseParser() => _instance;

  ResponseCallback<dynamic> getResponse({required Command command, Map<String, dynamic>? params}) {
    FusionLogger.log(tag: LogTag.ble, message: "Parsing response for command: $command with params: $params");

    if (params == null || params.isEmpty) {
      return ResponseCallback<dynamic>(
        success: false,
        message: "No parameters provided for command: $command",
      );
    }
    // {type: response, payload: {body: , status: 204}}
    final Map<String, dynamic> payload = params["payload"];

    print("Payload: $payload");

    switch (command) {
      case Command.setVip:
        if (payload.isEmpty) {
          return ResponseCallback<dynamic>(
            success: false,
            message: "No payload provided for setVip command",
          );
        } else {
          // final String body = payload["body"] ?? "";
          final int status = payload["status"] ?? 0;

          if (status == 204) {
            return ResponseCallback<dynamic>(
              success: true,
              message: "VIP set successfully",
              data: payload["body"] ?? "",
            );
          } else {
            return ResponseCallback<dynamic>(
              success: false,
              message: "Failed to set VIP, status code: $status",
            );
          }
        }

      case Command.blinkLed:
        // TODO: Handle this case.
        throw UnimplementedError();
      case Command.getFusionDevices:
        final List<dynamic> body = jsonDecode(payload["body"]) ?? <dynamic>[];
        if (body.isEmpty) {
          return ResponseCallback<List<dynamic>>(
            success: false,
            message: "No devices found",
            data: <dynamic>[],
          );
        } else {
          return ResponseCallback<List<dynamic>>(
            success: true,
            message: "Devices retrieved successfully",
            data: body,
          );
        }
      case Command.checkVip:
        final Map<String, dynamic> body = jsonDecode(payload["body"]) ?? <String, dynamic>{};
        if (body.isEmpty) {
          return ResponseCallback<dynamic>(
            success: false,
            message: "No VIP status found",
          );
        } else {
          final String vip = body["vip"] ?? "";

          if (vip.isEmpty) {
            return ResponseCallback<dynamic>(
              success: false,
              message: "VIP status is empty",
            );
          } else {
            return ResponseCallback<dynamic>(
              success: true,
              message: "VIP status retrieved successfully",
              data: vip,
            );
          }
        }
    }
  }
}
