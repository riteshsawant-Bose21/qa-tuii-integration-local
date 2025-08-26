/// Device API Data Module
/// 
/// This module exports all DSP device-related data structures and catalogs
/// that would typically be fetched from a device specifications API.

library device_api_data;

import 'dart:convert';
import 'device_catalog.dart';

export 'device_types.dart';
export 'device_catalog.dart';

/// Returns all DSP devices as a JSON string
String getAllDSPDevicesCatalog() {
	final devices = DeviceCatalog.devices.map((d) => d.toJson()).toList();
	return jsonEncode(devices);
}
