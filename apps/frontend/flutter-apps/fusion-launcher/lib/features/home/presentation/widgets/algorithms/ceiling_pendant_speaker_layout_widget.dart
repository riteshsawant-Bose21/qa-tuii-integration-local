import 'dart:math';

import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CeilingPendantSpeakerLayoutWidget extends StatefulWidget {
  const CeilingPendantSpeakerLayoutWidget({super.key});

  @override
  State<CeilingPendantSpeakerLayoutWidget> createState() =>
      _CeilingPendantSpeakerLayoutWidgetState();
}

class _CeilingPendantSpeakerLayoutWidgetState
    extends State<CeilingPendantSpeakerLayoutWidget> {
  // Form controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _roomWidthController = TextEditingController(
    text: '6.1',
  );
  final TextEditingController _roomLengthController = TextEditingController(
    text: '4.6',
  );
  final TextEditingController _ceilingHeightController = TextEditingController(
    text: '2.7',
  );
  final TextEditingController _listenerHeightController = TextEditingController(
    text: '1.2',
  );
  final TextEditingController _coverageAngleController = TextEditingController(
    text: '90.0',
  );
  final TextEditingController _pendantHeightController = TextEditingController(
    text: '2.1',
  );
  final TextEditingController _roomCoordinatesController =
      TextEditingController(
        text: '(0,0), (6.1,0), (6.1,4.6), (0,4.6)', // Default rectangle
      );

  // Form state
  SpeakerType _selectedSpeakerType = SpeakerType.ceiling;
  CoveragePreference _selectedCoveragePreference =
      CoveragePreference.minimumOverlap;
  LayoutPattern _selectedLayoutPattern = LayoutPattern.square;
  RoomType _selectedRoomType = RoomType.symmetrical;
  bool _useCustomOrigin = false;
  double _customOriginOffsetX = 0.0; // Offset from centroid
  double _customOriginOffsetY = 0.0; // Offset from centroid
  double _boundaryOverlapThreshold = 0.7; // Default 70% coverage within room

  // Results
  PlacementResult? _result;
  List<Point2D>? _allGridPoints; // Store all initial grid points
  List<Point2D>? _removedPoints; // Store removed/filtered points
  bool _isCalculating = false;

  @override
  void dispose() {
    _roomWidthController.dispose();
    _roomLengthController.dispose();
    _ceilingHeightController.dispose();
    _listenerHeightController.dispose();
    _coverageAngleController.dispose();
    _pendantHeightController.dispose();
    _roomCoordinatesController.dispose();
    super.dispose();
  }

  Future<void> _calculatePlacement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
      _result = null;
      _allGridPoints = null;
      _removedPoints = null;
    });

    try {
      // Create room based on selected type
      Room room;

      if (_selectedRoomType == RoomType.symmetrical) {
        // Create rectangular room
        room = Room(
          width: double.parse(_roomWidthController.text),
          roomLength: double.parse(_roomLengthController.text),
          ceilingHeight: double.parse(_ceilingHeightController.text),
          listenerHeight: double.parse(_listenerHeightController.text),
          roomType: RoomType.symmetrical,
        );
      } else {
        // Create asymmetrical room from coordinates
        final List<Point2D> geometry = _parseRoomCoordinates(
          _roomCoordinatesController.text,
        );
        room = Room.asymmetrical(
          geometry: geometry,
          ceilingHeight: double.parse(_ceilingHeightController.text),
          listenerHeight: double.parse(_listenerHeightController.text),
        );
      }

      // Create speaker spec
      final SpeakerSpec speakerSpec = SpeakerSpec(
        coverageAngle: double.parse(_coverageAngleController.text),
        type: _selectedSpeakerType,
        pendantHeight:
            _selectedSpeakerType == SpeakerType.pendant
                ? double.tryParse(_pendantHeightController.text)
                : null,
      );

      // Create custom origin offset if specified
      Point2D? customOriginOffset;
      if (_useCustomOrigin &&
          (_customOriginOffsetX != 0.0 || _customOriginOffsetY != 0.0)) {
        customOriginOffset = Point2D(
          _customOriginOffsetX,
          _customOriginOffsetY,
        );
      }

      // Ensure boundary threshold is within valid range
      final double clampedBoundaryThreshold = _boundaryOverlapThreshold.clamp(
        0.01,
        0.9,
      );

      // Calculate placement with enhanced details
      final PlacementResult result = AutoSpeakerPlacement.calculatePlacement(
        room: room,
        speakerSpec: speakerSpec,
        coveragePreference: _selectedCoveragePreference,
        layoutPattern: _selectedLayoutPattern,
        customOriginOffset: customOriginOffset,
        boundaryOverlapThreshold: clampedBoundaryThreshold,
      );

      // Generate all grid points for display purposes
      final List<Point2D> allGridPoints = _generateAllGridPoints(
        room,
        result,
        _selectedLayoutPattern,
      );
      final List<Point2D> removedPoints = _calculateRemovedPoints(
        allGridPoints,
        result.speakerPositions,
      );

      setState(() {
        _result = result;
        _allGridPoints = allGridPoints;
        _removedPoints = removedPoints;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        _isCalculating = false;
      });
    }
  }

  /// Generate all initial grid points (before filtering) for visualization
  List<Point2D> _generateAllGridPoints(
    Room room,
    PlacementResult result,
    LayoutPattern pattern,
  ) {
    final List<Point2D> points = <Point2D>[];

    // Safety check for grid spacing
    if (result.gridSpacing <= 0 || !result.gridSpacing.isFinite) {
      return points;
    }

    // Always include the centroid
    points.add(result.centroid);

    if (pattern == LayoutPattern.square) {
      // Generate square grid
      final double maxStepsXDouble =
          (room.width - result.centroid.x) / result.gridSpacing;
      final double maxStepsYDouble =
          (room.roomLength - result.centroid.y) / result.gridSpacing;
      final double minStepsXDouble = result.centroid.x / result.gridSpacing;
      final double minStepsYDouble = result.centroid.y / result.gridSpacing;

      if (maxStepsXDouble.isFinite &&
          maxStepsYDouble.isFinite &&
          minStepsXDouble.isFinite &&
          minStepsYDouble.isFinite) {
        final int maxStepsX = maxStepsXDouble.floor().clamp(0, 50);
        final int maxStepsY = maxStepsYDouble.floor().clamp(0, 50);
        final int minStepsX = minStepsXDouble.floor().clamp(0, 50);
        final int minStepsY = minStepsYDouble.floor().clamp(0, 50);

        for (int i = -minStepsX; i <= maxStepsX; i++) {
          for (int j = -minStepsY; j <= maxStepsY; j++) {
            if (i == 0 && j == 0) continue; // Skip centroid (already added)

            final double x = result.centroid.x + (i * result.gridSpacing);
            final double y = result.centroid.y + (j * result.gridSpacing);

            if (x >= 0 && x <= room.width && y >= 0 && y <= room.roomLength) {
              points.add(Point2D(x, y));
            }
          }
        }
      }
    } else {
      // Generate hexagonal grid
      final double horizontalSpacing = result.gridSpacing;
      final double verticalSpacing = result.gridSpacing * sqrt(3) / 2;
      final double rowOffset = result.gridSpacing / 2;

      final double maxStepsXDouble =
          (room.width - result.centroid.x) / horizontalSpacing;
      final double maxStepsYDouble =
          (room.roomLength - result.centroid.y) / verticalSpacing;
      final double minStepsXDouble = result.centroid.x / horizontalSpacing;
      final double minStepsYDouble = result.centroid.y / verticalSpacing;

      if (maxStepsXDouble.isFinite &&
          maxStepsYDouble.isFinite &&
          minStepsXDouble.isFinite &&
          minStepsYDouble.isFinite) {
        final int maxStepsX = maxStepsXDouble.floor().clamp(0, 50);
        final int maxStepsY = maxStepsYDouble.floor().clamp(0, 50);
        final int minStepsX = minStepsXDouble.floor().clamp(0, 50);
        final int minStepsY = minStepsYDouble.floor().clamp(0, 50);

        for (int rowIndex = -minStepsY; rowIndex <= maxStepsY; rowIndex++) {
          for (int colIndex = -minStepsX; colIndex <= maxStepsX; colIndex++) {
            if (rowIndex == 0 && colIndex == 0) continue; // Skip centroid
            double x = result.centroid.x + (colIndex * horizontalSpacing);
            final double y = result.centroid.y + (rowIndex * verticalSpacing);

            if (rowIndex % 2 != 0) {
              x += rowOffset;
            }

            if (x >= 0 && x <= room.width && y >= 0 && y <= room.roomLength) {
              points.add(Point2D(x, y));
            }
          }
        }
      }
    }

    return points;
  }

  /// Calculate which points were removed/filtered out
  List<Point2D> _calculateRemovedPoints(
    List<Point2D> allPoints,
    List<Point2D> validPoints,
  ) {
    final List<Point2D> removedPoints = <Point2D>[];

    for (Point2D point in allPoints) {
      final bool isValid = validPoints.any(
        (Point2D validPos) =>
            (point.x - validPos.x).abs() < 0.001 &&
            (point.y - validPos.y).abs() < 0.001,
      );

      if (!isValid) {
        removedPoints.add(point);
      }
    }

    return removedPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      // appBar: AppBar(
      //   title:,
      //   backgroundColor: Colors.transparent,
      // ),
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(left: 16.0, top: 16, bottom: 8),
            child: FusionGradientText(
              text: 'Ceiling/Pendant Speaker Auto Placement',
              fontSize: 20,
              style: context.textTheme.titleMedium,
              gradient: const LinearGradient(
                colors: <Color>[
                  Colors.deepOrange,
                  Colors.orangeAccent,
                ],
              ),
            ),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Input Panel
                  Expanded(
                    flex: 2,
                    child: FusionFlatContainer(
                      child: Form(
                        key: _formKey,
                        child: SingleChildScrollView(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text(
                                'Room Specifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),
                              _buildNumberField(
                                controller: _roomWidthController,
                                label: 'Room Width (m)',
                                hint: 'Enter room width in meters',
                                autoRecalculate: true,
                              ),
                              const SizedBox(height: 12),
                              _buildNumberField(
                                controller: _roomLengthController,
                                label: 'Room Length (m)',
                                hint: 'Enter room length in meters',
                                autoRecalculate: true,
                              ),
                              const SizedBox(height: 12),
                              _buildNumberField(
                                controller: _ceilingHeightController,
                                label: 'Ceiling Height (m)',
                                hint: 'Enter ceiling height in meters',
                                autoRecalculate: true,
                              ),
                              const SizedBox(height: 12),
                              _buildNumberField(
                                controller: _listenerHeightController,
                                label: 'Listener Height (m)',
                                hint: 'Enter listener height in meters',
                                autoRecalculate: true,
                              ),

                              const SizedBox(height: 16),

                              // Room Type Selection
                              const Text(
                                'Room Shape Type',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 8),

                              // Symmetrical room option
                              RadioListTile<RoomType>(
                                title: const Text('Symmetrical (Rectangular)'),
                                subtitle: const Text(
                                  'Standard width × length rectangle',
                                ),
                                value: RoomType.symmetrical,
                                groupValue: _selectedRoomType,
                                onChanged: (RoomType? value) {
                                  setState(() {
                                    _selectedRoomType = value!;
                                  });
                                  // Automatically recalculate when room type changes
                                  _calculatePlacement();
                                },
                                contentPadding: EdgeInsets.zero,
                              ),

                              // Asymmetrical room option
                              RadioListTile<RoomType>(
                                title: const Text(
                                  'Asymmetrical (Custom Shape)',
                                ),
                                subtitle: const Text(
                                  'Define room using coordinate points',
                                ),
                                value: RoomType.asymmetrical,
                                groupValue: _selectedRoomType,
                                onChanged: (RoomType? value) {
                                  setState(() {
                                    _selectedRoomType = value!;
                                  });
                                  // Automatically recalculate when room type changes
                                  // But only if coordinates are already provided
                                  if (_roomCoordinatesController
                                      .text
                                      .isNotEmpty) {
                                    _calculatePlacement();
                                  }
                                },
                                contentPadding: EdgeInsets.zero,
                              ),

                              if (_selectedRoomType ==
                                  RoomType.asymmetrical) ...<Widget>[
                                const SizedBox(height: 8),
                                FusionTextFormField(
                                  semanticId:
                                      "ceiling_pendant_speaker_layout_room_coordinates",
                                  controller: _roomCoordinatesController,
                                  maxLines: 3,
                                  title: 'Room Coordinates',
                                  isRequired:
                                      _selectedRoomType ==
                                      RoomType.asymmetrical,
                                  hintText:
                                      'Enter coordinates as: (x1,y1), (x2,y2), (x3,y3), ...\nExample: (0,0), (10,0), (10,8), (0,8)',
                                  // decoration: const InputDecoration(
                                  //   labelText: 'Room Coordinates',
                                  //   hintText: 'Enter coordinates as: (x1,y1), (x2,y2), (x3,y3), ...\nExample: (0,0), (10,0), (10,8), (0,8)',
                                  //   border: OutlineInputBorder(),
                                  //   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                  //   helperText: 'Coordinates should form a closed polygon',
                                  // ),
                                  onChanged: (String value) {
                                    // Auto-recalculate when coordinates change (with debounce)
                                    if (value.isNotEmpty &&
                                        _selectedRoomType ==
                                            RoomType.asymmetrical) {
                                      try {
                                        _parseRoomCoordinates(value);
                                        // Only recalculate if coordinates are valid
                                        Future<void>.delayed(
                                          const Duration(milliseconds: 500),
                                          () {
                                            if (_roomCoordinatesController
                                                    .text ==
                                                value) {
                                              _calculatePlacement();
                                            }
                                          },
                                        );
                                      } catch (e) {
                                        // Don't recalculate if coordinates are invalid
                                      }
                                    }
                                  },
                                  validator:
                                      _selectedRoomType == RoomType.asymmetrical
                                          ? (String? value) {
                                            if (value == null ||
                                                value.isEmpty) {
                                              return 'Room coordinates are required';
                                            }
                                            try {
                                              _parseRoomCoordinates(value);
                                              return null;
                                            } catch (e) {
                                              return 'Invalid coordinate format: ${e.toString()}';
                                            }
                                          }
                                          : null,
                                ),
                                const SizedBox(height: 8),
                                Container(
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.1),
                                    borderRadius: BorderRadius.circular(4),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'Quick Templates:',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 12,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 4,
                                        children: <Widget>[
                                          _buildTemplateButton(
                                            'Rectangle',
                                            '(0,0), (10,0), (10,8), (0,8)',
                                          ),
                                          _buildTemplateButton(
                                            'L-Shape',
                                            '(0,0), (10,0), (10,6), (4,6), (4,8), (0,8)',
                                          ),
                                          _buildTemplateButton(
                                            'U-Shape',
                                            '(0,8), (0,0), (10,0), (10,8), (7,8), (7,2), (3,2), (3,8)',
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),
                              const Text(
                                'Speaker Specifications',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Speaker Type
                              const Text(
                                'Speaker Type:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              FusionDropdownButtonFormField(
                                semanticKey:
                                    "ceiling_pendant_speaker_layout_speaker_type",
                                value: _selectedSpeakerType.name,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedSpeakerType = SpeakerType.values
                                        .firstWhere(
                                          (SpeakerType type) =>
                                              type.name == value,
                                        );
                                  });
                                  // Auto-recalculate when speaker type changes
                                  _calculatePlacement();
                                },
                                options:
                                    SpeakerType.values
                                        .map((SpeakerType type) => type.name)
                                        .toList(),
                                displayString: (String value) {
                                  final SpeakerType type = SpeakerType.values
                                      .firstWhere(
                                        (SpeakerType t) => t.name == value,
                                      );
                                  return _getSpeakerTypeLabel(type);
                                },
                                // items:
                                //     SpeakerType.values.map((SpeakerType type) {
                                //       return DropdownMenuItem<SpeakerType>(
                                //         value: type,
                                //         child: Text(_getSpeakerTypeLabel(type)),
                                //       );
                                //     }).toList(),
                                // decoration: const InputDecoration(
                                //   border: OutlineInputBorder(),
                                //   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                // ),
                              ),

                              const SizedBox(height: 12),
                              _buildNumberField(
                                controller: _coverageAngleController,
                                label: 'Coverage Angle (degrees)',
                                hint: 'Enter speaker coverage angle',
                                autoRecalculate: true,
                              ),

                              // Pendant Height (conditional)
                              if (_selectedSpeakerType ==
                                  SpeakerType.pendant) ...<Widget>[
                                const SizedBox(height: 12),
                                _buildNumberField(
                                  controller: _pendantHeightController,
                                  label: 'Pendant Height (m)',
                                  hint:
                                      'Enter pendant speaker height in meters',
                                ),
                              ],

                              const SizedBox(height: 24),
                              const Text(
                                'Layout Configuration',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              // Coverage Preference
                              const Text(
                                'Coverage Preference:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              FusionContainer(
                                child: DropdownButtonFormField<
                                  CoveragePreference
                                >(
                                  initialValue: _selectedCoveragePreference,
                                  onChanged: (CoveragePreference? value) {
                                    setState(() {
                                      _selectedCoveragePreference = value!;
                                    });
                                    // Auto-recalculate when coverage preference changes
                                    _calculatePlacement();
                                  },
                                  items:
                                      CoveragePreference.values.map((
                                        CoveragePreference pref,
                                      ) {
                                        return DropdownMenuItem<
                                          CoveragePreference
                                        >(
                                          value: pref,
                                          child: SizedBox(
                                            height:
                                                40, // Constrain height to prevent overflow
                                            child: Column(
                                              crossAxisAlignment:
                                                  CrossAxisAlignment.start,
                                              mainAxisSize: MainAxisSize.min,
                                              mainAxisAlignment:
                                                  MainAxisAlignment.center,
                                              children: <Widget>[
                                                Text(
                                                  _getCoveragePreferenceLabel(
                                                    pref,
                                                  ),
                                                  style: const TextStyle(
                                                    fontSize: 14,
                                                  ),
                                                ),
                                                Flexible(
                                                  child: Text(
                                                    pref.description,
                                                    style: TextStyle(
                                                      fontSize: 10,
                                                      color: Colors.grey
                                                          .withValues(
                                                            alpha: 0.6,
                                                          ),
                                                    ),
                                                    maxLines: 1,
                                                    overflow:
                                                        TextOverflow.ellipsis,
                                                  ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                    filled: false,
                                    enabledBorder: InputBorder.none,
                                    focusedBorder: InputBorder.none,
                                    errorBorder: InputBorder.none,
                                    contentPadding: EdgeInsets.symmetric(
                                      horizontal: 12,
                                      vertical: 8,
                                    ),
                                  ),
                                ),
                              ),

                              const SizedBox(height: 12),

                              // Layout Pattern
                              const Text(
                                'Layout Pattern:',
                                style: TextStyle(fontWeight: FontWeight.w500),
                              ),
                              const SizedBox(height: 8),
                              FusionDropdownButtonFormField(
                                semanticKey:
                                    "ceiling_pendant_speaker_layout_pattern",
                                value: _selectedLayoutPattern.name,
                                onChanged: (String? value) {
                                  setState(() {
                                    _selectedLayoutPattern = LayoutPattern
                                        .values
                                        .firstWhere(
                                          (LayoutPattern e) => e.name == value,
                                        );
                                  });
                                  // Auto-recalculate when layout pattern changes
                                  _calculatePlacement();
                                },
                                options:
                                    LayoutPattern.values
                                        .map(
                                          (LayoutPattern pattern) =>
                                              pattern.name,
                                        )
                                        .toList(),
                                displayString: (String value) {
                                  final LayoutPattern pattern = LayoutPattern
                                      .values
                                      .firstWhere(
                                        (LayoutPattern e) => e.name == value,
                                      );
                                  return _getLayoutPatternLabel(pattern);
                                },
                                // items:
                                //     LayoutPattern.values.map((LayoutPattern pattern) {
                                //       return DropdownMenuItem<LayoutPattern>(
                                //         value: pattern,
                                //         child: Text(_getLayoutPatternLabel(pattern)),
                                //       );
                                //     }).toList(),
                                // decoration: const InputDecoration(
                                //   border: OutlineInputBorder(),
                                //   contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                // ),
                              ),

                              const SizedBox(height: 16),

                              // Custom Origin
                              CheckboxListTile(
                                title: const Text('Use Custom Origin Offset'),
                                subtitle: const Text(
                                  'Adjust origin position relative to room centroid',
                                ),
                                value: _useCustomOrigin,
                                onChanged: (bool? value) {
                                  setState(() {
                                    _useCustomOrigin = value!;
                                    if (!_useCustomOrigin) {
                                      // Reset offsets when disabled
                                      _customOriginOffsetX = 0.0;
                                      _customOriginOffsetY = 0.0;
                                    }
                                  });
                                  // Auto-recalculate when custom origin option changes
                                  _calculatePlacement();
                                },
                                controlAffinity:
                                    ListTileControlAffinity.leading,
                                contentPadding: EdgeInsets.zero,
                              ),

                              if (_useCustomOrigin) ...<Widget>[
                                const SizedBox(height: 12),
                                Container(
                                  padding: const EdgeInsets.all(12),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.withValues(alpha: 0.05),
                                    borderRadius: BorderRadius.circular(8),
                                    border: Border.all(
                                      color: Colors.blue.withValues(alpha: 0.2),
                                    ),
                                  ),
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: <Widget>[
                                      const Text(
                                        'Origin Offset from Room Centroid',
                                        style: TextStyle(
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      const SizedBox(height: 8),
                                      Text(
                                        'Current offset: (${_customOriginOffsetX.toStringAsFixed(2)}, ${_customOriginOffsetY.toStringAsFixed(2)}) m',
                                        style: TextStyle(
                                          fontSize: 12,
                                          color: Colors.grey.withValues(
                                            alpha: 0.7,
                                          ),
                                          fontFamily: 'monospace',
                                        ),
                                      ),
                                      const SizedBox(height: 12),

                                      // X Offset Slider
                                      Text(
                                        'X Offset: ${_customOriginOffsetX.toStringAsFixed(2)} m',
                                      ),
                                      Slider(
                                        value: _customOriginOffsetX,
                                        min: -3.0,
                                        max: 3.0,
                                        divisions: 60,
                                        label:
                                            '${_customOriginOffsetX.toStringAsFixed(2)} m',
                                        onChanged: (double value) {
                                          setState(() {
                                            _customOriginOffsetX = value;
                                          });
                                        },
                                        onChangeEnd: (double value) {
                                          // Auto-recalculate when slider changes
                                          _calculatePlacement();
                                        },
                                      ),

                                      const SizedBox(height: 8),

                                      // Y Offset Slider
                                      Text(
                                        'Y Offset: ${_customOriginOffsetY.toStringAsFixed(2)} m',
                                      ),
                                      Slider(
                                        value: _customOriginOffsetY,
                                        min: -3.0,
                                        max: 3.0,
                                        divisions: 60,
                                        label:
                                            '${_customOriginOffsetY.toStringAsFixed(2)} m',
                                        onChanged: (double value) {
                                          setState(() {
                                            _customOriginOffsetY = value;
                                          });
                                        },
                                        onChangeEnd: (double value) {
                                          // Auto-recalculate when slider changes
                                          _calculatePlacement();
                                        },
                                      ),

                                      const SizedBox(height: 8),

                                      // Reset button
                                      Row(
                                        children: <Widget>[
                                          TextButton(
                                            onPressed: () {
                                              setState(() {
                                                _customOriginOffsetX = 0.0;
                                                _customOriginOffsetY = 0.0;
                                              });
                                              _calculatePlacement();
                                            },
                                            child: const Text(
                                              'Reset to Centroid',
                                            ),
                                          ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                              ],

                              const SizedBox(height: 24),

                              // Boundary Overlap Threshold
                              const Text(
                                'Boundary Filtering',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                              const SizedBox(height: 16),

                              Container(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: Colors.orange.withValues(alpha: 0.05),
                                  borderRadius: BorderRadius.circular(8),
                                  border: Border.all(
                                    color: Colors.orange.withValues(alpha: 0.2),
                                  ),
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const Text(
                                      'Coverage Overlap Threshold',
                                      style: TextStyle(
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                    const SizedBox(height: 8),
                                    Text(
                                      'Minimum percentage of speaker coverage that must be within room boundaries: ${(_boundaryOverlapThreshold * 100).toStringAsFixed(0)}%',
                                      style: TextStyle(
                                        fontSize: 12,
                                        color: Colors.grey.withValues(
                                          alpha: 0.7,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(height: 12),

                                    Text(
                                      'Boundary Threshold: ${(_boundaryOverlapThreshold * 100).toStringAsFixed(0)}%',
                                    ),
                                    Slider(
                                      value: _boundaryOverlapThreshold.clamp(
                                        0.01,
                                        0.9,
                                      ),
                                      min: 0.01,
                                      max: 0.9,
                                      // divisions: 12,
                                      label:
                                          '${(_boundaryOverlapThreshold * 100).toStringAsFixed(0)}%',
                                      onChanged: (double value) {
                                        setState(() {
                                          _boundaryOverlapThreshold = value
                                              .clamp(0.01, 0.9);
                                        });
                                      },
                                      onChangeEnd: (double value) {
                                        // Auto-recalculate when slider changes
                                        _calculatePlacement();
                                      },
                                    ),

                                    const SizedBox(height: 8),

                                    // Quick preset buttons
                                    Row(
                                      children: <Widget>[
                                        _buildThresholdPresetButton(
                                          'Conservative (90%)',
                                          0.9,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildThresholdPresetButton(
                                          'Balanced (70%)',
                                          0.7,
                                        ),
                                        const SizedBox(width: 8),
                                        _buildThresholdPresetButton(
                                          'Relaxed (50%)',
                                          0.5,
                                        ),
                                      ],
                                    ),

                                    const SizedBox(height: 8),

                                    Text(
                                      _boundaryOverlapThreshold >= 0.8
                                          ? '• Conservative: Speakers well inside room boundaries'
                                          : _boundaryOverlapThreshold >= 0.6
                                          ? '• Balanced: Good coverage with reasonable boundary margin'
                                          : '• Relaxed: Allows speakers closer to walls, more coverage',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: Colors.orange.withValues(
                                          alpha: 0.7,
                                        ),
                                        fontStyle: FontStyle.italic,
                                      ),
                                    ),
                                  ],
                                ),
                              ),

                              const SizedBox(height: 24),
                              SizedBox(
                                width: double.infinity,
                                child: ElevatedButton(
                                  onPressed:
                                      _isCalculating
                                          ? null
                                          : _calculatePlacement,
                                  style: ElevatedButton.styleFrom(
                                    padding: const EdgeInsets.symmetric(
                                      vertical: 16,
                                    ),
                                  ),
                                  child:
                                      _isCalculating
                                          ? const Row(
                                            mainAxisAlignment:
                                                MainAxisAlignment.center,
                                            children: <Widget>[
                                              SizedBox(
                                                width: 20,
                                                height: 20,
                                                child:
                                                    CircularProgressIndicator(
                                                      strokeWidth: 2,
                                                    ),
                                              ),
                                              SizedBox(width: 8),
                                              Text('Calculating...'),
                                            ],
                                          )
                                          : const Text(
                                            'Calculate Speaker Placement',
                                          ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(width: 8),

                  // Results Panel
                  Expanded(
                    flex: 3,
                    child: FusionFlatContainer(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Calculation Results',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 16),
                          Expanded(
                            child:
                                _result == null
                                    ? const Center(
                                      child: Text(
                                        'Enter room and speaker specifications, then click "Calculate Speaker Placement" to see results.',
                                        textAlign: TextAlign.center,
                                        style: TextStyle(
                                          fontSize: 16,
                                          color: Colors.grey,
                                        ),
                                      ),
                                    )
                                    : _buildResultsDisplay(),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = true,
    bool autoRecalculate = false,
  }) {
    return FusionTextFormField(
      semanticId: 'ceiling_pendant_speaker_layout_number_field',
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      title: label,
      hintText: hint,
      isRequired: required,
      // decoration: InputDecoration(
      //   labelText: label,
      //   hintText: hint,
      //   border: const OutlineInputBorder(),
      //   contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      // ),
      onChanged:
          autoRecalculate
              ? (String value) {
                // Auto-recalculate when value changes (with debounce)
                if (value.isNotEmpty && double.tryParse(value) != null) {
                  Future<void>.delayed(const Duration(milliseconds: 800), () {
                    if (controller.text == value) {
                      _calculatePlacement();
                    }
                  });
                }
              }
              : null,
      validator:
          required
              ? (String? value) {
                if (value == null || value.isEmpty) {
                  return 'This field is required';
                }
                if (double.tryParse(value) == null) {
                  return 'Please enter a valid number';
                }
                return null;
              }
              : null,
    );
  }

  Widget _buildTemplateButton(String label, String coordinates) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _roomCoordinatesController.text = coordinates;
        });
        // Automatically calculate placement when template is selected
        Future<void>.delayed(const Duration(milliseconds: 100), () {
          _calculatePlacement();
        });
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(60, 28),
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  Widget _buildThresholdPresetButton(String label, double threshold) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _boundaryOverlapThreshold = threshold.clamp(0.3, 0.9);
        });
        // Automatically calculate placement when preset is selected
        _calculatePlacement();
      },
      style: ElevatedButton.styleFrom(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
        minimumSize: const Size(60, 28),
        backgroundColor:
            (_boundaryOverlapThreshold - threshold).abs() < 0.001
                ? Theme.of(context).primaryColor
                : null,
        foregroundColor:
            (_boundaryOverlapThreshold - threshold).abs() < 0.001
                ? Colors.white
                : null,
      ),
      child: Text(
        label,
        style: const TextStyle(fontSize: 10),
      ),
    );
  }

  List<Point2D> _parseRoomCoordinates(String input) {
    final List<Point2D> points = <Point2D>[];

    // Remove any extra whitespace and split by commas outside parentheses
    final String cleaned = input.trim();

    // Use regex to find coordinate pairs in the format (x,y)
    final RegExp regex = RegExp(
      r'\(\s*([+-]?\d*\.?\d+)\s*,\s*([+-]?\d*\.?\d+)\s*\)',
    );
    final Iterable<RegExpMatch> matches = regex.allMatches(cleaned);

    if (matches.isEmpty) {
      throw const FormatException(
        'No valid coordinate pairs found. Use format: (x,y), (x,y), ...',
      );
    }

    for (final RegExpMatch match in matches) {
      final double x = double.parse(match.group(1)!);
      final double y = double.parse(match.group(2)!);
      points.add(Point2D(x, y));
    }

    if (points.length < 3) {
      throw const FormatException(
        'At least 3 coordinate pairs are required to form a room',
      );
    }

    return points;
  }

  Widget _buildResultsDisplay() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Summary Card
          FusionFlatContainer(
            color: Colors.blue.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Text(
                    'Placement Summary',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildSummaryRow(
                    'Number of Speakers:',
                    '${_result!.speakerPositions.length}',
                  ),
                  _buildSummaryRow(
                    'Grid Spacing:',
                    '${_result!.gridSpacing.toStringAsFixed(2)} m',
                  ),

                  // Show origin information based on whether custom offset is used
                  if (_result!.customOriginOffset != null) ...<Widget>[
                    _buildSummaryRow(
                      'Base Centroid:',
                      '${_result!.baseCentroid}',
                    ),
                    _buildSummaryRow(
                      'Custom Offset:',
                      '${_result!.customOriginOffset}',
                    ),
                    _buildSummaryRow(
                      'Effective Origin:',
                      '${_result!.centroid}',
                    ),
                  ] else ...<Widget>[
                    _buildSummaryRow(
                      'Origin (Centroid):',
                      '${_result!.centroid}',
                    ),
                  ],

                  _buildSummaryRow(
                    'Distance:',
                    '${_result!.distance.toStringAsFixed(2)} m',
                  ),
                  _buildSummaryRow(
                    'Boundary Threshold:',
                    '${(_boundaryOverlapThreshold * 100).toStringAsFixed(0)}%',
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // All Grid Coordinates Section
          if (_allGridPoints != null && _allGridPoints!.isNotEmpty) ...<Widget>[
            const Text(
              'All Grid Coordinates (Before Filtering)',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FusionFlatContainer(
              color: Colors.grey.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.info_outline,
                          color: Colors.blue.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Total grid positions generated: ${_allGridPoints!.length}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 200, // Fixed height with scrolling
                      child: SingleChildScrollView(
                        child: Column(
                          children: <Widget>[
                            for (int i = 0; i < _allGridPoints!.length; i++)
                              Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 2.0,
                                ),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color:
                                            _result!.speakerPositions.any(
                                                  (Point2D validPos) =>
                                                      (_allGridPoints![i].x -
                                                                  validPos.x)
                                                              .abs() <
                                                          0.001 &&
                                                      (_allGridPoints![i].y -
                                                                  validPos.y)
                                                              .abs() <
                                                          0.001,
                                                )
                                                ? Colors.green
                                                : Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _result!.speakerPositions.any(
                                                (Point2D validPos) =>
                                                    (_allGridPoints![i].x -
                                                                validPos.x)
                                                            .abs() <
                                                        0.001 &&
                                                    (_allGridPoints![i].y -
                                                                validPos.y)
                                                            .abs() <
                                                        0.001,
                                              )
                                              ? Icons.check
                                              : Icons.close,
                                          color: Colors.white,
                                          size: 14,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Text(
                                        'Grid ${i + 1}: (${_allGridPoints![i].x.toStringAsFixed(2)}, ${_allGridPoints![i].y.toStringAsFixed(2)})',
                                        style: const TextStyle(
                                          fontFamily: 'monospace',
                                          fontSize: 12,
                                        ),
                                      ),
                                    ),
                                    Text(
                                      _result!.speakerPositions.any(
                                            (Point2D validPos) =>
                                                (_allGridPoints![i].x -
                                                            validPos.x)
                                                        .abs() <
                                                    0.001 &&
                                                (_allGridPoints![i].y -
                                                            validPos.y)
                                                        .abs() <
                                                    0.001,
                                          )
                                          ? 'VALID'
                                          : 'FILTERED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color:
                                            _result!.speakerPositions.any(
                                                  (Point2D validPos) =>
                                                      (_allGridPoints![i].x -
                                                                  validPos.x)
                                                              .abs() <
                                                          0.001 &&
                                                      (_allGridPoints![i].y -
                                                                  validPos.y)
                                                              .abs() <
                                                          0.001,
                                                )
                                                ? Colors.green.withValues(
                                                  alpha: 0.7,
                                                )
                                                : Colors.red.withValues(
                                                  alpha: 0.7,
                                                ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Removed Points Section
          if (_removedPoints != null && _removedPoints!.isNotEmpty) ...<Widget>[
            const Text(
              'Filtered Out Positions',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            FusionFlatContainer(
              color: Colors.red.withValues(alpha: 0.05),
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          Icons.warning_outlined,
                          color: Colors.red.withValues(alpha: 0.7),
                          size: 16,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Positions removed due to boundary filtering: ${_removedPoints!.length}',
                          style: const TextStyle(fontWeight: FontWeight.w500),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Wrap(
                      spacing: 8,
                      runSpacing: 4,
                      children: <Widget>[
                        for (int i = 0; i < _removedPoints!.length; i++)
                          Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 4,
                            ),
                            decoration: BoxDecoration(
                              color: Colors.red.withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(
                                color: Colors.red.withValues(alpha: 0.3),
                              ),
                            ),
                            child: Text(
                              '(${_removedPoints![i].x.toStringAsFixed(2)}, ${_removedPoints![i].y.toStringAsFixed(2)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.red.withValues(alpha: 0.8),
                              ),
                            ),
                          ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      'These positions were filtered because they were too close to room boundaries (within ${(_result!.gridSpacing * _selectedCoveragePreference.overlapMultiplier).toStringAsFixed(2)}m margin).',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.red.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Speaker Positions
          const Text(
            'Speaker Positions',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FusionFlatContainer(
            color: context.colorScheme.elevation1,
            child: Column(
              children: <Widget>[
                for (int i = 0; i < _result!.speakerPositions.length; i++)
                  Padding(
                    padding: const EdgeInsets.symmetric(vertical: 4.0),
                    child: Row(
                      children: <Widget>[
                        Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: Colors.blue,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(
                                color: Colors.white,
                                fontSize: 12,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Text(
                          'Speaker ${i + 1}: (${_result!.speakerPositions[i].x.toStringAsFixed(2)}, ${_result!.speakerPositions[i].y.toStringAsFixed(2)})',
                          style: const TextStyle(fontFamily: 'monospace'),
                        ),
                      ],
                    ),
                  ),
              ],
            ),
          ),

          const SizedBox(height: 16),

          // Step-by-Step Calculations
          const Text(
            'Step-by-Step Calculations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          FusionFlatContainer(
            color: context.colorScheme.elevation2,
            borderColor: context.colorScheme.elevation2,
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  for (String step in _result!.calculationSteps)
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 2.0),
                      child: Text(
                        step,
                        style: const TextStyle(
                          fontFamily: 'monospace',
                          fontSize: 13,
                        ),
                      ),
                    ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 16),

          // Visual Representation
          const Text(
            'Visual Layout',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: _buildVisualLayout(),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualLayout() {
    if (_result == null) return const SizedBox.shrink();

    // Calculate room dimensions for visualization
    final double roomWidth = double.parse(_roomWidthController.text);
    final double roomLength = double.parse(_roomLengthController.text);

    // Create room geometry - for now using rectangular, but can be extended to support custom polygons
    final List<Point2D> roomGeometry = _generateRoomGeometry(
      roomWidth,
      roomLength,
    );

    return Column(
      children: <Widget>[
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildLegendItem(
              icon:
                  _selectedSpeakerType == SpeakerType.ceiling
                      ? Icons.speaker
                      : Icons.campaign,
              label: _getSpeakerTypeLabel(_selectedSpeakerType),
              color: Colors.blue,
            ),
            _buildLegendItem(
              icon: Icons.center_focus_strong,
              label: 'Base Centroid',
              color: Colors.blue,
            ),
            if (_result!.customOriginOffset != null)
              _buildLegendItem(
                icon: Icons.location_on,
                label: 'Effective Origin',
                color: Colors.red,
              ),
            if (_removedPoints != null && _removedPoints!.isNotEmpty)
              _buildLegendItem(
                icon: Icons.close,
                label: 'Filtered Points',
                color: Colors.red.withOpacity(0.7),
              ),
            _buildLegendItem(
              icon: Icons.crop_square,
              label: 'Room Boundary',
              color: Colors.grey,
            ),
          ],
        ),

        const SizedBox(height: 16),

        // Room Layout Visualization using CustomPainter
        Container(
          width: 400,
          height: 350,
          decoration: BoxDecoration(
            color: Colors.grey.withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
          ),
          child: CustomPaint(
            size: const Size(400, 350),
            painter: RoomLayoutPainter(
              roomGeometry: roomGeometry,
              speakerPositions: _result!.speakerPositions,
              allGridPoints: _allGridPoints ?? <Point2D>[],
              removedPoints: _removedPoints ?? <Point2D>[],
              centroid: _result!.centroid,
              baseCentroid: _result!.baseCentroid,
              customOriginOffset: _result!.customOriginOffset,
              gridSpacing: _result!.gridSpacing,
              speakerType: _selectedSpeakerType,
              layoutPattern: _selectedLayoutPattern,
              colorscheme: context.colorScheme,
            ),
          ),
        ),

        const SizedBox(height: 16),

        // Coordinate system info for custom rooms
        if (_selectedRoomType == RoomType.asymmetrical)
          Card(
            color: Colors.green.withValues(alpha: 0.05),
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        color: Colors.green.withValues(alpha: 0.7),
                        size: 16,
                      ),
                      const SizedBox(width: 8),
                      const Text(
                        'Custom Room Coordinates',
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 14,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  const Text(
                    '• Origin (0,0) is at bottom-left corner\n'
                    '• X-axis increases to the right\n'
                    '• Y-axis increases upward\n'
                    '• Coordinates define room boundary vertices\n'
                    '• Last point automatically connects to first point',
                    style: TextStyle(fontSize: 12),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Current room shape: ${_selectedRoomType == RoomType.asymmetrical ? "Custom polygon" : "Rectangle"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green.withValues(alpha: 0.7),
                    ),
                  ),
                ],
              ),
            ),
          ),

        const SizedBox(height: 16),

        // Layout Stats
        _buildLayoutStats(),
      ],
    );
  }

  Widget _buildLegendItem({
    required IconData icon,
    required String label,
    required Color color,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Text(
          label,
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }

  List<Point2D> _generateRoomGeometry(double width, double length) {
    if (_selectedRoomType == RoomType.asymmetrical &&
        _roomCoordinatesController.text.isNotEmpty) {
      try {
        return _parseRoomCoordinates(_roomCoordinatesController.text);
      } catch (e) {
        // Fallback to rectangle if parsing fails
        debugPrint('Error parsing custom coordinates: $e');
      }
    }

    // Default rectangle using width and length
    return <Point2D>[
      const Point2D(0, 0),
      Point2D(width, 0),
      Point2D(width, length),
      Point2D(0, length),
    ];
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Column(
      children: <Widget>[
        Icon(icon, color: Colors.blue.withValues(alpha: 0.7), size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey.withValues(alpha: 0.6),
          ),
        ),
        Text(
          value,
          style: const TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
          ),
        ),
      ],
    );
  }

  Widget _buildLayoutStats() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withValues(alpha: 0.05),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.2)),
      ),
      child: Column(
        children: <Widget>[
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildStatItem(
                icon: Icons.grid_on,
                label: 'Pattern',
                value: _getLayoutPatternLabel(_selectedLayoutPattern),
              ),
              _buildStatItem(
                icon: Icons.straighten,
                label: 'Spacing',
                value: '${_result!.gridSpacing.toStringAsFixed(1)} m',
              ),
              _buildStatItem(
                icon: Icons.settings_input_antenna,
                label: 'Coverage',
                value:
                    _getCoveragePreferenceLabel(
                      _selectedCoveragePreference,
                    ).split(' ')[0],
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceEvenly,
            children: <Widget>[
              _buildStatItem(
                icon: Icons.height,
                label: 'Distance',
                value: '${_result!.distance.toStringAsFixed(1)} m',
              ),
              _buildStatItem(
                icon: Icons.calculate,
                label: 'Total Speakers',
                value: '${_result!.speakerPositions.length}',
              ),
              _buildStatItem(
                icon: Icons.rotate_right,
                label: 'Coverage Angle',
                value: '${_coverageAngleController.text}°',
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        children: <Widget>[
          Expanded(
            flex: 2,
            child: Text(
              label,
              style: const TextStyle(fontWeight: FontWeight.w500),
            ),
          ),
          Expanded(
            flex: 3,
            child: Text(
              value,
              style: const TextStyle(fontFamily: 'monospace'),
            ),
          ),
        ],
      ),
    );
  }

  String _getSpeakerTypeLabel(SpeakerType type) {
    switch (type) {
      case SpeakerType.ceiling:
        return 'Ceiling-mounted';
      case SpeakerType.pendant:
        return 'Pendant-mounted';
    }
  }

  String _getCoveragePreferenceLabel(CoveragePreference pref) {
    switch (pref) {
      case CoveragePreference.edgeToEdge:
        return 'Edge to Edge';
      case CoveragePreference.minimumOverlap:
        return 'Minimum Overlap (Recommended)';
      case CoveragePreference.centerToCenter:
        return 'Center to Center';
    }
  }

  String _getLayoutPatternLabel(LayoutPattern pattern) {
    switch (pattern) {
      case LayoutPattern.square:
        return 'Square Grid';
      case LayoutPattern.hexagonal:
        return 'Hexagonal Grid';
    }
  }
}

/// Custom painter for drawing asymmetrical room layouts with speaker placement
class RoomLayoutPainter extends CustomPainter {
  final List<Point2D> roomGeometry;
  final List<Point2D> speakerPositions;
  final List<Point2D> allGridPoints;
  final List<Point2D> removedPoints;
  final Point2D centroid; // Effective origin used for calculations
  final Point2D baseCentroid; // Original room centroid
  final Point2D? customOriginOffset; // Custom offset applied
  final double gridSpacing;
  final SpeakerType speakerType;
  final LayoutPattern layoutPattern;
  final ColorScheme colorscheme;
  RoomLayoutPainter({
    required this.roomGeometry,
    required this.speakerPositions,
    required this.allGridPoints,
    required this.removedPoints,
    required this.centroid,
    required this.baseCentroid,
    this.customOriginOffset,
    required this.gridSpacing,
    required this.speakerType,
    required this.layoutPattern,
    required this.colorscheme,
  });

  @override
  void paint(Canvas canvas, Size size) {
    // Calculate bounds and scaling
    final RoomBounds bounds = _calculateBounds();
    final double scaleFactor = _calculateScaleFactor(bounds, size);
    final Offset offset = _calculateOffset(bounds, size, scaleFactor);

    // Draw room boundary
    _drawRoomBoundary(canvas, scaleFactor, offset);

    // Draw grid pattern (optional)
    if (layoutPattern == LayoutPattern.hexagonal) {
      _drawHexagonalGrid(canvas, scaleFactor, offset);
    } else {
      _drawSquareGrid(canvas, scaleFactor, offset);
    }

    // Draw coverage areas
    _drawCoverageAreas(canvas, scaleFactor, offset);

    // Draw centroid
    _drawCentroid(canvas, scaleFactor, offset);

    // Draw removed points
    _drawRemovedPoints(canvas, scaleFactor, offset);

    // Draw speakers
    _drawSpeakers(canvas, scaleFactor, offset);

    // Draw dimensions
    _drawDimensions(canvas, scaleFactor, offset, size);
  }

  RoomBounds _calculateBounds() {
    double minX = roomGeometry.first.x;
    double maxX = roomGeometry.first.x;
    double minY = roomGeometry.first.y;
    double maxY = roomGeometry.first.y;

    for (final Point2D point in roomGeometry) {
      minX = min(minX, point.x);
      maxX = max(maxX, point.x);
      minY = min(minY, point.y);
      maxY = max(maxY, point.y);
    }

    return RoomBounds(minX: minX, maxX: maxX, minY: minY, maxY: maxY);
  }

  double _calculateScaleFactor(RoomBounds bounds, Size size) {
    const double padding = 60.0; // Leave space for labels and padding
    final double availableWidth = size.width - padding;
    final double availableHeight = size.height - padding;

    final double roomWidth = bounds.maxX - bounds.minX;
    final double roomHeight = bounds.maxY - bounds.minY;

    final double scaleX = availableWidth / roomWidth;
    final double scaleY = availableHeight / roomHeight;

    return min(scaleX, scaleY) * 0.8; // Scale down a bit for aesthetics
  }

  Offset _calculateOffset(RoomBounds bounds, Size size, double scaleFactor) {
    final double roomWidth = bounds.maxX - bounds.minX;
    final double roomHeight = bounds.maxY - bounds.minY;

    final double scaledWidth = roomWidth * scaleFactor;
    final double scaledHeight = roomHeight * scaleFactor;

    final double offsetX =
        (size.width - scaledWidth) / 2 - bounds.minX * scaleFactor;
    // Adjust Y offset for bottom-left origin coordinate system
    final double offsetY =
        (size.height - scaledHeight) / 2 - bounds.minY * scaleFactor;

    return Offset(offsetX, offsetY);
  }

  void _drawRoomBoundary(Canvas canvas, double scaleFactor, Offset offset) {
    final Paint paint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.6)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    final Paint fillPaint =
        Paint()
          ..color = Colors.white
          ..style = PaintingStyle.fill;

    final Path path = Path();

    // Create path from room geometry points
    if (roomGeometry.isNotEmpty) {
      final Offset firstPoint = _transformPoint(
        roomGeometry.first,
        scaleFactor,
        offset,
      );
      path.moveTo(firstPoint.dx, firstPoint.dy);

      for (int i = 1; i < roomGeometry.length; i++) {
        final Offset point = _transformPoint(
          roomGeometry[i],
          scaleFactor,
          offset,
        );
        path.lineTo(point.dx, point.dy);
      }

      path.close();
    }

    // Draw filled room area
    canvas.drawPath(path, fillPaint);

    // Draw room boundary
    canvas.drawPath(path, paint);
  }

  void _drawSquareGrid(Canvas canvas, double scaleFactor, Offset offset) {
    final Paint paint =
        Paint()
          ..color = Colors.grey.withValues(alpha: 0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    final RoomBounds bounds = _calculateBounds();

    // Draw vertical lines
    for (double x = bounds.minX; x <= bounds.maxX; x += gridSpacing) {
      final Offset startPoint = _transformPoint(
        Point2D(x, bounds.minY),
        scaleFactor,
        offset,
      );
      final Offset endPoint = _transformPoint(
        Point2D(x, bounds.maxY),
        scaleFactor,
        offset,
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }

    // Draw horizontal lines
    for (double y = bounds.minY; y <= bounds.maxY; y += gridSpacing) {
      final Offset startPoint = _transformPoint(
        Point2D(bounds.minX, y),
        scaleFactor,
        offset,
      );
      final Offset endPoint = _transformPoint(
        Point2D(bounds.maxX, y),
        scaleFactor,
        offset,
      );
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }

  void _drawHexagonalGrid(Canvas canvas, double scaleFactor, Offset offset) {
    // For hexagonal, we'll draw a more subtle indication
    final Paint paint =
        Paint()
          ..color = Colors.orange.withValues(alpha: 0.2)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 0.5;

    // Draw diagonal lines to indicate hexagonal pattern
    final RoomBounds bounds = _calculateBounds();

    for (double x = bounds.minX; x <= bounds.maxX; x += gridSpacing) {
      for (double y = bounds.minY; y <= bounds.maxY; y += gridSpacing * 0.866) {
        final Offset centerPoint = _transformPoint(
          Point2D(x, y),
          scaleFactor,
          offset,
        );
        final double radius = gridSpacing * scaleFactor * 0.3;

        // Draw small hexagon outline
        final Path path = Path();
        for (int i = 0; i < 6; i++) {
          final double angle = (i * pi) / 3;
          final double pointX = centerPoint.dx + radius * cos(angle);
          final double pointY = centerPoint.dy + radius * sin(angle);

          if (i == 0) {
            path.moveTo(pointX, pointY);
          } else {
            path.lineTo(pointX, pointY);
          }
        }
        path.close();
        canvas.drawPath(path, paint);
      }
    }
  }

  void _drawCoverageAreas(Canvas canvas, double scaleFactor, Offset offset) {
    final Paint paint =
        Paint()
          ..color = Colors.blue.withOpacity(0.15)
          ..style = PaintingStyle.fill;

    final Paint strokePaint =
        Paint()
          ..color = Colors.blue.withOpacity(0.3)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.0;

    for (final Point2D speakerPos in speakerPositions) {
      final Offset center = _transformPoint(speakerPos, scaleFactor, offset);
      final double radius = (gridSpacing * scaleFactor) / 2;

      canvas.drawCircle(center, radius, paint);
      canvas.drawCircle(center, radius, strokePaint);
    }
  }

  void _drawCentroid(Canvas canvas, double scaleFactor, Offset offset) {
    // Draw base centroid (always present)
    final Offset baseCenterPoint = _transformPoint(
      baseCentroid,
      scaleFactor,
      offset,
    );

    final Paint basePaint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

    canvas.drawCircle(baseCenterPoint, 6, basePaint);

    // Draw cross lines for base centroid
    final Paint baseLinePaint =
        Paint()
          ..color = Colors.blue
          ..strokeWidth = 2.0;

    canvas.drawLine(
      Offset(baseCenterPoint.dx - 10, baseCenterPoint.dy),
      Offset(baseCenterPoint.dx + 10, baseCenterPoint.dy),
      baseLinePaint,
    );
    canvas.drawLine(
      Offset(baseCenterPoint.dx, baseCenterPoint.dy - 10),
      Offset(baseCenterPoint.dx, baseCenterPoint.dy + 10),
      baseLinePaint,
    );

    // Draw effective origin (if different from base centroid)
    if (customOriginOffset != null) {
      final Offset effectiveCenter = _transformPoint(
        centroid,
        scaleFactor,
        offset,
      );

      final Paint paint =
          Paint()
            ..color = Colors.red
            ..style = PaintingStyle.fill;

      canvas.drawCircle(effectiveCenter, 8, paint);

      // Draw cross lines for effective origin
      final Paint linePaint =
          Paint()
            ..color = Colors.red
            ..strokeWidth = 2.0;

      canvas.drawLine(
        Offset(effectiveCenter.dx - 12, effectiveCenter.dy),
        Offset(effectiveCenter.dx + 12, effectiveCenter.dy),
        linePaint,
      );
      canvas.drawLine(
        Offset(effectiveCenter.dx, effectiveCenter.dy - 12),
        Offset(effectiveCenter.dx, effectiveCenter.dy + 12),
        linePaint,
      );

      // Draw line connecting base centroid to effective origin
      final Paint connectionPaint =
          Paint()
            ..color = Colors.orange
            ..strokeWidth = 1.5
            ..style = PaintingStyle.stroke;

      canvas.drawLine(baseCenterPoint, effectiveCenter, connectionPaint);

      // Draw offset arrow
      _drawArrow(canvas, baseCenterPoint, effectiveCenter, connectionPaint);
    }
  }

  /// Draw an arrow from start to end point
  void _drawArrow(Canvas canvas, Offset start, Offset end, Paint paint) {
    const double arrowLength = 8.0;
    const double arrowAngle = 0.5; // radians

    // Calculate direction vector
    final Offset direction = end - start;
    final double length = direction.distance;

    if (length < arrowLength * 2)
      return; // Don't draw arrow if line is too short

    final Offset unitDirection = direction / length;

    // Calculate arrow head points
    final double angle = atan2(unitDirection.dy, unitDirection.dx);

    final Offset arrowHead1 =
        end +
        Offset(
          -arrowLength * cos(angle - arrowAngle),
          -arrowLength * sin(angle - arrowAngle),
        );

    final Offset arrowHead2 =
        end +
        Offset(
          -arrowLength * cos(angle + arrowAngle),
          -arrowLength * sin(angle + arrowAngle),
        );

    // Draw arrow head
    canvas.drawLine(end, arrowHead1, paint);
    canvas.drawLine(end, arrowHead2, paint);
  }

  void _drawRemovedPoints(Canvas canvas, double scaleFactor, Offset offset) {
    final Paint paint =
        Paint()
          ..color = Colors.red.withOpacity(0.6)
          ..style = PaintingStyle.fill;

    final Paint borderPaint =
        Paint()
          ..color = Colors.red
          ..style = PaintingStyle.stroke
          ..strokeWidth = 1.5;

    for (final Point2D removedPos in removedPoints) {
      final Offset center = _transformPoint(removedPos, scaleFactor, offset);

      // Draw removed point as X
      canvas.drawCircle(center, 8, paint);
      canvas.drawCircle(center, 8, borderPaint);

      // Draw X mark
      final Paint xPaint =
          Paint()
            ..color = Colors.white
            ..strokeWidth = 2.0
            ..strokeCap = StrokeCap.round;

      canvas.drawLine(
        Offset(center.dx - 4, center.dy - 4),
        Offset(center.dx + 4, center.dy + 4),
        xPaint,
      );
      canvas.drawLine(
        Offset(center.dx - 4, center.dy + 4),
        Offset(center.dx + 4, center.dy - 4),
        xPaint,
      );
    }
  }

  void _drawSpeakers(Canvas canvas, double scaleFactor, Offset offset) {
    final Paint paint =
        Paint()
          ..color = Colors.blue
          ..style = PaintingStyle.fill;

    final Paint borderPaint =
        Paint()
          ..color = Colors.blue.withValues(alpha: 0.8)
          ..style = PaintingStyle.stroke
          ..strokeWidth = 2.0;

    for (int i = 0; i < speakerPositions.length; i++) {
      final Offset center = _transformPoint(
        speakerPositions[i],
        scaleFactor,
        offset,
      );

      // Draw speaker circle
      canvas.drawCircle(center, 12, paint);
      canvas.drawCircle(center, 12, borderPaint);

      // Draw speaker number
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 10,
            fontWeight: FontWeight.bold,
          ),
        ),
        textDirection: TextDirection.ltr,
      );

      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          center.dx - textPainter.width / 2,
          center.dy - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawDimensions(
    Canvas canvas,
    double scaleFactor,
    Offset offset,
    Size size,
  ) {
    final RoomBounds bounds = _calculateBounds();
    final double roomWidth = bounds.maxX - bounds.minX;
    final double roomHeight = bounds.maxY - bounds.minY;

    // Draw width dimension
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '${roomWidth.toStringAsFixed(1)} m',
        style: TextStyle(
          // color: Colors.black87,
          color: colorscheme.textBody,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    textPainter.layout();
    textPainter.paint(
      canvas,
      Offset(size.width / 2 - textPainter.width / 2, 10),
    );

    // Draw height dimension (rotated)
    final TextPainter heightPainter = TextPainter(
      text: TextSpan(
        text: '${roomHeight.toStringAsFixed(1)} m',
        style: TextStyle(
          color: colorscheme.textBody,

          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );

    heightPainter.layout();

    canvas.save();
    canvas.translate(15, size.height / 2 + heightPainter.width / 2);
    canvas.rotate(-pi / 2);
    heightPainter.paint(canvas, Offset.zero);
    canvas.restore();
  }

  Offset _transformPoint(Point2D point, double scaleFactor, Offset offset) {
    final RoomBounds bounds = _calculateBounds();
    final double roomHeight = bounds.maxY - bounds.minY;

    return Offset(
      point.x * scaleFactor + offset.dx,
      // Flip Y coordinate to have (0,0) at bottom-left
      (roomHeight - point.y) * scaleFactor + offset.dy,
    );
  }

  @override
  bool shouldRepaint(covariant RoomLayoutPainter oldDelegate) {
    return roomGeometry != oldDelegate.roomGeometry ||
        speakerPositions != oldDelegate.speakerPositions ||
        allGridPoints != oldDelegate.allGridPoints ||
        removedPoints != oldDelegate.removedPoints ||
        centroid != oldDelegate.centroid ||
        baseCentroid != oldDelegate.baseCentroid ||
        customOriginOffset != oldDelegate.customOriginOffset ||
        gridSpacing != oldDelegate.gridSpacing ||
        speakerType != oldDelegate.speakerType ||
        layoutPattern != oldDelegate.layoutPattern;
  }
}

/// Helper class to represent room bounds
class RoomBounds {
  final double minX;
  final double maxX;
  final double minY;
  final double maxY;

  const RoomBounds({
    required this.minX,
    required this.maxX,
    required this.minY,
    required this.maxY,
  });
}
