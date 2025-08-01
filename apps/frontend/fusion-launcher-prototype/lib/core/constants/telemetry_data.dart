import 'package:flutter/material.dart';
import 'package:fusion_design_tool_prototype/core/models/response_callback.dart';
import 'package:fusion_design_tool_prototype/core/network_clients/fusion_network_client.dart';
import 'package:fusion_design_tool_prototype/core/service_locator.dart';

import '../models/fusion_device.dart';

class TelemetryData {
  static const List<String> testTelemetryAddresses = <String>[
    // "ws://192.168.0.123:5566",
    // "ws://192.168.0.126:5566",
    // "ws://192.168.0.123:5567",
    // "ws://192.168.0.126:5567",
    // "ws://192.168.0.123:5568",
    // "ws://192.168.0.126:5568",
    "ws://192.168.0.123:5678",
    "ws://192.168.0.126:5678",
    // "ws://localhost:5566",
    // "ws://localhost:5567",
    // "ws://localhost:5568",
    // "tcp://10.8.50.54:5566",
    // "tcp://10.0.2.2:5567",
    // "tcp://10.0.2.2:5568",
    // "tcp://localhost:5566",
    // "tcp://localhost:5567",
    // "tcp://localhost:5568",
  ];

  static List<String> telemetryAddresses = <String>[];

  Future<void> initializeTelemetryAddresses() async {
    try {
      final ResponseCallback<dynamic> responseCallback = await serviceLocator<FusionNetworkClient>().get(
        api: FusionApiEndpoint.fusionDevice,
      );

      if (responseCallback.success && responseCallback.data != null) {
        final List<FusionDevice> fusionDevices =
            (responseCallback.data as List<dynamic>).map((dynamic e) => FusionDevice.fromJson(e as Map<String, dynamic>)).toList();

       final List<String> addresses = fusionDevices.map((FusionDevice device) => "ws://${device.localIp}:5678").toList();

        telemetryAddresses = addresses;

        debugPrint("Telemetry addresses initialized: ${TelemetryData.telemetryAddresses}");
      } else {
        throw Exception(responseCallback.message);
      }
    } catch (exception) {
      debugPrint("Error initializing telemetry addresses: $exception");
    }
  }
}
