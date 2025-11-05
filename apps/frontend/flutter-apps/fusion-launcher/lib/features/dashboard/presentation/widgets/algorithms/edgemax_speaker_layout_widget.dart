import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_algorithms/edgemax_speakers_autolayout/edgemax_speakers_autolayout.dart';

/// Represents a single calculation step in the EdgeMax algorithm
class CalculationStep {
  final int stepNumber;
  final String title;
  final String description;
  final Map<String, dynamic> inputs;
  final Map<String, dynamic> outputs;
  final String result;
  final bool isComplete;

  CalculationStep({
    required this.stepNumber,
    required this.title,
    required this.description,
    required this.inputs,
    required this.outputs,
    required this.result,
    this.isComplete = false,
  });
}

/// EdgeMax Speaker Layout Widget
/// 
/// A Flutter widget that provides a user interface for the EdgeMax speaker
/// auto-placement algorithm. This widget uses the EdgeMax library from fusion_lib
/// to calculate optimal speaker placements in rectangular rooms.
/// 
/// All measurements are in meters (m).
class EdgeMaxSpeakerLayoutWidget extends StatefulWidget {
  const EdgeMaxSpeakerLayoutWidget({super.key});

  @override
  State<EdgeMaxSpeakerLayoutWidget> createState() => _EdgeMaxSpeakerLayoutWidgetState();
}

class _EdgeMaxSpeakerLayoutWidgetState extends State<EdgeMaxSpeakerLayoutWidget> {
  final TextEditingController _lengthController = TextEditingController(text: '7.0');
  final TextEditingController _widthController = TextEditingController(text: '4.0');
  final TextEditingController _ceilingHeightController = TextEditingController(text: '3.0');
  final TextEditingController _listenerHeightController = TextEditingController(text: '1.2');
  
  EdgeMaxPlacementResult? _result;
  RectangularRoom? _currentRoom;
  List<String> _validationErrors = <String>[];
  bool _isLoading = false;
  
  // Step-by-step calculation state
  int _currentStep = 0;
  final int _totalSteps = 8;
  List<CalculationStep> _calculationSteps = <CalculationStep>[];
  bool _showStepByStep = false;

  @override
  void initState() {
    super.initState();
    // Don't auto-calculate on widget load - wait for user to click calculate button
  }

  void _calculatePlacement() async {
    setState(() {
      _isLoading = true;
      _validationErrors.clear();
      _calculationSteps.clear();
      _currentStep = 0;
      _showStepByStep = false;
    });

    try {
      final double length = double.parse(_lengthController.text);
      final double width = double.parse(_widthController.text);
      final double ceilingHeight = double.parse(_ceilingHeightController.text);
      final double listenerHeight = double.parse(_listenerHeightController.text);

      _currentRoom = RectangularRoom(
        length: length,
        width: width,
        ceilingHeight: ceilingHeight,
        listenerHeight: listenerHeight,
      );

      // Generate step-by-step calculations
      await _generateCalculationSteps(_currentRoom!);
      
      // Start step-by-step animation
      setState(() {
        _isLoading = false;
        _showStepByStep = true;
      });
      
      // Animate through each step
      await _animateSteps();
      
      // Calculate final result
      final EdgeMaxPlacementResult result = EdgeMaxSpeakerPlacementService.calculateCompleteResult(_currentRoom!);
      setState(() {
        _result = result;
      });

    } catch (e) {
      setState(() {
        _validationErrors = <String>['Invalid input: Please enter valid numbers'];
        _isLoading = false;
      });
    }
  }

