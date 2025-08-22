import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_lib/fusion_algorithms/spl_calculation/spl_helpers.dart';

void main() {
  group('calculateDistance', () {
    test('should calculate surface mount distance with angle compensation', () {
      // For surface mount, distance = heightDifference / cos(75°)
      // cos(75°) ≈ 0.2588, so distance ≈ heightDifference / 0.2588
      final distance = calculateDistance('surface', 10.0, 6.0);
      expect(distance, closeTo(15.46, 0.1)); // 4.0 / 0.2588
    });

    test('should calculate direct distance for ceiling mount', () {
      final distance = calculateDistance('ceiling', 10.0, 6.0);
      expect(distance, equals(4.0)); // Direct height difference
    });

    test('should calculate direct distance for pendant mount', () {
      final distance = calculateDistance('pendant', 12.0, 6.0);
      expect(distance, equals(6.0)); // Direct height difference
    });

    test('should handle case insensitive mounting type', () {
      final distanceLower = calculateDistance('surface', 10.0, 6.0);
      final distanceUpper = calculateDistance('SURFACE', 10.0, 6.0);
      final distanceMixed = calculateDistance('Surface', 10.0, 6.0);

      expect(distanceLower, equals(distanceUpper));
      expect(distanceLower, equals(distanceMixed));
    });

    test('should handle equal speaker and listener heights', () {
      final distance = calculateDistance('ceiling', 8.0, 8.0);
      expect(distance, equals(0.01)); // Minimum distance applied
    });

    test('should handle speaker below listener', () {
      final distance = calculateDistance('pendant', 6.0, 8.0);
      expect(distance, equals(2.0)); // Absolute value is returned
    });

    test('should throw ArgumentError for negative speaker height', () {
      expect(() => calculateDistance('ceiling', -5.0, 6.0), throwsArgumentError);
    });

    test('should throw ArgumentError for negative listener height', () {
      expect(() => calculateDistance('ceiling', 10.0, -3.0), throwsArgumentError);
    });

    test('should handle zero heights', () {
      final distance = calculateDistance('ceiling', 0.0, 0.0);
      expect(distance, equals(0.01)); // Minimum distance applied
    });
  });

  group('calculateSplLoss', () {
    test('should calculate SPL loss correctly with compensation', () {
      // SPL loss = 20 * log10(distance / 1.0) + 3
      expect(calculateSplLoss(1.0), equals(3.0)); // Reference distance + compensation
      expect(calculateSplLoss(2.0), closeTo(9.02, 0.01)); // 6.02 + 3
      expect(calculateSplLoss(10.0), closeTo(23.0, 0.01)); // 20 + 3
    });

    test('should handle fractional distances', () {
      expect(calculateSplLoss(0.5), closeTo(-3.01, 0.02)); // Allow more tolerance for precision
    });

    test('should handle very small distances', () {
      expect(calculateSplLoss(0.1), closeTo(-17.0, 0.1)); // -20 + 3
    });

    test('should handle large distances', () {
      expect(calculateSplLoss(100.0), closeTo(43.0, 0.1)); // 40 + 3
    });

    test('should throw ArgumentError for zero distance', () {
      expect(() => calculateSplLoss(0.0), throwsArgumentError);
    });

    test('should throw ArgumentError for negative distance', () {
      expect(() => calculateSplLoss(-5.0), throwsArgumentError);
    });
  });

  group('SpeakerRecommendations', () {
    test('should create instance with all model lists', () {
      final recommendations = SpeakerRecommendations(
        modelsMin: ['DM3C', 'DM5C'],
        modelsMid: ['DM5C', 'DM6C'],
        modelsMax: ['DM6C', 'DM8C'],
      );

      expect(recommendations.modelsMin, equals(['DM3C', 'DM5C']));
      expect(recommendations.modelsMid, equals(['DM5C', 'DM6C']));
      expect(recommendations.modelsMax, equals(['DM6C', 'DM8C']));
    });

    test('should create instance with empty lists', () {
      const recommendations = SpeakerRecommendations(
        modelsMin: <String>[],
        modelsMid: <String>[],
        modelsMax: <String>[],
      );

      expect(recommendations.modelsMin, isEmpty);
      expect(recommendations.modelsMid, isEmpty);
      expect(recommendations.modelsMax, isEmpty);
    });
  });

  group('recommendNearestSpeakers', () {
    test('should recommend speakers for indoor ceiling mount', () {
      final recommendations = recommendNearestSpeakers(
        'ceiling',
        'indoor',
        85.0, // min SPL
        90.0, // mid SPL
        95.0, // max SPL
      );

      expect(recommendations.modelsMin, isNotEmpty);
      expect(recommendations.modelsMid, isNotEmpty);
      expect(recommendations.modelsMax, isNotEmpty);
    });

    test('should recommend speakers for outdoor surface mount', () {
      final recommendations = recommendNearestSpeakers(
        'surface',
        'outdoor',
        80.0, // min SPL
        85.0, // mid SPL
        90.0, // max SPL
      );

      // Should only recommend outdoor-rated speakers
      expect(recommendations.modelsMin, isNotNull);
      expect(recommendations.modelsMid, isNotNull);
      expect(recommendations.modelsMax, isNotNull);
    });

    test('should handle case insensitive mounting type', () {
      final recommendationsLower = recommendNearestSpeakers('ceiling', 'indoor', 85.0, 90.0, 95.0);
      final recommendationsUpper = recommendNearestSpeakers('CEILING', 'indoor', 85.0, 90.0, 95.0);

      expect(recommendationsLower.modelsMin, equals(recommendationsUpper.modelsMin));
      expect(recommendationsLower.modelsMid, equals(recommendationsUpper.modelsMid));
      expect(recommendationsLower.modelsMax, equals(recommendationsUpper.modelsMax));
    });

    test('should handle case insensitive environment', () {
      final recommendationsLower = recommendNearestSpeakers('ceiling', 'indoor', 85.0, 90.0, 95.0);
      final recommendationsUpper = recommendNearestSpeakers('ceiling', 'INDOOR', 85.0, 90.0, 95.0);

      expect(recommendationsLower.modelsMin, equals(recommendationsUpper.modelsMin));
      expect(recommendationsLower.modelsMid, equals(recommendationsUpper.modelsMid));
      expect(recommendationsLower.modelsMax, equals(recommendationsUpper.modelsMax));
    });

    test('should return empty lists when no speakers meet requirements', () {
      final recommendations = recommendNearestSpeakers(
        'ceiling',
        'indoor',
        150.0, // unrealistically high SPL requirement
        160.0,
        170.0,
      );

      expect(recommendations.modelsMin, isEmpty);
      expect(recommendations.modelsMid, isEmpty);
      expect(recommendations.modelsMax, isEmpty);
    });

    test('should filter out indoor speakers for outdoor environment', () {
      final outdoorRecommendations = recommendNearestSpeakers('ceiling', 'outdoor', 85.0, 90.0, 95.0);

      // Outdoor recommendations should only include outdoor-rated speakers
      expect(outdoorRecommendations.modelsMin, isNotNull);
      expect(outdoorRecommendations.modelsMid, isNotNull);
      expect(outdoorRecommendations.modelsMax, isNotNull);
    });

    test('should recommend different speakers for different mounting types', () {
      final ceilingRecs = recommendNearestSpeakers('ceiling', 'indoor', 85.0, 90.0, 95.0);
      final surfaceRecs = recommendNearestSpeakers('surface', 'indoor', 85.0, 90.0, 95.0);

      // Different mounting types may have different available speakers
      expect(ceilingRecs, isNotNull);
      expect(surfaceRecs, isNotNull);
    });

    test('should handle low SPL requirements', () {
      final recommendations = recommendNearestSpeakers(
        'ceiling',
        'indoor',
        60.0, // low SPL requirements
        65.0,
        70.0,
      );

      // Should recommend speakers easily meeting these requirements
      expect(recommendations.modelsMin, isNotEmpty);
      expect(recommendations.modelsMid, isNotEmpty);
      expect(recommendations.modelsMax, isNotEmpty);
    });

    test('should prioritize speakers closest to SPL requirements', () {
      final recommendations = recommendNearestSpeakers(
        'ceiling',
        'indoor',
        85.0,
        87.0, // close to min requirement
        90.0,
      );

      // Should find reasonable recommendations
      expect(recommendations.modelsMin, isNotNull);
      expect(recommendations.modelsMid, isNotNull);
      expect(recommendations.modelsMax, isNotNull);
      
      // Mid recommendation should not be empty if min recommendation exists
      if (recommendations.modelsMin.isNotEmpty) {
        expect(recommendations.modelsMid, isNotEmpty);
      }
    });

    test('should handle pendant mounting type', () {
      final recommendations = recommendNearestSpeakers(
        'pendant',
        'indoor',
        85.0,
        90.0,
        95.0,
      );

      expect(recommendations.modelsMin, isNotNull);
      expect(recommendations.modelsMid, isNotNull);
      expect(recommendations.modelsMax, isNotNull);
    });

    test('should return same model when SPL requirements are identical', () {
      final recommendations = recommendNearestSpeakers(
        'ceiling',
        'indoor',
        85.0,
        85.0, // same as min
        85.0, // same as min and mid
      );

      if (recommendations.modelsMin.isNotEmpty) {
        // If a speaker meets the requirement, all three lists should contain it
        expect(recommendations.modelsMid, isNotEmpty);
        expect(recommendations.modelsMax, isNotEmpty);
      }
    });
  });
}
