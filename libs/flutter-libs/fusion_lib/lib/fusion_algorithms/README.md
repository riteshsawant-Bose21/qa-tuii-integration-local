# Fusion Algorithms Library

A comprehensive collection of professional audio algorithms for speaker system design, amplifier matching, SPL calculations, and device recommendations.

## 📚 Library Overview

This library provides essential algorithms for designing and configuring professional audio systems, specifically tailored for Bose professional speakers and amplifiers.

### 🎯 Core Modules

- **[SPL Calculation](#spl-calculation)** - Sound Pressure Level calculations and coverage analysis
- **[Tap Setting](#tap-setting)** - Hi-Z distributed speaker tap optimization
- **[Amplifier Matching](#amplifier-matching)** - Amplifier selection and compatibility analysis
- **[Device Recommender](#device-recommender)** - DSP device selection based on system requirements
- **[Circuiting](#circuiting)** - Speaker circuit configuration and impedance calculations
- **[Shared Utilities](#shared-utilities)** - Common mathematical and validation functions

---

## 🔊 SPL Calculation

**Module**: `spl_calculation/`  
**Purpose**: Calculate sound pressure levels, coverage patterns, and acoustic performance

### Features
- Maximum SPL calculations for speaker models
- Distance-based SPL attenuation
- Coverage pattern analysis
- Multi-speaker system SPL summation

### Usage Example
```dart
import 'package:fusion_lib/fusion_algorithms/spl_calculation/spl_calculation.dart';

// Calculate SPL at distance
final spl = calculateSPLAtDistance(
  speakerModel: 'DM6C',
  distance: 10.0, // meters
  power: 100.0,   // watts
);

// Calculate coverage area
final coverage = calculateCoverageArea(
  speakers: [
    SpeakerPosition(model: 'DM6C', x: 0, y: 0, height: 3.0),
    SpeakerPosition(model: 'DM5C', x: 10, y: 0, height: 3.0),
  ],
  targetSPL: 85.0,
);
```

### Key Functions
- `calculateSPLAtDistance()` - SPL calculation for single speaker
- `calculateCoverageArea()` - Multi-speaker coverage analysis
- `calculateRequiredPower()` - Power requirements for target SPL

---

## 🎛️ Tap Setting

**Module**: `tap_setting/`  
**Purpose**: Optimize Hi-Z transformer tap settings for distributed speaker systems

### Features
- Automatic tap selection for uniform SPL
- Distance-based power optimization
- Multiple speaker system balancing
- 70V and 100V circuit support

### Usage Example
```dart
import 'package:fusion_lib/fusion_algorithms/tap_setting/tap_calculation.dart';

final inputs = [
  SpeakerTapInput(
    model: 'DM3C',
    speakerHeight: 3.0,
    listenerHeight: 1.8,
    voltage: 70,
    circuitType: 'hi-z',
  ),
  SpeakerTapInput(
    model: 'DM5C', 
    speakerHeight: 4.0,
    listenerHeight: 1.8,
    voltage: 70,
    circuitType: 'hi-z',
  ),
];

final result = recommendTapsForSpeakers(inputs);

// Access recommendations
for (final tapResult in result.results) {
  print('Power: ${tapResult.powerWatts}W, Distance: ${tapResult.distanceMeters}m');
}
```

### Key Functions
- `recommendTapsForSpeakers()` - Multi-speaker tap optimization
- `recommendTapForSpeaker()` - Single speaker tap calculation
- `calculateDistance()` - Listener-to-speaker distance calculation

---

## 🔌 Amplifier Matching

**Module**: `amplifier_matching/`  
**Purpose**: Select compatible amplifiers for speaker loads and system requirements

### Features
- Automatic amplifier selection based on power requirements
- Channel configuration optimization
- Impedance matching verification
- Multiple circuit type support (Hi-Z, Lo-Z)

### Usage Example
```dart
import 'package:fusion_lib/fusion_algorithms/amplifier_matching/amplifier_matching.dart';

final request = AmpMatchingRequest(
  speakers: [
    SpeakerLoad(model: 'DM6C', quantity: 4, tapWatts: 50),
    SpeakerLoad(model: 'DM3C', quantity: 8, tapWatts: 25),
  ],
  circuitType: 'hi-z',
  voltage: 70,
  redundancy: false,
);

final result = findBestAmplifierMatch(request);

print('Recommended: ${result.recommendedAmplifier.model}');
print('Channels needed: ${result.channelsNeeded}');
print('Total power: ${result.totalPowerRequired}W');
```

### Key Functions
- `findBestAmplifierMatch()` - Complete amplifier selection
- `calculatePowerRequirements()` - Power and channel calculations
- `validateAmplifierMatch()` - Compatibility verification

---

## 📱 Device Recommender

**Module**: `device_recommender/`  
**Purpose**: Recommend DSP devices based on system I/O requirements

### Features
- Automatic device selection based on input/output requirements
- Analog and network I/O counting
- Multiple device type support (Fusion Mini, PowerSmart)
- Scalability analysis

### Usage Example
```dart
import 'package:fusion_lib/fusion_algorithms/device_recommender/device_recommender.dart';

final requirements = SystemRequirements(
  analogInputs: 8,
  analogOutputs: 16,
  networkInputs: 4,
  networkOutputs: 8,
  zones: 12,
);

final recommendation = recommendDevice(requirements);

print('Recommended: ${recommendation.deviceModel}');
print('Meets requirements: ${recommendation.meetsRequirements}');
print('Capacity utilization: ${recommendation.utilizationPercentage}%');
```

### Key Functions
- `recommendDevice()` - Primary device selection
- `calculateIORequirements()` - I/O requirement analysis
- `compareDeviceCapabilities()` - Device comparison

---

## ⚡ Circuiting

**Module**: `circuiting/`  
**Purpose**: Calculate speaker circuit configurations and impedance based on impedance rules

### Features
- Automatic grouping by area and speaker model
- Parallel impedance calculations
- Smart lo-z/hi-z assignment based on impedance
- Circuit optimization without power constraints

### Usage Example
```dart
import 'package:fusion_lib/fusion_algorithms/circuiting/circuiting_calculation.dart';

final speakers = [
  InputSpeaker(
    model: 'DM6C',
    quantity: 2,
    area: 'Main Hall',
    tapSetting: 'lo-z',
  ),
  InputSpeaker(
    model: 'DM3C',
    quantity: 4,
    area: 'Conference Room',
    tapSetting: 'hi-z',
  ),
];

final assignments = automaticCircuiting(speakers);

for (final assignment in assignments) {
  print('Circuit ${assignment.circuitId}: ${assignment.area}');
  print('Mode: ${assignment.mode}, Impedance: ${assignment.impedance}Ω');
  if (assignment.mode == 'hi-z') {
    print('Tap: ${assignment.tapWatts}W, Total: ${assignment.totalPower}W');
  }
}
```

### Key Functions
- `automaticCircuiting()` - Primary circuiting algorithm
- `calculateParallelImpedance()` - Parallel impedance calculations
- `groupSpeakersByAreaModel()` - Speaker grouping logic

---

## 🛠️ Shared Utilities

**Module**: `shared/`  
**Purpose**: Common utilities and helper functions used across algorithms

### Components

#### Mathematical Utilities (`math_utils.dart`)
```dart
import 'package:fusion_lib/fusion_algorithms/shared/math_utils.dart';

// Decibel calculations
final db = powerToDb(100.0); // Convert watts to dB
final watts = dbToPower(20.0); // Convert dB to watts

// Distance calculations
final distance3D = calculateDistance3D(x1, y1, z1, x2, y2, z2);
final distanceHorizontal = calculateHorizontalDistance(x1, y1, x2, y2);
```

#### Validation Utilities (`validation_utils.dart`)
```dart
import 'package:fusion_lib/fusion_algorithms/shared/validation_utils.dart';

// Input validation
validatePositiveNumber(value, 'power');
validateSpeakerModel('DM6C');
validateVoltage(70); // Validates 70V or 100V
validateCircuitType('hi-z');
```

#### Speaker Database (`speaker_database.dart`)
```dart
import 'package:fusion_lib/fusion_algorithms/shared/speaker_database.dart';

// Access speaker specifications
final speaker = speakerDatabase['DM6C'];
print('Max SPL: ${speaker?.maxSpl}dB');
print('Available taps: ${speaker?.taps70V}');
```

---

## 🚀 Getting Started

### Installation
Add to your `pubspec.yaml`:
```yaml
dependencies:
  fusion_lib:
    path: ../fusion_lib
```

### Basic Setup
```dart
import 'package:fusion_lib/fusion_algorithms/fusion_algorithms.dart';

void main() {
  // Initialize any required configurations
  
  // Use algorithms as needed
  final splResult = calculateSPLAtDistance(
    speakerModel: 'DM6C',
    distance: 10.0,
    power: 100.0,
  );
  
  print('SPL at 10m: ${splResult}dB');
}
```

---

## 📊 Algorithm Integration Examples

### Complete System Design Workflow
```dart
// 1. Calculate SPL requirements
final splNeeds = calculateSPLRequirements(room);

// 2. Select appropriate speakers
final selectedSpeakers = selectSpeakersForSPL(splNeeds);

// 3. Optimize tap settings
final tapSettings = recommendTapsForSpeakers(selectedSpeakers);

// 4. Match amplifiers
final amplifiers = findBestAmplifierMatch(
  AmpMatchingRequest.fromSpeakers(selectedSpeakers)
);

// 5. Recommend DSP device
final dspDevice = recommendDevice(
  SystemRequirements.fromSpeakers(selectedSpeakers)
);

// 6. Design circuits
final circuits = optimizeCircuitConfiguration(selectedSpeakers);
```

---

## 🔧 Configuration

### Supported Speaker Models
- **DesignMax Series**: DM2C-LP, DM3C, DM3P, DM3SE, DM5C, DM5P, DM5SE, DM6C, DM6PE, DM6SE, DM8C, DM8SE

### Supported Amplifiers  
- **PSX Series**: PSX300-4, PSX300-8, PSX600-4, PSX600-8, PSX1200-4, PSX1200-8

### Supported DSP Devices
- **Fusion Mini**: 8 analog I/O, 8 network I/O
- **PowerSmart**: 16 analog I/O, 16 network I/O

---

## 📈 Performance Considerations

- **SPL Calculations**: O(n) complexity for n speakers
- **Tap Optimization**: O(n²) complexity for multi-speaker balancing
- **Amplifier Matching**: O(m×n) where m=amplifiers, n=speakers
- **Memory Usage**: Minimal, all calculations are stateless

---

## 🧪 Testing

Each module includes comprehensive tests:

```bash
# Run all algorithm tests
flutter test test/fusion_algorithms/

# Run specific module tests
flutter test test/fusion_algorithms/spl_calculation_test.dart
flutter test test/fusion_algorithms/tap_setting_test.dart
```

---

## 🤝 Contributing

When adding new algorithms:
1. Follow the existing module structure
2. Include comprehensive tests
3. Add usage examples to this README
4. Update the main `fusion_algorithms.dart` export file

---

