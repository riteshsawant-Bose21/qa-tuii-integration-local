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
  final TextEditingController _roomHeightController = TextEditingController(text: '4.6');
  final TextEditingController _ceilingHeightController = TextEditingController(text: '2.7');
  final TextEditingController _listenerHeightController = TextEditingController(text: '1.2');
  final TextEditingController _coverageAngleController = TextEditingController(text: '90.0');
  final TextEditingController _pendantHeightController = TextEditingController(text: '2.1');
  final TextEditingController _customXController = TextEditingController();
  final TextEditingController _customYController = TextEditingController();

  // Form state
  SpeakerType _selectedSpeakerType = SpeakerType.ceiling;
  CoveragePreference _selectedCoveragePreference = CoveragePreference.minimumOverlap;
  LayoutPattern _selectedLayoutPattern = LayoutPattern.square;
  bool _useCustomOrigin = false;
  
  // Results
  PlacementResult? _result;
  bool _isCalculating = false;

  @override
  void dispose() {
    _roomWidthController.dispose();
    _roomHeightController.dispose();
    _ceilingHeightController.dispose();
    _listenerHeightController.dispose();
    _coverageAngleController.dispose();
    _pendantHeightController.dispose();
    _customXController.dispose();
    _customYController.dispose();
    super.dispose();
  }

  Future<void> _calculatePlacement() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isCalculating = true;
      _result = null;
    });

    try {
      // Create room
      final Room room = Room(
        width: double.parse(_roomWidthController.text),
        height: double.parse(_roomHeightController.text),
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

      // Calculate placement
      final PlacementResult result = AutoSpeakerPlacement.calculatePlacement(
        room: room,
        speakerSpec: speakerSpec,
        coveragePreference: _selectedCoveragePreference,
        layoutPattern: _selectedLayoutPattern,
        customOrigin: customOrigin,
      );

      setState(() {
        _result = result;
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
                            controller: _roomHeightController,
                            label: 'Room Height (m)',
                            hint: 'Enter room height in meters',
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
    final double roomHeight = double.parse(_roomHeightController.text);
    
    // Scale factor to fit the visualization in a reasonable size
    const double maxDisplaySize = 300.0;
    final double scaleFactor = maxDisplaySize / (roomWidth > roomHeight ? roomWidth : roomHeight);
    final double displayWidth = roomWidth * scaleFactor;
    final double displayHeight = roomHeight * scaleFactor;
    
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
            _buildLegendItem(
              icon: Icons.crop_square,
              label: 'Room Boundary',
              color: Colors.grey,
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Room Layout Visualization
        Container(
          width: displayWidth + 40,
          height: displayHeight + 40,
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.grey[300]!),
          ),
          child: Stack(
            children: <Widget>[
              // Room boundary
              Positioned(
                left: 20,
                top: 20,
                child: Container(
                  width: displayWidth,
                  height: displayHeight,
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[600]!, width: 2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                ),
              ),
              
              // Room dimensions labels
              Positioned(
                left: 20 + displayWidth / 2 - 30,
                top: 2,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: Colors.grey[600],
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(
                    '${roomWidth.toStringAsFixed(1)} m',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 10,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
              
              Positioned(
                left: 2,
                top: 20 + displayHeight / 2 - 10,
                child: RotatedBox(
                  quarterTurns: 3,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Colors.grey[600],
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${roomHeight.toStringAsFixed(1)} m',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
              ),
              
              // Room centroid
              Positioned(
                left: 20 + (_result!.centroid.x * scaleFactor) - 6,
                top: 20 + (_result!.centroid.y * scaleFactor) - 6,
                child: Container(
                  decoration: const BoxDecoration(
                    color: Colors.red,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.location_on,
                    color: Colors.white,
                    size: 12,
                  ),
                ),
              ),
              
              // Speakers
              for (int i = 0; i < _result!.speakerPositions.length; i++)
                Positioned(
                  left: 20 + (_result!.speakerPositions[i].x * scaleFactor) - 15,
                  top: 20 + (_result!.speakerPositions[i].y * scaleFactor) - 15,
                  child: _buildSpeakerIcon(i + 1),
                ),
              
              // Coverage circles (optional, for better visualization)
              for (int i = 0; i < _result!.speakerPositions.length; i++)
                Positioned(
                  left: 20 + (_result!.speakerPositions[i].x * scaleFactor) - (_result!.gridSpacing * scaleFactor * 0.5),
                  top: 20 + (_result!.speakerPositions[i].y * scaleFactor) - (_result!.gridSpacing * scaleFactor * 0.5),
                  child: Container(
                    width: _result!.gridSpacing * scaleFactor,
                    height: _result!.gridSpacing * scaleFactor,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: Colors.blue.withValues(alpha: 0.3),
                        width: 1,
                      ),
                      color: Colors.blue.withValues(alpha: 0.1),
                    ),
                  ),
                ),
            ],
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
  
  Widget _buildSpeakerIcon(int number) {
    return Container(
      width: 30,
      height: 30,
      decoration: BoxDecoration(
        color: Colors.blue,
        shape: BoxShape.circle,
        boxShadow: <BoxShadow>[
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.2),
            blurRadius: 4,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Stack(
        children: <Widget>[
          Center(
            child: Icon(
              _selectedSpeakerType == SpeakerType.ceiling 
                  ? Icons.speaker 
                  : Icons.campaign,
              color: Colors.white,
              size: 16,
            ),
          ),
          Positioned(
            right: 0,
            top: 0,
            child: Container(
              width: 14,
              height: 14,
              decoration: const BoxDecoration(
                color: Colors.orange,
                shape: BoxShape.circle,
              ),
              child: Center(
                child: Text(
                  '$number',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 8,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
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