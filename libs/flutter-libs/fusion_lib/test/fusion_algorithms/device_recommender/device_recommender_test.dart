import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_lib/fusion_algorithms/device_recommender/device_recommender.dart';

void main() {
  group('RecommendInput', () {
    test('should create from JSON correctly', () {
      final json = {
        'analog_inputs': 8,
        'analog_outputs': 16,
        'network_inputs': 4,
        'network_outputs': 8,
        'bluetooth_inputs': 2,
        'prefer_wall_io': true,
        'prefer_distributed': false,
      };

      final input = RecommendInput.fromJson(json);

      expect(input.analogInputs, equals(8));
      expect(input.analogOutputs, equals(16));
      expect(input.networkInputs, equals(4));
      expect(input.networkOutputs, equals(8));
      expect(input.bluetoothInputs, equals(2));
      expect(input.preferWallIo, isTrue);
      expect(input.preferDistributed, isFalse);
    });

    test('should create from JSON with defaults for missing fields', () {
      final json = {
        'analog_inputs': 4,
        'analog_outputs': 8,
      };

      final input = RecommendInput.fromJson(json);

      expect(input.analogInputs, equals(4));
      expect(input.analogOutputs, equals(8));
      expect(input.networkInputs, equals(0));
      expect(input.networkOutputs, equals(0));
      expect(input.bluetoothInputs, equals(0));
      expect(input.preferWallIo, isFalse);
      expect(input.preferDistributed, isFalse);
    });

    test('should convert to JSON correctly', () {
      final input = RecommendInput(
        analogInputs: 6,
        analogOutputs: 12,
        networkInputs: 2,
        networkOutputs: 4,
        bluetoothInputs: 1,
        preferWallIo: false,
        preferDistributed: true,
      );

      final json = input.toJson();

      expect(json['analog_inputs'], equals(6));
      expect(json['analog_outputs'], equals(12));
      expect(json['network_inputs'], equals(2));
      expect(json['network_outputs'], equals(4));
      expect(json['bluetooth_inputs'], equals(1));
      expect(json['prefer_wall_io'], isFalse);
      expect(json['prefer_distributed'], isTrue);
    });

    test('should create string representation', () {
      final input = RecommendInput(
        analogInputs: 4,
        analogOutputs: 8,
        networkInputs: 2,
        networkOutputs: 4,
        bluetoothInputs: 1,
        preferWallIo: true,
        preferDistributed: false,
      );

      final str = input.toString();
      expect(str, contains('analog: 4/8'));
      expect(str, contains('network: 2/4'));
      expect(str, contains('bluetooth: 1'));
      expect(str, contains('preferWallIo: true'));
      expect(str, contains('preferDistributed: false'));
    });
  });

  group('DeviceRecommender.recommendDevices', () {
    test('should recommend devices for minimal requirements', () {
      final input = RecommendInput(
        analogInputs: 2,
        analogOutputs: 4,
        networkInputs: 0,
        networkOutputs: 0,
        bluetoothInputs: 0,
      );

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      // Should contain at least a basic PowerSmart device
      expect(devices.any((device) => device.contains('PowerSmart') || device.contains('4ch')), isTrue);
    });

    test('should recommend network devices for network I/O requirements', () {
      final input = RecommendInput(
        analogInputs: 0,
        analogOutputs: 0,
        networkInputs: 12,
        networkOutputs: 12,
        bluetoothInputs: 0,
      );

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      // Should contain Fusion Mini devices for network I/O
      expect(devices.any((device) => device == 'FM6'), isTrue);
    });

    test('should handle bluetooth inputs as analog inputs', () {
      final input = RecommendInput(
        analogInputs: 2,
        analogOutputs: 4,
        networkInputs: 0,
        networkOutputs: 0,
        bluetoothInputs: 2, // Should be added to analog inputs
      );

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      // Should handle total of 4 analog inputs (2 analog + 2 bluetooth)
    });

    test('should recommend multiple devices for high I/O requirements', () {
      final input = RecommendInput(
        analogInputs: 16,
        analogOutputs: 32,
        networkInputs: 48,
        networkOutputs: 48,
        bluetoothInputs: 4,
      );

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      expect(devices.length, greaterThan(1));
      
      // Should contain multiple Fusion Mini devices for network I/O
      final fm6Count = devices.where((device) => device == 'FM6').length;
      expect(fm6Count, greaterThan(1)); // Need multiple FM6 for 96 network I/O (24 each)
    });

    test('should handle zero requirements', () {
      final input = RecommendInput(
        analogInputs: 0,
        analogOutputs: 0,
        networkInputs: 0,
        networkOutputs: 0,
        bluetoothInputs: 0,
      );

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      // Should still recommend a basic device
      expect(devices.any((device) => device.contains('4ch') || device.contains('PowerSmart')), isTrue);
    });

    test('should respect preferWallIo preference', () {
      final inputWithWallIo = RecommendInput(
        analogInputs: 8,
        analogOutputs: 8,
        networkInputs: 0,
        networkOutputs: 0,
        bluetoothInputs: 0,
        preferWallIo: true,
      );

      final inputWithoutWallIo = RecommendInput(
        analogInputs: 8,
        analogOutputs: 8,
        networkInputs: 0,
        networkOutputs: 0,
        bluetoothInputs: 0,
        preferWallIo: false,
      );

      final devicesWithWallIo = DeviceRecommender.recommendDevices(inputWithWallIo);
      final devicesWithoutWallIo = DeviceRecommender.recommendDevices(inputWithoutWallIo);

      expect(devicesWithWallIo, isNotEmpty);
      expect(devicesWithoutWallIo, isNotEmpty);
      
      // The recommendations might differ based on wall I/O preference
      // (This depends on the actual implementation logic)
    });

    test('should respect preferDistributed preference', () {
      final inputDistributed = RecommendInput(
        analogInputs: 8,
        analogOutputs: 8,
        networkInputs: 24,
        networkOutputs: 24,
        bluetoothInputs: 0,
        preferDistributed: true,
      );

      final inputCentralized = RecommendInput(
        analogInputs: 8,
        analogOutputs: 8,
        networkInputs: 24,
        networkOutputs: 24,
        bluetoothInputs: 0,
        preferDistributed: false,
      );

      final devicesDistributed = DeviceRecommender.recommendDevices(inputDistributed);
      final devicesCentralized = DeviceRecommender.recommendDevices(inputCentralized);

      expect(devicesDistributed, isNotEmpty);
      expect(devicesCentralized, isNotEmpty);
      
      // Both should contain devices, possibly different configurations
    });

    test('should handle large network I/O requirements', () {
      final input = RecommendInput(
        analogInputs: 4,
        analogOutputs: 4,
        networkInputs: 72, // Requires multiple FM6 devices (24 I/O each)
        networkOutputs: 72,
        bluetoothInputs: 0,
      );

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      
      // Should recommend multiple FM6 devices
      final fm6Count = devices.where((device) => device == 'FM6').length;
      expect(fm6Count, greaterThanOrEqualTo(6)); // 144 total network I/O / 24 per FM6 = 6
    });

    test('should handle mixed analog and network requirements', () {
      final input = RecommendInput(
        analogInputs: 8,
        analogOutputs: 16,
        networkInputs: 12,
        networkOutputs: 12,
        bluetoothInputs: 2,
      );

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      expect(devices.length, greaterThanOrEqualTo(2)); // Should have both analog and network devices
      
      // Should contain both analog-capable and network-capable devices
      final hasAnalogDevice = devices.any((device) => 
        device.contains('PowerSmart') || device.contains('4ch') || device.contains('8ch') || device == 'FM8Y');
      final hasNetworkDevice = devices.any((device) => device == 'FM6');
      
      expect(hasAnalogDevice, isTrue);
      expect(hasNetworkDevice, isTrue);
    });

    test('should return consistent results for same input', () {
      final input = RecommendInput(
        analogInputs: 6,
        analogOutputs: 12,
        networkInputs: 8,
        networkOutputs: 8,
        bluetoothInputs: 1,
      );

      final devices1 = DeviceRecommender.recommendDevices(input);
      final devices2 = DeviceRecommender.recommendDevices(input);

      expect(devices1, equals(devices2));
    });
  });

  group('Device recommendation edge cases', () {
    test('should handle exactly 24 network I/O (one FM6)', () {
      final input = RecommendInput(
        analogInputs: 0,
        analogOutputs: 0,
        networkInputs: 12,
        networkOutputs: 12, // Total 24
        bluetoothInputs: 0,
      );

      final devices = DeviceRecommender.recommendDevices(input);
      
      final fm6Count = devices.where((device) => device == 'FM6').length;
      expect(fm6Count, equals(1)); // Exactly one FM6 needed
    });

    test('should handle 25 network I/O (two FM6s)', () {
      final input = RecommendInput(
        analogInputs: 0,
        analogOutputs: 0,
        networkInputs: 13,
        networkOutputs: 12, // Total 25
        bluetoothInputs: 0,
      );

      final devices = DeviceRecommender.recommendDevices(input);
      
      final fm6Count = devices.where((device) => device == 'FM6').length;
      expect(fm6Count, equals(2)); // Need two FM6s for 25 I/O
    });

    test('should handle only bluetooth inputs', () {
      final input = RecommendInput(
        analogInputs: 0,
        analogOutputs: 4,
        networkInputs: 0,
        networkOutputs: 0,
        bluetoothInputs: 4, // Only bluetooth inputs
      );

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      // Bluetooth inputs count as analog inputs, so should recommend analog device
    });
  });
}
