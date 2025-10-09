import 'dart:math';
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';

class CeilingPendantSpeakerLayoutWidget extends StatefulWidget {
  const CeilingPendantSpeakerLayoutWidget({super.key});

  @override
  State<CeilingPendantSpeakerLayoutWidget> createState() => _CeilingPendantSpeakerLayoutWidgetState();
}

class _CeilingPendantSpeakerLayoutWidgetState extends State<CeilingPendantSpeakerLayoutWidget> {
  // Form controllers
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  final TextEditingController _roomWidthController = TextEditingController(text: '6.1');
  final TextEditingController _roomLengthController = TextEditingController(text: '4.6');
  final TextEditingController _ceilingHeightController = TextEditingController(text: '2.7');
  final TextEditingController _listenerHeightController = TextEditingController(text: '1.2');
  final TextEditingController _coverageAngleController = TextEditingController(text: '90.0');
  final TextEditingController _pendantHeightController = TextEditingController(text: '2.1');
  final TextEditingController _customXController = TextEditingController();
  final TextEditingController _customYController = TextEditingController();
  final TextEditingController _roomCoordinatesController = TextEditingController(
    text: '(0,0), (6.1,0), (6.1,4.6), (0,4.6)', // Default rectangle
  );

  // Form state
  SpeakerType _selectedSpeakerType = SpeakerType.ceiling;
  CoveragePreference _selectedCoveragePreference = CoveragePreference.minimumOverlap;
  LayoutPattern _selectedLayoutPattern = LayoutPattern.square;
  bool _useCustomOrigin = false;
  bool _useCustomRoomShape = false;
  
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
    _customXController.dispose();
    _customYController.dispose();
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
      // Create room
      final Room room = Room(
        width: double.parse(_roomWidthController.text),
        roomLength: double.parse(_roomLengthController.text),
        ceilingHeight: double.parse(_ceilingHeightController.text),
        listenerHeight: double.parse(_listenerHeightController.text),
      );

      // Create speaker spec
      final SpeakerSpec speakerSpec = SpeakerSpec(
        coverageAngle: double.parse(_coverageAngleController.text),
        type: _selectedSpeakerType,
        pendantHeight: _selectedSpeakerType == SpeakerType.pendant 
            ? double.tryParse(_pendantHeightController.text)
            : null,
      );

      // Create custom origin if specified
      Point2D? customOrigin;
      if (_useCustomOrigin && 
          _customXController.text.isNotEmpty && 
          _customYController.text.isNotEmpty) {
        customOrigin = Point2D(
          double.parse(_customXController.text),
          double.parse(_customYController.text),
        );
      }

      // Calculate placement with enhanced details
      final PlacementResult result = AutoSpeakerPlacement.calculatePlacement(
        room: room,
        speakerSpec: speakerSpec,
        coveragePreference: _selectedCoveragePreference,
        layoutPattern: _selectedLayoutPattern,
        customOrigin: customOrigin,
      );

