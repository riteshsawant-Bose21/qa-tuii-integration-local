import 'package:fusion_lib/fusion_algorithms/ceiling_pendant_speakers_autolayout/ceiling_pendant_speakers_autolayout.dart';

void printResult(String title, PlacementResult r) {
  print('\n=== $title ===');
  print('Speakers placed: ${r.speakerPositions.length}');
  print('Grid spacing: ${r.gridSpacing.toStringAsFixed(2)} m');
  print('Centroid: ${r.centroid}');
  print('Distance (vertical): ${r.distance.toStringAsFixed(2)} m');
  print('Positions: ${r.speakerPositions.join(', ')}');
  print('\nCalculation steps:');
  r.calculationSteps.forEach((s) => print('  $s'));
}

void main() {
  // 1) Small living room, ceiling speakers, square layout
  final room1 = Room(width: 5.0, roomLength: 4.0, ceilingHeight: 2.8, listenerHeight: 1.1);
  final spec1 = SpeakerSpec(coverageAngle: 90.0, type: SpeakerType.ceiling);
  final res1 = AutoSpeakerPlacement.calculatePlacement(
    room: room1,
    speakerSpec: spec1,
    coveragePreference: CoveragePreference.minimumOverlap,
    layoutPattern: LayoutPattern.square,
  );
  printResult('Small living room — ceiling, square', res1);

  // 2) Large open hall, pendant speakers, hexagonal layout
  final room2 = Room(width: 20.0, roomLength: 12.0, ceilingHeight: 6.0, listenerHeight: 1.2);
  final spec2 = SpeakerSpec(coverageAngle: 60.0, type: SpeakerType.pendant, pendantHeight: 3.0);
  final res2 = AutoSpeakerPlacement.calculatePlacement(
    room: room2,
    speakerSpec: spec2,
    coveragePreference: CoveragePreference.edgeToEdge,
    layoutPattern: LayoutPattern.hexagonal,
  );
  printResult('Large hall — pendant, hexagonal', res2);

  // 3) Narrow corridor, ceiling speakers, square layout
  final room3 = Room(width: 12.0, roomLength: 2.5, ceilingHeight: 3.0, listenerHeight: 1.2);
  final spec3 = SpeakerSpec(coverageAngle: 110.0, type: SpeakerType.ceiling);
  final res3 = AutoSpeakerPlacement.calculatePlacement(
    room: room3,
    speakerSpec: spec3,
    coveragePreference: CoveragePreference.centerToCenter,
    layoutPattern: LayoutPattern.square,
  );
  printResult('Narrow corridor — ceiling, square', res3);

  // 4) Very small room where grid spacing may exceed room size
  final room4 = Room(width: 2.0, roomLength: 1.5, ceilingHeight: 2.5, listenerHeight: 1.0);
  final spec4 = SpeakerSpec(coverageAngle: 30.0, type: SpeakerType.ceiling);
  final res4 = AutoSpeakerPlacement.calculatePlacement(
    room: room4,
    speakerSpec: spec4,
    coveragePreference: CoveragePreference.minimumOverlap,
    layoutPattern: LayoutPattern.square,
  );
  printResult('Tiny room — spacing > room', res4);

  // 5) Error case: pendant speaker without pendantHeight (should throw)
  try {
    final badSpec = SpeakerSpec(coverageAngle: 60.0, type: SpeakerType.pendant);
    AutoSpeakerPlacement.calculatePlacement(
      room: room1,
      speakerSpec: badSpec,
      coveragePreference: CoveragePreference.minimumOverlap,
    );
  } catch (e) {
    print('\n=== Error case: pendant without height ===');
    print('Caught error as expected: $e');
  }
}
