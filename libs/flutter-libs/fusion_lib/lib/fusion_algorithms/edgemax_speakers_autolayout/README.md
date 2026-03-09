# EdgeMax Speaker Auto-Placement Integration

This document describes the integration of the EdgeMax speaker auto-placement algorithm into the fusion monorepo.

## Structure Created

### 1. Library (in fusion_lib)
**Location:** `/libs/flutter-libs/fusion_lib/lib/fusion_algorithms/edgemax_speaker_auto_layout/edgemax_autolayout.dart`

This contains the core EdgeMax algorithm implementation including:
- `EdgeMaxPoint` - 2D point representation
- `SpeakerPlacement` - Speaker placement result
- `RectangularRoom` - Room geometry representation  
- `SpeakerConfig` - Speaker configuration properties
- `EdgeMaxAutoPlacement` - Main algorithm implementation
- `EdgeMaxPlacementResult` - Complete result with summary and details
- `PlacementSummary` - Summary of speaker counts by type
- `EdgeMaxSpeakerPlacementService` - Widget-friendly service class

### 2. Widget Implementation (in fusion-launcher)
**Location:** `/apps/frontend/flutter-apps/fusion-launcher/lib/features/dashboard/presentation/widgets/algorithms/edgemax_speaker_layout_widget.dart`

This contains the Flutter UI widget that:
- Imports the EdgeMax library from fusion_lib
- Provides input fields for room dimensions
- Validates user input
- Calls the algorithm service
- Displays results in a user-friendly format
- Shows calculation details in expandable sections
- Color-codes different speaker types

### 3. Integration into Test Library Screen
**Location:** `/apps/frontend/flutter-apps/fusion-launcher/lib/core/widgets/test_library_screen.dart`

Added "EdgeMax Placement" tab to the Algorithms section.

### 4. Export Configuration
**Location:** `/libs/flutter-libs/fusion_lib/lib/fusion_algorithms/fusion_algorithms.dart`

Added export for the EdgeMax algorithm to make it available through the main fusion_algorithms library.

## Algorithm Steps Implemented

The complete 8-step EdgeMax algorithm:

1. **Validate room shape** - Ensure rectangular room with positive dimensions
2. **Select speaker type** - Choose EM vs EM-LP based on ceiling height (≤3.7m threshold)
3. **Calculate UTD** - Usable Throw Distance using vertical angle and height difference
4. **Determine diagonal corner coverage** - Place speakers in opposite corners based on UTD vs diagonal
5. **Calculate LSD** - Loudspeaker Spacing Distance using horizontal angle
6. **Determine adjacent corner coverage** - Add corner speakers based on room dimensions vs LSD
7. **Place corner speakers** - EM90/EM-LP90 speakers at determined corners
8. **Place wall speakers** - EM180/EM-LP180 speakers on walls when needed

## Usage Examples

### Basic Usage (Library)
```dart
import 'package:fusion_lib/fusion_algorithms/edgemax_speaker_auto_layout/edgemax_autolayout.dart';

final room = RectangularRoom(
  length: 7.0,
  width: 4.0, 
  ceilingHeight: 3.0,
  listenerHeight: 1.2,
);

final result = EdgeMaxSpeakerPlacementService.calculateCompleteResult(room);
print('Total speakers: ${result.summary.totalSpeakers}');
```

### Widget Usage
```dart
import 'package:fusion_lib/fusion_algorithms/edgemax_speaker_auto_layout/edgemax_autolayout.dart';

class MyWidget extends StatefulWidget {
  void _calculate() {
    final room = RectangularRoom(...);
    final result = EdgeMaxSpeakerPlacementService.calculateCompleteResult(room);
    setState(() {
      // Update UI with result
    });
  }
}
```

## Available Service Methods

- `calculateCompleteResult()` - Full calculation with details and summary
- `getPlacementsOnly()` - Just speaker placements (lightweight)
- `getPlacementSummary()` - Just summary counts
- `isValidRoom()` - Validate room dimensions
- `getRoomValidationErrors()` - Get detailed validation errors  
- `getRecommendedSpeakerTypes()` - Get speaker types for room
- `getPlacementsByType()` - Group placements by speaker type
- `getPlacementsByLocation()` - Group placements by location (corner/wall)
- `calculateTotalCost()` - Calculate cost with price map

## Features Implemented

### Algorithm Features
- ✅ Complete 8-step EdgeMax algorithm
- ✅ EM vs EM-LP speaker selection based on ceiling height
- ✅ UTD and LSD calculations with proper trigonometry
- ✅ Corner and wall speaker placement logic
- ✅ Comprehensive validation and error handling

### Widget Features  
- ✅ Intuitive input interface with labeled fields
- ✅ Real-time validation with detailed error messages
- ✅ Loading states during calculations
- ✅ Comprehensive results display with color coding
- ✅ Expandable calculation details
- ✅ Speaker placement list with positions
- ✅ Reset functionality

### Integration Features
- ✅ Proper library structure in fusion_lib
- ✅ Widget integration in algorithms section
- ✅ Export configuration for easy importing
- ✅ Clean separation between algorithm logic and UI

## Testing

The implementation can be tested by:

1. Running the fusion-launcher app
2. Navigating to the Library section
3. Going to the Algorithms tab  
4. Selecting "EdgeMax Placement"
5. Entering room dimensions and calculating results

Example test case:
- Length: 7.0m
- Width: 4.0m  
- Ceiling Height: 3.0m
- Listener Height: 1.2m

This should result in EM-LP speakers being selected and specific placement calculations.
