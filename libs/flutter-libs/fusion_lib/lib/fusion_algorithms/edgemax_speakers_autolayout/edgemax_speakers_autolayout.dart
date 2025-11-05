/// EdgeMax Speaker Auto-Placement Library
/// 
/// A comprehensive library for calculating optimal speaker placement in rectangular rooms
/// using the EdgeMax algorithm. This library implements the complete 8-step algorithm
/// for determining speaker positions, types, and configurations.
/// 
/// ## Usage
/// 
/// ### Basic Usage:
/// ```dart
/// import 'package:fusion_lib/fusion_algorithms/edgemax_speaker_auto_layout/edgemax_autolayout.dart';
/// 
/// // Create a room
/// final room = RectangularRoom(
///   length: 7.0,
///   width: 4.0, 
///   ceilingHeight: 3.0,
///   listenerHeight: 1.2,
/// );
/// 
/// // Get placement results
/// final result = EdgeMaxSpeakerPlacementService.calculateCompleteResult(room);
/// print('Total speakers: ${result.summary.totalSpeakers}');
/// ```
/// 
/// ### Available Methods:
/// - `calculateCompleteResult()` - Full calculation with details and summary
/// - `getPlacementsOnly()` - Just the speaker placements (lightweight)
/// - `getPlacementSummary()` - Just the summary counts
/// - `isValidRoom()` - Validate room dimensions
/// - `getRoomValidationErrors()` - Get detailed validation errors
/// - `getRecommendedSpeakerTypes()` - Get speaker types for room
/// - `getPlacementsByType()` - Group placements by speaker type
/// - `getPlacementsByLocation()` - Group placements by location (corner/wall)
/// - `calculateTotalCost()` - Calculate cost with price map
/// 
/// ## Algorithm Steps:
/// 1. Validate room shape (rectangular)
/// 2. Select speaker type (EM vs EM-LP based on ceiling height ≤ 12ft/3.7m)
/// 3. Calculate UTD (Usable Throw Distance)
/// 4. Determine diagonal corner coverage (Corner #1 if UTD ≥ d1, else Corner #1 & #3)
/// 5. Calculate LSD (Loudspeaker Spacing Distance)  
/// 6. Determine adjacent corner coverage (Corner #2 if d2 > LSD, Corner #4 if d3 < LSD & UTD < d1)
/// 7. Place corner speakers (EM90/EM-LP90)
/// 8. Place wall speakers (EM180/EM-LP180 if d2 > 2*LSD or d3 > 2*LSD)
/// 
library edgemax_speaker_placement;

import 'dart:math';

/// Represents a 2D point (corner position)
class EdgeMaxPoint {
  final double x;
  final double y;

  const EdgeMaxPoint(this.x, this.y);

  @override
  String toString() => 'EdgeMaxPoint($x, $y)';

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is EdgeMaxPoint && 
      runtimeType == other.runtimeType &&
      x == other.x &&
      y == other.y;

  @override
  int get hashCode => x.hashCode ^ y.hashCode;
}

/// Represents speaker placement result
class SpeakerPlacement {
  final EdgeMaxPoint position;
  final String speakerType; // 'EM' or 'EM-LP'
  final String location; // 'corner1', 'corner2', 'wall_north', etc.

  SpeakerPlacement({
    required this.position,
    required this.speakerType,
    required this.location,
  });

  @override
  String toString() =>
      'SpeakerPlacement(pos: $position, type: $speakerType, location: $location)';
}

/// Room geometry representation
class RectangularRoom {
  final double length; // d2 in PDF
  final double width; // d3 in PDF
  final double ceilingHeight;
  final double listenerHeight;

  RectangularRoom({
    required this.length,
    required this.width,
    required this.ceilingHeight,
    required this.listenerHeight,
  });

  /// Calculate room diagonal (d1)
  double get diagonal => sqrt(length * length + width * width);

  /// Height difference for calculations
  double get heightDifference => ceilingHeight - listenerHeight;

  /// Check if room is valid rectangular shape
  bool get isValidRectangle => length > 0 && width > 0;

