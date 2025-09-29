// import 'dart:ui';
// import 'dart:math' as math;

// import 'package:fusion_launcher/features/wireing_design/model/circuit_component.dart';

// import '../model/wire.dart';

// class PathAdjuster {
//   final List<CircuitComponent> obstacles;
//   final double spacing;

//   PathAdjuster({required this.obstacles, this.spacing = 12});

//   /// Adjusts all wires so overlapping segments become parallel
//   void resolveAll(List<Wire> wires) {
//     if (wires.length < 2) return;

//     // 1. Build all segments
//     final segments = _buildSegments(wires);

//     // 2. Find corridor groups (segments that overlap and should be parallel)
//     final groups = _findCorridorGroups(segments);

//     print("Found ${groups.length} corridor groups");
//     for (final g in groups) {
//       print("Group: \n${g.map((e) => e.toString()).join("\n")}");
//       _resolveParallelGroup(g, wires);
//     }
//   }

//   List<_Segment> _buildSegments(List<Wire> wires) {
//     final segs = <_Segment>[];
//     for (int wi = 0; wi < wires.length; wi++) {
//       final pts = wires[wi].joints;
//       for (int i = 0; i < pts.length - 1; i++) {
//         segs.add(_Segment(wi, i, pts[i], pts[i + 1]));
//       }
//     }
//     return segs;
//   }

//   /// Group wires by corridor (collinear overlaps along same line)
//   List<List<_Segment>> _findCorridorGroups(List<_Segment> segments) {
//     final groups = <List<_Segment>>[];
//     final visited = <_Segment>{};

//     for (final s in segments) {
//       if (visited.contains(s)) continue;

//       final group = segments.where((t) {
//         if (s.isHorizontal && t.isHorizontal && s.p1.dy == t.p1.dy) {
//           return _projectionOverlap(s.p1.dx, s.p2.dx, t.p1.dx, t.p2.dx);
//         }
//         if (s.isVertical && t.isVertical && s.p1.dx == t.p1.dx) {
//           return _projectionOverlap(s.p1.dy, s.p2.dy, t.p1.dy, t.p2.dy);
//         }
//         return false;
//       }).toList();

//       if (group.length > 1) {
//         groups.add(group);
//         visited.addAll(group);
//       }
//     }
//     return groups;
//   }

//   bool _projectionOverlap(double a1, double a2, double b1, double b2) {
//     final minA = math.min(a1, a2);
//     final maxA = math.max(a1, a2);
//     final minB = math.min(b1, b2);
//     final maxB = math.max(b1, b2);
//     return maxA > minB && maxB > minA;
//   }

//   /// Spread wires in a corridor into parallel lanes
//   void _resolveParallelGroup(List<_Segment> group, List<Wire> wires) {
//     if (group.length < 2) return;
//     final perLineLength = 5;
//     final requiredMaxDimension =
//         (group.length - 1) * spacing + perLineLength * group.length;
//     final currentBounds = _getBounds(group);
//     final width = currentBounds.maxX - currentBounds.minX;
//     final height = currentBounds.maxY - currentBounds.minY;
//     print("Bounds: $currentBounds, width: $width, height: $height");

//     final requiredSize = Size(
//       currentBounds.isHorizontal ? width : requiredMaxDimension,
//       currentBounds.isHorizontal ? requiredMaxDimension : height,
//     );

//     print("Required size: $requiredSize");

//     final bestPosition = _getBestPosition(
//       Offset(currentBounds.minX, currentBounds.minY),
//       requiredSize,
//       currentBounds.isHorizontal,
//     );
//     print("Best position: $bestPosition");

//     ///
//     /// 3. seperate Lanes
//     ///

//     // Calculate lane positions based on the current bounds
//     final lanePositions = <double>[];

//     if (currentBounds.isHorizontal) {
//       // For horizontal segments, create lanes at different Y positions
//       final centerY = (currentBounds.minY + currentBounds.maxY) / 2;
//       final totalSpacing = (group.length - 1) * spacing;
//       final startY = centerY - totalSpacing / 2;

