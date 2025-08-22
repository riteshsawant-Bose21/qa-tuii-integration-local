# Tap Setting Calculation Algorithm - Dart Port

This directory contains the Dart port of the tap setting calculation algorithm from the Go fusion-algo project.

## Overview

The tap setting algorithm calculates optimal power tap settings for Hi-Z (high impedance) speaker installations to achieve balanced sound levels across multiple speaker locations. It uses the farthest speaker as a reference point and attenuates closer speakers to maintain consistent audio levels throughout the coverage area.

## Key Concepts

### Hi-Z Speaker Systems
- **70V and 100V Systems**: Constant voltage audio distribution systems
- **Tap Settings**: Power taps on speaker transformers (e.g., 3W, 6W, 12W, 25W, 50W)
- **Attenuation**: Reduction in power/volume relative to maximum tap setting

### Distance-Based Calculation
- Uses inverse square law for sound propagation
- Calculates SPL (Sound Pressure Level) differences based on speaker-to-listener distances
- Determines required attenuation to balance audio levels

## Features

- **Multi-Speaker Processing**: Handles installations with multiple speakers at different distances
- **Voltage System Support**: Works with both 70V and 100V distributed audio systems  
- **Speaker Database Integration**: Uses comprehensive Bose speaker tap specifications
- **Precision Matching**: Finds closest available tap setting to theoretical requirement
- **Robust Error Handling**: Graceful handling of unknown speakers and invalid parameters
- **JSON Serialization**: Full support for API integration and data persistence

## Usage

### Basic Single Speaker

```dart
import 'package:your_package/fusion_algorithms/fusion_algorithms.dart';

void main() {
  final result = calculateSingleSpeakerTap(
    model: 'DM5C',
    speakerHeight: 12.0,    // feet
    listenerHeight: 6.0,     // feet
    voltage: 70,
    circuitType: 'hi-z',    // Hi-Z circuit (required for tap calculations)
  );

  print('Recommended Tap: ${result.powerWatts}W');
  print('Attenuation: ${result.attenuationDb}dB');
}
```

### Multiple Speaker Installation

```dart
final inputs = [
  SpeakerTapInput(model: 'DM5C', speakerHeight: 14.0, listenerHeight: 6.0, voltage: 70, circuitType: 'hi-z'),
  SpeakerTapInput(model: 'DM5C', speakerHeight: 12.0, listenerHeight: 6.0, voltage: 70, circuitType: 'hi-z'),
  SpeakerTapInput(model: 'DM5C', speakerHeight: 10.0, listenerHeight: 6.0, voltage: 70, circuitType: 'hi-z'),
];

final result = recommendTapsForSpeakers(inputs);

for (int i = 0; i < result.results.length; i++) {
  final tap = result.results[i];
  print('Speaker ${i + 1}: ${tap.powerWatts}W (${tap.attenuationDb}dB attenuation)');
}
```

### Mixed Voltage Systems

```dart
final inputs = [
  // 70V system speakers
  SpeakerTapInput(model: 'DM6C', speakerHeight: 12.0, listenerHeight: 6.0, voltage: 70),
  SpeakerTapInput(model: 'DM3C', speakerHeight: 9.0, listenerHeight: 6.0, voltage: 70),
  
  // 100V system speakers  
  SpeakerTapInput(model: 'DM5SE', speakerHeight: 12.0, listenerHeight: 6.0, voltage: 100),
  SpeakerTapInput(model: 'DM5SE', speakerHeight: 10.0, listenerHeight: 6.0, voltage: 100),
];

final result = recommendTapsForSpeakers(inputs);
// Returns appropriate tap settings for each voltage system
```

## Algorithm Details

### Step-by-Step Process

1. **Distance Calculation**: `distance = speakerHeight - listenerHeight`
2. **Reference Selection**: Find maximum distance among all speakers
3. **SPL Loss Calculation**: `splLoss = 20 * log10(refDistance / currentDistance)`
4. **Required Attenuation**: `requiredAttenuation = -splLoss`
5. **Tap Selection**: Find closest available tap to required attenuation
6. **Result Generation**: Return power setting and actual attenuation

### Mathematical Foundation

The algorithm uses the inverse square law for sound propagation:
```
SPL₂ = SPL₁ + 20 * log₁₀(d₁/d₂)
```

Where:
- `SPL₁`, `SPL₂` = Sound pressure levels at distances d₁ and d₂
- `d₁`, `d₂` = Distances from sound source

### Attenuation Calculation

Tap attenuations are calculated using power ratios:
```
Attenuation(dB) = 10 * log₁₀(TapPower / MaxTapPower)
```