  /// Get corner positions (correct layout: 1=top-left, 2=top-right, 3=bottom-right, 4=bottom-left)
  List<EdgeMaxPoint> get corners => <EdgeMaxPoint>[
    EdgeMaxPoint(0, width), // Corner 1 (top-left)
    EdgeMaxPoint(length, width), // Corner 2 (top-right)
    EdgeMaxPoint(length, 0), // Corner 3 (bottom-right)
    const EdgeMaxPoint(0, 0), // Corner 4 (bottom-left)
  ];
}

/// Speaker configuration and properties
class SpeakerConfig {
  final String baseType; // 'EM' or 'EM-LP'
  final double verticalAngle; // degrees
  final double horizontalAngle; // degrees - actual horizontal coverage angle

  SpeakerConfig({
    required this.baseType,
    required this.verticalAngle,
    required this.horizontalAngle,
  });

  // Legacy compatibility getters
  double get horizontalAngle90 => horizontalAngle;
  double get horizontalAngle180 => horizontalAngle;

  /// Get speaker type based on coverage angle
  String getSpeakerType(int coverageAngle) => '$baseType$coverageAngle';
}

/// Main EdgeMax auto-placement algorithm implementation
class EdgeMaxAutoPlacement {
  static const double _ceilingHeightThreshold = 3.7; // 12 feet in meters

  /// Standard speaker configurations
  static final Map<String, SpeakerConfig> _speakerConfigs = <String, SpeakerConfig>{
    'EM': SpeakerConfig(
      baseType: 'EM',
      verticalAngle: 75.0,
      horizontalAngle: 90.0,  // EM speakers have 90° horizontal coverage
    ),
    'EM-LP': SpeakerConfig(
      baseType: 'EM-LP',
      verticalAngle: 80.0,
      horizontalAngle: 120.0, // EM-LP speakers have 120° horizontal coverage
    ),
  };

  /// Main algorithm entry point
  static List<SpeakerPlacement> calculatePlacement(RectangularRoom room) {
    final List<SpeakerPlacement> result = <SpeakerPlacement>[];

    // Step 1: Validate room shape
    if (!room.isValidRectangle) {
      throw ArgumentError('Room must be rectangular with positive dimensions');
    }

    // Step 2: Select speaker type based on ceiling height
    final SpeakerConfig speakerConfig = _selectSpeakerType(room.ceilingHeight);

    // Step 3: Calculate UTD (Usable Throw Distance)
    final double utd = _calculateUTD(room, speakerConfig);

    // Step 4: Determine diagonal corner coverage
    final Set<int> diagonalCorners = _getDiagonalCorners(room, utd);

    // Step 5: Calculate LSD (Loudspeaker Spacing Distance)
    final double lsd = _calculateLSD(room, speakerConfig);

    // Step 6: Determine adjacent corner coverage
    final Set<int> adjacentCorners = _getAdjacentCorners(room, lsd, utd, diagonalCorners);

    // Step 7: Place corner speakers (EM90)
    final Set<int> allCorners = <int>{...diagonalCorners, ...adjacentCorners};
    for (final int corner in allCorners) {
      result.add(_createCornerSpeaker(room, corner, speakerConfig));
    }

    // Step 8: Determine wall speaker placement (EM180)
    final List<String> wallSpeakers = _getWallSpeakers(room, lsd, allCorners);
    result.addAll(
      wallSpeakers.map((String wall) => _createWallSpeaker(room, wall, speakerConfig)),
    );

    return result;
  }

  /// Step 2: Select speaker type based on ceiling height
  static SpeakerConfig _selectSpeakerType(double ceilingHeight) {
    return ceilingHeight <= _ceilingHeightThreshold
        ? _speakerConfigs['EM-LP']!
        : _speakerConfigs['EM']!;
  }

  /// Step 3: Calculate Usable Throw Distance
  static double _calculateUTD(RectangularRoom room, SpeakerConfig config) {
    final double h = room.heightDifference;
    final double angleRad = config.verticalAngle * pi / 180;
    return h * tan(angleRad);
  }

