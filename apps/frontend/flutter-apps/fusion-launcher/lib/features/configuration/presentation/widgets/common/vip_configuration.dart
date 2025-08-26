import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_logger/logger.dart';
import 'package:fusion_lib/fusion_networking/ble/ble_connection_manager.dart';

import '../ble/ble_listing.dart';
import '../ble/setup_vip_screen.dart';

void configureVip(BuildContext context) async {
  final bool? deviceConnected = await showDialog<bool>(
    context: context,
    builder: (_) => const BleDiscovery(),
  );

  if (deviceConnected == true && context.mounted) {
    final bool? isVipSet = await showDialog<bool>(
      context: context,
      builder: (_) => const VipConfiguration(),
    );

    if (isVipSet == true && context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('VIP Configuration Successful')),
      );
    } else {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('VIP Configuration Failed')),
        );
      }
    }
  } else {
    FusionLogger.log(message: "Device not connected or dialog dismissed", tag: LogTag.ble);
    BleConnectionManager().disconnect();
  }
}
