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




## Testing

Comprehensive test suite covers:
- Single and multiple speaker scenarios
- Both 70V and 100V system calculations
- Input validation and error cases
- Mathematical accuracy verification


Run tests with:
```bash
dart test test/tap_setting_test.dart
```
