import 'package:fusion_lib/product_data/data_sources/data_sources.dart';

import '../../api_data/devices/device_catalog.dart';

class RecommendedDeviceResult {
  final String device;
  final int quantity;

  RecommendedDeviceResult({required this.device, required this.quantity});
  @override
  String toString() {
    return "$quantity x $device";
  }
}

class DspDeviceRecommendation {
  // List<RecommendedDeviceResult> pickBasedOnPrice({
  //   required List<List<RecommendedDeviceResult>> combinations,
  //   required ProductCatalog productCatalog,
  // }) {

  // }

  ({List<RecommendedDeviceResult> powerPure, List<RecommendedDeviceResult> powerSmart}) recommendDevices({
    required int analogInputs,
    required int analogOutputs,
  }) {
    final powerPureCombination = _buildPowerPureCombination(
      analogInputs: analogInputs,
      analogOutputs: analogOutputs,
    );
    final powerSmartCombination = _buildPowerSmartCombination(
      analogInputs: analogInputs,
      analogOutputs: analogOutputs,
    );
    print("*" * 50);
    print("Power Pure Combination: $powerPureCombination");
    print("Power Smart Combination: $powerSmartCombination");
    print("*" * 50);
    return (powerPure: powerPureCombination, powerSmart: powerSmartCombination);
  }

  /// Builds a Power Pure combination: FM (DSP) + PowerPure (Amplifier).
  ///
  /// Algorithm:
  ///  1. FM devices handle all DSP inputs and provide line outputs to PP amps.
  ///     Each PP amp input requires exactly one FM line output (1:1 mapping),
  ///     so FM devices must satisfy both input and output demand.
  ///  2. Determine the minimum FM device count as:
  ///       max(ceil(inputs / 4), ceil(outputs / 8))
  ///     since FM6 and FM8Y both have 4 input ports, and FM8Y has the
  ///     maximum of 8 output ports.
  ///  3. Default all FM devices to FM6 (4in/4out, cheaper). If total FM6
  ///     output capacity is insufficient, upgrade the minimum number of
  ///     FM6 units to FM8Y (4in/8out) to cover the shortfall (+4 outputs each).
  ///  4. Allocate PowerPure amplifiers for loudspeaker outputs using 8ch
  ///     units first, then a 4ch unit for any remainder.
  List<RecommendedDeviceResult> _buildPowerPureCombination({
    required int analogInputs,
    required int analogOutputs,
  }) {
    final devices = <String, int>{};

    // Minimum FM count must cover both input demand and output demand.
    // FM6/FM8Y share 4 input ports; FM8Y has 8 output ports (maximum).
    final fmForInputs = (analogInputs + _fm6InputPorts - 1) ~/ _fm6InputPorts;
    final fmForOutputs = (analogOutputs + _fm8yOutputPorts - 1) ~/ _fm8yOutputPorts;
    final fmCount = fmForInputs > fmForOutputs ? fmForInputs : fmForOutputs;
    final totalFm = fmCount < 1 ? 1 : fmCount;

    // Start with all FM6 (4 outputs each). If total output capacity falls
    // short, upgrade the minimum number of FM6 → FM8Y (+4 outputs each).
    final fm6OutputCapacity = totalFm * _fm6OutputPorts;
    final extraOutputsNeeded = analogOutputs - fm6OutputCapacity;
    final fm8yCount = extraOutputsNeeded > 0 ? (extraOutputsNeeded + (_fm8yOutputPorts - _fm6OutputPorts) - 1) ~/ (_fm8yOutputPorts - _fm6OutputPorts) : 0;
    final fm6Count = totalFm - fm8yCount;

    _addDevice(devices, _deviceFm6, fm6Count);
    _addDevice(devices, _deviceFm8y, fm8yCount);

    // Allocate PowerPure amplifiers for loudspeaker outputs.
    // Prefer 8ch units to minimize device count; use 4ch for remainder.
    var remainingOutputs = analogOutputs;
    final pp8chCount = remainingOutputs ~/ _powerPure8chOutputPorts;
    remainingOutputs %= _powerPure8chOutputPorts;
    _addDevice(devices, _device8chPowerPure, pp8chCount);

    if (remainingOutputs > _powerPure4chOutputPorts) {
      _addDevice(devices, _device8chPowerPure, 1);
    } else if (remainingOutputs > 0) {
      _addDevice(devices, _device4chPowerPure, 1);
    }

    return _toRecommendationList(devices);
  }

