import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/models/response_callback.dart';

import '../fusion_networking/network/fusion_network_client.dart';
import '../models/project_entities/fusion_dsp.dart';

class TelemetryData {
  TelemetryData();

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

  Future<void> initializeTelemetryAddresses(FusionNetworkClient fusionNetworkClient, String vip) async {
    try {
      final ResponseCallback<List<FusionNetworkDevice>> networkDevicesResponse = await FusionDeviceService(networkClient: fusionNetworkClient)
          .getAvailableDevicesOnNetwork(
            ip: vip,
          );
      if (networkDevicesResponse.success && networkDevicesResponse.data != null) {
        final List<FusionNetworkDevice> fusionDevices = networkDevicesResponse.data ?? <FusionNetworkDevice>[];

        final List<String> addresses = fusionDevices.map((FusionNetworkDevice device) => "ws://${device.address}:5678").toList();

        telemetryAddresses = addresses;

        debugPrint("Telemetry addresses initialized: ${TelemetryData.telemetryAddresses}");
      } else {
        throw Exception(networkDevicesResponse.message);
      }
    } catch (exception) {
      debugPrint("Error initializing telemetry addresses: $exception");
    }
  }
}