## Data Structures

### SpeakerTapInput
```dart
class SpeakerTapInput {
  final String model;           // Speaker model (e.g., 'DM5C')
  final double speakerHeight;   // Height in feet
  final double listenerHeight;  // Height in feet  
  final int voltage;           // 70 or 100 (volts)
  final String circuitType;    // 'hi-z' or 'lo-z' (only hi-z supported)
}
```

### TapResult
```dart
class TapResult {
  final double distanceMeters;  // Distance from speaker to listener
  final double splLoss;         // SPL difference vs reference speaker
  final double powerWatts;      // Recommended tap power setting
  final double attenuationDb;   // Attenuation vs maximum tap
}
```

### TapCalculationResult
```dart
class TapCalculationResult {
  final List<TapResult> results;     // Per-speaker results
  final double referenceDistance;    // Maximum distance used as reference
  final String calculationMethod;    // Algorithm method used
}
```

## Speaker Database Integration

The algorithm leverages the comprehensive speaker database with detailed tap specifications:

```dart
const Map<String, SpeakerSpec> speakerDatabase = {
  'DM5C': SpeakerSpec(
    model: 'DM5C',
    taps70V: [3, 6, 12, 25, 50],      // Available 70V taps
    taps100V: [6, 12, 25, 50],        // Available 100V taps
    // ... other specifications
  ),
  // ... other speakers
};
```

## Error Handling

### Robust Input Validation
- **Invalid Voltages**: Only 70V and 100V are supported
- **Circuit Type Validation**: Only Hi-Z circuits are supported (Lo-Z circuits don't use tap settings)
- **Negative Heights**: All height values must be non-negative  
- **Empty Models**: Speaker model names cannot be empty
- **Unknown Speakers**: Gracefully handles speakers not in database

### Edge Case Handling
- **Zero/Negative Distances**: Automatically converted to small positive values
- **No Available Taps**: Returns zero power setting with appropriate logging
- **Mathematical Errors**: Proper handling of logarithm edge cases

## Performance Characteristics

- **Time Complexity**: O(n × m) where n = speakers, m = average taps per speaker
- **Memory Efficiency**: Minimal memory footprint with immutable data structures
- **Precision**: Maintains mathematical accuracy equivalent to Go version
- **Scalability**: Efficient for typical installations (1-100 speakers)

## Testing

Comprehensive test suite covers:
- Single and multiple speaker scenarios
- Both 70V and 100V system calculations
- Input validation and error cases
- Mathematical accuracy verification
- JSON serialization round-trips
- Realistic installation examples

Run tests with:
```bash
dart test test/tap_setting_test.dart
```

## Integration Examples

### API Integration
```dart
// REST API endpoint example
Map<String, dynamic> calculateTapsApi(Map<String, dynamic> requestJson) {
  final inputs = List<SpeakerTapInput>.from(
    requestJson['speakers'].map((s) => SpeakerTapInput.fromJson(s))
  );
  
  final result = recommendTapsForSpeakers(inputs);
  return result.toJson();
}
```

### Commercial Installation
```dart
// Large office building example
final conferenceRoomSpeakers = [
  SpeakerTapInput(model: 'DM6C', speakerHeight: 14.0, listenerHeight: 6.0, voltage: 70),
  SpeakerTapInput(model: 'DM6C', speakerHeight: 14.0, listenerHeight: 6.0, voltage: 70),
];

final lobbySpeakers = [
  SpeakerTapInput(model: 'DM5P', speakerHeight: 16.0, listenerHeight: 6.0, voltage: 70),
];

final allSpeakers = [...conferenceRoomSpeakers, ...lobbySpeakers];
final result = recommendTapsForSpeakers(allSpeakers);
```

## Differences from Go Version

The Dart implementation maintains algorithmic compatibility while adding:

1. **Enhanced Type Safety**: Leverages Dart's null safety and strong typing
2. **Immutable Data**: All data structures use immutable patterns
3. **JSON Support**: Built-in serialization for all data types
4. **Functional Style**: More functional programming patterns where appropriate
5. **Better Error Messages**: More descriptive error messages and validation
6. **Documentation**: Comprehensive dartdoc comments throughout

## Dependencies

- **dart:math** - Mathematical operations (logarithms, etc.)
- **dart:developer** - Logging and debugging support

No external package dependencies required.

## Future Enhancements

Potential areas for extension:
- Support for additional voltage systems (25V, etc.)
- Integration with room acoustics calculations
- Support for line array and cluster speaker configurations
- Advanced optimization algorithms for complex installations
- Integration with amplifier load calculations