  /// Builds a Power Smart combination: FM (DSP) + PowerSmart (MixAmp).
  ///
  /// Algorithm:
  ///  1. PowerSmart is a MixAmp — its inputs act as both DSP and amplifier
  ///     inputs, and only PowerSmart devices can provide loudspeaker outputs.
  ///  2. Allocate PowerSmart devices to cover all loudspeaker outputs.
  ///     Prefer 8ch units first, then a 4ch unit for any remainder.
  ///  3. Sum the input capacity already provided by the allocated PS devices
  ///     (PS is a MixAmp, so its inputs double as DSP inputs).
  ///  4. If PS input capacity does not cover all required inputs, add FM6
  ///     devices (4 inputs each) to handle the shortfall.
  ///  5. At least 1 FM device is always required in the system.
  List<RecommendedDeviceResult> _buildPowerSmartCombination({
    required int analogInputs,
    required int analogOutputs,
  }) {
    final devices = <String, int>{};

    // Allocate PowerSmart devices to cover all loudspeaker outputs.
    // Prefer 8ch units to minimize device count; use 4ch for remainder.
    var remainingOutputs = analogOutputs;
    var ps8chCount = remainingOutputs ~/ _powerSmart8chOutputPorts;
    remainingOutputs %= _powerSmart8chOutputPorts;
    var ps4chCount = 0;

    if (remainingOutputs > _powerSmart4chOutputPorts) {
      ps8chCount += 1;
    } else if (remainingOutputs > 0) {
      ps4chCount = 1;
    }

    // PS inputs double as DSP inputs (MixAmp). Calculate spare input capacity.
    final psInputCapacity = ps8chCount * _powerSmart8chInputPorts + ps4chCount * _powerSmart4chInputPorts;

    // Add FM6 devices for any remaining inputs not covered by PS devices.
    // At least 1 FM device is always required.
    final remainingInputs = analogInputs - psInputCapacity;
    final fmCount = remainingInputs > 0 ? (remainingInputs + _fm6InputPorts - 1) ~/ _fm6InputPorts : 1;
    _addDevice(devices, _deviceFm6, fmCount);
    _addDevice(devices, _device8chPowerSmart, ps8chCount);
    _addDevice(devices, _device4chPowerSmart, ps4chCount);

    return _toRecommendationList(devices);
  }

  void _addDevice(Map<String, int> devices, String name, int quantity) {
    if (quantity <= 0) {
      return;
    }

    devices.update(name, (existing) => existing + quantity, ifAbsent: () => quantity);
  }

  List<RecommendedDeviceResult> _toRecommendationList(Map<String, int> devices) {
    return devices.entries.map((entry) => RecommendedDeviceResult(device: entry.key, quantity: entry.value)).toList();
  }

  double _calculateCombinationPrice(List<RecommendedDeviceResult> devices) {
    var total = 0.0;

    for (final device in devices) {
      total += _devicePriceByName(device.device) * device.quantity;
    }

    return total;
  }

  double _devicePriceByName(String deviceName) {
    switch (deviceName) {
      case _device4chPowerSmart:
        return DeviceCatalog.powerSmart4ch.price;
      case _device8chPowerSmart:
        return DeviceCatalog.powerSmart8ch.price;
      case _deviceFm6:
        return DeviceCatalog.fm6.price;
      case _deviceFm8y:
        return DeviceCatalog.fm8y.price;
      case _device4chPowerPure:
        return DeviceCatalog.powerPureAmplifier.price;
      case _device8chPowerPure:
        // Catalog has 4ch PowerPure only; treat 8ch as two 4ch units.
        return DeviceCatalog.powerPureAmplifier.price * 2;
      default:
        return 0;
    }
  }

  static const String _deviceFm6 = 'FM6';
  static const String _deviceFm8y = 'FM8Y';
  static const String _device4chPowerPure = '4ch PowerPure';
  static const String _device8chPowerPure = '8ch PowerPure';
  static const String _device4chPowerSmart = '4ch PowerSmart';
  static const String _device8chPowerSmart = '8ch PowerSmart';

  static const int _fm6InputPorts = 4;
  static const int _fm6OutputPorts = 4;
  static const int _fm8yOutputPorts = 8;

  static const int _powerSmart4chInputPorts = 4;
  static const int _powerSmart8chInputPorts = 8;
  static const int _powerSmart4chOutputPorts = 4;
  static const int _powerSmart8chOutputPorts = 8;

  static const int _powerPure4chOutputPorts = 4;
  static const int _powerPure8chOutputPorts = 8;
}