//       for (int i = 0; i < group.length; i++) {
//         lanePositions.add(startY + i * spacing);
//       }
//     } else {
//       // For vertical segments, create lanes at different X positions
//       final centerX = (currentBounds.minX + currentBounds.maxX) / 2;
//       final totalSpacing = (group.length - 1) * spacing;
//       final startX = centerX - totalSpacing / 2;

//       for (int i = 0; i < group.length; i++) {
//         lanePositions.add(startX + i * spacing);
//       }
//     }

//     print("Lane positions: $lanePositions");

//     // Sort segments by their position along the corridor
//     final sortedSegments = [...group];
//     if (currentBounds.isHorizontal) {
//       // Sort by X position (left to right)
//       sortedSegments.sort((a, b) {
//         final aStart = math.min(a.p1.dx, a.p2.dx);
//         final bStart = math.min(b.p1.dx, b.p2.dx);
//         return aStart.compareTo(bStart);
//       });
//     } else {
//       // Sort by Y position (top to bottom)
//       sortedSegments.sort((a, b) {
//         final aStart = math.min(a.p1.dy, a.p2.dy);
//         final bStart = math.min(b.p1.dy, b.p2.dy);
//         return aStart.compareTo(bStart);
//       });
//     }

//     print("Sorted segments:");
//     for (final s in sortedSegments) {
//       print(s);
//     }
//     // Assign each lane to the best available segment
//     final remainingSegments = [...sortedSegments];

//     for (int i = 0; i < lanePositions.length; i++) {
//       final lanePos = lanePositions[i];

//       // Find the best segment for this lane position
//       final bestSegment = _findBestSegmentForLane(
//         lanePos,
//         remainingSegments,
//         wires,
//         currentBounds.isHorizontal,
//       );

//       // Remove the selected segment from remaining segments
//       remainingSegments.remove(bestSegment);

//       final wire = wires[bestSegment.wireIndex];

//       // Calculate the movement delta
//       Offset delta;
//       if (currentBounds.isHorizontal) {
//         // Move segment to new Y position (horizontal segments)
//         final currentY =
//             bestSegment.p1.dy; // Both points have same Y for horizontal
//         delta = Offset(0, lanePos - currentY);
//       } else {
//         // Move segment to new X position (vertical segments)
//         final currentX =
//             bestSegment.p1.dx; // Both points have same X for vertical
//         delta = Offset(lanePos - currentX, 0);
//       }

//       // Apply the movement to the wire joints
//       final oldP1 = wire.joints[bestSegment.segIndex];
//       final oldP2 = wire.joints[bestSegment.segIndex + 1];
//       final newP1 = oldP1 + delta;
//       final newP2 = oldP2 + delta;

//       wire.joints[bestSegment.segIndex] = newP1;
//       wire.joints[bestSegment.segIndex + 1] = newP2;
//     }
//   }

//   /// Find the best segment for a specific lane position to minimize intersections
//   _Segment _findBestSegmentForLane(
//     double lanePos,
//     List<_Segment> availableSegments,
//     List<Wire> allWires,
//     bool isHorizontal,
//   ) {
//     _Segment? bestSegment;
//     int minIntersections = double.maxFinite.toInt();
//     double minDistance = double.infinity;

//     for (final segment in availableSegments) {
//       // Calculate movement delta for this segment to reach lane position
//       Offset delta;
//       double currentDistance;

//       if (isHorizontal) {
//         final currentY = segment.p1.dy;
//         delta = Offset(0, lanePos - currentY);
//         currentDistance = (lanePos - currentY).abs();
//       } else {
//         final currentX = segment.p1.dx;
//         delta = Offset(lanePos - currentX, 0);
//         currentDistance = (lanePos - currentX).abs();
//       }

