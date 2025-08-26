import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_lib/fusion_algorithms/tap_setting/tap_calculation.dart';
import 'package:fusion_lib/fusion_algorithms/tap_setting/tap_types.dart';

void main() {
  group('SpeakerTapInput', () {
    test('should create from JSON correctly', () {
      final json = {
        'model': 'DM6C',
        'speaker_height': 10.0,
        'listener_height': 6.0,
        'voltage': 70,
        'circuit_type': 'hi-z',
      };

      final input = SpeakerTapInput.fromJson(json);

      expect(input.model, equals('DM6C'));
      expect(input.speakerHeight, equals(10.0));
      expect(input.listenerHeight, equals(6.0));
      expect(input.voltage, equals(70));
      expect(input.circuitType, equals('hi-z'));
    });

    test('should convert to JSON correctly', () {
      final input = SpeakerTapInput(
        model: 'DM5C',
        speakerHeight: 8.0,
        listenerHeight: 4.0,
        voltage: 100,
        circuitType: 'lo-z',
      );

      final json = input.toJson();

      expect(json['model'], equals('DM5C'));
      expect(json['speaker_height'], equals(8.0));
      expect(json['listener_height'], equals(4.0));
      expect(json['voltage'], equals(100));
      expect(json['circuit_type'], equals('lo-z'));
    });

    test('should create string representation', () {
      final input = SpeakerTapInput(
        model: 'DM3C',
        speakerHeight: 12.0,
        listenerHeight: 6.0,
        voltage: 70,
        circuitType: 'hi-z',
      );

      final str = input.toString();
      expect(str, contains('DM3C'));
      expect(str, contains('12.0'));
      expect(str, contains('6.0'));
      expect(str, contains('70'));
      expect(str, contains('hi-z'));
    });
  });

  group('TapResult', () {
    test('should create from JSON correctly', () {
      final json = {
        'distance_meters': 5.5,
        'spl_loss': 2.3,
        'power_watts': 25.0,
        'attenuation_db': -6.0,
      };

      final result = TapResult.fromJson(json);

      expect(result.distanceMeters, equals(5.5));
      expect(result.splLoss, equals(2.3));
      expect(result.powerWatts, equals(25.0));
      expect(result.attenuationDb, equals(-6.0));
    });

    test('should convert to JSON correctly', () {
      final result = TapResult(
        distanceMeters: 4.2,
        splLoss: 1.8,
        powerWatts: 50.0,
        attenuationDb: -3.0,
      );

      final json = result.toJson();

      expect(json['distance_meters'], equals(4.2));
      expect(json['spl_loss'], equals(1.8));
      expect(json['power_watts'], equals(50.0));
      expect(json['attenuation_db'], equals(-3.0));
    });

    test('should create string representation', () {
      final result = TapResult(
        distanceMeters: 4.25,
        splLoss: 1.85,
        powerWatts: 25.5,
        attenuationDb: -6.25,
      );

      final str = result.toString();
      expect(str, contains('4.25m'));
      expect(str, contains('1.85dB'));
      expect(str, contains('25.5W'));
      expect(str, contains('-6.25dB'));
    });
  });

  group('TapCalculationResult', () {
    test('should create empty result', () {
      const result = TapCalculationResult(results: [], referenceDistance: 0);

      expect(result.results, isEmpty);
      expect(result.referenceDistance, equals(0));
    });

    test('should create result with multiple tap results', () {
      final results = [
        TapResult(
          distanceMeters: 5.0,
          splLoss: 2.0,
          powerWatts: 25.0,
          attenuationDb: -6.0,
        ),
        TapResult(
          distanceMeters: 3.0,
          splLoss: 4.4,
          powerWatts: 12.5,
          attenuationDb: -9.0,
        ),
      ];

      final result = TapCalculationResult(
        results: results,
        referenceDistance: 5.0,
      );

      expect(result.results, hasLength(2));
      expect(result.referenceDistance, equals(5.0));
    });
  });

  group('recommendTapsForSpeakers', () {
    test('should throw error for empty input', () {
      expect(() => recommendTapsForSpeakers([]), throwsArgumentError);
    });

    test('should calculate tap for single speaker', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(1));
      expect(result.referenceDistance, greaterThan(0));
      
      final tapResult = result.results.first;
      expect(tapResult.distanceMeters, greaterThan(0));
      expect(tapResult.powerWatts, greaterThanOrEqualTo(0));
    });

    test('should calculate taps for multiple speakers', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 12.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
        SpeakerTapInput(
          model: 'DM5C',
          speakerHeight: 8.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
        SpeakerTapInput(
          model: 'DM3C',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(3));
      expect(result.referenceDistance, greaterThan(0));
      
      // All results should have valid values
      for (final tapResult in result.results) {
        expect(tapResult.distanceMeters, greaterThan(0));
        expect(tapResult.powerWatts, greaterThanOrEqualTo(0));
      }
    });

    test('should use farthest speaker as reference', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 15.0, // Farthest from listener
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
        SpeakerTapInput(
          model: 'DM5C',
          speakerHeight: 8.0, // Closer to listener
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(2));
      // Reference distance should be the largest height difference
      expect(result.referenceDistance, equals(9.0)); // 15.0 - 6.0
      
      // First speaker (farthest) should have higher power than second
      expect(result.results[0].powerWatts, greaterThanOrEqualTo(result.results[1].powerWatts));
    });

    test('should handle equal speaker heights', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 8.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
        SpeakerTapInput(
          model: 'DM5C',
          speakerHeight: 8.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(2));
      expect(result.referenceDistance, equals(2.0)); // 8.0 - 6.0
      
      // Both speakers should have same distance, but may have different tap values
      // based on their individual speaker specifications
      expect(result.results[0].distanceMeters, equals(result.results[1].distanceMeters));
    });

    test('should handle 100V circuit type', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 100,
          circuitType: 'hi-z',
        ),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(1));
      expect(result.results.first.powerWatts, greaterThanOrEqualTo(0));
    });

    test('should handle speaker at listener height', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 6.0,
          listenerHeight: 6.0, // Same height
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(1));
      // Distance should be set to minimum safe value
      expect(result.results.first.distanceMeters, greaterThan(0));
    });

    test('should handle speaker below listener height', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM3C',
          speakerHeight: 4.0,
          listenerHeight: 6.0, // Listener higher than speaker
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(1));
      // Should handle negative height difference
      expect(result.results.first.distanceMeters, greaterThan(0));
    });

    test('should handle mixed speaker models', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 12.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
        SpeakerTapInput(
          model: 'DM3C',
          speakerHeight: 8.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
        SpeakerTapInput(
          model: 'DM5C',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      final result = recommendTapsForSpeakers(inputs);

      expect(result.results, hasLength(3));
      expect(result.referenceDistance, equals(6.0)); // 12.0 - 6.0
      
      // All results should be valid
      for (final tapResult in result.results) {
        expect(tapResult.distanceMeters, greaterThan(0));
        expect(tapResult.powerWatts, greaterThanOrEqualTo(0));
        expect(tapResult.attenuationDb, lessThanOrEqualTo(0)); // Attenuation should be negative or zero
      }
    });

    test('should handle invalid speaker models gracefully', () {
      final invalidInputs = [
        SpeakerTapInput(
          model: 'INVALID_MODEL',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      // Should not crash, but may return zero power
      final result = recommendTapsForSpeakers(invalidInputs);
      expect(result.results, hasLength(1));
    });
  });

  group('calculateTapsWithValidation', () {
    test('should pass validation for valid inputs', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      final result = calculateTapsWithValidation(inputs: inputs);
      expect(result.results, hasLength(1));
    });

    test('should throw ArgumentError for invalid voltage when enabled', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 50, // Invalid voltage
          circuitType: 'hi-z',
        ),
      ];

      expect(() => calculateTapsWithValidation(
        inputs: inputs, 
        throwOnInvalidVoltage: true
      ), throwsArgumentError);
    });

    test('should validate voltage even when not strict', () {
      final inputs = [
        SpeakerTapInput(
          model: 'DM6C',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 50, // Invalid voltage
          circuitType: 'hi-z',
        ),
      ];

      // Invalid voltage should still throw error 
      expect(() => calculateTapsWithValidation(
        inputs: inputs, 
        throwOnInvalidVoltage: false
      ), throwsArgumentError);
    });

    test('should throw ArgumentError for unknown speaker when enabled', () {
      final inputs = [
        SpeakerTapInput(
          model: 'UNKNOWN_SPEAKER',
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          voltage: 70,
          circuitType: 'hi-z',
        ),
      ];

      expect(() => calculateTapsWithValidation(
        inputs: inputs, 
        throwOnSpeakerNotFound: true
      ), throwsArgumentError);
    });
  });
}