  /// Step 4: Determine which diagonal corners need speakers
  static Set<int> _getDiagonalCorners(RectangularRoom room, double utd) {
    final double diagonal = room.diagonal;

    if (utd >= diagonal) {
      return <int>{0}; // Corner 1 only
    } else {
      return <int>{0, 2}; // Corner 1 and Corner 3 (opposite corners)
    }
  }

  /// Step 5: Calculate Loudspeaker Spacing Distance
  static double _calculateLSD(RectangularRoom room, SpeakerConfig config) {
    final double h = room.heightDifference;
    // Use the horizontal angle of the selected speaker type (90° for EM, 120° for EM-LP)
    final double halfAngleRad = (config.horizontalAngle / 2) * pi / 180;
    return h * 2 * tan(halfAngleRad);
  }

  /// Step 6: Determine which adjacent corners need speakers
  static Set<int> _getAdjacentCorners(
    RectangularRoom room,
    double lsd,
    double utd,
    Set<int> diagonalCorners,
  ) {
    final Set<int> adjacentCorners = <int>{};

    // Following spec: if d2 > LSD, add Corner #2
    if (room.length > lsd) {
      adjacentCorners.add(1); // Corner 2 (index 1)
    }

    // Following spec: if UTD < d1, add Corner #4
    if (utd < room.diagonal) {
      adjacentCorners.add(3); // Corner 4 (index 3)
    }

    return adjacentCorners;
  }

  /// Step 8: Determine which walls need EM180 speakers
  static List<String> _getWallSpeakers(
    RectangularRoom room,
    double lsd,
    Set<int> populatedCorners,
  ) {
    final List<String> wallSpeakers = <String>[];
    // Use the LSD from step 5 (90° speakers) to determine wall coverage gaps
    final double doubleLSD = 2 * lsd;

    // Wall speakers are needed when room dimension is GREATER than 2*LSD_90
    // This means the 90° corner speakers cannot provide adequate coverage
    if (room.length > doubleLSD && populatedCorners.isNotEmpty) {
      // Always add top wall (between corners 1&2)
      wallSpeakers.add('wall_top');
      
      // Always add bottom wall (between corners 3&4) when length coverage is needed
      wallSpeakers.add('wall_bottom');
    }

    // Wall speakers needed when width is greater than 2*LSD_90
    if (room.width > doubleLSD && populatedCorners.isNotEmpty) {
      // Always add left wall (between corners 1&4)
      wallSpeakers.add('wall_left');
      
      // Always add right wall (between corners 2&3) when width coverage is needed
      wallSpeakers.add('wall_right');
    }

    return wallSpeakers;
  }

  /// Create corner speaker placement (90° speakers)
  static SpeakerPlacement _createCornerSpeaker(
    RectangularRoom room,
    int cornerIndex,
    SpeakerConfig config,
  ) {
    final List<EdgeMaxPoint> corners = room.corners;
    final List<String> cornerNames = <String>['corner1', 'corner2', 'corner3', 'corner4'];

    return SpeakerPlacement(
      position: EdgeMaxPoint(corners[cornerIndex].x, corners[cornerIndex].y),
      speakerType: '${config.baseType}90', // EM90 or EM-LP90 for corner speakers
      location: cornerNames[cornerIndex],
    );
  }

  /// Create wall speaker placement
  static SpeakerPlacement _createWallSpeaker(
    RectangularRoom room,
    String wallType,
    SpeakerConfig config,
  ) {
    EdgeMaxPoint position;
    String location;

    switch (wallType) {
      case 'wall_top':
        // Place EM180 on the top wall between corners 1 and 2
        position = EdgeMaxPoint(
          room.length / 2,  // Center of length
          room.width,       // On the top wall (y = width)
        );
        location = 'wall_top_center';
        break;
      case 'wall_bottom':
        // Place EM180 on the bottom wall between corners 3 and 4
        position = EdgeMaxPoint(
          room.length / 2,  // Center of length
          0,                // On the bottom wall (y = 0)
        );
        location = 'wall_bottom_center';
        break;
      case 'wall_left':
        // Place EM180 on the left wall between corners 1 and 4
        position = EdgeMaxPoint(
          0,                // On the left wall (x = 0)
          room.width / 2,   // Center of width
        );
        location = 'wall_left_center';
        break;
      case 'wall_right':
        // Place EM180 on the right wall between corners 2 and 3
        position = EdgeMaxPoint(
          room.length,      // On the right wall (x = length)
          room.width / 2,   // Center of width
        );
        location = 'wall_right_center';
        break;
      case 'wall_length':
        // Legacy support - map to bottom wall
        position = EdgeMaxPoint(
          room.length / 2,  // Center of length
          0,                // On the bottom wall (y = 0)
        );
        location = 'wall_bottom_center';
        break;
      case 'wall_width':
        // Legacy support - map to left wall
        position = EdgeMaxPoint(
          0,                // On the left wall (x = 0)
          room.width / 2,   // Center of width
        );
        location = 'wall_left_center';
        break;
      default:
        throw ArgumentError('Unknown wall type: $wallType');
    }

    return SpeakerPlacement(
      position: position,
      speakerType: '${config.baseType}180', // EM180 or EM-LP180 for wall speakers
      location: location,
    );
  }