//       // Create temporary moved positions to test for intersections
//       final tempP1 = segment.p1 + delta;
//       final tempP2 = segment.p2 + delta;

//       // Count potential intersections with other wires
//       int intersectionCount = _countIntersectionsForMovedSegment(
//         tempP1,
//         tempP2,
//         segment.wireIndex,
//         allWires,
//       );

//       // Select best segment based on:
//       // 1. Fewest intersections (priority)
//       // 2. Shortest movement distance (tie-breaker)
//       bool isBetter = false;

//       if (bestSegment == null) {
//         isBetter = true;
//       } else if (intersectionCount < minIntersections) {
//         isBetter = true;
//       } else if (intersectionCount == minIntersections &&
//           currentDistance < minDistance) {
//         isBetter = true;
//       }

//       if (isBetter) {
//         bestSegment = segment;
//         minIntersections = intersectionCount;
//         minDistance = currentDistance;
//       }
//     }

//     print(
//       "Selected segment ${bestSegment?.wireIndex}-${bestSegment?.segIndex} "
//       "for lane $lanePos (intersections: $minIntersections, distance: $minDistance)",
//     );

//     return bestSegment!;
//   }

//   /// Count intersections that would occur if a segment is moved to new position
//   int _countIntersectionsForMovedSegment(
//     Offset newP1,
//     Offset newP2,
//     int excludeWireIndex,
//     List<Wire> allWires,
//   ) {
//     int count = 0;

//     for (int wireIdx = 0; wireIdx < allWires.length; wireIdx++) {
//       if (wireIdx == excludeWireIndex) continue; // Skip the wire being moved

//       final otherWire = allWires[wireIdx];

//       // Check intersection with each segment of the other wire
//       for (int segIdx = 0; segIdx < otherWire.joints.length - 1; segIdx++) {
//         if (_segmentsIntersect(
//           newP1,
//           newP2,
//           otherWire.joints[segIdx],
//           otherWire.joints[segIdx + 1],
//         )) {
//           count++;
//         }
//       }
//     }

//     return count;
//   }

//   /// Check if two line segments intersect
//   bool _segmentsIntersect(Offset a1, Offset a2, Offset b1, Offset b2) {
//     // For orthogonal segments, we can use simpler logic
//     final isA1Horizontal = a1.dy == a2.dy;
//     final isB1Horizontal = b1.dy == b2.dy;

//     // If both segments are parallel, they don't intersect (unless they overlap)
//     if (isA1Horizontal == isB1Horizontal) {
//       return false;
//     }

//     // One is horizontal, one is vertical
//     Offset h1, h2, v1, v2; // horizontal and vertical segments
//     if (isA1Horizontal) {
//       h1 = a1;
//       h2 = a2;
//       v1 = b1;
//       v2 = b2;
//     } else {
//       h1 = b1;
//       h2 = b2;
//       v1 = a1;
//       v2 = a2;
//     }

//     // Check if they intersect
//     final hMinX = math.min(h1.dx, h2.dx);
//     final hMaxX = math.max(h1.dx, h2.dx);
//     final vMinY = math.min(v1.dy, v2.dy);
//     final vMaxY = math.max(v1.dy, v2.dy);

//     return (v1.dx >= hMinX && v1.dx <= hMaxX) &&
//         (h1.dy >= vMinY && h1.dy <= vMaxY);
//   }

//   _OverlapBounds _getBounds(List<_Segment> group) {
//     double minX = double.infinity, maxX = double.negativeInfinity;
//     double minY = double.infinity, maxY = double.negativeInfinity;

//     for (final s in group) {
//       minX = math.min(minX, math.min(s.p1.dx, s.p2.dx));
//       maxX = math.max(maxX, math.max(s.p1.dx, s.p2.dx));
//       minY = math.min(minY, math.min(s.p1.dy, s.p2.dy));
//       maxY = math.max(maxY, math.max(s.p1.dy, s.p2.dy));
//     }

//     return _OverlapBounds(minX, maxX, minY, maxY, group.first.isHorizontal);
//   }

