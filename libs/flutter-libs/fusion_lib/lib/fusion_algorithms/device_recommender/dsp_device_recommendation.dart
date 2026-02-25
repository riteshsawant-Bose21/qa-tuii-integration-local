class RecommendedDeviceResult {
  final String device;
  final int quantity;

  RecommendedDeviceResult({required this.device, required this.quantity});
}

class DspDeviceRecommendation {
  List<RecommendedDeviceResult> recommendDevices({required int analogInputs, required int analogOutputs}) {
    final recommendation = <RecommendedDeviceResult>[];
    final _DeviceSystem? matchingSystem = _findMatchingDeviceSystem(analogInputs, analogOutputs);
    if (matchingSystem != null) {
      recommendation.addAll(matchingSystem.devices);
    } else {}
    return recommendation;
  }

  _DeviceSystem? _findMatchingDeviceSystem(int analogInputs, int analogOutputs) {
    final deviceSystems = _getDeviceSystems();

    for (final deviceSystem in deviceSystems) {
      if (analogOutputs >= deviceSystem.analogOutputRange.$1 &&
          analogOutputs <= deviceSystem.analogOutputRange.$2 &&
          analogInputs >= deviceSystem.analogInputRange.$1 &&
          analogInputs <= deviceSystem.analogInputRange.$2) {
        return deviceSystem;
      }
    }
    return null; // No matching system found
  }

  List<_DeviceSystem> _getDeviceSystems() {
    return [
      ///
      /// Default
      ///
      _DeviceSystem(
        analogOutputRange: (1, 4),
        analogInputRange: (1, 4),
        devices: [
          RecommendedDeviceResult(device: "FM6", quantity: 1),
          RecommendedDeviceResult(device: "4ch PowerPure", quantity: 1),
        ],
      ),

      /// First Column
      _DeviceSystem(
        analogOutputRange: (4, 8),
        analogInputRange: (1, 4),
        devices: [
          RecommendedDeviceResult(device: "FM8Y", quantity: 1),
          RecommendedDeviceResult(device: "8ch PowerPure", quantity: 1),
        ],
      ),
      _DeviceSystem(
        analogOutputRange: (1, 4),
        analogInputRange: (4, 8),
        devices: [
          RecommendedDeviceResult(device: "FM6", quantity: 1),
          RecommendedDeviceResult(device: "4ch PowerSmart", quantity: 1),
        ],
      ),
      _DeviceSystem(
        analogOutputRange: (5, 8),
        analogInputRange: (5, 8),
        devices: [
          RecommendedDeviceResult(device: "FM6", quantity: 1),
          RecommendedDeviceResult(device: "8ch PowerSmart", quantity: 1),
        ],
      ),

      ///
      /// Second layer
      ///
      _DeviceSystem(
        analogOutputRange: (8, 12),
        analogInputRange: (1, 4),
        devices: [
          RecommendedDeviceResult(device: "FM6", quantity: 1),
          RecommendedDeviceResult(device: "8ch PowerSmart", quantity: 1),
          RecommendedDeviceResult(device: "4ch PowerSmart", quantity: 1),
        ],
      ),
      _DeviceSystem(
        analogOutputRange: (1, 4),
        analogInputRange: (9, 12),
        devices: [
          RecommendedDeviceResult(device: "FM6", quantity: 2),
          RecommendedDeviceResult(device: "4ch PowerSmart", quantity: 1),
        ],
      ),
    ];
  }



}

class _DeviceSystem {
  final (int min, int max) analogOutputRange;
  final (int min, int max) analogInputRange;

  List<RecommendedDeviceResult> devices;
  _DeviceSystem({
    required this.analogOutputRange,
    required this.analogInputRange,
    required this.devices,
  });
}