  /// Get detailed calculation results for debugging
  static Map<String, dynamic> getCalculationDetails(RectangularRoom room) {
    final SpeakerConfig speakerConfig = _selectSpeakerType(room.ceilingHeight);
    final double utd = _calculateUTD(room, speakerConfig);
    final double lsd = _calculateLSD(room, speakerConfig);

    return <String, dynamic>{
      'room_diagonal': room.diagonal,
      'height_difference': room.heightDifference,
      'speaker_type': speakerConfig.baseType,
      'vertical_angle': speakerConfig.verticalAngle,
      'horizontal_angle': speakerConfig.horizontalAngle, // Single horizontal angle
      'utd': utd,
      'lsd': lsd,
      'double_lsd': 2 * lsd,
      'utd_vs_diagonal': utd > room.diagonal
          ? 'UTD > diagonal'
          : 'UTD <= diagonal',
      'length_coverage': lsd >= room.length
          ? 'Single speaker covers length'
          : 'Multiple speakers needed for length',
      'width_coverage': lsd >= room.width
          ? 'Single speaker covers width'
          : 'Multiple speakers needed for width',
    };
  }
}

/// EdgeMax Speaker Placement Result
class EdgeMaxPlacementResult {
  final List<SpeakerPlacement> placements;
  final Map<String, dynamic> calculationDetails;
  final PlacementSummary summary;

  EdgeMaxPlacementResult({
    required this.placements,
    required this.calculationDetails,
    required this.summary,
  });
}

/// Summary of speaker placement
class PlacementSummary {
  final int totalSpeakers;
  final int em90Count;
  final int em180Count;
  final int emlp90Count;
  final int emlp180Count;

  PlacementSummary({
    required this.totalSpeakers,
    required this.em90Count,
    required this.em180Count,
    required this.emlp90Count,
    required this.emlp180Count,
  });

  /// Get count by speaker type
  int getCountByType(String speakerType) {
    switch (speakerType.toUpperCase()) {
      case 'EM90':
        return em90Count;
      case 'EM180':
        return em180Count;
      case 'EM-LP90':
        return emlp90Count;
      case 'EM-LP180':
        return emlp180Count;
      // Legacy support for old UI
      case 'EM':
        return em90Count + em180Count;  // Total EM speakers
      case 'EM-LP':
        return emlp90Count + emlp180Count;  // Total EM-LP speakers
      default:
        return 0;
    }
  }
}

/// Widget-friendly EdgeMax Auto-Placement Service
class EdgeMaxSpeakerPlacementService {
  /// Calculate complete speaker placement with all details
  static EdgeMaxPlacementResult calculateCompleteResult(RectangularRoom room) {
    final List<SpeakerPlacement> placements = EdgeMaxAutoPlacement.calculatePlacement(room);
    final Map<String, dynamic> details = EdgeMaxAutoPlacement.getCalculationDetails(room);
    final PlacementSummary summary = _createSummary(placements);

    return EdgeMaxPlacementResult(
      placements: placements,
      calculationDetails: details,
      summary: summary,
    );
  }

  /// Get only speaker placements (lightweight)
  static List<SpeakerPlacement> getPlacementsOnly(RectangularRoom room) {
    return EdgeMaxAutoPlacement.calculatePlacement(room);
  }

