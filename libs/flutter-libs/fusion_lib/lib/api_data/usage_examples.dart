/// Example demonstrating unified FusionDevices usage
/// 
/// This shows how you can now use the unified FusionDevices interface
/// to access all device catalogs through convenient getter methods.

import '../api_data/fusion_devices.dart';

void main() {
  print('=== Unified FusionDevices Usage Example ===\n');
  
  // Use the unified fusionDevices interface
  final speakersJson = fusionDevices.getSpeakers();
  print('Speakers JSON:');
  print(speakersJson);
  print('\n');
  
  // final amplifiersJson = fusionDevices.getAmplifiers();
  // print('Amplifiers JSON:');
  // print(amplifiersJson);
  // print('\n');
  
  final devicesJson = fusionDevices.getDevices();
  print('DSP Devices JSON:');
  print(devicesJson);
  print('\n');

  final allDevicesJson = fusionDevices.getAllDevices();
  print('All Devices JSON:');
  print(allDevicesJson);
  print('\n');
  
  final controllersJson = fusionDevices.getControllers();
  print('Controllers JSON:');
  print(controllersJson);
  print('\n');

  final allEndpointsJson = fusionDevices.getAllEndpoints();
  print('Endpoints JSON:');
  print(allEndpointsJson);
  print('\n');
    
  print('=== Unified Interface Success! ===');
}
