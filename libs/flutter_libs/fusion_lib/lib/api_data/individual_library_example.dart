/// Example demonstrating individual library imports and usage
/// 
/// This shows how you can now import each library independently
/// and access their respective JSON export functions.

import '../api_data/speakers/speakers.dart' as speakers;
import '../api_data/amplifiers/amplifiers.dart' as amplifiers;
import '../api_data/devices/devices.dart' as devices;

void main() {
  print('=== Individual Library Usage Example ===\n');
  
  // Use speakers library independently
  final speakersJson = speakers.getAllSpeakersCatalog();
  print(speakersJson);
  
  // Use amplifiers library independently
  final amplifiersJson = amplifiers.getAllAmplifiersCatalog();
  print(amplifiersJson);
  
  // Use devices library independently
  final devicesJson = devices.getAllDSPDevicesCatalog();
  print(devicesJson);
  
  print('=== Library Independence Achieved! ===');
}