  /// Get placement summary only
  static PlacementSummary getPlacementSummary(RectangularRoom room) {
    final List<SpeakerPlacement> placements = EdgeMaxAutoPlacement.calculatePlacement(room);
    return _createSummary(placements);
  }

  /// Validate room dimensions before calculation
  static bool isValidRoom(RectangularRoom room) {
    return room.isValidRectangle &&
           room.ceilingHeight > room.listenerHeight &&
           room.ceilingHeight > 0 &&
           room.listenerHeight >= 0;
  }

  /// Get recommended speaker types for room
  static List<String> getRecommendedSpeakerTypes(RectangularRoom room) {
    if (!isValidRoom(room)) return <String>[];
    
    final SpeakerConfig config = EdgeMaxAutoPlacement._selectSpeakerType(room.ceilingHeight);
    return <String>[
      '${config.baseType}90',
      '${config.baseType}180',
    ];
  }

  /// Get room validation errors
  static List<String> getRoomValidationErrors(RectangularRoom room) {
    final List<String> errors = <String>[];
    
    if (room.length <= 0) errors.add('Length must be positive');
    if (room.width <= 0) errors.add('Width must be positive');
    if (room.ceilingHeight <= 0) errors.add('Ceiling height must be positive');
    if (room.listenerHeight < 0) errors.add('Listener height cannot be negative');
    if (room.ceilingHeight <= room.listenerHeight) {
      errors.add('Ceiling height must be greater than listener height');
    }
    
    return errors;
  }

  /// Get placements grouped by speaker type
  static Map<String, List<SpeakerPlacement>> getPlacementsByType(RectangularRoom room) {
    final List<SpeakerPlacement> placements = getPlacementsOnly(room);
    final Map<String, List<SpeakerPlacement>> grouped = <String, List<SpeakerPlacement>>{};
    
    for (final SpeakerPlacement placement in placements) {
      grouped.putIfAbsent(placement.speakerType, () => <SpeakerPlacement>[]);
      grouped[placement.speakerType]!.add(placement);
    }
    
    return grouped;
  }

  /// Get placements grouped by location type (corner vs wall)
  static Map<String, List<SpeakerPlacement>> getPlacementsByLocation(RectangularRoom room) {
    final List<SpeakerPlacement> placements = getPlacementsOnly(room);
    final Map<String, List<SpeakerPlacement>> grouped = <String, List<SpeakerPlacement>>{
      'corners': <SpeakerPlacement>[],
      'walls': <SpeakerPlacement>[],
    };
    
    for (final SpeakerPlacement placement in placements) {
      if (placement.location.startsWith('corner')) {
        grouped['corners']!.add(placement);
      } else {
        grouped['walls']!.add(placement);
      }
    }
    
    return grouped;
  }

  /// Calculate total cost estimate (requires price per speaker type)
  static double calculateTotalCost(RectangularRoom room, Map<String, double> priceMap) {
    final List<SpeakerPlacement> placements = getPlacementsOnly(room);
    double totalCost = 0.0;
    
    for (final SpeakerPlacement placement in placements) {
      totalCost += priceMap[placement.speakerType] ?? 0.0;
    }
    
    return totalCost;
  }

  static PlacementSummary _createSummary(List<SpeakerPlacement> placements) {
    final int em90Count = placements.where((SpeakerPlacement p) => p.speakerType == 'EM90').length;
    final int em180Count = placements.where((SpeakerPlacement p) => p.speakerType == 'EM180').length;
    final int emlp90Count = placements.where((SpeakerPlacement p) => p.speakerType == 'EM-LP90').length;
    final int emlp180Count = placements.where((SpeakerPlacement p) => p.speakerType == 'EM-LP180').length;

    return PlacementSummary(
      totalSpeakers: placements.length,
      em90Count: em90Count,        // EM90 corner speakers
      em180Count: em180Count,      // EM180 wall speakers
      emlp90Count: emlp90Count,    // EM-LP90 corner speakers
      emlp180Count: emlp180Count,  // EM-LP180 wall speakers
    );
  }
}