      // Generate all grid points for display purposes
      final List<Point2D> allGridPoints = _generateAllGridPoints(room, result, _selectedLayoutPattern);
      final List<Point2D> removedPoints = _calculateRemovedPoints(allGridPoints, result.speakerPositions);

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
  List<Point2D> _generateAllGridPoints(Room room, PlacementResult result, LayoutPattern pattern) {
    final List<Point2D> points = <Point2D>[];
    
    // Safety check for grid spacing
    if (result.gridSpacing <= 0 || !result.gridSpacing.isFinite) {
      return points;
    }
    
    // Always include the centroid
    points.add(result.centroid);
    
    if (pattern == LayoutPattern.square) {
      // Generate square grid
      final double maxStepsXDouble = (room.width - result.centroid.x) / result.gridSpacing;
      final double maxStepsYDouble = (room.roomLength - result.centroid.y) / result.gridSpacing;
      final double minStepsXDouble = result.centroid.x / result.gridSpacing;
      final double minStepsYDouble = result.centroid.y / result.gridSpacing;
      
      if (maxStepsXDouble.isFinite && maxStepsYDouble.isFinite && 
          minStepsXDouble.isFinite && minStepsYDouble.isFinite) {
        
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
      
      final double maxStepsXDouble = (room.width - result.centroid.x) / horizontalSpacing;
      final double maxStepsYDouble = (room.roomLength - result.centroid.y) / verticalSpacing;
      final double minStepsXDouble = result.centroid.x / horizontalSpacing;
      final double minStepsYDouble = result.centroid.y / verticalSpacing;
      
      if (maxStepsXDouble.isFinite && maxStepsYDouble.isFinite && 
          minStepsXDouble.isFinite && minStepsYDouble.isFinite) {
        
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
  List<Point2D> _calculateRemovedPoints(List<Point2D> allPoints, List<Point2D> validPoints) {
    final List<Point2D> removedPoints = <Point2D>[];
    
    for (Point2D point in allPoints) {
      final bool isValid = validPoints.any((Point2D validPos) => 
        (point.x - validPos.x).abs() < 0.001 && (point.y - validPos.y).abs() < 0.001);
      
      if (!isValid) {
        removedPoints.add(point);
      }
    }
    
    return removedPoints;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Ceiling/Pendant Speaker Auto Placement'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Input Panel
            Expanded(
              flex: 2,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Form(
                    key: _formKey,
                    child: SingleChildScrollView(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text(
                            'Room Specifications',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          _buildNumberField(
                            controller: _roomWidthController,
                            label: 'Room Width (m)',
                            hint: 'Enter room width in meters',
                          ),
                          const SizedBox(height: 12),
                          _buildNumberField(
                            controller: _roomLengthController,
                            label: 'Room Length (m)',
                            hint: 'Enter room length in meters',
                          ),
                          const SizedBox(height: 12),
                          _buildNumberField(
                            controller: _ceilingHeightController,
                            label: 'Ceiling Height (m)',
                            hint: 'Enter ceiling height in meters',
                          ),
                          const SizedBox(height: 12),
                          _buildNumberField(
                            controller: _listenerHeightController,
                            label: 'Listener Height (m)',
                            hint: 'Enter listener height in meters',
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Custom Room Shape
                          CheckboxListTile(
                            title: const Text('Use Custom Room Shape'),
                            subtitle: Text(
                              _useCustomRoomShape 
                                  ? 'Enter coordinates to define room geometry'
                                  : 'Use width × length rectangle',
                              style: TextStyle(
                                fontSize: 12,
                                color: Colors.grey[600],
                              ),
                            ),
                            value: _useCustomRoomShape,
                            onChanged: (bool? value) {
                              setState(() {
                                _useCustomRoomShape = value!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          if (_useCustomRoomShape) ...<Widget>[
                            const SizedBox(height: 8),
                            TextFormField(
                              controller: _roomCoordinatesController,
                              maxLines: 3,
                              decoration: const InputDecoration(
                                labelText: 'Room Coordinates',
                                hintText: 'Enter coordinates as: (x1,y1), (x2,y2), (x3,y3), ...\nExample: (0,0), (10,0), (10,8), (0,8)',
                                border: OutlineInputBorder(),
                                contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                helperText: 'Coordinates should form a closed polygon',
                              ),
                              validator: _useCustomRoomShape ? (String? value) {
                                if (value == null || value.isEmpty) {
                                  return 'Room coordinates are required';
                                }
                                try {
                                  _parseRoomCoordinates(value);
                                  return null;
                                } catch (e) {
                                  return 'Invalid coordinate format: ${e.toString()}';
                                }
                              } : null,
                            ),
                            const SizedBox(height: 8),
                            Container(
                              padding: const EdgeInsets.all(8),
                              decoration: BoxDecoration(
                                color: Colors.blue[50],
                                borderRadius: BorderRadius.circular(4),
                                border: Border.all(color: Colors.blue[200]!),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Quick Templates:',
                                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                                  ),
                                  const SizedBox(height: 4),
                                  Wrap(
                                    spacing: 4,
                                    children: <Widget>[
                                      _buildTemplateButton('Rectangle', '(0,0), (10,0), (10,8), (0,8)'),
                                      _buildTemplateButton('L-Shape', '(0,0), (10,0), (10,6), (4,6), (4,8), (0,8)'),
                                      _buildTemplateButton('U-Shape', '(0,0), (3,0), (3,7), (7,7), (7,0), (10,0), (10,8), (0,8)'),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Speaker Specifications',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          
                          // Speaker Type
                          const Text('Speaker Type:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<SpeakerType>(
                            value: _selectedSpeakerType,
                            onChanged: (SpeakerType? value) {
                              setState(() {
                                _selectedSpeakerType = value!;
                              });
                            },
                            items: SpeakerType.values.map((SpeakerType type) {
                              return DropdownMenuItem<SpeakerType>(
                                value: type,
                                child: Text(_getSpeakerTypeLabel(type)),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          _buildNumberField(
                            controller: _coverageAngleController,
                            label: 'Coverage Angle (degrees)',
                            hint: 'Enter speaker coverage angle',
                          ),
                          
                          // Pendant Height (conditional)
                          if (_selectedSpeakerType == SpeakerType.pendant) ...<Widget>[
                            const SizedBox(height: 12),
                            _buildNumberField(
                              controller: _pendantHeightController,
                              label: 'Pendant Height (m)',
                              hint: 'Enter pendant speaker height in meters',
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          const Text(
                            'Layout Configuration',
                            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          const SizedBox(height: 16),
                          
                          // Coverage Preference
                          const Text('Coverage Preference:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<CoveragePreference>(
                            value: _selectedCoveragePreference,
                            onChanged: (CoveragePreference? value) {
                              setState(() {
                                _selectedCoveragePreference = value!;
                              });
                            },
                            items: CoveragePreference.values.map((CoveragePreference pref) {
                              return DropdownMenuItem<CoveragePreference>(
                                value: pref,
                                child: SizedBox(
                                  height: 40, // Constrain height to prevent overflow
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    mainAxisSize: MainAxisSize.min,
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: <Widget>[
                                      Text(
                                        _getCoveragePreferenceLabel(pref),
                                        style: const TextStyle(fontSize: 14),
                                      ),
                                      Flexible(
                                        child: Text(
                                          pref.description,
                                          style: TextStyle(
                                            fontSize: 10,
                                            color: Colors.grey[600],
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          
                          const SizedBox(height: 12),
                          
                          // Layout Pattern
                          const Text('Layout Pattern:', style: TextStyle(fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          DropdownButtonFormField<LayoutPattern>(
                            value: _selectedLayoutPattern,
                            onChanged: (LayoutPattern? value) {
                              setState(() {
                                _selectedLayoutPattern = value!;
                              });
                            },
                            items: LayoutPattern.values.map((LayoutPattern pattern) {
                              return DropdownMenuItem<LayoutPattern>(
                                value: pattern,
                                child: Text(_getLayoutPatternLabel(pattern)),
                              );
                            }).toList(),
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            ),
                          ),
                          
                          const SizedBox(height: 16),
                          
                          // Custom Origin
                          CheckboxListTile(
                            title: const Text('Use Custom Origin'),
                            value: _useCustomOrigin,
                            onChanged: (bool? value) {
                              setState(() {
                                _useCustomOrigin = value!;
                              });
                            },
                            controlAffinity: ListTileControlAffinity.leading,
                            contentPadding: EdgeInsets.zero,
                          ),
                          
                          if (_useCustomOrigin) ...<Widget>[
                            const SizedBox(height: 8),
                            Row(
                              children: <Widget>[
                                Expanded(
                                  child: _buildNumberField(
                                    controller: _customXController,
                                    label: 'X Coordinate',
                                    hint: 'X position',
                                    required: false,
                                  ),
                                ),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: _buildNumberField(
                                    controller: _customYController,
                                    label: 'Y Coordinate',
                                    hint: 'Y position',
                                    required: false,
                                  ),
                                ),
                              ],
                            ),
                          ],
                          
                          const SizedBox(height: 24),
                          SizedBox(
                            width: double.infinity,
                            child: ElevatedButton(
                              onPressed: _isCalculating ? null : _calculatePlacement,
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(vertical: 16),
                              ),
                              child: _isCalculating
                                  ? const Row(
                                      mainAxisAlignment: MainAxisAlignment.center,
                                      children: <Widget>[
                                        SizedBox(
                                          width: 20,
                                          height: 20,
                                          child: CircularProgressIndicator(strokeWidth: 2),
                                        ),
                                        SizedBox(width: 8),
                                        Text('Calculating...'),
                                      ],
                                    )
                                  : const Text('Calculate Speaker Placement'),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
            
            const SizedBox(width: 16),
            
            // Results Panel
            Expanded(
              flex: 3,
              child: Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Calculation Results',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 16),
                      Expanded(
                        child: _result == null
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
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNumberField({
    required TextEditingController controller,
    required String label,
    required String hint,
    bool required = true,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      decoration: InputDecoration(
        labelText: label,
        hintText: hint,
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      validator: required ? (String? value) {
        if (value == null || value.isEmpty) {
          return 'This field is required';
        }
        if (double.tryParse(value) == null) {
          return 'Please enter a valid number';
        }
        return null;
      } : null,
    );
  }

  Widget _buildTemplateButton(String label, String coordinates) {
    return ElevatedButton(
      onPressed: () {
        setState(() {
          _roomCoordinatesController.text = coordinates;
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

  List<Point2D> _parseRoomCoordinates(String input) {
    final List<Point2D> points = <Point2D>[];
    
    // Remove any extra whitespace and split by commas outside parentheses
    final String cleaned = input.trim();
    
    // Use regex to find coordinate pairs in the format (x,y)
    final RegExp regex = RegExp(r'\(\s*([+-]?\d*\.?\d+)\s*,\s*([+-]?\d*\.?\d+)\s*\)');
    final Iterable<RegExpMatch> matches = regex.allMatches(cleaned);
    
    if (matches.isEmpty) {
      throw const FormatException('No valid coordinate pairs found. Use format: (x,y), (x,y), ...');
    }
    
    for (final RegExpMatch match in matches) {
      final double x = double.parse(match.group(1)!);
      final double y = double.parse(match.group(2)!);
      points.add(Point2D(x, y));
    }
    
    if (points.length < 3) {
      throw const FormatException('At least 3 coordinate pairs are required to form a room');
    }
    
    return points;
  }

  Widget _buildResultsDisplay() {
    return SingleChildScrollView(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Summary Card
          Card(
            color: Colors.blue[50],
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
                  _buildSummaryRow('Number of Speakers:', '${_result!.speakerPositions.length}'),
                  _buildSummaryRow('Grid Spacing:', '${_result!.gridSpacing.toStringAsFixed(2)} m'),
                  _buildSummaryRow('Room Centroid:', '${_result!.centroid}'),
                  _buildSummaryRow('Distance:', '${_result!.distance.toStringAsFixed(2)} m'),
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
            Card(
              color: Colors.grey[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.info_outline, color: Colors.blue[700], size: 16),
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
                                padding: const EdgeInsets.symmetric(vertical: 2.0),
                                child: Row(
                                  children: <Widget>[
                                    Container(
                                      width: 20,
                                      height: 20,
                                      decoration: BoxDecoration(
                                        color: _result!.speakerPositions.any((Point2D validPos) => 
                                          (_allGridPoints![i].x - validPos.x).abs() < 0.001 && 
                                          (_allGridPoints![i].y - validPos.y).abs() < 0.001)
                                            ? Colors.green
                                            : Colors.red,
                                        borderRadius: BorderRadius.circular(10),
                                      ),
                                      child: Center(
                                        child: Icon(
                                          _result!.speakerPositions.any((Point2D validPos) => 
                                            (_allGridPoints![i].x - validPos.x).abs() < 0.001 && 
                                            (_allGridPoints![i].y - validPos.y).abs() < 0.001)
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
                                        style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                                      ),
                                    ),
                                    Text(
                                      _result!.speakerPositions.any((Point2D validPos) => 
                                        (_allGridPoints![i].x - validPos.x).abs() < 0.001 && 
                                        (_allGridPoints![i].y - validPos.y).abs() < 0.001)
                                          ? 'VALID'
                                          : 'FILTERED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.bold,
                                        color: _result!.speakerPositions.any((Point2D validPos) => 
                                          (_allGridPoints![i].x - validPos.x).abs() < 0.001 && 
                                          (_allGridPoints![i].y - validPos.y).abs() < 0.001)
                                            ? Colors.green[700]
                                            : Colors.red[700],
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
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.warning_outlined, color: Colors.red[700], size: 16),
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
                            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: Colors.red[100],
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: Colors.red[300]!),
                            ),
                            child: Text(
                              '(${_removedPoints![i].x.toStringAsFixed(2)}, ${_removedPoints![i].y.toStringAsFixed(2)})',
                              style: TextStyle(
                                fontSize: 11,
                                fontFamily: 'monospace',
                                color: Colors.red[800],
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
                        color: Colors.red[600],
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
          Card(
            child: Padding(
              padding: const EdgeInsets.all(12.0),
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
          ),
          
          const SizedBox(height: 16),
          
          // Step-by-Step Calculations
          const Text(
            'Step-by-Step Calculations',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Card(
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
    final List<Point2D> roomGeometry = _generateRoomGeometry(roomWidth, roomLength);

    return Column(
      children: <Widget>[
        // Legend
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            _buildLegendItem(
              icon: _selectedSpeakerType == SpeakerType.ceiling 
                  ? Icons.speaker 
                  : Icons.campaign,
              label: _getSpeakerTypeLabel(_selectedSpeakerType),
              color: Colors.blue,
            ),
            _buildLegendItem(
              icon: Icons.location_on,
              label: 'Room Center',
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
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: CustomPaint(
            size: const Size(400, 350),
            painter: RoomLayoutPainter(
              roomGeometry: roomGeometry,
              speakerPositions: _result!.speakerPositions,
              allGridPoints: _allGridPoints ?? <Point2D>[],
              removedPoints: _removedPoints ?? <Point2D>[],
              centroid: _result!.centroid,
              gridSpacing: _result!.gridSpacing,
              speakerType: _selectedSpeakerType,
              layoutPattern: _selectedLayoutPattern,
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Coordinate system info for custom rooms
        if (_useCustomRoomShape)
          Card(
            color: Colors.green[50],
            child: Padding(
              padding: const EdgeInsets.all(12.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.info_outline, color: Colors.green[700], size: 16),
                      const SizedBox(width: 8),
                      const Text(
                        'Custom Room Coordinates',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
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
                    'Current room shape: ${_useCustomRoomShape ? "Custom polygon" : "Rectangle"}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: Colors.green[700],
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
    if (_useCustomRoomShape && _roomCoordinatesController.text.isNotEmpty) {
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
        Icon(icon, color: Colors.blue[700], size: 20),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Colors.grey[600],
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
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
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
                value: _getCoveragePreferenceLabel(_selectedCoveragePreference).split(' ')[0],
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
  final Point2D centroid;
  final double gridSpacing;
  final SpeakerType speakerType;
  final LayoutPattern layoutPattern;
  
  RoomLayoutPainter({
    required this.roomGeometry,
    required this.speakerPositions,
    required this.allGridPoints,
    required this.removedPoints,
    required this.centroid,
    required this.gridSpacing,
    required this.speakerType,
    required this.layoutPattern,
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
    
    final double offsetX = (size.width - scaledWidth) / 2 - bounds.minX * scaleFactor;
    final double offsetY = (size.height - scaledHeight) / 2 - bounds.minY * scaleFactor;
    
    return Offset(offsetX, offsetY);
  }
  
  void _drawRoomBoundary(Canvas canvas, double scaleFactor, Offset offset) {
    final Paint paint = Paint()
      ..color = Colors.grey[600]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
      
    final Paint fillPaint = Paint()
      ..color = Colors.white
      ..style = PaintingStyle.fill;
    
    final Path path = Path();
    
    // Create path from room geometry points
    if (roomGeometry.isNotEmpty) {
      final Offset firstPoint = _transformPoint(roomGeometry.first, scaleFactor, offset);
      path.moveTo(firstPoint.dx, firstPoint.dy);
      
      for (int i = 1; i < roomGeometry.length; i++) {
        final Offset point = _transformPoint(roomGeometry[i], scaleFactor, offset);
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
    final Paint paint = Paint()
      ..color = Colors.grey[300]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    final RoomBounds bounds = _calculateBounds();
    
    // Draw vertical lines
    for (double x = bounds.minX; x <= bounds.maxX; x += gridSpacing) {
      final Offset startPoint = _transformPoint(Point2D(x, bounds.minY), scaleFactor, offset);
      final Offset endPoint = _transformPoint(Point2D(x, bounds.maxY), scaleFactor, offset);
      canvas.drawLine(startPoint, endPoint, paint);
    }
    
    // Draw horizontal lines
    for (double y = bounds.minY; y <= bounds.maxY; y += gridSpacing) {
      final Offset startPoint = _transformPoint(Point2D(bounds.minX, y), scaleFactor, offset);
      final Offset endPoint = _transformPoint(Point2D(bounds.maxX, y), scaleFactor, offset);
      canvas.drawLine(startPoint, endPoint, paint);
    }
  }
  
  void _drawHexagonalGrid(Canvas canvas, double scaleFactor, Offset offset) {
    // For hexagonal, we'll draw a more subtle indication
    final Paint paint = Paint()
      ..color = Colors.orange[200]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 0.5;
    
    // Draw diagonal lines to indicate hexagonal pattern
    final RoomBounds bounds = _calculateBounds();
    
    for (double x = bounds.minX; x <= bounds.maxX; x += gridSpacing) {
      for (double y = bounds.minY; y <= bounds.maxY; y += gridSpacing * 0.866) {
        final Offset centerPoint = _transformPoint(Point2D(x, y), scaleFactor, offset);
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
    final Paint paint = Paint()
      ..color = Colors.blue.withOpacity(0.15)
      ..style = PaintingStyle.fill;
      
    final Paint strokePaint = Paint()
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
    final Offset center = _transformPoint(centroid, scaleFactor, offset);
    
    final Paint paint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.fill;
    
    canvas.drawCircle(center, 6, paint);
    
    // Draw cross lines
    final Paint linePaint = Paint()
      ..color = Colors.red
      ..strokeWidth = 2.0;
    
    canvas.drawLine(
      Offset(center.dx - 10, center.dy),
      Offset(center.dx + 10, center.dy),
      linePaint,
    );
    canvas.drawLine(
      Offset(center.dx, center.dy - 10),
      Offset(center.dx, center.dy + 10),
      linePaint,
    );
  }
  
  void _drawRemovedPoints(Canvas canvas, double scaleFactor, Offset offset) {
    final Paint paint = Paint()
      ..color = Colors.red.withOpacity(0.6)
      ..style = PaintingStyle.fill;
      
    final Paint borderPaint = Paint()
      ..color = Colors.red
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5;
    
    for (final Point2D removedPos in removedPoints) {
      final Offset center = _transformPoint(removedPos, scaleFactor, offset);
      
      // Draw removed point as X
      canvas.drawCircle(center, 8, paint);
      canvas.drawCircle(center, 8, borderPaint);
      
      // Draw X mark
      final Paint xPaint = Paint()
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
    final Paint paint = Paint()
      ..color = Colors.blue
      ..style = PaintingStyle.fill;
    
    final Paint borderPaint = Paint()
      ..color = Colors.blue[800]!
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.0;
    
    for (int i = 0; i < speakerPositions.length; i++) {
      final Offset center = _transformPoint(speakerPositions[i], scaleFactor, offset);
      
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
  
  void _drawDimensions(Canvas canvas, double scaleFactor, Offset offset, Size size) {
    final RoomBounds bounds = _calculateBounds();
    final double roomWidth = bounds.maxX - bounds.minX;
    final double roomHeight = bounds.maxY - bounds.minY;
    
    // Draw width dimension
    final TextPainter textPainter = TextPainter(
      text: TextSpan(
        text: '${roomWidth.toStringAsFixed(1)} m',
        style: const TextStyle(
          color: Colors.black87,
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
      textDirection: TextDirection.ltr,
    );
    
    textPainter.layout();
    textPainter.paint(canvas, Offset(size.width / 2 - textPainter.width / 2, 10));
    
    // Draw height dimension (rotated)
    final TextPainter heightPainter = TextPainter(
      text: TextSpan(
        text: '${roomHeight.toStringAsFixed(1)} m',
        style: const TextStyle(
          color: Colors.black87,
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
    return Offset(
      point.x * scaleFactor + offset.dx,
      point.y * scaleFactor + offset.dy,
    );
  }
  
  @override
  bool shouldRepaint(covariant RoomLayoutPainter oldDelegate) {
    return roomGeometry != oldDelegate.roomGeometry ||
           speakerPositions != oldDelegate.speakerPositions ||
           allGridPoints != oldDelegate.allGridPoints ||
           removedPoints != oldDelegate.removedPoints ||
           centroid != oldDelegate.centroid ||
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