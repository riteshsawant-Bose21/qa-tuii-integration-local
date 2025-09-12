import 'package:flutter_test/flutter_test.dart';
import 'package:fusion_lib/fusion_algorithms/circuiting/circuiting_calculation.dart';
import 'package:fusion_lib/fusion_algorithms/circuiting/circuiting_types.dart';

void main() {
  group('InputSpeaker', () {
    test('should create from JSON correctly', () {
      final json = {
        'Model': 'DM6C',
        'Quantity': 4,
        'TapSetting': 'lo-z',
        'Area': 'Main Dining',
      };

      final speaker = InputSpeaker.fromJson(json);

      expect(speaker.model, equals('DM6C'));
      expect(speaker.quantity, equals(4));
      expect(speaker.tapSetting, equals('lo-z'));
      expect(speaker.area, equals('Main Dining'));
    });

    test('should convert to JSON correctly', () {
      final speaker = InputSpeaker(
        model: 'DM5C',
        quantity: 6,
        tapSetting: 'hi-z',
        area: 'Conference Room',
      );

      final json = speaker.toJson();

      expect(json['Model'], equals('DM5C'));
      expect(json['Quantity'], equals(6));
      expect(json['TapSetting'], equals('hi-z'));
      expect(json['Area'], equals('Conference Room'));
    });
  });

  group('CircuitAssignment', () {
    test('should create instance with all fields', () {
      final assignment = CircuitAssignment(
        area: 'Lobby',
        circuitId: 1,
        model: 'DM6C',
        mode: 'lo-z',
        tapWatts: 25.0,
        totalPower: 100.0,
        impedance: 8.0,
      );

      expect(assignment.area, equals('Lobby'));
      expect(assignment.circuitId, equals(1));
      expect(assignment.model, equals('DM6C'));
      expect(assignment.mode, equals('lo-z'));
      expect(assignment.tapWatts, equals(25.0));
      expect(assignment.totalPower, equals(100.0));
      expect(assignment.impedance, equals(8.0));
    });

    test('should create instance with optional fields as null', () {
      final assignment = CircuitAssignment(
        area: 'Kitchen',
        circuitId: 2,
        model: 'DM3C',
        mode: 'hi-z',
      );

      expect(assignment.area, equals('Kitchen'));
      expect(assignment.circuitId, equals(2));
      expect(assignment.model, equals('DM3C'));
      expect(assignment.mode, equals('hi-z'));
      expect(assignment.tapWatts, isNull);
      expect(assignment.totalPower, isNull);
      expect(assignment.impedance, isNull);
    });
  });

  group('automaticCircuiting', () {
    test('should assign lo-z circuit for impedance >= 4Ω', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 2, // Two 8Ω speakers = 4Ω parallel
          tapSetting: 'lo-z',
          area: 'Main Room',
        ),
      ];

      final assignments = automaticCircuiting(speakers);

      expect(assignments, hasLength(1));
      final assignment = assignments.first;
      expect(assignment.mode, equals('lo-z'));
      expect(assignment.impedance, equals(4.0));
      expect(assignment.area, equals('Main Room'));
      expect(assignment.model, equals('DM6C'));
    });

    test('should assign hi-z circuit for impedance < 4Ω', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 4, // Four 8Ω speakers = 2Ω parallel
          tapSetting: 'hi-z',
          area: 'Conference Room',
        ),
      ];

      final assignments = automaticCircuiting(speakers);

      expect(assignments, hasLength(1));
      final assignment = assignments.first;
      expect(assignment.mode, equals('hi-z'));
      expect(assignment.impedance, lessThan(4.0));
      expect(assignment.area, equals('Conference Room'));
      expect(assignment.model, equals('DM6C'));
    });

    test('should handle multiple areas', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 2,
          tapSetting: 'lo-z',
          area: 'Lobby',
        ),
        InputSpeaker(
          model: 'DM5C',
          quantity: 3,
          tapSetting: 'lo-z',
          area: 'Conference Room',
        ),
        InputSpeaker(
          model: 'DM3C',
          quantity: 1,
          tapSetting: 'lo-z',
          area: 'Office',
        ),
      ];

      final assignments = automaticCircuiting(speakers);

      expect(assignments, hasLength(3));

      final areas = assignments.map((a) => a.area).toSet();
      expect(areas, containsAll(['Lobby', 'Conference Room', 'Office']));

      // Each circuit should have a unique ID
      final circuitIds = assignments.map((a) => a.circuitId).toList();
      expect(circuitIds, hasLength(3));
      expect(circuitIds.toSet(), hasLength(3)); // All unique
    });

    test('should group by area and model', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 2,
          tapSetting: 'lo-z',
          area: 'Main Room',
        ),
        InputSpeaker(
          model: 'DM6C',
          quantity: 1,
          tapSetting: 'lo-z',
          area: 'Main Room', // Same area and model, should be grouped
        ),
        InputSpeaker(
          model: 'DM5C',
          quantity: 2,
          tapSetting: 'lo-z',
          area: 'Main Room', // Same area, different model
        ),
      ];

      final assignments = automaticCircuiting(speakers);

      expect(assignments, hasLength(2)); // Two unique area-model combinations

      final dm6cAssignment = assignments.firstWhere((a) => a.model == 'DM6C');
      final dm5cAssignment = assignments.firstWhere((a) => a.model == 'DM5C');

      // DM6C should reflect combined quantity (2 + 1 = 3 speakers)
      // Three 8Ω speakers in parallel = 8/3 = 2.67Ω
      expect(dm6cAssignment.impedance, closeTo(2.67, 0.1));

      // DM5C should have 2 speakers
      // Two 8Ω speakers in parallel = 4Ω
      expect(dm5cAssignment.impedance, equals(4.0));
    });

    test('should throw ArgumentError for unknown speaker model', () {
      final speakers = [
        InputSpeaker(
          model: 'UNKNOWN_MODEL',
          quantity: 2,
          tapSetting: 'lo-z',
          area: 'Test Area',
        ),
      ];

      expect(() => automaticCircuiting(speakers), throwsArgumentError);
    });

    test('should handle empty speaker list', () {
      final assignments = automaticCircuiting([]);
      expect(assignments, isEmpty);
    });

    test('should check power limits for hi-z circuits', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 20, // Many speakers requiring high power
          tapSetting: 'hi-z',
          area: 'Large Hall',
        ),
      ];

      // Test with low max power - should fail if power exceeds limit
      expect(() => automaticCircuiting(speakers), throwsA(isA<ArgumentError>()));
    });

    test('should create valid circuit assignments for mixed scenarios', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 2, // 4Ω parallel - should be lo-z
          tapSetting: 'lo-z',
          area: 'Reception',
        ),
        InputSpeaker(
          model: 'DM3C',
          quantity: 6, // Low impedance - should be hi-z
          tapSetting: 'hi-z',
          area: 'Ballroom',
        ),
        InputSpeaker(
          model: 'DM5C',
          quantity: 1, // Single speaker - should be lo-z
          tapSetting: 'lo-z',
          area: 'VIP Room',
        ),
      ];

      final assignments = automaticCircuiting(speakers);

      expect(assignments, hasLength(3));

      for (final assignment in assignments) {
        expect(assignment.circuitId, greaterThan(0));
        expect(assignment.impedance, greaterThan(0));
        expect(['lo-z', 'hi-z'], contains(assignment.mode));
      }
    });

    test('should maintain correct circuit ID sequence', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 2,
          tapSetting: 'lo-z',
          area: 'Area 1',
        ),
        InputSpeaker(
          model: 'DM5C',
          quantity: 2,
          tapSetting: 'lo-z',
          area: 'Area 2',
        ),
        InputSpeaker(
          model: 'DM3C',
          quantity: 2,
          tapSetting: 'lo-z',
          area: 'Area 3',
        ),
      ];

      final assignments = automaticCircuiting(speakers);

      expect(assignments, hasLength(3));

      final circuitIds = assignments.map((a) => a.circuitId).toList();
      circuitIds.sort();
      expect(circuitIds, equals([1, 2, 3]));
    });

    test('should handle zero quantity speakers', () {
      final speakers = [
        InputSpeaker(
          model: 'DM6C',
          quantity: 0, // Zero quantity
          tapSetting: 'lo-z',
          area: 'Empty Area',
        ),
        InputSpeaker(
          model: 'DM5C',
          quantity: 2,
          tapSetting: 'lo-z',
          area: 'Normal Area',
        ),
      ];

      final assignments = automaticCircuiting(speakers);

      // Should still process the zero quantity speaker
      expect(assignments, hasLength(2));

      final emptyAssignment = assignments.firstWhere((a) => a.area == 'Empty Area');
      // This might cause division issues or special handling
      expect(emptyAssignment.circuitId, greaterThan(0));
    });
  });
}