  Future<void> _generateCalculationSteps(RectangularRoom room) async {
    _calculationSteps.clear();
    
    // Get calculation details for reference
    final Map<String, dynamic> details = EdgeMaxAutoPlacement.getCalculationDetails(room);
    final double utd = details['utd'] as double;
    final double lsd = details['lsd'] as double;
    final String speakerType = details['speaker_type'] as String;
    
    // Step 1: Room Validation
    _calculationSteps.add(CalculationStep(
      stepNumber: 1,
      title: 'Validate Room Shape',
      description: 'Confirm the room is rectangular with valid dimensions',
      inputs: <String, dynamic>{
        'Length': '${room.length}m',
        'Width': '${room.width}m',
        'Ceiling Height': '${room.ceilingHeight}m',
        'Listener Height': '${room.listenerHeight}m',
      },
      outputs: <String, dynamic>{
        'Room Diagonal': '${room.diagonal.toStringAsFixed(2)}m',
        'Height Difference': '${room.heightDifference.toStringAsFixed(2)}m',
        'Is Valid': room.isValidRectangle ? 'Yes' : 'No',
      },
      result: room.isValidRectangle ? '✓ Room is valid rectangular shape' : '✗ Invalid room shape',
    ));

    // Step 2: Speaker Type Selection
    _calculationSteps.add(CalculationStep(
      stepNumber: 2,
      title: 'Select Speaker Type',
      description: 'Choose EM-LP for ≤3.7m ceiling height, EM for >3.7m',
      inputs: <String, dynamic>{
        'Ceiling Height': '${room.ceilingHeight}m',
        'Threshold': '3.7m (12 feet)',
      },
      outputs: <String, dynamic>{
        'Selected Type': speakerType,
        'Vertical Angle': speakerType == 'EM-LP' ? '80°' : '75°',
        'Horizontal Angle': speakerType == 'EM-LP' ? '120°' : '90°',
      },
      result: 'Selected $speakerType speakers (${room.ceilingHeight <= 3.7 ? 'Low ceiling' : 'Standard ceiling'})',
    ));

    // Step 3: UTD Calculation
    _calculationSteps.add(CalculationStep(
      stepNumber: 3,
      title: 'Calculate UTD (Usable Throw Distance)',
      description: 'UTD = height_difference × tan(vertical_angle)',
      inputs: <String, dynamic>{
        'Height Difference': '${room.heightDifference.toStringAsFixed(2)}m',
        'Vertical Angle': speakerType == 'EM-LP' ? '80°' : '75°',
      },
      outputs: <String, dynamic>{
        'UTD': '${utd.toStringAsFixed(2)}m',
        'Formula': 'UTD = ${room.heightDifference.toStringAsFixed(2)} × tan(${speakerType == 'EM-LP' ? '80' : '75'}°)',
      },
      result: 'UTD = ${utd.toStringAsFixed(2)}m',
    ));

    // Step 4: Diagonal Corner Coverage
    final bool utdGreaterThanDiagonal = utd >= room.diagonal;
    _calculationSteps.add(CalculationStep(
      stepNumber: 4,
      title: 'Diagonal Corner Coverage Decision',
      description: 'Compare UTD with room diagonal to determine corner placement',
      inputs: <String, dynamic>{
        'UTD': '${utd.toStringAsFixed(2)}m',
        'Room Diagonal': '${room.diagonal.toStringAsFixed(2)}m',
      },
      outputs: <String, dynamic>{
        'UTD vs Diagonal': utdGreaterThanDiagonal ? 'UTD ≥ Diagonal' : 'UTD < Diagonal',
        'Corner Strategy': utdGreaterThanDiagonal ? 'Place Corner #1 only' : 'Place Corner #1 & #3',
      },
      result: utdGreaterThanDiagonal ? 'Place speaker in corner 1 only' : 'Place speakers in opposite corners (1 & 3)',
    ));

    // Step 5: LSD Calculation
    final String horizontalAngle = speakerType == 'EM-LP' ? '120°' : '90°';
    final String halfAngle = speakerType == 'EM-LP' ? '60°' : '45°';
    _calculationSteps.add(CalculationStep(
      stepNumber: 5,
      title: 'Calculate LSD (Loudspeaker Spacing Distance)',
      description: 'LSD = height_difference × 2 × tan(horizontal_angle/2)',
      inputs: <String, dynamic>{
        'Height Difference': '${room.heightDifference.toStringAsFixed(2)}m',
        'Horizontal Angle': horizontalAngle,
        'Half Angle': halfAngle,
      },
      outputs: <String, dynamic>{
        'LSD': '${lsd.toStringAsFixed(2)}m',
        'Double LSD': '${(2 * lsd).toStringAsFixed(2)}m',
        'Formula': 'LSD = ${room.heightDifference.toStringAsFixed(2)} × 2 × tan($halfAngle)',
      },
      result: 'LSD = ${lsd.toStringAsFixed(2)}m (using $speakerType $horizontalAngle coverage)',
    ));

    // Step 6: Adjacent Corner Analysis
    final bool needsCorner2 = room.length > lsd;
    final bool needsCorner4 = utd < room.diagonal;
    _calculationSteps.add(CalculationStep(
      stepNumber: 6,
      title: 'Adjacent Corner Coverage Analysis',
      description: 'Determine if additional corner speakers are needed',
      inputs: <String, dynamic>{
        'LSD': '${lsd.toStringAsFixed(2)}m',
        'Room Length (d2)': '${room.length}m',
        'UTD': '${utd.toStringAsFixed(2)}m',
        'Room Diagonal (d1)': '${room.diagonal.toStringAsFixed(2)}m',
      },
      outputs: <String, dynamic>{
        'd2 > LSD': needsCorner2 ? 'Yes → Add Corner #2' : 'No',
        'UTD < d1': needsCorner4 ? 'Yes → Add Corner #4' : 'No',
      },
      result: 'Additional corners: ${needsCorner2 ? 'Corner #2 ' : ''}${needsCorner4 ? 'Corner #4' : ''}${!needsCorner2 && !needsCorner4 ? 'None' : ''}',
    ));

    // Step 7: Wall Speaker Analysis
    final bool needsLengthWall = room.length > 2 * lsd;
    final bool needsWidthWall = room.width > 2 * lsd;
    _calculationSteps.add(CalculationStep(
      stepNumber: 7,
      title: 'Wall Speaker Analysis',
      description: 'Determine if additional wall speakers are needed to fill coverage gaps',
      inputs: <String, dynamic>{
        'Room Length (d2)': '${room.length}m',
        'Room Width (d3)': '${room.width}m',
        'Double LSD (2×LSD)': '${(2 * lsd).toStringAsFixed(2)}m',
      },
      outputs: <String, dynamic>{
        'd2 > 2×LSD': needsLengthWall ? 'Yes → Add $speakerType between corners 1-2 (and 3-4 if speakers exist)' : 'No',
        'd3 > 2×LSD': needsWidthWall ? 'Yes → Add $speakerType between corners 1-4 and 2-3' : 'No',
      },
      result: 'Wall speakers: ${needsLengthWall ? 'Top/Bottom walls (1-2, 3-4) ' : ''}${needsWidthWall ? 'Left/Right walls (1-4, 2-3)' : ''}${!needsLengthWall && !needsWidthWall ? 'None needed' : ''}',
    ));

    // Step 8: Final Placement Summary
    final EdgeMaxPlacementResult finalResult = EdgeMaxSpeakerPlacementService.calculateCompleteResult(room);
    _calculationSteps.add(CalculationStep(
      stepNumber: 8,
      title: 'Final Speaker Placement',
      description: 'Complete speaker layout with positions and types',
      inputs: <String, dynamic>{
        'Total Calculations': 'Steps 1-7 completed',
      },
      outputs: <String, dynamic>{
        'Total Speakers': finalResult.summary.totalSpeakers.toString(),
        // Show speaker breakdown based on ceiling height
        if (_currentRoom!.ceilingHeight > 3.7) ...<String, String>{
          'EM90 (Corner)': '${finalResult.summary.getCountByType('EM90')}',
          'EM180 (Wall)': '${finalResult.summary.getCountByType('EM180')}',
        } else ...<String, String>{
          'EM-LP90 (Corner)': '${finalResult.summary.getCountByType('EM-LP90')}',
          'EM-LP180 (Wall)': '${finalResult.summary.getCountByType('EM-LP180')}',
        },
      },
      result: 'Algorithm complete: ${finalResult.summary.totalSpeakers} speakers placed',
    ));
  }

