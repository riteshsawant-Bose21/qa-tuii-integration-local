import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:fusion_lib/fusion_algorithms/surface_speakers_autolayout/surface_speakers_autolayout.dart';

/// A widget for surface speaker placement calculation and visualization.
class SurfaceSpeakerLayoutWidget extends StatefulWidget {
  const SurfaceSpeakerLayoutWidget({super.key});

  @override
  State<SurfaceSpeakerLayoutWidget> createState() => _SurfaceSpeakerLayoutWidgetState();
}

class _SurfaceSpeakerLayoutWidgetState extends State<SurfaceSpeakerLayoutWidget> {
  // Form controllers
  final TextEditingController _lengthController = TextEditingController(text: '30.5');
  final TextEditingController _widthController = TextEditingController(text: '20.1');
  final TextEditingController _heightController = TextEditingController(text: '11.9');
  final TextEditingController _listenerHeightController = TextEditingController(text: '1.7');
  // Speaker height removed - now hardcoded to 3 feet (0.914m) in the algorithm
  final TextEditingController _coverageAngleController = TextEditingController(text: '90.0');
  final TextEditingController _speakerTypeController = TextEditingController(text: 'Surface Mount Speaker');
  
  // Configuration
  CoveragePreference _coveragePreference = CoveragePreference.minimumOverlap;
  
  // Results
  SurfacePlacementResult? _result;
  String? _errorMessage;
  
