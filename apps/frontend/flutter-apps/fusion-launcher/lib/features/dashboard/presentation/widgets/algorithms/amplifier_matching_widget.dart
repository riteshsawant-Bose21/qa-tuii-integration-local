import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_gradient_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_form_field.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_gradient_text.dart';
import 'package:fusion_lib/fusion_algorithms/amplifier_matching/amplifier_matching.dart';
import 'package:fusion_lib/api_data/speakers/speakers.dart';
import '../../../../../core/services/circuit_data_service.dart';


/// Input model for circuit configuration
class CircuitInput {
  String? selectedModel;
  final TextEditingController speakerCountController = TextEditingController(text: '1');
  final TextEditingController tapWattsController = TextEditingController(text: '15.0');
  final TextEditingController offsetDbController = TextEditingController(text: '0.0');
  String mode = 'hi-z';
  int circuitId;

  CircuitInput(this.circuitId);

  void dispose() {
    speakerCountController.dispose();
    tapWattsController.dispose();
    offsetDbController.dispose();
  }

  Circuit? toCircuit() {
    if (selectedModel == null || selectedModel!.isEmpty) return null;
    
    final int speakerCount = int.tryParse(speakerCountController.text) ?? 1;
    final double tapWatts = double.tryParse(tapWattsController.text) ?? 0.0;
    final double offsetDb = double.tryParse(offsetDbController.text) ?? 0.0;

    return Circuit(
      circuitId: circuitId,
      model: selectedModel!,
      mode: mode,
      speakerCount: speakerCount,
      tapWatts: tapWatts,
      outputOffsetDb: offsetDb,
    );
  }
}

class AmplifierMatchingWidget extends StatefulWidget {
  const AmplifierMatchingWidget({super.key});

  @override
  State<AmplifierMatchingWidget> createState() => _AmplifierMatchingWidgetState();
}

class _AmplifierMatchingWidgetState extends State<AmplifierMatchingWidget> {
  final List<CircuitInput> circuits = <CircuitInput>[CircuitInput(1)];
  AmpMatchingResult? matchingResult;
  bool isLoading = false;
  String? errorMessage;
  final CircuitDataService _circuitDataService = CircuitDataService();
  bool _useCircuitingData = false;

  List<String> get availableSpeakerModels => SpeakerCatalog.database.keys.toList();
  @override
  void dispose() {
    for (final CircuitInput circuit in circuits) {
      circuit.dispose();
    }
    super.dispose();
  }

  void _addCircuit() {
    setState(() {
      circuits.add(CircuitInput(circuits.length + 1));
    });
  }

  void _removeCircuit(int index) {
    if (circuits.length > 1) {
      setState(() {
        circuits[index].dispose();
        circuits.removeAt(index);
        // Update circuit IDs
        for (int i = 0; i < circuits.length; i++) {
          circuits[i].circuitId = i + 1;
        }
      });
    }
  }

