import 'package:flutter/material.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';
import 'package:go_router/go_router.dart';
class DeviceActionsHandler {
  // ================= VIEW DETAILS =================

  static void viewDetails({
    required BuildContext context,
    required Device device,
  }) {
    print("View details clicked");
    context.go("/devices/${device.deviceId}");
  }
}
