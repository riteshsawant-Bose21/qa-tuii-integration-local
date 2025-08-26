import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_lib/fusion_algorithms/spl_calculation/spl_calculation.dart';
import 'package:fusion_lib/fusion_algorithms/spl_calculation/spl_types.dart';

void main() {
  group('SplInput', () {
    test('should create from JSON correctly', () {
      final json = {
        'mounting_type': ['surface', 'ceiling'],
        'speaker_height': 10.0,
        'listener_height': 6.0,
        'environment': 'indoor',
        'target_spl_range': [75.0, 85.0],
      };

      final input = SplInput.fromJson(json);

      expect(input.mountingType, equals(['surface', 'ceiling']));
      expect(input.speakerHeight, equals(10.0));
      expect(input.listenerHeight, equals(6.0));
      expect(input.environment, equals('indoor'));
      expect(input.targetSplRange, equals([75.0, 85.0]));
    });

    test('should convert to JSON correctly', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 8.0,
        listenerHeight: 4.0,
        environment: 'outdoor',
        targetSplRange: [70.0, 80.0],
      );

      final json = input.toJson();

      expect(json['mounting_type'], equals(['surface']));
      expect(json['speaker_height'], equals(8.0));
      expect(json['listener_height'], equals(4.0));
      expect(json['environment'], equals('outdoor'));
      expect(json['target_spl_range'], equals([70.0, 80.0]));
    });
  });

  group('validateSplInput', () {
    test('should pass validation for valid input', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      expect(() => validateSplInput(input), returnsNormally);
    });

    test('should throw ArgumentError for empty mounting type', () {
      final input = SplInput(
        mountingType: [],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      expect(() => validateSplInput(input), throwsArgumentError);
    });

    test('should throw ArgumentError for negative speaker height', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: -5.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      expect(() => validateSplInput(input), throwsArgumentError);
    });

    test('should throw ArgumentError for negative listener height', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: -6.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      expect(() => validateSplInput(input), throwsArgumentError);
    });

    test('should throw ArgumentError for invalid target SPL range length', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0], // Only one value
      );

      expect(() => validateSplInput(input), throwsArgumentError);
    });

    test('should throw ArgumentError for invalid target SPL range order', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [85.0, 75.0], // Max before min
      );

      expect(() => validateSplInput(input), throwsArgumentError);
    });

    test('should throw ArgumentError for invalid environment', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'invalid_env',
        targetSplRange: [75.0, 85.0],
      );

      expect(() => validateSplInput(input), throwsArgumentError);
    });

    test('should throw ArgumentError for invalid mounting type', () {
      final input = SplInput(
        mountingType: ['invalid_mount'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      expect(() => validateSplInput(input), throwsArgumentError);
    });

    test('should handle case insensitive environment validation', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'INDOOR', // uppercase
        targetSplRange: [75.0, 85.0],
      );

      expect(() => validateSplInput(input), returnsNormally);
    });

    test('should handle case insensitive mounting type validation', () {
      final input = SplInput(
        mountingType: ['SURFACE', 'Ceiling', 'pendant'], // mixed case
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      expect(() => validateSplInput(input), returnsNormally);
    });
  });

  group('calculateSpl', () {
    test('should calculate SPL for single mounting type', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      final result = calculateSpl(input);

      expect(result.mountingTypes, equals(['surface']));
      expect(result.results, hasLength(1));
      
      final mountResult = result.results.first;
      expect(mountResult.mountingType, equals('surface'));
      expect(mountResult.distance, greaterThan(0));
      expect(mountResult.splLoss, greaterThan(0));
      expect(mountResult.splRequiredMin, greaterThan(0));
      expect(mountResult.splRequiredMid, greaterThan(mountResult.splRequiredMin));
      expect(mountResult.splRequiredMax, greaterThan(mountResult.splRequiredMid));
    });

    test('should calculate SPL for multiple mounting types', () {
      final input = SplInput(
        mountingType: ['surface', 'ceiling', 'pendant'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      final result = calculateSpl(input);

      expect(result.mountingTypes, equals(['surface', 'ceiling', 'pendant']));
      expect(result.results, hasLength(3));
      
      // Verify each mounting type has results
      final mountTypes = result.results.map((r) => r.mountingType).toList();
      expect(mountTypes, containsAll(['surface', 'ceiling', 'pendant']));
    });

    test('should throw ArgumentError for invalid target SPL range', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [75.0], // Only one value
      );

      expect(() => calculateSpl(input), throwsArgumentError);
    });

    test('should handle equal speaker and listener heights', () {
      final input = SplInput(
        mountingType: ['ceiling'],
        speakerHeight: 8.0,
        listenerHeight: 8.0,
        environment: 'indoor',
        targetSplRange: [75.0, 85.0],
      );

      // Equal heights should result in very small distance (minimum distance)
      final result = calculateSpl(input);

      expect(result.results, hasLength(1));
      expect(result.results.first.distance, greaterThan(0));
      // Distance should be the minimum distance when heights are equal
      expect(result.results.first.distance, equals(0.01)); // 1cm minimum
    });

    test('should handle outdoor environment', () {
      final input = SplInput(
        mountingType: ['surface'],
        speakerHeight: 10.0,
        listenerHeight: 6.0,
        environment: 'outdoor',
        targetSplRange: [75.0, 85.0],
      );

      final result = calculateSpl(input);

      expect(result.results, hasLength(1));
      final mountResult = result.results.first;
      expect(mountResult.recommendedModelsMin, isNotEmpty);
    });

    test('should provide speaker recommendations', () {
      final input = SplInput(
        mountingType: ['ceiling'],
        speakerHeight: 12.0,
        listenerHeight: 6.0,
        environment: 'indoor',
        targetSplRange: [80.0, 90.0],
      );

      final result = calculateSpl(input);

      expect(result.results, hasLength(1));
      final mountResult = result.results.first;
      
      // Should have recommendations for min, mid, and max SPL
      expect(mountResult.recommendedModelsMin, isNotNull);
      expect(mountResult.recommendedModelsMid, isNotNull);
      expect(mountResult.recommendedModelsMax, isNotNull);
    });

    test('should round results to appropriate precision', () {
      final input = SplInput(
        mountingType: ['pendant'],
        speakerHeight: 15.7,
        listenerHeight: 6.3,
        environment: 'indoor',
        targetSplRange: [78.5, 88.7],
      );

      final result = calculateSpl(input);

      expect(result.results, hasLength(1));
      final mountResult = result.results.first;
      
      // Check that values are rounded to 2 decimal places
      expect(mountResult.distance.toString().split('.')[1].length, lessThanOrEqualTo(2));
      expect(mountResult.splLoss.toString().split('.')[1].length, lessThanOrEqualTo(2));
    });
  });

  group('calculateSplForApplication', () {
    test('should throw UnimplementedError', () {
      expect(
        () => calculateSplForApplication(
          mountingType: ['surface'],
          speakerHeight: 10.0,
          listenerHeight: 6.0,
          environment: 'indoor',
        ),
        throwsUnimplementedError,
      );
    });
  });

  group('SplPerMountResult', () {
    test('should create instance with all required fields', () {
      final result = SplPerMountResult(
        mountingType: 'surface',
        distance: 5.5,
        splLoss: 14.8,
        splRequiredMin: 89.8,
        splRequiredMid: 94.8,
        splRequiredMax: 99.8,
        recommendedModelsMin: ['DM3C'],
        recommendedModelsMid: ['DM5C'],
        recommendedModelsMax: ['DM6C'],
      );

      expect(result.mountingType, equals('surface'));
      expect(result.distance, equals(5.5));
      expect(result.splLoss, equals(14.8));
      expect(result.splRequiredMin, equals(89.8));
      expect(result.splRequiredMid, equals(94.8));
      expect(result.splRequiredMax, equals(99.8));
      expect(result.recommendedModelsMin, equals(['DM3C']));
      expect(result.recommendedModelsMid, equals(['DM5C']));
      expect(result.recommendedModelsMax, equals(['DM6C']));
    });
  });

  group('SplMultiMountResult', () {
    test('should create instance with multiple results', () {
      final results = [
        SplPerMountResult(
          mountingType: 'surface',
          distance: 5.5,
          splLoss: 14.8,
          splRequiredMin: 89.8,
          splRequiredMid: 94.8,
          splRequiredMax: 99.8,
          recommendedModelsMin: ['DM3C'],
          recommendedModelsMid: ['DM5C'],
          recommendedModelsMax: ['DM6C'],
        ),
        SplPerMountResult(
          mountingType: 'ceiling',
          distance: 4.0,
          splLoss: 12.0,
          splRequiredMin: 87.0,
          splRequiredMid: 92.0,
          splRequiredMax: 97.0,
          recommendedModelsMin: ['DM3C'],
          recommendedModelsMid: ['DM5C'],
          recommendedModelsMax: ['DM5C'],
        ),
      ];

      final multiResult = SplMultiMountResult(
        mountingTypes: ['surface', 'ceiling'],
        results: results,
      );

      expect(multiResult.mountingTypes, equals(['surface', 'ceiling']));
      expect(multiResult.results, hasLength(2));
      expect(multiResult.results[0].mountingType, equals('surface'));
      expect(multiResult.results[1].mountingType, equals('ceiling'));
    });
  });
}
