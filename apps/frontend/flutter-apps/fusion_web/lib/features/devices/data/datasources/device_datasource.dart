import 'dart:convert';
import 'package:flutter/services.dart';
import 'package:fusion_web/features/devices/data/models/devices_model.dart';

class DeviceDatasource {

  Future<DevicesModel> getDeviceStats() async {

    final jsonString =
        await rootBundle.loadString('assets/data/devices.json');

    final Map<String, dynamic> data = json.decode(jsonString);

    return DevicesModel.fromJson(data);
  }
}