import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_lib/api_data/amplifiers/amplifier_catalog.dart';
import 'package:fusion_lib/api_data/devices/devices.dart';
import 'package:fusion_lib/fusion_algorithms/fusion_algorithms.dart';

void main() {
  group('Fusion Algorithms Integration Tests', () {
    test('Math utilities should work correctly', () {
      // Test basic math functions
      expect(roundToPrecision(3.14159, 2), equals(3.14));
      expect(round2(3.14159), equals(3.14));
      expect(round1(3.14159), equals(3.1));

      // Test distance calculations
      expect(ensurePositiveDistance(5.0), equals(5.0));
      expect(ensurePositiveDistance(-1.0), equals(FusionMathConstants.minimumDistanceMeters));

      // Test angle conversions
      expect(degreesToRadians(90), closeTo(1.5708, 0.001));
      expect(radiansToDegrees(1.5708), closeTo(90.0, 0.1));
    });

    test('SPL calculations should handle valid inputs', () {
      final input = SplInput(mountingType: ['ceiling'], speakerHeight: 10.0, listenerHeight: 6.0, environment: 'indoor', targetSplRange: [75.0, 85.0]);

      final result = calculateSpl(input);

      expect(result.mountingTypes, equals(['ceiling']));
      expect(result.results, hasLength(1));
      expect(result.results.first.distance, greaterThan(0));
    });

    test('Tap settings should calculate for multiple speakers', () {
      final inputs = [
        SpeakerTapInput(model: 'DM6C', speakerHeight: 10.0, listenerHeight: 6.0, voltage: 70, circuitType: 'hi-z'),
        SpeakerTapInput(model: 'DM5C', speakerHeight: 8.0, listenerHeight: 6.0, voltage: 70, circuitType: 'hi-z'),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(2));
      expect(result.referenceDistance, greaterThan(0));

      for (final tapResult in result.results) {
        expect(tapResult.distanceMeters, greaterThan(0));
        expect(tapResult.powerWatts, greaterThanOrEqualTo(0));
      }
    });

    test('Circuiting should assign proper circuit types', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 2, // Two 8Ω speakers = 4Ω parallel (should be lo-z)
          tapSetting: 'lo-z',
          area: 'Test Room',
        ),
      ];

      final assignments = automaticCircuiting(speakers, 300.0);

      expect(assignments, hasLength(1));
      final assignment = assignments.first;
      expect(assignment.mode, equals('lo-z'));
      expect(assignment.impedance, equals(4.0));
      expect(assignment.area, equals('Test Room'));
    });

    test('Device recommender should suggest appropriate devices', () {
      final input = RecommendInput(analogInputs: 4, analogOutputs: 8, networkInputs: 12, networkOutputs: 12, bluetoothInputs: 0);

      final devices = DeviceRecommender.recommendDevices(input);

      expect(devices, isNotEmpty);
      // Should contain devices for both analog and network I/O
      expect(devices.any((device) => device.contains('PowerSmart') || device.contains('4ch')), isTrue);
      expect(devices.any((device) => device == 'FM6'), isTrue);
    });

    test('API data structures should be accessible', () {
      // Test that speaker data is available
      expect(SpeakerCatalog.getAllSpeakers(), isNotEmpty);

      // Test that amplifier data is available
      expect(AmpCatalog.models, isNotEmpty);

      // Test that device data is available
      expect(DeviceCatalog.getAllDevices(), isNotEmpty);
    });

    test('Input validation should catch common errors', () {
      // SPL input validation
      expect(
        () => validateSplInput(SplInput(mountingType: [], speakerHeight: 10.0, listenerHeight: 6.0, environment: 'indoor', targetSplRange: [75.0, 85.0])),
        throwsArgumentError,
      );

      // Negative height validation
      expect(
        () => validateSplInput(
          SplInput(mountingType: ['ceiling'], speakerHeight: -5.0, listenerHeight: 6.0, environment: 'indoor', targetSplRange: [75.0, 85.0]),
        ),
        throwsArgumentError,
      );
    });

    test('JSON serialization should work correctly', () {
      // Test SPL input serialization
      final splInput = SplInput(mountingType: ['surface'], speakerHeight: 10.0, listenerHeight: 6.0, environment: 'outdoor', targetSplRange: [70.0, 80.0]);

      final json = splInput.toJson();
      final restored = SplInput.fromJson(json);

      expect(restored.mountingType, equals(splInput.mountingType));
      expect(restored.speakerHeight, equals(splInput.speakerHeight));
      expect(restored.environment, equals(splInput.environment));

      // Test tap input serialization
      final tapInput = SpeakerTapInput(model: 'DM5C', speakerHeight: 8.0, listenerHeight: 4.0, voltage: 100, circuitType: 'lo-z');

      final tapJson = tapInput.toJson();
      final restoredTap = SpeakerTapInput.fromJson(tapJson);

      expect(restoredTap.model, equals(tapInput.model));
      expect(restoredTap.voltage, equals(tapInput.voltage));
      expect(restoredTap.circuitType, equals(tapInput.circuitType));
    });

    test('Algorithm edge cases should be handled gracefully', () {
      // Test very small distances
      expect(ensurePositiveDistance(0.0), equals(FusionMathConstants.minimumDistanceMeters));

      // Test power attenuation edge cases
      expect(calculatePowerAttenuationDb(0.0, 100.0), equals(double.negativeInfinity));

      // Test empty lists
      expect(() => findMaximum([]), throwsArgumentError);
      expect(() => findClosestIndex(5.0, []), throwsArgumentError);
    });
  });
}