  final GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    // Don't call _calculatePlacement() here as the form isn't built yet
  }

  @override
  void dispose() {
    _lengthController.dispose();
    _widthController.dispose();
    _heightController.dispose();
    _listenerHeightController.dispose();
    // _speakerHeightController removed - height now hardcoded
    _coverageAngleController.dispose();
    _speakerTypeController.dispose();
    super.dispose();
  }

  void _calculatePlacement() {
    if (_formKey.currentState == null || !_formKey.currentState!.validate()) return;
    
    setState(() {
      _errorMessage = null;
      _result = null;
    });

    try {
      final SurfaceRoom room = SurfaceRoom(
        length: double.parse(_lengthController.text),
        width: double.parse(_widthController.text),
        ceilingHeight: double.parse(_heightController.text),
        listenerHeight: double.parse(_listenerHeightController.text),
      );

      final Loudspeaker speaker = Loudspeaker(
        // height defaults to 3 feet (0.914m) - no longer user configurable
        horizontalCoverageAngle: double.parse(_coverageAngleController.text),
        type: _speakerTypeController.text,
      );

      final PlacementConfig config = PlacementConfig(
        coveragePreference: _coveragePreference,
        enableDebugOutput: false,
      );

      final SurfacePlacementResult result = SurfaceSpeakerPlacer.calculatePlacement(
        room: room,
        speaker: speaker,
        config: config,
      );

      // Additional validation checks
      
      setState(() {
        _result = result;
      });
    } catch (e) {
      setState(() {
        _errorMessage = e.toString();
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Surface Speaker Layout Calculator'),
        backgroundColor: Theme.of(context).colorScheme.inversePrimary,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildRoomParametersCard(),
              const SizedBox(height: 16),
              _buildSpeakerParametersCard(),
              const SizedBox(height: 16),
              _buildConfigurationCard(),
              const SizedBox(height: 16),
              _buildDownAngleReferenceCard(),
              const SizedBox(height: 16),
              _buildActionButtons(),
              const SizedBox(height: 16),
              if (_errorMessage != null) _buildErrorCard(),
              if (_result != null) ...<Widget>[
                _buildResultsCard(),
                const SizedBox(height: 16),
                _buildVisualizationCard(),
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildRoomParametersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Room Parameters', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: _buildNumberField(_lengthController, 'Length (m)', Icons.straighten)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_widthController, 'Width (m)', Icons.width_normal)),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: <Widget>[
                Expanded(child: _buildNumberField(_heightController, 'Ceiling Height (m)', Icons.height)),
                const SizedBox(width: 16),
                Expanded(child: _buildNumberField(_listenerHeightController, 'Listener Height (m)', Icons.person, min: 0.1, max: 2.4)),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpeakerParametersCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Speaker Parameters', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 16),
            TextFormField(
              controller: _speakerTypeController,
              decoration: const InputDecoration(
                labelText: 'Speaker Type',
                prefixIcon: Icon(Icons.speaker),
                border: OutlineInputBorder(),
              ),
              validator: (String? value) => value?.isEmpty == true ? 'Please enter speaker type' : null,
            ),
            const SizedBox(height: 16),
            _buildNumberField(_coverageAngleController, 'Coverage Angle (°)', Icons.radio_button_unchecked, min: 30, max: 180),
            const SizedBox(height: 8),
            Text(
              'Mounting: 6 inches below ceiling (practical installation)',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildConfigurationCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text('Coverage Configuration', style: Theme.of(context).textTheme.headlineSmall),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.5)),
              ),
              child: Row(
                children: <Widget>[
                  Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      'Surface speakers have directional coverage (sector/wedge shaped), not circular like ceiling speakers.',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Theme.of(context).colorScheme.onSurfaceVariant,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Text('Coverage Preference: ${_coveragePreference.name}'),
            const SizedBox(height: 8),
            Text(
              _coveragePreference.description,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                color: Theme.of(context).colorScheme.onSurfaceVariant,
                fontStyle: FontStyle.italic,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8.0,
              children: CoveragePreference.values.map((CoveragePreference preference) {
                final bool isSelected = _coveragePreference == preference;
                return ChoiceChip(
                  label: Text(_formatPreferenceName(preference.name)),
                  selected: isSelected,
                  onSelected: (bool selected) {
                    if (selected) {
                      setState(() {
                        _coveragePreference = preference;
                      });
                      _calculatePlacement();
                    }
                  },
                );
              }).toList(),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.onSurfaceVariant),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'Overlap multiplier: ${_coveragePreference.overlapMultiplier}x (directional sector coverage, not circular)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
  
  String _formatPreferenceName(String name) {
    // Convert camelCase to Title Case
    return name.replaceAllMapped(RegExp(r'([A-Z])'), (Match match) => ' ${match.group(1)}')
               .split(' ')
               .map((String word) => word.isEmpty ? '' : word[0].toUpperCase() + word.substring(1))
               .join(' ')
               .trim();
  }

  Widget _buildDownAngleReferenceCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.table_chart, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text('Down Angle Reference Table', 
                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                       color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: <Widget>[
                  // Header
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.secondaryContainer,
                      borderRadius: const BorderRadius.only(
                        topLeft: Radius.circular(8),
                        topRight: Radius.circular(8),
                      ),
                    ),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Mounting Height (m)',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                        Container(
                          width: 1,
                          height: 20,
                          color: Theme.of(context).colorScheme.outline,
                        ),
                        Expanded(
                          child: Text(
                            'Down-angle (deg)',
                            style: Theme.of(context).textTheme.titleSmall?.copyWith(
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                  // Table rows
                  _buildTableRow('Less than 2.4', '-5', _result?.mountingHeight != null && _result!.mountingHeight < 2.4),
                  _buildTableRow('2.4 - 4.6', '-15', _result?.mountingHeight != null && _result!.mountingHeight >= 2.4 && _result!.mountingHeight <= 4.6),
                  _buildTableRow('4.6 - 5.5', '-30', _result?.mountingHeight != null && _result!.mountingHeight >= 4.6 && _result!.mountingHeight <= 5.5),
                  _buildTableRow('5.5 and above', '-45', _result?.mountingHeight != null && _result!.mountingHeight >= 5.5),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Row(
              children: <Widget>[
                Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    'The highlighted row shows the range for your current mounting height.',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.primary,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTableRow(String height, String angle, bool isHighlighted) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: isHighlighted 
            ? Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5)
            : null,
        border: Border(
          bottom: BorderSide(
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
            width: 0.5,
          ),
        ),
      ),
      child: Row(
        children: <Widget>[
          Expanded(
            child: Text(
              height,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted 
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
          Container(
            width: 1,
            height: 20,
            color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
          ),
          Expanded(
            child: Text(
              angle,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: isHighlighted ? FontWeight.bold : FontWeight.normal,
                color: isHighlighted 
                    ? Theme.of(context).colorScheme.primary
                    : null,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildNumberField(
    TextEditingController controller,
    String label,
    IconData icon, {
    double min = 0.1,
    double max = 1000,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: TextInputType.number,
      inputFormatters: <TextInputFormatter>[
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon),
        border: const OutlineInputBorder(),
      ),
      validator: (String? value) {
        if (value?.isEmpty == true) return 'Please enter $label';
        final double? number = double.tryParse(value!);
        if (number == null) return 'Please enter a valid number';
        if (number < min || number > max) return 'Value must be between $min and $max';
        return null;
      },
      onChanged: (_) => _calculatePlacement(),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: <Widget>[
        ElevatedButton.icon(
          onPressed: _calculatePlacement,
          icon: const Icon(Icons.calculate),
          label: const Text('Calculate'),
        ),
        const SizedBox(width: 16),
        OutlinedButton.icon(
          onPressed: _resetToDefaults,
          icon: const Icon(Icons.refresh),
          label: const Text('Reset'),
        ),
      ],
    );
  }

  void _resetToDefaults() {
    _lengthController.text = '30.5';
    _widthController.text = '20.1';
    _heightController.text = '11.9';
    _listenerHeightController.text = '1.7';
    // Speaker height removed - now hardcoded to 0.91 meters
    _coverageAngleController.text = '90.0';
    _speakerTypeController.text = 'Surface Mount Speaker';
    setState(() => _coveragePreference = CoveragePreference.minimumOverlap);
    _calculatePlacement();
  }

  Widget _buildErrorCard() {
    final bool isWarning = _errorMessage!.startsWith('Warning:');
    final Color backgroundColor = isWarning 
        ? Colors.orange.shade100 
        : Theme.of(context).colorScheme.errorContainer;
    final Color iconColor = isWarning 
        ? Colors.orange.shade700 
        : Theme.of(context).colorScheme.error;
    final Color textColor = isWarning 
        ? Colors.orange.shade700 
        : Theme.of(context).colorScheme.onErrorContainer;
    final IconData icon = isWarning ? Icons.warning : Icons.error;

    return Card(
      color: backgroundColor,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          children: <Widget>[
            Icon(icon, color: iconColor),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                _errorMessage!,
                style: TextStyle(color: textColor),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsCard() {
    if (_result == null) return const SizedBox.shrink();

    return Column(
      children: <Widget>[
        // Quick Summary Card
        Card(
          color: Theme.of(context).colorScheme.primaryContainer,
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                Row(
                  children: <Widget>[
                    Icon(Icons.summarize, color: Theme.of(context).colorScheme.primary),
                    const SizedBox(width: 8),
                    Text('Speaker Layout Summary', 
                         style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                           color: Theme.of(context).colorScheme.primary)),
                  ],
                ),
                const SizedBox(height: 16),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                  children: <Widget>[
                    _buildSummaryMetric('Total Speakers', '${_result!.totalSpeakers}', Icons.speaker_group),
                    _buildSummaryMetric('Front/Back Walls', '${_result!.speakersOnLength} each', Icons.linear_scale),
                    _buildSummaryMetric('Left/Right Walls', '${_result!.speakersOnWidth} each', Icons.linear_scale_outlined),
                  ],
                ),
              ],
            ),
          ),
        ),
        const SizedBox(height: 16),
        
        // Detailed Step-by-Step Calculations
        _buildCalculationStepsCard(),
      ],
    );
  }

  Widget _buildSummaryMetric(String label, String value, IconData icon) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 32, color: Theme.of(context).colorScheme.primary),
        const SizedBox(height: 4),
        Text(value, style: Theme.of(context).textTheme.headlineMedium?.copyWith(
          fontWeight: FontWeight.bold,
          color: Theme.of(context).colorScheme.primary,
        )),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
      ],
    );
  }

  Widget _buildCalculationStepsCard() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.calculate, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Text('Calculation Steps', 
                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                       color: Theme.of(context).colorScheme.secondary)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Step 1: Find distance d from loudspeaker to listener plane
            _buildCalculationStep(
              stepNumber: 1,
              title: 'Find Distance from Loudspeaker to Listener Plane',
              icon: Icons.straighten,
              formula: 'd_horiz = (mounting_height - listener_height) / tan(down_angle)',
              calculation: 'd_horiz = (${_result!.mountingHeight.toStringAsFixed(1)} - ${double.parse(_listenerHeightController.text)}) / tan(${_result!.downAngle.abs().toStringAsFixed(0)}°)\n'
                          'd_horiz = ${(_result!.mountingHeight - double.parse(_listenerHeightController.text)).toStringAsFixed(1)} / ${(tan(_result!.downAngle.abs() * pi / 180)).toStringAsFixed(3)}\n'
                          'd_horiz = ${_result!.distanceToListenerPlane.toStringAsFixed(2)} m',
              result: 'd_horiz = ${_result!.distanceToListenerPlane.toStringAsFixed(2)} m',
              explanation: 'Horizontal distance from loudspeaker to the listener plane using the down-angle',
            ),
            
            // Step 2: Determine horizontal coverage
            _buildCalculationStep(
              stepNumber: 2,
              title: 'Determine Horizontal Coverage at Initial Mounting Height',
              icon: Icons.radio_button_unchecked,
              formula: 'Horizontal_coverage = 2 × tan(θ/2) × d',
              calculation: 'Horizontal_coverage = 2 × tan(${double.parse(_coverageAngleController.text)}°/2) × ${_result!.distanceToListenerPlane.toStringAsFixed(2)}\n'
                          'Horizontal_coverage = 2 × tan(${(double.parse(_coverageAngleController.text)/2).toStringAsFixed(1)}°) × ${_result!.distanceToListenerPlane.toStringAsFixed(2)}\n'
                          'Horizontal_coverage = 2 × ${(tan((double.parse(_coverageAngleController.text)/2) * pi / 180)).toStringAsFixed(3)} × ${_result!.distanceToListenerPlane.toStringAsFixed(2)}\n'
                          'Horizontal_coverage = ${_result!.coverageWidth.toStringAsFixed(2)} m',
              result: '${_result!.coverageWidth.toStringAsFixed(2)} m',
              explanation: 'Horizontal coverage slice the loudspeaker provides at the initial mounting height',
            ),
            
            // Step 3: Place speakers around perimeter with overlap
            _buildCalculationStep(
              stepNumber: 3,
              title: 'Place Horizontal Loudspeakers Around Perimeter',
              icon: Icons.grid_view,
              formula: 'Speakers per Wall = ceil(Wall Length / Effective Coverage)',
              calculation: 'Effective Coverage = ${_result!.coverageWidth.toStringAsFixed(2)} × ${_coveragePreference.overlapMultiplier} (${_coveragePreference.name}) = ${_result!.effectiveCoverage.toStringAsFixed(2)} m\n\n'
                          'Length Walls (${double.parse(_lengthController.text)} m): ceil(${double.parse(_lengthController.text)} / ${_result!.effectiveCoverage.toStringAsFixed(2)}) = ${_result!.speakersOnLength} each\n'
                          'Width Walls (${double.parse(_widthController.text)} m): ceil(${double.parse(_widthController.text)} / ${_result!.effectiveCoverage.toStringAsFixed(2)}) = ${_result!.speakersOnWidth} each\n\n'
                          'Total: (${_result!.speakersOnLength} × 2) + (${_result!.speakersOnWidth} × 2) = ${_result!.totalSpeakers} speakers',
              result: 'Total: ${_result!.totalSpeakers} speakers',
              explanation: 'Place horizontal loudspeakers around perimeter such that desired overlap is fulfilled',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCalculationStep({
    required int stepNumber,
    required String title,
    required IconData icon,
    required String formula,
    required String calculation,
    required String result,
    required String explanation,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
        borderRadius: BorderRadius.circular(8),
        color: Theme.of(context).colorScheme.surface,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Step Header
          Row(
            children: <Widget>[
              CircleAvatar(
                radius: 16,
                backgroundColor: Theme.of(context).colorScheme.secondary,
                child: Text(
                  '$stepNumber',
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.onSecondary,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Icon(icon, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Text(
                  result,
                  style: TextStyle(
                    color: Theme.of(context).colorScheme.primary,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          
          // Formula
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Row(
              children: <Widget>[
                Icon(Icons.functions, size: 16, color: Theme.of(context).colorScheme.secondary),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    formula,
                    style: TextStyle(
                      fontFamily: 'monospace',
                      color: Theme.of(context).colorScheme.secondary,
                      fontSize: 12,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Calculation
          Text(
            'Calculation:',
            style: Theme.of(context).textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            calculation,
            style: TextStyle(
              fontFamily: 'monospace',
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ),
          ),
          const SizedBox(height: 8),
          
          // Explanation
          Row(
            children: <Widget>[
              Icon(Icons.info_outline, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  explanation,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: Theme.of(context).colorScheme.primary,
                    fontStyle: FontStyle.italic,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildVisualizationCard() {
    if (_result == null) return const SizedBox.shrink();

    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.view_in_ar, color: Theme.of(context).colorScheme.tertiary),
                const SizedBox(width: 8),
                Text('Speaker Placement Visualization', 
                     style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                       color: Theme.of(context).colorScheme.tertiary)),
              ],
            ),
            const SizedBox(height: 16),
            
            // Room dimensions info
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                children: <Widget>[
                  _buildDimensionInfo('Length', '${double.parse(_lengthController.text)} m', Icons.straighten),
                  _buildDimensionInfo('Width', '${double.parse(_widthController.text)} m', Icons.width_normal),
                  _buildDimensionInfo('Height', '${double.parse(_heightController.text)} m', Icons.height),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // 2D Top View with improved visualization
            Container(
              height: 350,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Theme.of(context).colorScheme.outline),
                borderRadius: BorderRadius.circular(8),
                color: Theme.of(context).colorScheme.surface,
                boxShadow: <BoxShadow>[
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 4,
                    offset: const Offset(0, 2),
                  ),
                ],
              ),
              child: CustomPaint(
                painter: RoomLayoutPainter(_result!),
              ),
            ),
            const SizedBox(height: 16),
            
            // Enhanced Legend with more details
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceVariant.withOpacity(0.3),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                children: <Widget>[
                  Text('Legend & Coverage Pattern', style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                  )),
                  const SizedBox(height: 8),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                    children: <Widget>[
                      _buildLegendItem(Colors.blue.shade700, 'Room Walls', Icons.crop_square),
                      _buildLegendItem(Colors.red.shade600, 'Surface Speakers', Icons.crop_square),
                      _buildLegendItem(Colors.orange.withOpacity(0.3), 'Directional Coverage', Icons.play_arrow),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Top-down view showing surface speakers mounted on walls with directional sector coverage patterns',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontStyle: FontStyle.italic,
                      color: Theme.of(context).colorScheme.onSurfaceVariant,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            
            // Detailed Speaker Positions List
            _buildSpeakerPositionsList(),
            const SizedBox(height: 16),
            
            // Speaker Placement Details
            _buildPlacementDetails(),
          ],
        ),
      ),
    );
  }

  Widget _buildDimensionInfo(String label, String value, IconData icon) {
    return Column(
      children: <Widget>[
        Icon(icon, size: 24, color: Theme.of(context).colorScheme.tertiary),
        const SizedBox(height: 4),
        Text(label, style: Theme.of(context).textTheme.bodySmall),
        Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
          fontWeight: FontWeight.bold,
        )),
      ],
    );
  }

  Widget _buildPlacementDetails() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.info, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text('Speaker Placement Details', 
                   style: Theme.of(context).textTheme.titleSmall?.copyWith(
                     fontWeight: FontWeight.bold,
                     color: Theme.of(context).colorScheme.primary,
                   )),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildDetailItem(
                  'Mounting Height',
                  '${_result!.mountingHeight.toStringAsFixed(1)} m',
                  Icons.height,
                  'Height above floor',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Down Angle',
                  '${_result!.downAngle.toStringAsFixed(1)}°',
                  Icons.trending_down,
                  'Speaker tilt angle',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Coverage Angle',
                  '${_result!.horizontalCoverageAngle.toStringAsFixed(0)}°',
                  Icons.radio_button_unchecked,
                  'Horizontal coverage spread',
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: <Widget>[
              Expanded(
                child: _buildDetailItem(
                  'Coverage Width',
                  '${_result!.coverageWidth.toStringAsFixed(1)} m',
                  Icons.radio_button_unchecked,
                  'Sound coverage width',
                ),
              ),
              Expanded(
                child: _buildDetailItem(
                  'Coverage',
                  '${_coveragePreference.overlapMultiplier}x',
                  Icons.compare_arrows,
                  'Coverage preference: ${_coveragePreference.name}',
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildDetailItem(String label, String value, IconData icon, String description) {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 4),
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(icon, size: 16, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 4),
              Expanded(
                child: Text(label, style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontWeight: FontWeight.bold,
                )),
              ),
            ],
          ),
          const SizedBox(height: 2),
          Text(value, style: Theme.of(context).textTheme.bodyMedium?.copyWith(
            color: Theme.of(context).colorScheme.primary,
            fontWeight: FontWeight.bold,
          )),
          Text(description, style: Theme.of(context).textTheme.bodySmall?.copyWith(
            color: Theme.of(context).colorScheme.onSurfaceVariant,
            fontSize: 10,
          )),
        ],
      ),
    );
  }

  Widget _buildLegendItem(Color color, String label, IconData icon) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Icon(icon, color: color, size: 16),
        const SizedBox(width: 4),
        Container(
          width: 12,
          height: 12,
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(2),
          ),
        ),
        const SizedBox(width: 4),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  Widget _buildSpeakerPositionsList() {
    if (_result == null) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.list_alt, color: Theme.of(context).colorScheme.primary),
              const SizedBox(width: 8),
              Text(
                'Speaker Positions (${_result!.totalSpeakers} total)',
                style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          // Group speakers by wall
          _buildWallSpeakers('Front Wall (Length)', 
              _result!.positions.where((SpeakerPosition p) => p.y == 0).toList()),
          const SizedBox(height: 8),
          _buildWallSpeakers('Back Wall (Length)', 
              _result!.positions.where((SpeakerPosition p) => p.y == double.parse(_widthController.text)).toList()),
          const SizedBox(height: 8),
          _buildWallSpeakers('Left Wall (Width)', 
              _result!.positions.where((SpeakerPosition p) => p.x == 0).toList()),
          const SizedBox(height: 8),
          _buildWallSpeakers('Right Wall (Width)', 
              _result!.positions.where((SpeakerPosition p) => p.x == double.parse(_lengthController.text)).toList()),
        ],
      ),
    );
  }

  Widget _buildWallSpeakers(String wallName, List<SpeakerPosition> speakers) {
    if (speakers.isEmpty) return const SizedBox.shrink();

    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Theme.of(context).colorScheme.outline.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.border_all, size: 16, color: Theme.of(context).colorScheme.secondary),
              const SizedBox(width: 8),
              Text(
                '$wallName (${speakers.length} speakers)',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.secondary,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8,
            runSpacing: 4,
            children: speakers.asMap().entries.map((MapEntry<int, SpeakerPosition> entry) {
              final int index = entry.key;
              final SpeakerPosition speaker = entry.value;
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.tertiaryContainer.withOpacity(0.3),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  'SP${index + 1}: (${speaker.x.toStringAsFixed(1)}, ${speaker.y.toStringAsFixed(1)}, ${speaker.z.toStringAsFixed(1)})',
                  style: const TextStyle(
                    fontSize: 11,
                    fontFamily: 'monospace',
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }
}

/// Enhanced custom painter for room layout visualization with proper directional coverage patterns
class RoomLayoutPainter extends CustomPainter {
  const RoomLayoutPainter(this.result);
  
  final SurfacePlacementResult result;

  @override
  void paint(Canvas canvas, Size size) {
    // Use actual room dimensions from the result
    final double roomLength = result.roomLength;
    final double roomWidth = result.roomWidth;

    // Calculate scale with proper padding
    const double padding = 60.0;
    final double scaleX = (size.width - 2 * padding) / roomLength;
    final double scaleY = (size.height - 2 * padding) / roomWidth;
    final double scale = scaleX < scaleY ? scaleX : scaleY;

    // Calculate offset to center the room
    final double offsetX = (size.width - roomLength * scale) / 2;
    final double offsetY = (size.height - roomWidth * scale) / 2;

    _drawRoom(canvas, size, offsetX, offsetY, roomLength, roomWidth, scale);
    _drawDirectionalCoverage(canvas, offsetX, offsetY, roomLength, roomWidth, scale);
    _drawSpeakers(canvas, offsetX, offsetY, scale);
    _drawRoomLabels(canvas, offsetX, offsetY, roomLength, roomWidth, scale);
  }

  void _drawRoom(Canvas canvas, Size size, double offsetX, double offsetY, double roomLength, double roomWidth, double scale) {
    // Paint styles
    final Paint roomFillPaint = Paint()
      ..color = const Color(0xFFF5F5F5)
      ..style = PaintingStyle.fill;
    
    final Paint roomBorderPaint = Paint()
      ..color = Colors.blue.shade700
      ..style = PaintingStyle.stroke
      ..strokeWidth = 3;

    final Paint gridPaint = Paint()
      ..color = Colors.grey.withOpacity(0.2)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Draw room background
    final Rect roomRect = Rect.fromLTWH(
      offsetX,
      offsetY,
      roomLength * scale,
      roomWidth * scale,
    );

    // Draw subtle grid lines every 1.5 meters
    for (double i = 0; i <= roomLength; i += 1.5) {
      final double x = offsetX + i * scale;
      canvas.drawLine(
        Offset(x, offsetY),
        Offset(x, offsetY + roomWidth * scale),
        gridPaint,
      );
    }
    for (double i = 0; i <= roomWidth; i += 1.5) {
      final double y = offsetY + i * scale;
      canvas.drawLine(
        Offset(offsetX, y),
        Offset(offsetX + roomLength * scale, y),
        gridPaint,
      );
    }

    canvas.drawRect(roomRect, roomFillPaint);
    canvas.drawRect(roomRect, roomBorderPaint);
  }

  void _drawDirectionalCoverage(Canvas canvas, double offsetX, double offsetY, double roomLength, double roomWidth, double scale) {
    final Paint coveragePaint = Paint()
      ..color = Colors.orange.withOpacity(0.15)
      ..style = PaintingStyle.fill;

    final Paint coverageStrokePaint = Paint()
      ..color = Colors.orange.withOpacity(0.4)
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1;

    // Create clipping rectangle for room boundaries
    final Rect roomBounds = Rect.fromLTWH(
      offsetX,
      offsetY,
      roomLength * scale,
      roomWidth * scale,
    );

    // Save canvas state and apply clipping
    canvas.save();
    canvas.clipRect(roomBounds);

    // Draw directional coverage sectors for each speaker
    for (final SpeakerPosition position in result.positions) {
      final double speakerX = offsetX + position.x * scale;
      final double speakerY = offsetY + position.y * scale;
      
      // Determine speaker wall position and coverage direction
      final bool onLeftWall = position.x == 0;
      final bool onRightWall = position.x == roomLength;
      final bool onFrontWall = position.y == 0;
      final bool onBackWall = position.y == roomWidth;

      // Calculate coverage sector based on wall position
      // For visualization, limit coverage distance to room dimensions
      double maxCoverageDistance;
      if (onFrontWall || onBackWall) {
        maxCoverageDistance = roomWidth; // Front/back walls cover across width
      } else {
        maxCoverageDistance = roomLength; // Left/right walls cover across length
      }
      
      // Use the smaller of calculated distance or room dimension for visualization
      final double actualDistance = result.distanceToListenerPlane;
      final double visualDistance = (actualDistance < maxCoverageDistance) ? actualDistance : maxCoverageDistance;
      final double coverageDistance = visualDistance * scale;
      final double coverageWidth = result.coverageWidth * scale;
      
      final Path coveragePath = Path();
      
      if (onFrontWall) {
        // Speaker on front wall - coverage points into room (downward)
        _drawSectorCoverage(canvas, coveragePath, speakerX, speakerY, 
                           coverageDistance, coverageWidth, 90, // 90 degrees = pointing down into room
                           coveragePaint, coverageStrokePaint);
      } else if (onBackWall) {
        // Speaker on back wall - coverage points into room (upward)  
        _drawSectorCoverage(canvas, coveragePath, speakerX, speakerY,
                           coverageDistance, coverageWidth, 270, // 270 degrees = pointing up into room
                           coveragePaint, coverageStrokePaint);
      } else if (onLeftWall) {
        // Speaker on left wall - coverage points into room (rightward)
        _drawSectorCoverage(canvas, coveragePath, speakerX, speakerY,
                           coverageDistance, coverageWidth, 0, // 0 degrees = pointing right into room
                           coveragePaint, coverageStrokePaint);
      } else if (onRightWall) {
        // Speaker on right wall - coverage points into room (leftward)
        _drawSectorCoverage(canvas, coveragePath, speakerX, speakerY,
                           coverageDistance, coverageWidth, 180, // 180 degrees = pointing left into room
                           coveragePaint, coverageStrokePaint);
      }
    }

    // Restore canvas state (remove clipping)
    canvas.restore();
  }

  void _drawSectorCoverage(Canvas canvas, Path path, double centerX, double centerY, 
                          double distance, double width, double directionDegrees,
                          Paint fillPaint, Paint strokePaint) {
    // Convert direction to radians
    final double directionRadians = directionDegrees * 3.14159 / 180;
    
    // Use actual horizontal coverage angle from speaker specification
    final double halfAngleRadians = (result.horizontalCoverageAngle * 3.14159 / 180) / 2;
    
    // Calculate the sector endpoints
    final double leftAngle = directionRadians - halfAngleRadians;
    final double rightAngle = directionRadians + halfAngleRadians;
    
    // Calculate the end points of the sector
    final double leftEndX = centerX + distance * cos(leftAngle);
    final double leftEndY = centerY + distance * sin(leftAngle);
    
    // Create directional sector path (pie slice)
    path.reset();
    path.moveTo(centerX, centerY); // Start at speaker position
    path.lineTo(leftEndX, leftEndY); // Line to left edge of coverage
    
    // Add arc between the endpoints
    path.arcTo(
      Rect.fromCenter(center: Offset(centerX, centerY), width: distance * 2, height: distance * 2),
      leftAngle,
      rightAngle - leftAngle,
      false,
    );
    
    path.lineTo(centerX, centerY); // Line back to speaker position
    path.close();
    
    // Draw coverage sector
    canvas.drawPath(path, fillPaint);
    canvas.drawPath(path, strokePaint);
  }

  void _drawSpeakers(Canvas canvas, double offsetX, double offsetY, double scale) {
    final Paint speakerPaint = Paint()
      ..color = Colors.red.shade600
      ..style = PaintingStyle.fill;

    final Paint speakerBorderPaint = Paint()
      ..color = Colors.red.shade800
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2;

    // Draw speakers with directional indicators
    for (int i = 0; i < result.positions.length; i++) {
      final SpeakerPosition position = result.positions[i];
      final double speakerX = offsetX + position.x * scale;
      final double speakerY = offsetY + position.y * scale;
      
      // Draw speaker as a square (more representative of surface mount)
      final Rect speakerRect = Rect.fromCenter(
        center: Offset(speakerX, speakerY),
        width: 12,
        height: 12,
      );
      
      canvas.drawRRect(RRect.fromRectAndRadius(speakerRect, const Radius.circular(2)), speakerPaint);
      canvas.drawRRect(RRect.fromRectAndRadius(speakerRect, const Radius.circular(2)), speakerBorderPaint);
      
      // Draw speaker number
      final TextPainter textPainter = TextPainter(
        text: TextSpan(
          text: '${i + 1}',
          style: const TextStyle(
            color: Colors.white,
            fontSize: 9,
            fontWeight: FontWeight.bold,
          ),
        ),
        textAlign: TextAlign.center,
        textDirection: TextDirection.ltr,
      );
      textPainter.layout();
      textPainter.paint(
        canvas,
        Offset(
          speakerX - textPainter.width / 2,
          speakerY - textPainter.height / 2,
        ),
      );
    }
  }

  void _drawRoomLabels(Canvas canvas, double offsetX, double offsetY, double roomLength, double roomWidth, double scale) {
    final TextPainter labelPainter = TextPainter(
      textAlign: TextAlign.center,
      textDirection: TextDirection.ltr,
    );

    // Front wall label
    labelPainter.text = const TextSpan(
      text: 'FRONT WALL',
      style: TextStyle(
        color: Colors.blue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(offsetX + roomLength * scale / 2 - labelPainter.width / 2, offsetY - 35),
    );

    // Length dimension
    labelPainter.text = TextSpan(
      text: '${roomLength.toStringAsFixed(1)} m',
      style: const TextStyle(color: Colors.black54, fontSize: 11),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(offsetX + roomLength * scale / 2 - labelPainter.width / 2, offsetY - 20),
    );

    // Back wall label
    labelPainter.text = const TextSpan(
      text: 'BACK WALL',
      style: TextStyle(
        color: Colors.blue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(offsetX + roomLength * scale / 2 - labelPainter.width / 2, offsetY + roomWidth * scale + 15),
    );

    // Width dimension
    labelPainter.text = TextSpan(
      text: '${roomWidth.toStringAsFixed(1)} m',
      style: const TextStyle(color: Colors.black54, fontSize: 11),
    );
    labelPainter.layout();
    labelPainter.paint(
      canvas,
      Offset(offsetX + roomLength * scale / 2 - labelPainter.width / 2, offsetY + roomWidth * scale + 30),
    );

    // Left wall label (rotated)
    canvas.save();
    canvas.translate(offsetX - 25, offsetY + roomWidth * scale / 2);
    canvas.rotate(-3.14159 / 2); // Rotate 90 degrees counterclockwise
    labelPainter.text = const TextSpan(
      text: 'LEFT WALL',
      style: TextStyle(
        color: Colors.blue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(-labelPainter.width / 2, 0));
    canvas.restore();

    // Right wall label (rotated)
    canvas.save();
    canvas.translate(offsetX + roomLength * scale + 25, offsetY + roomWidth * scale / 2);
    canvas.rotate(3.14159 / 2); // Rotate 90 degrees clockwise
    labelPainter.text = const TextSpan(
      text: 'RIGHT WALL',
      style: TextStyle(
        color: Colors.blue,
        fontSize: 12,
        fontWeight: FontWeight.bold,
      ),
    );
    labelPainter.layout();
    labelPainter.paint(canvas, Offset(-labelPainter.width / 2, 0));
    canvas.restore();
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => true;
}
