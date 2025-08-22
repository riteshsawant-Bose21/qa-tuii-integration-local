# API Data Refactoring

This folder contains refactored data structures that were previously embedded within algorithm modules. These data structures represent information that would typically be fetched from various APIs in production.

## Structure

### `/api_data/speakers/`
Contains speaker specifications and catalog data:
- **`speaker_types.dart`** - Speaker data structure definitions
- **`speaker_catalog.dart`** - Speaker database with all product specifications
- **`speakers.dart`** - Main export file for speaker-related APIs

**API Integration**: This data would typically come from a product catalog API endpoint such as `GET /api/v1/speakers`

### `/api_data/amplifiers/`
Contains amplifier specifications and catalog data:
- **`amplifier_types.dart`** - Amplifier model data structures
- **`amplifier_catalog.dart`** - Amplifier database with PSX series specifications
- **`amplifiers.dart`** - Main export file for amplifier-related APIs

**API Integration**: This data would typically come from an amplifier specifications API endpoint such as `GET /api/v1/amplifiers`

### `/api_data/devices/`
Contains DSP device specifications and catalog data:
- **`device_types.dart`** - DSP device specification data structures
- **`device_catalog.dart`** - Device database with Fusion Mini and PowerSmart specifications
- **`devices.dart`** - Main export file for device-related APIs

**API Integration**: This data would typically come from a device specifications API endpoint such as `GET /api/v1/devices`

## Benefits of Refactoring

1. **Separation of Concerns**: Algorithm logic is now separate from data definitions
2. **API Readiness**: Easy to replace hardcoded data with actual API calls
3. **Maintainability**: Centralized data management with single source of truth
4. **Reusability**: Data structures can be shared across different parts of the application
5. **Testing**: Easier to mock and test with isolated data structures

## Migration Guide

### Before (Old Structure)
```dart
// Data was embedded in algorithm files
import '../shared/speaker_database.dart';
import 'amp_matching_types.dart'; // contained AmpCatalog

// Hardcoded data access
final speakers = speakerDatabase;
final amps = AmpCatalog.models;
```

### After (New Structure)
```dart
// Import from centralized API data
import '../../api_data/speakers/speakers.dart';
import '../../api_data/amplifiers/amplifiers.dart';
import '../../api_data/devices/devices.dart';

// Access through catalogs
final speakers = SpeakerCatalog.getAllSpeakers();
final amps = AmpCatalog.models;
final devices = DeviceCatalog.getAllDevices();
```

## Future API Integration

Each catalog class includes placeholder methods for API integration:

```dart
// Example: Replace static data with API call
final speakers = await SpeakerCatalog.fetchFromApi(
  apiEndpoint: 'https://api.bose.com/v1/speakers',
  headers: {'Authorization': 'Bearer $token'},
);

// Example: Filtered API calls
final powerfulAmps = await AmpCatalog.fetchFilteredFromApi(
  minPower: 1200.0,
  channels: 4,
);
```

## Backward Compatibility

The refactoring maintains full backward compatibility:
- Existing algorithm imports continue to work
- Legacy `speakerDatabase` constant is preserved
- No changes needed to algorithm logic

## Files Modified

### New Files Created:
- `/api_data/speakers/speaker_types.dart`
- `/api_data/speakers/speaker_catalog.dart`
- `/api_data/speakers/speakers.dart`
- `/api_data/amplifiers/amplifier_types.dart`
- `/api_data/amplifiers/amplifier_catalog.dart`
- `/api_data/amplifiers/amplifiers.dart`
- `/api_data/devices/device_types.dart`
- `/api_data/devices/device_catalog.dart`
- `/api_data/devices/devices.dart`
- `/api_data/api_data.dart` (main export)

### Files Refactored:
- `/fusion_algorithms/shared/speaker_types.dart` → Now re-exports from API data
- `/fusion_algorithms/shared/speaker_database.dart` → Now delegates to API data
- `/fusion_algorithms/shared/shared.dart` → Updated imports
- `/fusion_algorithms/amplifier_matching/amp_matching_types.dart` → Removed duplicate definitions
- `/fusion_algorithms/amplifier_matching/amplifier_matcher.dart` → Updated imports
- `/fusion_algorithms/amplifier_matching/amplifier_matching.dart` → Updated imports
- `/fusion_algorithms/device_recommender/device_recommender.dart` → Updated imports

## Usage Examples

```dart
// Import the main API data module
import 'package:fusion_lib/api_data/api_data.dart';

// Or import specific modules
import 'package:fusion_lib/api_data/speakers/speakers.dart';
import 'package:fusion_lib/api_data/amplifiers/amplifiers.dart';
import 'package:fusion_lib/api_data/devices/devices.dart';

// Access data through catalogs
final allSpeakers = SpeakerCatalog.getAllSpeakers();
final ceilingSpeakers = SpeakerCatalog.getByMountingType('ceiling');
final powerSmartDevices = DeviceCatalog.getPowerSmartDevices();
final fourChannelAmps = AmpCatalog.fourChannelModels;
```
