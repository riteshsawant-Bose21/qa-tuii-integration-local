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
  List<RecommendedDeviceResult> recommendDevices({
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

    final powerPurePrice = _calculateCombinationPrice(powerPureCombination);
    final powerSmartPrice = _calculateCombinationPrice(powerSmartCombination);
    print("*" * 50);
    print("Power Pure Combination: $powerPureCombination, Total Price: \$${powerPurePrice.toStringAsFixed(2)}");
    print("Power Smart Combination: $powerSmartCombination, Total Price: \$${powerSmartPrice.toStringAsFixed(2)}");
    print("*" * 50);
    return powerPurePrice <= powerSmartPrice ? powerPureCombination : powerSmartCombination;
  }

  List<RecommendedDeviceResult> _buildPowerPureCombination({
    required int analogInputs,
    required int analogOutputs,
  }) {
    final devices = <String, int>{};

    final outputCounts = _calculateEightAndFourChannelCounts(analogOutputs);
    _addDevice(devices, _device8chPowerPure, outputCounts.$1);
    _addDevice(devices, _device4chPowerPure, outputCounts.$2);

    final fmCountsForOutputs = _calculateEightAndFourChannelCounts(analogOutputs);
    _addDevice(devices, _deviceFm8y, fmCountsForOutputs.$1);
    _addDevice(devices, _deviceFm6, fmCountsForOutputs.$2);

    final availableInputsFromFm = fmCountsForOutputs.$1 * _fm8yInputPorts + fmCountsForOutputs.$2 * _fm6InputPorts;

    if (analogInputs > availableInputsFromFm) {
      final balanceInputs = analogInputs - availableInputsFromFm;
      final additionalFmCounts = _calculateEightAndFourChannelCounts(balanceInputs);
      _addDevice(devices, _deviceFm8y, additionalFmCounts.$1);
      _addDevice(devices, _deviceFm6, additionalFmCounts.$2);
    }

    return _toRecommendationList(devices);
  }

  List<RecommendedDeviceResult> _buildPowerSmartCombination({
    required int analogInputs,
    required int analogOutputs,
  }) {
    final devices = <String, int>{};

    final powerSmartCounts = _calculateEightAndFourChannelCounts(analogOutputs);
    _addDevice(devices, _device8chPowerSmart, powerSmartCounts.$1);
    _addDevice(devices, _device4chPowerSmart, powerSmartCounts.$2);

    final availableInputsFromPowerSmart = powerSmartCounts.$1 * _powerSmart8chInputPorts + powerSmartCounts.$2 * _powerSmart4chInputPorts;

    if (availableInputsFromPowerSmart > analogInputs) {
      _addDevice(devices, _deviceFm6, 1);
    } else if (availableInputsFromPowerSmart < analogInputs) {
      final balanceInputs = analogInputs - availableInputsFromPowerSmart;
      final additionalFmCounts = _calculateEightAndFourChannelCounts(balanceInputs);
      _addDevice(devices, _deviceFm8y, additionalFmCounts.$1);
      _addDevice(devices, _deviceFm6, additionalFmCounts.$2);
    }

    // Every PowerSmart system must include at least one FM device.
    if (!devices.containsKey(_deviceFm6) && !devices.containsKey(_deviceFm8y)) {
      _addDevice(devices, _deviceFm6, 1);
    }

    return _toRecommendationList(devices);
  }

  (int, int) _calculateEightAndFourChannelCounts(int ports) {
    if (ports <= 0) {
      return (0, 0);
    }

    var numberOf8ch = ports ~/ 8;
    final remainingPorts = ports - (numberOf8ch * 8);
    var numberOf4ch = 0;

    if (remainingPorts > 0 && remainingPorts <= 4) {
      numberOf4ch = 1;
    } else if (remainingPorts >= 4) {
      numberOf8ch += 1;
    }

    print("Required ports: $ports, 8ch count: $numberOf8ch, 4ch count: $numberOf4ch");
    return (numberOf8ch, numberOf4ch);
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
  static const int _fm8yInputPorts = 4;
  static const int _powerSmart4chInputPorts = 4;
  static const int _powerSmart8chInputPorts = 8;
}