//   Offset _getBestPosition(Offset position, Size size, bool isHorizontal) {
//     final rect = !isHorizontal
//         ? _expandHorizontally(position & Size(10, 10), 10, size.width)
//         : _expandVertically(position & Size(10, 10), 10, size.height);
//     return rect.topLeft;
//   }

//   Rect _expandHorizontally(Rect r, double amount, double maxWidth) {
//     ///
//     /// Expand Left
//     ///
//     Rect leftRect = Rect.fromLTWH(r.left, r.top, r.width, r.height);
//     do {
//       leftRect = Rect.fromLTWH(
//         leftRect.left - amount,
//         leftRect.top,
//         leftRect.width + amount,
//         leftRect.height,
//       );
//     } while (!_isBlocked(leftRect) && leftRect.width <= maxWidth);

//     r = Rect.fromLTRB(
//       leftRect.left + amount,
//       leftRect.top,
//       leftRect.right - amount,
//       leftRect.bottom,
//     );

//     if (r.width >= maxWidth) {
//       return r;
//     }

//     /// Need Right expansion
//     Rect rightRect = Rect.fromLTWH(r.left, r.top, r.width, r.height);
//     do {
//       rightRect = Rect.fromLTWH(
//         leftRect.left,
//         leftRect.top,
//         leftRect.width + amount,
//         leftRect.height,
//       );
//     } while (!_isBlocked(rightRect) && rightRect.width <= maxWidth);

//     return r;
//   }

//   Rect _expandVertically(Rect r, double amount, double maxHeight) {
//     ///
//     /// Expand Up
//     ///
//     Rect upRect = Rect.fromLTWH(r.left, r.top, r.width, r.height);
//     do {
//       upRect = Rect.fromLTWH(
//         upRect.left,
//         upRect.top - amount,
//         upRect.width,
//         upRect.height + amount,
//       );
//     } while (!_isBlocked(upRect) && upRect.height <= maxHeight);

//     r = Rect.fromLTRB(
//       upRect.left,
//       upRect.top + amount,
//       upRect.right,
//       upRect.bottom,
//     );

//     if (r.height >= maxHeight) {
//       return r;
//     }

//     /// Need Down expansion
//     Rect downRect = Rect.fromLTWH(r.left, r.top, r.width, r.height);
//     do {
//       downRect = Rect.fromLTWH(
//         downRect.left,
//         downRect.top,
//         downRect.width,
//         downRect.height + amount,
//       );
//     } while (!_isBlocked(downRect) && downRect.height <= maxHeight);

//     return r;
//   }

//   bool _isBlocked(Rect p) {
//     for (final r in obstacles) {
//       if (p.overlaps(r.position & r.size)) {
//         return true;
//       }
//     }
//     return false;
//   }
// }

// // -------------------------------
// // INTERNAL HELPERS
// // -------------------------------

// class _Segment {
//   final int wireIndex;
//   final int segIndex;
//   final Offset p1;
//   final Offset p2;

//   _Segment(this.wireIndex, this.segIndex, this.p1, this.p2);

//   bool get isHorizontal => p1.dy == p2.dy;
//   bool get isVertical => p1.dx == p2.dx;

//   @override
//   String toString() {
//     return '''Segment(wire: $wireIndex, seg: $segIndex, p1: $p1, p2: $p2,isHorizontal: $isHorizontal, isVertical: $isVertical)
//         ''';
//   }
// }

// class _OverlapBounds {
//   final double minX;
//   final double maxX;
//   final double minY;
//   final double maxY;
//   final bool isHorizontal;

//   _OverlapBounds(this.minX, this.maxX, this.minY, this.maxY, this.isHorizontal);
//   @override
//   String toString() {
//     return 'Bounds(\nminX: $minX, maxX: $maxX, \nminY: $minY, maxY: $maxY, '
//         '\nisHorizontal: $isHorizontal)\n';
//   }
// }