  void _calculateAmplifierMatching() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      matchingResult = null;
    });

    try {
      // Convert circuit inputs to circuit objects
      final List<Circuit> validCircuits = <Circuit>[];
      for (final CircuitInput input in circuits) {
        final Circuit? circuit = input.toCircuit();
        if (circuit != null) {
          validCircuits.add(circuit);
        }
      }

      if (validCircuits.isEmpty) {
        throw Exception('Please configure at least one valid circuit');
      }

      // Perform amplifier matching
      final AmpMatchingResult result = await matchAmplifiers(validCircuits, SpeakerCatalog.database);
      
      setState(() {
        matchingResult = result;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
      });
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  void _resetForm() {
    setState(() {
      circuits.clear();
      circuits.add(CircuitInput(1));
      matchingResult = null;
      errorMessage = null;
      _useCircuitingData = false;
    });
  }

  void _importCircuitingData() {
    if (!_circuitDataService.hasCircuitingData) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('No circuiting data available. Please run circuiting algorithm first.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }

    setState(() {
      // Clear existing circuits
      for (final CircuitInput circuit in circuits) {
        circuit.dispose();
      }
      circuits.clear();

      // Convert and import circuiting data
      final List<Circuit> importedCircuits = _circuitDataService.convertToCircuits(SpeakerCatalog.database);
      
      for (final Circuit circuit in importedCircuits) {
        final CircuitInput circuitInput = CircuitInput(circuit.circuitId);
        circuitInput.selectedModel = circuit.model;
        circuitInput.speakerCountController.text = circuit.speakerCount.toString();
        circuitInput.tapWattsController.text = circuit.tapWatts.toString();
        circuitInput.offsetDbController.text = circuit.outputOffsetDb.toString();
        circuitInput.mode = circuit.mode;
        
        circuits.add(circuitInput);
      }

      _useCircuitingData = true;
      matchingResult = null;
      errorMessage = null;
    });

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Imported ${circuits.length} circuits from circuiting algorithm'),
        backgroundColor: Colors.green,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          const FusionGradientText(
            text: 'Amplifier Matching',
            gradient: LinearGradient(colors: <Color>[Colors.orange, Colors.red]),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 8),
          Text(
            'Configure your circuits and get optimal amplifier recommendations',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
          ),
          const SizedBox(height: 24),

          // Circuit Data Import Section
          AnimatedBuilder(
            animation: _circuitDataService,
            builder: (BuildContext context, Widget? child) {
              return Container(
                width: double.infinity,
                padding: const EdgeInsets.all(16.0),
                decoration: BoxDecoration(
                  color: _circuitDataService.hasCircuitingData 
                    ? Colors.green.withValues(alpha: 0.1) 
                    : Colors.grey.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12.0),
                  border: Border.all(
                    color: _circuitDataService.hasCircuitingData 
                      ? Colors.green.withValues(alpha: 0.3)
                      : Colors.grey.withValues(alpha: 0.3)
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          _circuitDataService.hasCircuitingData ? Icons.check_circle : Icons.info,
                          color: _circuitDataService.hasCircuitingData ? Colors.green : Colors.grey,
                          size: 20,
                        ),
                        const SizedBox(width: 8),
                        const Text(
                          'Import from Circuiting Algorithm',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _circuitDataService.hasCircuitingData 
                        ? _circuitDataService.circuitingSummary
                        : 'No circuiting data available. Run the circuiting algorithm first to import circuit configurations.',
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey[600],
                      ),
                    ),
                    if (_circuitDataService.hasCircuitingData) ...<Widget>[
                      const SizedBox(height: 12),
                      Row(
                        children: <Widget>[
                          Expanded(
                            child: OutlinedButton.icon(
                              onPressed: _importCircuitingData,
                              icon: const Icon(Icons.download),
                              label: const Text('Import Circuit Data'),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: Colors.green,
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          if (_useCircuitingData)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 8.0),
                              decoration: BoxDecoration(
                                color: Colors.green.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(16.0),
                              ),
                              child: const Text(
                                'Using imported data',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.green,
                                ),
                              ),
                            ),
                        ],
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Circuit Configuration Section
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: <Widget>[
                      Text(
                        'Circuit Configuration',
                        style: Theme.of(context).textTheme.headlineSmall,
                      ),
                      Row(
                        children: <Widget>[
                          IconButton(
                            onPressed: _addCircuit,
                            icon: const Icon(Icons.add_circle),
                            tooltip: 'Add Circuit',
                            color: Colors.green,
                          ),
                          IconButton(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.refresh),
                            tooltip: 'Reset All',
                            color: Colors.blue,
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Circuit inputs
                  ...circuits.asMap().entries.map((MapEntry<int, CircuitInput> entry) {
                    final int index = entry.key;
                    final CircuitInput circuit = entry.value;
                    return _buildCircuitCard(circuit, index);
                  }),

                  const SizedBox(height: 16),

                  // Calculate button
                  Center(
                    child: isLoading
                        ? const CircularProgressIndicator()
                        : FusionGradientButton(
                            label: 'Calculate Amplifier Matching',
                            onTap: _calculateAmplifierMatching,
                            gradient: const LinearGradient(colors: <Color>[Colors.orange, Colors.red]),
                          ),
                  ),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Error message
          if (errorMessage != null) ...<Widget>[
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    const Icon(Icons.error, color: Colors.red),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        errorMessage!,
                        style: const TextStyle(color: Colors.red),
                      ),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
          ],

          // Results section
          if (matchingResult != null) _buildResultsSection(matchingResult!),
        ],
      ),
    );
  }

  Widget _buildCircuitCard(CircuitInput circuit, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Circuit header
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  'Circuit ${circuit.circuitId}',
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (circuits.length > 1)
                  IconButton(
                    onPressed: () => _removeCircuit(index),
                    icon: const Icon(Icons.delete),
                    color: Colors.red,
                    iconSize: 20,
                  ),
              ],
            ),
            const SizedBox(height: 12),

            // Speaker model selection
            DropdownButtonFormField<String>(
              value: circuit.selectedModel,
              items: availableSpeakerModels.map((String model) {
                return DropdownMenuItem<String>(
                  value: model,
                  child: Text(model),
                );
              }).toList(),
              onChanged: (String? value) {
                setState(() {
                  circuit.selectedModel = value;
                  // Auto-populate tap watts based on speaker model
                  if (value != null && SpeakerCatalog.database.containsKey(value)) {
                    final Speaker spec = SpeakerCatalog.database[value]!;
                    if (spec.hiZTaps.isNotEmpty) {
                      circuit.tapWattsController.text = spec.hiZTaps[1].toString();
                    }
                  }
                });
              },
              decoration: const InputDecoration(
                labelText: 'Speaker Model',
                hintText: 'Select Speaker Model',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 12),

            // Mode selection
            Row(
              children: <Widget>[
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Hi-Z'),
                    value: 'hi-z',
                    groupValue: circuit.mode,
                    onChanged: (String? value) {
                      setState(() {
                        circuit.mode = value ?? 'hi-z';
                      });
                    },
                    dense: true,
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Lo-Z'),
                    value: 'lo-z',
                    groupValue: circuit.mode,
                    onChanged: (String? value) {
                      setState(() {
                        circuit.mode = value ?? 'hi-z';
                      });
                    },
                    dense: true,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Configuration fields
            Row(
              children: <Widget>[
                Expanded(
                  child: FusionTextFormField(
                    title: 'Speaker Count',
                    hintText: 'e.g., 4',
                    controller: circuit.speakerCountController,
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                if (circuit.mode == 'hi-z')
                  Expanded(
                    child: FusionTextFormField(
                      title: 'Tap Watts',
                      hintText: 'e.g., 15.0',
                      controller: circuit.tapWattsController,
                      keyboardType: TextInputType.number,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: FusionTextFormField(
                    title: 'Offset (dB)',
                    hintText: 'e.g., 0.0',
                    controller: circuit.offsetDbController,
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            // Show available tap settings for selected speaker
            if (circuit.selectedModel != null && 
                SpeakerCatalog.database.containsKey(circuit.selectedModel) && 
                circuit.mode == 'hi-z') ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Available Taps: ${SpeakerCatalog.database[circuit.selectedModel]!.hiZTaps.map((double t) => '${t}W').join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600],
                  fontStyle: FontStyle.italic,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection(AmpMatchingResult result) {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'Amplifier Matching Results',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.green[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 16),

            // Summary metrics
            _buildMetricsRow(result),
            const SizedBox(height: 16),

            // Amplifier assignments
            Text(
              'Recommended Amplifiers',
              style: Theme.of(context).textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),

            ...result.assignments.asMap().entries.map((MapEntry<int, AmpAssignment> entry) {
              final int index = entry.key;
              final AmpAssignment assignment = entry.value;
              return _buildAmplifierCard(assignment, index);
            }),

            // Display errors if any
            if (result.hasErrors) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.red[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.red[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.error, color: Colors.red[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Errors',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...result.errors.map((String error) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $error',
                        style: TextStyle(color: Colors.red[700]),
                      ),
                    )),
                  ],
                ),
              ),
            ],

            // Display warnings if any
            if (result.hasWarnings) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.orange[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.orange[200]!),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(Icons.warning, color: Colors.orange[700], size: 20),
                        const SizedBox(width: 8),
                        Text(
                          'Warnings',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: Colors.orange[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    ...result.warnings.map((String warning) => Padding(
                      padding: const EdgeInsets.only(bottom: 4),
                      child: Text(
                        '• $warning',
                        style: TextStyle(color: Colors.orange[700]),
                      ),
                    )),
                  ],
                ),
              ),
            ],

            // Optimization notes
            if (result.optimizationNotes.isNotEmpty) ...<Widget>[
              const SizedBox(height: 16),
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: Colors.blue[50],
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: Colors.blue[200]!),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.info, color: Colors.blue[700], size: 20),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Text(
                            'Optimization Notes',
                            style: TextStyle(
                              fontWeight: FontWeight.bold,
                              color: Colors.blue[700],
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            result.optimizationNotes,
                            style: TextStyle(color: Colors.blue[700]),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildMetricsRow(AmpMatchingResult result) {
    return Row(
      children: <Widget>[
        Expanded(
          child: _buildMetricCard(
            'Power Efficiency',
            '${(result.powerEfficiency * 100).toStringAsFixed(1)}%',
            Icons.battery_charging_full,
            Colors.green,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            'Channel Efficiency',
            '${(result.channelEfficiency * 100).toStringAsFixed(1)}%',
            Icons.settings_input_component,
            Colors.blue,
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildMetricCard(
            'Amplifiers',
            result.amplifierCount.toString(),
            Icons.speaker,
            Colors.orange,
          ),
        ),
      ],
    );
  }

  Widget _buildMetricCard(String label, String value, IconData icon, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        // ignore: deprecated_member_use
        color: color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
        // ignore: deprecated_member_use
        border: Border.all(color: color.withOpacity(0.3)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildAmplifierCard(AmpAssignment assignment, int index) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: Padding(
        padding: const EdgeInsets.all(12.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                Text(
                  assignment.ampModel.name,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    '${assignment.usedChannels}/${assignment.totalChannels} channels',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.blue[700],
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 4),
            Text(
              '${assignment.ampModel.peakPerChannel.toInt()}W × ${assignment.ampModel.channels}ch '
              '(${(assignment.channelUtilization * 100).toStringAsFixed(1)}% utilization)',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 13,
              ),
            ),
            const SizedBox(height: 8),
              const Text(
                'Assigned Circuits:',
                style: TextStyle(fontWeight: FontWeight.w500),
              ),
            const SizedBox(height: 4),
            ...assignment.circuits.map((Circuit circuit) {
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Text(
                  '• Circuit ${circuit.circuitId}: ${circuit.speakerCount}× ${circuit.model} '
                  '(${circuit.mode}${circuit.mode == 'hi-z' ? ', ${circuit.tapWatts}W' : ''})',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey[700],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }
}
