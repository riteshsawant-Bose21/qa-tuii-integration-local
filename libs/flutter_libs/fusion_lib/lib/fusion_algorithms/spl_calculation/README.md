# SPL Calculation Algorithm - Dart Port

This directory contains the Dart port of the Sound Pressure Level (SPL) calculation algorithm from the Go fusion-algo project.

## Overview

The SPL calculation algorithm helps determine the appropriate speaker placement and selection based on:

- Speaker and listener heights
- Mounting type (ceiling, surface, pendant)
- Environmental conditions (indoor/outdoor)
- Target SPL requirements

## Features

- **Distance Calculation**: Computes the effective distance between speaker and listener based on mounting type
- **SPL Loss Calculation**: Applies inverse square law for sound pressure level loss over distance
- **Speaker Recommendations**: Suggests appropriate speaker models based on SPL requirements
- **Multi-Mount Support**: Handles multiple mounting types in a single calculation
- **Environment Filtering**: Considers outdoor rating for outdoor installations
- **Input Validation**: Comprehensive validation of input parameters

## Usage

### Basic Example

```dart
import 'package:your_package/fusion_algorithms/fusion_algorithms.dart';

void main() {
  final input = SplInput(
    mountingType: ['ceiling'],
    speakerHeight: 10.0,    // feet
    listenerHeight: 6.0,     // feet
    environment: 'indoor',
    targetSplRange: [65.0, 75.0], // [min, max] SPL in dB
  );

  try {
    final result = calculateSpl(input);
    
    for (final res in result.results) {
      print('Mounting Type: ${res.mountingType}');
      print('Distance: ${res.distance} feet');
      print('SPL Loss: ${res.splLoss} dB');
      print('Recommended Models: ${res.recommendedModelsMid}');
    }
  } catch (e) {
    print('Calculation error: $e');
  }
}
```

### Multiple Mounting Types

```dart
final input = SplInput(
  mountingType: ['ceiling', 'surface', 'pendant'],
  speakerHeight: 12.0,
  listenerHeight: 6.0,
  application: 'Paging',
  environment: 'indoor',
  targetSplRange: [70.0, 80.0],
);

final result = calculateSpl(input);
// Returns calculations for all three mounting types
```

### Outdoor Environment

```dart
final input = SplInput(
  mountingType: ['surface'],
  speakerHeight: 15.0,
  listenerHeight: 6.0,
  application: 'Foreground music',
  environment: 'outdoor',
  targetSplRange: [75.0, 90.0],
);

final result = calculateSpl(input);
// Only recommends outdoor-rated speakers
```

## Algorithm Details

### Distance Calculation

- **Surface Mount**: Uses cosine calculation with 75° angle: `distance = (speakerHeight - listenerHeight) / cos(75°)`
- **Ceiling/Pendant Mount**: Direct height difference: `distance = speakerHeight - listenerHeight`

### SPL Loss Calculation

Uses inverse square law with 1-meter reference distance:
```
splLoss = 20 * log10(distance / 1.0) + 3
```

### Speaker Selection

The algorithm finds the speaker with the smallest SPL margin above the requirement:
1. Filters speakers by mounting type compatibility
2. For outdoor environments, only considers outdoor-rated speakers
3. Selects speakers with `maxSPL >= splRequired`
4. Chooses the one with the smallest difference to avoid over-specification

## Data Structures

### SplInput
```dart
class SplInput {
  final List<String> mountingType;      // ['ceiling', 'surface', 'pendant']
  final double speakerHeight;           // Height in feet
  final double listenerHeight;          // Height in feet
  final String application;             // Application name
  final String environment;             // 'indoor' or 'outdoor'
  final List<double> targetSplRange;    // [min, max] SPL in dB
}
```

### SplMultiMountResult
```dart
class SplMultiMountResult {
  final List<String> mountingTypes;
  final List<SplPerMountResult> results;
}
```

### SplPerMountResult
```dart
class SplPerMountResult {
  final String mountingType;
  final double distance;
  final double splLoss;
  final double splRequiredMin;
  final double splRequiredMid;
  final double splRequiredMax;
  final List<String> recommendedModelsMin;
  final List<String> recommendedModelsMid;
  final List<String> recommendedModelsMax;
}
```

## Speaker Database

The algorithm includes a comprehensive database of speakers with:
- Model names (DM2C-LP, DM3C, DM5SE, etc.)
- Maximum SPL ratings
- Mounting type compatibility
- Outdoor ratings
- Subwoofer classifications

## Error Handling

The algorithm provides comprehensive error handling for:
- Invalid input parameters (negative heights, invalid ranges)
- Unsupported mounting types
- Invalid environment specifications
- Mathematical errors (division by zero, invalid logarithms)

## Testing

Run the test file to see examples and verify functionality:

```dart
dart test/spl_calculation_test.dart
```

The test includes:
- Basic SPL calculations
- Multiple mounting type scenarios
- Outdoor environment testing
- Input validation testing

## Differences from Go Version

While maintaining the same core algorithm and results, the Dart version includes:

1. **Immutable Data Structures**: Uses immutable classes with const constructors
2. **JSON Serialization**: Built-in `toJson()` and `fromJson()` methods
3. **Dart Conventions**: Follows Dart naming conventions (camelCase)
4. **Type Safety**: Leverages Dart's null safety and strong typing
5. **Error Handling**: Uses Dart's exception system with `ArgumentError` and `StateError`
6. **Logging**: Uses Dart's `developer.log()` for debugging output

## Dependencies

- `dart:math` - Mathematical operations
- `dart:developer` - Logging functionality

No external package dependencies required.