  Future<void> _animateSteps() async {
    for (int i = 0; i < _calculationSteps.length; i++) {
      setState(() {
        _currentStep = i + 1;
      });
      await Future<void>.delayed(const Duration(milliseconds: 800));
    }
    
    // Mark all steps as complete by setting current step beyond total steps
    setState(() {
      _currentStep = _totalSteps + 1;
    });
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('EdgeMax Speaker Layout Calculator'),
        backgroundColor: Colors.teal,
        foregroundColor: Colors.white,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          children: <Widget>[
            // Input Section
            Card(
              elevation: 4,
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        const Icon(Icons.input, color: Colors.teal),
                        const SizedBox(width: 8),
                        Text(
                          'Room Parameters',
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildInputField(
                            controller: _lengthController,
                            label: 'Length (m)',
                            icon: Icons.straighten,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            controller: _widthController,
                            label: 'Width (m)', 
                            icon: Icons.width_normal,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: _buildInputField(
                            controller: _ceilingHeightController,
                            label: 'Ceiling Height (m)',
                            icon: Icons.height,
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: _buildInputField(
                            controller: _listenerHeightController,
                            label: 'Listener Height (m)',
                            icon: Icons.person,
                          ),
                        ),
                      ],
                    ),
                    
                    if (_validationErrors.isNotEmpty) ...<Widget>[
                      const SizedBox(height: 16),
                      Container(
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: Colors.red.shade50,
                          border: Border.all(color: Colors.red),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: _validationErrors.map((String error) => 
                            Row(
                              children: <Widget>[
                                const Icon(Icons.error, color: Colors.red, size: 16),
                                const SizedBox(width: 8),
                                Text(error, style: const TextStyle(color: Colors.red)),
                              ],
                            )
                          ).toList(),
                        ),
                      ),
                    ],
                    
                    const SizedBox(height: 20),
                    SizedBox(
                      width: double.infinity,
                      child: ElevatedButton.icon(
                        onPressed: _isLoading ? null : _calculatePlacement,
                        icon: _isLoading 
                          ? const SizedBox(
                              width: 16,
                              height: 16,
                              child: CircularProgressIndicator(strokeWidth: 2),
                            )
                          : const Icon(Icons.calculate),
                        label: Text(_isLoading ? 'Calculating...' : 'Calculate Step-by-Step'),
                        style: ElevatedButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            
            const SizedBox(height: 20),
            
            
            const SizedBox(height: 20),
            
            // Step-by-Step Calculation Section
            if (_showStepByStep) ...<Widget>[
              Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.timeline, color: Colors.blue, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'EdgeMax Algorithm Steps',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      LinearProgressIndicator(
                        value: _currentStep > _totalSteps ? 1.0 : _currentStep / _totalSteps,
                        backgroundColor: Colors.grey.shade300,
                        valueColor: const AlwaysStoppedAnimation<Color>(Colors.blue),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _currentStep > _totalSteps 
                          ? 'All steps completed!'
                          : 'Step $_currentStep of $_totalSteps',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                      ),
                      const SizedBox(height: 20),
                      
                      // Display steps
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _calculationSteps.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CalculationStep step = _calculationSteps[index];
                          final bool isActive = index < _currentStep;
                          final bool isCurrent = index == _currentStep - 1 && _currentStep <= _totalSteps;
                          final bool isCompleted = index < _currentStep - 1 || _currentStep > _totalSteps;
                          
                          return _buildStepWidget(step, isActive, isCurrent, isCompleted);
                        },
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ] else if (!_isLoading) ...<Widget>[
              // Instruction card when no calculation has been performed
              Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    children: <Widget>[
                      Icon(
                        Icons.info_outline,
                        size: 48,
                        color: Colors.blue.shade300,
                      ),
                      const SizedBox(height: 16),
                      Text(
                        'Ready to Calculate Speaker Placement',
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          color: Colors.blue.shade700,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Enter room dimensions above or select a test scenario, then click "Calculate Step-by-Step" to see the EdgeMax algorithm in action.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: Colors.grey[600],
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: <Widget>[
                          Icon(Icons.arrow_upward, color: Colors.blue.shade300),
                          const SizedBox(width: 8),
                          Text(
                            'Click "Calculate Step-by-Step" when ready',
                            style: TextStyle(
                              color: Colors.blue.shade600,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              
              const SizedBox(height: 20),
            ],
            
            // Results Section - Show only after all steps are complete
            if (_result != null && _currentStep >= _totalSteps) ...<Widget>[
              // Room Layout Visualization
              Card(
                elevation: 6,
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.view_in_ar, color: Colors.green, size: 28),
                          const SizedBox(width: 12),
                          Text(
                            'Final Room Layout',
                            style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: Colors.green,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 20),
                      Center(child: _buildRoomVisualization()),
                    ],
                  ),
                ),
              ),
              
              // Summary Section
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.summarize, color: Colors.green),
                          const SizedBox(width: 8),
                          Text(
                            'Final Summary',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: Colors.green.shade50,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Column(
                          children: <Widget>[
                            _buildSummaryRow('Total Speakers', '${_result!.summary.totalSpeakers}', isTotal: true),
                            // Show speaker breakdown based on ceiling height
                            if (_currentRoom!.ceilingHeight > 3.7) ...<Widget>[
                              _buildSummaryRow('EM90 (Corner)', '${_result!.summary.getCountByType('EM90')}'),
                              _buildSummaryRow('EM180 (Wall)', '${_result!.summary.getCountByType('EM180')}'),
                            ] else ...<Widget>[
                              _buildSummaryRow('EM-LP90 (Corner)', '${_result!.summary.getCountByType('EM-LP90')}'),
                              _buildSummaryRow('EM-LP180 (Wall)', '${_result!.summary.getCountByType('EM-LP180')}'),
                            ],
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),

              // Speaker Details
              Card(
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Icon(Icons.place, color: Colors.purple),
                          const SizedBox(width: 8),
                          Text(
                            'Speaker Details (${_result!.placements.length})',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      
                      // Placements list
                      ListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: _result!.placements.length,
                        itemBuilder: (BuildContext context, int index) {
                          final SpeakerPlacement placement = _result!.placements[index];
                          return Container(
                            margin: const EdgeInsets.only(bottom: 8.0),
                            decoration: BoxDecoration(
                              color: _getSpeakerColor(placement.speakerType).withOpacity(0.1),
                              borderRadius: BorderRadius.circular(8),
                              border: Border.all(
                                color: _getSpeakerColor(placement.speakerType).withOpacity(0.3),
                              ),
                            ),
                            child: ListTile(
                              leading: CircleAvatar(
                                backgroundColor: _getSpeakerColor(placement.speakerType),
                                child: Text(
                                  '${index + 1}',
                                  style: const TextStyle(
                                    color: Colors.white,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              title: Text(
                                placement.speakerType,
                                style: const TextStyle(fontWeight: FontWeight.bold),
                              ),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text('Location: ${placement.location}'),
                                  const SizedBox(height: 2),
                                  Text(
                                    'Position: (${placement.position.x.toStringAsFixed(2)}, '
                                    '${placement.position.y.toStringAsFixed(2)})',
                                    style: TextStyle(
                                      color: Colors.grey[600],
                                      fontSize: 12,
                                    ),
                                  ),
                                ],
                              ),
                              trailing: Icon(
                                _getSpeakerIcon(placement.speakerType),
                                color: _getSpeakerColor(placement.speakerType),
                              ),
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStepWidget(CalculationStep step, bool isActive, bool isCurrent, bool isCompleted) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16.0),
      child: Card(
        elevation: isCurrent ? 8 : (isActive ? 4 : 2),
        color: isCurrent 
          ? Colors.blue.shade50 
          : isCompleted || isActive 
            ? Colors.green.shade50 
            : Colors.grey.shade100,
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              // Step Header
              Row(
                children: <Widget>[
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isCurrent 
                        ? Colors.blue 
                        : isCompleted || isActive 
                          ? Colors.green 
                          : Colors.grey,
                    ),
                    child: Center(
                      child: isCurrent
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                            ),
                          )
                        : Icon(
                            isCompleted || isActive ? Icons.check : Icons.pending,
                            color: Colors.white,
                            size: 20,
                          ),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Step ${step.stepNumber}: ${step.title}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: isCurrent 
                              ? Colors.blue 
                              : isCompleted || isActive 
                                ? Colors.green.shade700 
                                : Colors.grey.shade600,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          step.description,
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              
              // Step Content - Only show if active or completed
              if (isActive || isCompleted) ...<Widget>[
                const SizedBox(height: 16),
                
                // Inputs Section
                if (step.inputs.isNotEmpty) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.blue.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.input, color: Colors.blue.shade700, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Inputs',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.blue.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...step.inputs.entries.map((MapEntry<String, dynamic> entry) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(entry.key, style: const TextStyle(fontSize: 12)),
                                Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Outputs Section
                if (step.outputs.isNotEmpty) ...<Widget>[
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange.shade50,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.orange.shade200),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Icon(Icons.output, color: Colors.orange.shade700, size: 16),
                            const SizedBox(width: 8),
                            Text(
                              'Calculations',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: Colors.orange.shade700,
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        ...step.outputs.entries.map((MapEntry<String, dynamic> entry) =>
                          Padding(
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                Text(entry.key, style: const TextStyle(fontSize: 12)),
                                Text(
                                  entry.value.toString(),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ).toList(),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                ],
                
                // Result Section
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(8),
                    border: Border.all(color: Colors.green.shade200),
                  ),
                  child: Row(
                    children: <Widget>[
                      Icon(Icons.check_circle, color: Colors.green.shade700, size: 16),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          step.result,
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade700,
                            fontSize: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomVisualization() {
    if (_result == null) return const SizedBox.shrink();

    final double roomLength = double.tryParse(_lengthController.text) ?? 10.0;
    final double roomWidth = double.tryParse(_widthController.text) ?? 8.0;
    
    // Calculate scaling for visual representation (fit in 450x350 box for better detail)
    const double maxVisualWidth = 450.0;
    const double maxVisualHeight = 350.0;
    
    final double aspectRatio = roomLength / roomWidth;
    double visualWidth, visualHeight;
    
    if (aspectRatio > maxVisualWidth / maxVisualHeight) {
      visualWidth = maxVisualWidth;
      visualHeight = maxVisualWidth / aspectRatio;
    } else {
      visualHeight = maxVisualHeight;
      visualWidth = maxVisualHeight * aspectRatio;
    }
    
    final double scaleX = visualWidth / roomLength;
    final double scaleY = visualHeight / roomWidth;

    return Container(
      width: visualWidth + 180, // More padding for enhanced layout
      height: visualHeight + 160, // More padding for controls and legend
      child: Stack(
        children: <Widget>[
          // Enhanced Room Background with Grid
          Positioned(
            left: 80,
            top: 50,
            child: Container(
              width: visualWidth,
              height: visualHeight,
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: <Color>[
                    Colors.grey.shade100,
                    Colors.grey.shade200,
                    Colors.grey.shade100,
                  ],
                ),
                border: Border.all(color: Colors.brown.shade800, width: 5),
                borderRadius: BorderRadius.circular(8),
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.2),
                    blurRadius: 15,
                    offset: const Offset(0, 8),
                  ),
                  BoxShadow(
                    color: Colors.brown.withOpacity(0.1),
                    blurRadius: 20,
                    offset: const Offset(0, 12),
                  ),
                ],
              ),
              child: Stack(
                children: <Widget>[
                  // Room Corner Markers
                  ..._buildCornerMarkers(visualWidth, visualHeight),
                  
                  // Center Point Indicator
                  Positioned(
                    left: visualWidth / 2 - 4,
                    top: visualHeight / 2 - 4,
                    child: Container(
                      width: 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: Colors.red.shade400,
                        shape: BoxShape.circle,
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                    ),
                  ),
                  
                  // Enhanced Speaker Positions
                  ..._result!.placements.asMap().entries.map((MapEntry<int, SpeakerPlacement> entry) {
                    final int index = entry.key;
                    final SpeakerPlacement placement = entry.value;
                    
                    final double visualX = placement.position.x * scaleX;
                    // Flip Y coordinate: room (0,0) = bottom-left, Flutter (0,0) = top-left
                    final double visualY = visualHeight - (placement.position.y * scaleY);
                    
                    return _buildEnhancedSpeaker(
                      index: index,
                      placement: placement,
                      visualX: visualX,
                      visualY: visualY,
                      containerWidth: visualWidth,
                      containerHeight: visualHeight,
                    );
                  }).toList(),
                  
                  // Coverage Area Indicators (optional)
                  ..._buildCoverageAreas(scaleX, scaleY, visualHeight),
                ],
              ),
            ),
          ),
          
          // Enhanced Room Dimension Labels
          ..._buildEnhancedDimensionLabels(roomLength, roomWidth, visualWidth, visualHeight),
          
          // Coordinate System
          _buildCoordinateSystem(visualWidth, visualHeight),
        ],
      ),
    );
  }

  Widget _buildEnhancedSpeaker({
    required int index,
    required SpeakerPlacement placement,
    required double visualX,
    required double visualY,
    required double containerWidth,
    required double containerHeight,
  }) {
    return Stack(
      children: <Widget>[
        // Speaker Coverage Circle (subtle background)
        Positioned(
          left: visualX - 35,
          top: visualY - 35,
          child: Container(
            width: 70,
            height: 70,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: _getSpeakerColor(placement.speakerType).withOpacity(0.1),
              border: Border.all(
                color: _getSpeakerColor(placement.speakerType).withOpacity(0.3),
                width: 1,
              ),
            ),
          ),
        ),
        // Main Speaker Icon
        Positioned(
          left: visualX - 25,
          top: visualY - 25,
          child: Container(
            width: 50,
            height: 50,
            decoration: BoxDecoration(
              gradient: RadialGradient(
                colors: <Color>[
                  _getSpeakerColor(placement.speakerType).withOpacity(0.9),
                  _getSpeakerColor(placement.speakerType),
                ],
              ),
              borderRadius: BorderRadius.circular(25),
              border: Border.all(color: Colors.white, width: 3),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 10,
                  offset: const Offset(0, 5),
                ),
                BoxShadow(
                  color: _getSpeakerColor(placement.speakerType).withOpacity(0.4),
                  blurRadius: 15,
                  offset: const Offset(0, 0),
                ),
              ],
            ),
            child: Center(
              child: Icon(
                _getSpeakerIcon(placement.speakerType),
                color: Colors.white,
                size: 28,
              ),
            ),
          ),
        ),
        // Enhanced Speaker Label - dynamically positioned to stay visible
        Positioned(
          left: (visualX + 120 > containerWidth) ? visualX - 120 : visualX + 30, // Avoid going off-screen right
          top: (visualY - 50 < 0) ? visualY + 30 : visualY - 50, // Avoid going off-screen top
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[
                  _getSpeakerColor(placement.speakerType),
                  _getSpeakerColor(placement.speakerType).withOpacity(0.8),
                ],
              ),
              borderRadius: BorderRadius.circular(18),
              border: Border.all(color: Colors.white, width: 2),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                Text(
                  '${index + 1}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(width: 4),
                Text(
                  placement.speakerType,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
        // Coordinate Display - positioned directly below speaker icon to avoid overlap
        Positioned(
          left: visualX - 30, // Center under the speaker icon
          top: visualY + 35, // Always below the speaker icon
          child: Container(
            width: 60,
            padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
            decoration: BoxDecoration(
              color: Colors.black.withOpacity(0.8),
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.white38, width: 0.5),
            ),
            child: Text(
              '(${placement.position.x.toStringAsFixed(1)},${placement.position.y.toStringAsFixed(1)})',
              textAlign: TextAlign.center,
              style: const TextStyle(
                color: Colors.white,
                fontSize: 7,
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ),
      ],
    );
  }

  List<Widget> _buildCornerMarkers(double width, double height) {
    const double markerSize = 12.0;
    return <Widget>[
      // Corner 1 (Top-left in Flutter = top-left in room coordinates)
      Positioned(
        left: 0,
        top: 0,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: const BorderRadius.only(
              bottomRight: Radius.circular(6),
            ),
          ),
          child: const Center(
            child: Text(
              '1',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      // Corner 2 (Top-right in Flutter = top-right in room coordinates)
      Positioned(
        right: 0,
        top: 0,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: const BorderRadius.only(
              bottomLeft: Radius.circular(6),
            ),
          ),
          child: const Center(
            child: Text(
              '2',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      // Corner 4 (Bottom-left in Flutter = bottom-left in room coordinates)
      Positioned(
        left: 0,
        bottom: 0,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: const BorderRadius.only(
              topRight: Radius.circular(6),
            ),
          ),
          child: const Center(
            child: Text(
              '4',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
      // Corner 3 (Bottom-right in Flutter = bottom-right in room coordinates)
      Positioned(
        right: 0,
        bottom: 0,
        child: Container(
          width: markerSize,
          height: markerSize,
          decoration: BoxDecoration(
            color: Colors.brown.shade600,
            borderRadius: const BorderRadius.only(
              topLeft: Radius.circular(6),
            ),
          ),
          child: const Center(
            child: Text(
              '3',
              style: TextStyle(
                color: Colors.white,
                fontSize: 8,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
      ),
    ];
  }

  List<Widget> _buildCoverageAreas(double scaleX, double scaleY, double visualHeight) {
    if (_result == null) return <Widget>[];
    
    // Simplified coverage areas - you could enhance this based on actual coverage calculations
    return _result!.placements.map((SpeakerPlacement placement) {
      final double visualX = placement.position.x * scaleX;
      // Flip Y coordinate: room (0,0) = bottom-left, Flutter (0,0) = top-left
      final double visualY = visualHeight - (placement.position.y * scaleY);
      final double coverageRadius = placement.speakerType.contains('180') ? 60.0 : 45.0;
      
      return Positioned(
        left: visualX - coverageRadius,
        top: visualY - coverageRadius,
        child: Container(
          width: coverageRadius * 2,
          height: coverageRadius * 2,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: _getSpeakerColor(placement.speakerType).withOpacity(0.05),
            border: Border.all(
              color: _getSpeakerColor(placement.speakerType).withOpacity(0.2),
              width: 1,
              style: BorderStyle.solid,
            ),
          ),
        ),
      );
    }).toList();
  }

  List<Widget> _buildEnhancedDimensionLabels(
    double roomLength,
    double roomWidth,
    double visualWidth,
    double visualHeight,
  ) {
    return <Widget>[
      // Top dimension label with enhanced styling
      Positioned(
        top: 10,
        left: 80 + visualWidth / 2 - 60,
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: <Color>[Colors.brown.shade700, Colors.brown.shade600],
            ),
            borderRadius: BorderRadius.circular(20),
            boxShadow: <BoxShadow>[
              BoxShadow(
                color: Colors.black.withOpacity(0.3),
                blurRadius: 6,
                offset: const Offset(0, 3),
              ),
            ],
          ),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              const Icon(Icons.straighten, color: Colors.white, size: 16),
              const SizedBox(width: 6),
              Text(
                'Length: ${roomLength.toStringAsFixed(1)}m',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
      // Left dimension label with enhanced styling
      Positioned(
        left: 10,
        top: 50 + visualHeight / 2 - 20,
        child: RotatedBox(
          quarterTurns: 3,
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Colors.brown.shade700, Colors.brown.shade600],
              ),
              borderRadius: BorderRadius.circular(20),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.3),
                  blurRadius: 6,
                  offset: const Offset(0, 3),
                ),
              ],
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const Icon(Icons.width_normal, color: Colors.white, size: 16),
                const SizedBox(width: 6),
                Text(
                  'Width: ${roomWidth.toStringAsFixed(1)}m',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 14,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    ];
  }

  Widget _buildCoordinateSystem(double visualWidth, double visualHeight) {
    return Positioned(
      left: 80,
      top: 50,
      child: Container(
        width: visualWidth,
        height: visualHeight,
        child: Stack(
          children: <Widget>[
            // Origin marker (0,0)
            Positioned(
              left: -8,
              top: -8,
              child: Container(
                width: 16,
                height: 16,
                decoration: BoxDecoration(
                  color: Colors.red,
                  shape: BoxShape.circle,
                  border: Border.all(color: Colors.white, width: 2),
                ),
                child: const Center(
                  child: Text(
                    '0',
                    style: TextStyle(
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
      ),
    );
  }







  Widget _buildInputField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
  }) {
    return TextField(
      controller: controller,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, size: 20),
        border: const OutlineInputBorder(),
        contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
      ),
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
    );
  }

  Widget _buildSummaryRow(String label, String value, {bool isTotal = false}) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6.0),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label, 
            style: TextStyle(
              fontWeight: isTotal ? FontWeight.bold : FontWeight.w500,
              fontSize: isTotal ? 16 : 14,
            ),
          ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
            decoration: BoxDecoration(
              color: isTotal ? Colors.green : Colors.grey.shade200,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Text(
              value, 
              style: TextStyle(
                fontWeight: FontWeight.bold,
                color: isTotal ? Colors.white : Colors.black87,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Color _getSpeakerColor(String speakerType) {
    switch (speakerType) {
      case 'EM90':
      case 'EM-LP90':
        return Colors.blue;
      case 'EM180':
      case 'EM-LP180':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  IconData _getSpeakerIcon(String speakerType) {
    switch (speakerType) {
      case 'EM90':
      case 'EM-LP90':
        return Icons.volume_up; // Directional speaker icon
      case 'EM180':
      case 'EM-LP180':
        return Icons.surround_sound; // Wide coverage speaker
      default:
        return Icons.speaker;
    }
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _ceilingHeightController.dispose();
    _listenerHeightController.dispose();
    super.dispose();
  }
}
