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
/// 2. Select speaker type (EM vs EM-LP based on ceiling height)
/// 3. Calculate UTD (Usable Throw Distance)
/// 4. Determine diagonal corner coverage
/// 5. Calculate LSD (Loudspeaker Spacing Distance)  
/// 6. Determine adjacent corner coverage
/// 7. Place corner speakers (EM90/EM-LP90)
/// 8. Place wall speakers (EM180/EM-LP180)
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
  final String speakerType; // 'EM90', 'EM180', 'EM-LP90', 'EM-LP180'
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

  /// Get corner positions (clockwise from bottom-left)
  List<EdgeMaxPoint> get corners => <EdgeMaxPoint>[
    const EdgeMaxPoint(0, 0), // Corner 1 (bottom-left)
    EdgeMaxPoint(length, 0), // Corner 2 (bottom-right)
    EdgeMaxPoint(length, width), // Corner 3 (top-right)
    EdgeMaxPoint(0, width), // Corner 4 (top-left)
  ];
}

/// Speaker configuration and properties
class SpeakerConfig {
  final String baseType; // 'EM' or 'EM-LP'
  final double verticalAngle; // degrees
  final double horizontalAngle90; // degrees for 90-degree speakers
  final double horizontalAngle180; // degrees for 180-degree speakers

  SpeakerConfig({
    required this.baseType,
    required this.verticalAngle,
    required this.horizontalAngle90,
    required this.horizontalAngle180,
  });

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
      horizontalAngle90: 90.0,
      horizontalAngle180: 180.0,
    ),
    'EM-LP': SpeakerConfig(
      baseType: 'EM-LP',
      verticalAngle: 80.0,
      horizontalAngle90: 90.0,
      horizontalAngle180: 180.0,
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
    final Set<int> adjacentCorners = _getAdjacentCorners(room, lsd, diagonalCorners);

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

    if (utd <= diagonal) {
      return <int>{0}; // Corner 1 only
    } else {
      return <int>{0, 2}; // Corner 1 and Corner 3 (opposite corners)
    }
  }

  /// Step 5: Calculate Loudspeaker Spacing Distance
  static double _calculateLSD(RectangularRoom room, SpeakerConfig config) {
    final double h = room.heightDifference;
    final double halfAngleRad = (config.horizontalAngle90 / 2) * pi / 180;
    return h * 2 * tan(halfAngleRad);
  }

  /// Step 6: Determine which adjacent corners need speakers
  static Set<int> _getAdjacentCorners(
    RectangularRoom room,
    double lsd,
    Set<int> diagonalCorners,
  ) {
    final Set<int> adjacentCorners = <int>{};

    // Check if length coverage requires additional corners
    if (lsd < room.length) {
      if (diagonalCorners.contains(0)) {
        adjacentCorners.add(1); // Corner 2 (adjacent to Corner 1 along length)
      }
      if (diagonalCorners.contains(2)) {
        adjacentCorners.add(3); // Corner 4 (adjacent to Corner 3 along length)
      }
    }

    // Check if width coverage requires additional corners
    if (lsd < room.width) {
      if (diagonalCorners.contains(0)) {
        adjacentCorners.add(3); // Corner 4 (adjacent to Corner 1 along width)
      }
      if (diagonalCorners.contains(2)) {
        adjacentCorners.add(1); // Corner 2 (adjacent to Corner 3 along width)
      }
    }

    return adjacentCorners;
  }

  /// Step 7: Determine which walls need EM180 speakers
  static List<String> _getWallSpeakers(
    RectangularRoom room,
    double lsd,
    Set<int> populatedCorners,
  ) {
    final List<String> wallSpeakers = <String>[];
    final double doubleLSD = 2 * lsd;

    // Check length walls (north and south)
    if (room.length > doubleLSD) {
      // Check if corners are populated along length
      final bool hasLengthCorners = populatedCorners.any(
        (int corner) => <int>[0, 1, 2, 3].contains(corner),
      );
      if (hasLengthCorners) {
        wallSpeakers.add('wall_length');
      }
    }

    // Check width walls (east and west)
    if (room.width > doubleLSD) {
      // Check if corners are populated along width
      final bool hasWidthCorners = populatedCorners.any(
        (int corner) => <int>[0, 1, 2, 3].contains(corner),
      );
      if (hasWidthCorners) {
        wallSpeakers.add('wall_width');
      }
    }

    return wallSpeakers;
  }

  /// Create corner speaker placement
  static SpeakerPlacement _createCornerSpeaker(
    RectangularRoom room,
    int cornerIndex,
    SpeakerConfig config,
  ) {
    final List<EdgeMaxPoint> corners = room.corners;
    final List<String> cornerNames = <String>['corner1', 'corner2', 'corner3', 'corner4'];

    return SpeakerPlacement(
      position: EdgeMaxPoint(corners[cornerIndex].x, corners[cornerIndex].y),
      speakerType: config.getSpeakerType(90), // EM90 for corners
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
      case 'wall_length':
        position = EdgeMaxPoint(
          room.length / 2,
          room.width / 2,
        ); // Center for simplicity
        location = 'wall_length_center';
        break;
      case 'wall_width':
        position = EdgeMaxPoint(
          room.length / 2,
          room.width / 2,
        ); // Center for simplicity
        location = 'wall_width_center';
        break;
      default:
        throw ArgumentError('Unknown wall type: $wallType');
    }

    return SpeakerPlacement(
      position: position,
      speakerType: config.getSpeakerType(180), // EM180 for walls
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
      em90Count: em90Count,
      em180Count: em180Count,
      emlp90Count: emlp90Count,
      emlp180Count: emlp180Count,
    );
  }
}