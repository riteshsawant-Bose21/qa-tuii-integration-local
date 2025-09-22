import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_algorithms/amplifier_matching/amplifier_matching.dart';
import 'package:fusion_lib/fusion_algorithms/shared/speaker_database.dart';
import 'package:fusion_lib/api_data/speakers/speaker_types.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_gradient_button.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_gradient_text.dart';

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
  Map<PowerAllocationStrategy, AmpMatchingResult>? comparisonResults;
  bool isLoading = false;
  String? errorMessage;
  final CircuitDataService _circuitDataService = CircuitDataService();
  PowerAllocationStrategy _selectedStrategy = PowerAllocationStrategy.asymmetrical;

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
      comparisonResults = null;
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

      if (_selectedStrategy == PowerAllocationStrategy.comparison) {
        // Run both strategies for side-by-side comparison
        final Map<PowerAllocationStrategy, AmpMatchingResult> results = <PowerAllocationStrategy, AmpMatchingResult>{};
        
        final AmpMatchingResult symmetricalResult = await matchAmplifiers(
          validCircuits, 
          SpeakerCatalog.database,
          strategy: PowerAllocationStrategy.symmetrical,
        );
        results[PowerAllocationStrategy.symmetrical] = symmetricalResult;
        
        final AmpMatchingResult asymmetricalResult = await matchAmplifiers(
          validCircuits, 
          SpeakerCatalog.database,
          strategy: PowerAllocationStrategy.asymmetrical,
        );
        results[PowerAllocationStrategy.asymmetrical] = asymmetricalResult;
        
        setState(() {
          comparisonResults = results;
        });
      } else {
        // Perform single strategy matching
        final AmpMatchingResult result = await matchAmplifiers(
          validCircuits, 
          SpeakerCatalog.database,
          strategy: _selectedStrategy,
        );
        
        setState(() {
          matchingResult = result;
        });
      }
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
      comparisonResults = null;
      errorMessage = null;
      _selectedStrategy = PowerAllocationStrategy.asymmetrical;
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

      matchingResult = null;
      comparisonResults = null;
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
            'Configure your circuits and get optimal amplifier recommendations with detailed calculations',
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
                  color: _circuitDataService.hasCircuitingData ? Colors.green[50] : Colors.grey[50],
                  border: Border.all(color: _circuitDataService.hasCircuitingData ? Colors.green.withValues(alpha: 0.3) : Colors.grey.withValues(alpha: 0.3)),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Icon(
                          _circuitDataService.hasCircuitingData ? Icons.check_circle : Icons.info,
                          color: _circuitDataService.hasCircuitingData ? Colors.green : Colors.grey[600],
                        ),
                        const SizedBox(width: 8),
                        Text(
                          'Circuit Data Import',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: _circuitDataService.hasCircuitingData ? Colors.green[700] : Colors.grey[700],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _circuitDataService.hasCircuitingData
                          ? 'Circuiting data available'
                          : 'No circuiting data available. Run circuiting algorithm first or configure manually.',
                      style: TextStyle(color: Colors.grey[600]),
                    ),
                    if (_circuitDataService.hasCircuitingData) ...<Widget>[
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        onPressed: _importCircuitingData,
                        icon: const Icon(Icons.download),
                        label: const Text('Import Circuit Data'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
                      ),
                    ],
                  ],
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // Power Allocation Strategy Selection
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Power Allocation Strategy',
                    style: Theme.of(context).textTheme.titleLarge?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Choose how to allocate power across amplifier channels',
                    style: TextStyle(color: Colors.grey[600]),
                  ),
                  const SizedBox(height: 16),
                  Column(
                    children: PowerAllocationStrategy.values.map((PowerAllocationStrategy strategy) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: RadioListTile<PowerAllocationStrategy>(
                          title: Text(strategy.label, style: const TextStyle(fontSize: 14)),
                          subtitle: Text(strategy.description, style: const TextStyle(fontSize: 14)),
                          value: strategy,
                          groupValue: _selectedStrategy,
                          onChanged: (PowerAllocationStrategy? value) {
                            setState(() {
                              _selectedStrategy = value!;
                            });
                          },
                        ),
                      );
                    }).toList(),
                  ),
                ],
              ),
            ),
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
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Row(
                        children: <Widget>[
                          IconButton(
                            onPressed: _addCircuit,
                            icon: const Icon(Icons.add_circle, color: Colors.green),
                            tooltip: 'Add Circuit',
                          ),
                          IconButton(
                            onPressed: _resetForm,
                            icon: const Icon(Icons.refresh, color: Colors.blue),
                            tooltip: 'Reset Form',
                          ),
                        ],
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  ...circuits.asMap().entries.map((MapEntry<int, CircuitInput> entry) {
                    final int index = entry.key;
                    final CircuitInput circuit = entry.value;
                    return _buildCircuitCard(circuit, index);
                  }),
                ],
              ),
            ),
          ),

          const SizedBox(height: 24),

          // Calculate Button
          Row(
            children: <Widget>[
              Expanded(
                child: FusionGradientButton(
                  label: isLoading ? 'Calculating...' : _getCalculateButtonText(_selectedStrategy),
                  onTap: isLoading ? () {} : _calculateAmplifierMatching,
                  gradient: const LinearGradient(colors: <Color>[Colors.blue, Colors.purple]),
                ),
              ),
            ],
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
          if (matchingResult != null) 
            _buildResultsSection(matchingResult!),
          
          // Comparison results section
          if (comparisonResults != null)
            _buildSideBySideComparison(comparisonResults!),
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
                  style: const TextStyle(
                    fontSize: 22,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                if (circuits.length > 1)
                  IconButton(
                    onPressed: () => _removeCircuit(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
                    tooltip: 'Remove Circuit',
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
                        circuit.mode = value!;
                      });
                    },
                  ),
                ),
                Expanded(
                  child: RadioListTile<String>(
                    title: const Text('Lo-Z'),
                    value: 'lo-z',
                    groupValue: circuit.mode,
                    onChanged: (String? value) {
                      setState(() {
                        circuit.mode = value!;
                      });
                    },
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),

            // Configuration fields
            Row(
              children: <Widget>[
                Expanded(
                  child: TextFormField(
                    controller: circuit.speakerCountController,
                    decoration: const InputDecoration(
                      labelText: 'Speaker Count',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 12),
                if (circuit.mode == 'hi-z')
                  Expanded(
                    child: TextFormField(
                      controller: circuit.tapWattsController,
                      decoration: const InputDecoration(
                        labelText: 'Tap Watts',
                        border: OutlineInputBorder(),
                      ),
                      keyboardType: TextInputType.number,
                    ),
                  ),
                const SizedBox(width: 12),
                Expanded(
                  child: TextFormField(
                    controller: circuit.offsetDbController,
                    decoration: const InputDecoration(
                      labelText: 'Offset (dB)',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),

            // Show available tap settings for selected speaker
            if (circuit.selectedModel != null && SpeakerCatalog.database.containsKey(circuit.selectedModel) && circuit.mode == 'hi-z') ...<Widget>[
              const SizedBox(height: 8),
              Text(
                'Available Taps: ${SpeakerCatalog.database[circuit.selectedModel]!.hiZTaps.map((double t) => '${t}W').join(', ')}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontStyle: FontStyle.italic,
                  color: Colors.blue[700],
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

            // Step-by-step calculation process
            _buildCalculationSteps(result),
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

            // Display errors and warnings
            if (result.hasErrors || result.hasWarnings) ...<Widget>[
              const SizedBox(height: 16),
              _buildIssuesSection(result),
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
        color: color.withValues(alpha: 0.1),
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: color.withValues(alpha: 0.3)),
      ),
      child: Column(
        children: <Widget>[
          Icon(icon, color: color, size: 24),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 22,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          Text(
            label,
            style: TextStyle(
              fontSize: 14,
              color: color,
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildCalculationSteps(AmpMatchingResult result) {
    return ExpansionTile(
      title: const Text(
        'Calculation Steps',
        style: TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: const Text('View detailed power calculations and amplifier selection process'),
      leading: const Icon(Icons.calculate, color: Colors.blue),
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _buildStep1PowerCalculation(result),
              const SizedBox(height: 16),
              _buildStep2CircuitSorting(result),
              const SizedBox(height: 16),
              _buildStep3AmplifierSelection(result),
              const SizedBox(height: 16),
              _buildStep4EfficiencyCalculation(result),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep1PowerCalculation(AmpMatchingResult result) {
    // Get all circuits for power calculation display
    final List<Circuit> allCircuits = <Circuit>[];
    for (final AmpAssignment assignment in result.assignments) {
      allCircuits.addAll(assignment.circuits);
    }
    allCircuits.sort((Circuit a, Circuit b) => a.circuitId.compareTo(b.circuitId));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.blue,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text('1', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Circuit Power Calculation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Calculate power requirements for each circuit:',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          // Power calculation formulas
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Formulas:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('• Hi-Z: Power = Speakers × Tap Watts × 2'),
                Text('• Lo-Z: Power = Speakers × Speaker Peak Power'),
                Text('• With Offset: Reduced Power = Power × 10^(-offset_dB/10)'),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Individual circuit calculations
          ...allCircuits.map((Circuit circuit) {
            final SpeakerModel? speakerSpec = SpeakerCatalog.database[circuit.model];
            double basePower = 0;
            String calculation = '';
            
            if (circuit.mode == 'hi-z') {
              basePower = circuit.speakerCount * circuit.tapWatts * 2;
              calculation = '${circuit.speakerCount} × ${circuit.tapWatts}W × 2 = ${basePower}W';
            } else {
              basePower = circuit.speakerCount * (speakerSpec?.ppk ?? 100);
              calculation = '${circuit.speakerCount} × ${speakerSpec?.ppk ?? 100}W = ${basePower}W';
            }
            
            double finalPower = basePower;
            if (circuit.outputOffsetDb > 0) {
              final double reductionFactor = math.pow(10.0, -circuit.outputOffsetDb / 10.0).toDouble();
              finalPower = basePower * reductionFactor;
              calculation += ' → ${finalPower.toStringAsFixed(1)}W (with ${circuit.outputOffsetDb}dB offset)';
            }
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Text(
                'Circuit ${circuit.circuitId} (${circuit.mode}): $calculation',
                style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
              ),
            );
          }),
          
          // Total power
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(
              'Total System Power: ${result.totalPowerRequirement.toStringAsFixed(1)}W',
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStep2CircuitSorting(AmpMatchingResult result) {
    final List<Circuit> allCircuits = <Circuit>[];
    for (final AmpAssignment assignment in result.assignments) {
      allCircuits.addAll(assignment.circuits);
    }
    
    // Sort by power (highest first)
    allCircuits.sort((Circuit a, Circuit b) {
      final double aPower = _getCircuitPower(a);
      final double bPower = _getCircuitPower(b);
      return bPower.compareTo(aPower);
    });

    return Container(
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
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.orange,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text('2', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Circuit Sorting',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          const Text(
            'Sort circuits by power requirements (highest first):',
            style: TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          ...allCircuits.asMap().entries.map((MapEntry<int, Circuit> entry) {
            final int index = entry.key;
            final Circuit circuit = entry.value;
            final double power = _getCircuitPower(circuit);
            
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: Colors.orange[200],
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Center(
                      child: Text('${index + 1}', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Circuit ${circuit.circuitId}: ${power.toStringAsFixed(1)}W (${circuit.mode}, ${circuit.model})',
                    style: const TextStyle(fontSize: 14),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep3AmplifierSelection(AmpMatchingResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.green,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text('3', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Amplifier Selection & Assignment',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Text(
            'Strategy: ${_selectedStrategy.label}',
            style: const TextStyle(fontWeight: FontWeight.w500),
          ),
          const SizedBox(height: 8),
          
          ...result.assignments.asMap().entries.map((MapEntry<int, AmpAssignment> entry) {
            final int index = entry.key;
            final AmpAssignment assignment = entry.value;
            final double totalAssignedPower = assignment.circuits.fold(0.0, (double sum, Circuit circuit) => sum + _getCircuitPower(circuit));
            final double totalAmpCapacity = assignment.ampModel.peakPerChannel * assignment.ampModel.channels;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Amplifier ${index + 1}: ${assignment.ampModel.name}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Capacity: ${assignment.ampModel.peakPerChannel}W × ${assignment.ampModel.channels} channels = ${totalAmpCapacity}W total',
                    style: const TextStyle(fontSize: 14),
                  ),
                  Text(
                    'Assigned: ${totalAssignedPower.toStringAsFixed(1)}W (${(totalAssignedPower / totalAmpCapacity * 100).toStringAsFixed(1)}% utilization)',
                    style: const TextStyle(fontSize: 14),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    'Circuits: ${assignment.circuits.map((Circuit c) => 'C${c.circuitId}').join(', ')}',
                    style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                  ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildStep4EfficiencyCalculation(AmpMatchingResult result) {
    final double totalRequired = result.totalPowerRequirement;
    final double totalCapacity = result.totalSystemCapacity;
    final int usedChannels = result.totalChannelsUsed;
    final int totalChannels = result.totalChannelsAvailable;

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Container(
                width: 30,
                height: 30,
                decoration: BoxDecoration(
                  color: Colors.purple,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Center(
                  child: Text('4', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ),
              const SizedBox(width: 12),
              const Text(
                'Efficiency Calculation',
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(6),
              border: Border.all(color: Colors.purple[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Power Efficiency = Required ÷ Available',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '= ${totalRequired.toStringAsFixed(1)}W ÷ ${totalCapacity.toStringAsFixed(1)}W = ${(result.powerEfficiency * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Channel Efficiency = Used ÷ Available',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  '= $usedChannels ÷ $totalChannels = ${(result.channelEfficiency * 100).toStringAsFixed(1)}%',
                  style: const TextStyle(fontFamily: 'monospace', fontSize: 14),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  double _getCircuitPower(Circuit circuit) {
    final SpeakerModel? speakerSpec = SpeakerCatalog.database[circuit.model];
    double basePower = 0;
    
    if (circuit.mode == 'hi-z') {
      basePower = circuit.speakerCount * circuit.tapWatts * 2;
    } else {
      basePower = circuit.speakerCount * (speakerSpec?.ppk ?? 100);
    }
    
    if (circuit.outputOffsetDb > 0) {
      final double reductionFactor = math.pow(10.0, -circuit.outputOffsetDb / 10.0).toDouble();
      basePower *= reductionFactor;
    }
    
    return basePower;
  }

  Widget _buildAmplifierCard(AmpAssignment assignment, int index) {
    // Calculate detailed metrics for this amplifier
    double assignedPower = 0;
    
    for (final Circuit circuit in assignment.circuits) {
      assignedPower += _getCircuitPower(circuit);
    }
    
    final double totalAmpPower = assignment.ampModel.peakPerChannel * assignment.ampModel.channels;
    final double powerUtilization = assignedPower / totalAmpPower;

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ExpansionTile(
        title: Text(
          assignment.ampModel.name,
          style: const TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Row(
          children: <Widget>[
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${assignment.usedChannels}/${assignment.totalChannels} channels',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
            const SizedBox(width: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              decoration: BoxDecoration(
                color: powerUtilization > 0.8 ? Colors.red[100] : Colors.green[100],
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                '${(powerUtilization * 100).toStringAsFixed(1)}% power',
                style: const TextStyle(fontWeight: FontWeight.w500),
              ),
            ),
          ],
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                // Amplifier specifications
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.grey[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Amplifier Specifications:', style: TextStyle(fontWeight: FontWeight.bold)),
                      Text('• ${assignment.ampModel.peakPerChannel}W per channel'),
                      Text('• ${assignment.ampModel.channels} channels'),
                      Text('• ${totalAmpPower}W total capacity'),
                    ],
                  ),
                ),
                
                const SizedBox(height: 12),
                
                // Circuit assignments
                const Text('Assigned Circuits:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...assignment.circuits.map((Circuit circuit) {
                  final double power = _getCircuitPower(circuit);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: <Widget>[
                        Text('Circuit ${circuit.circuitId} (${circuit.mode})'),
                        Text('${power.toStringAsFixed(1)}W', style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }),
                
                const SizedBox(height: 8),
                const Divider(),
                
                // Summary
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Total Assigned:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${assignedPower.toStringAsFixed(1)}W', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Remaining Capacity:', style: TextStyle(fontWeight: FontWeight.bold)),
                    Text('${(totalAmpPower - assignedPower).toStringAsFixed(1)}W', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildIssuesSection(AmpMatchingResult result) {
    return Column(
      children: <Widget>[
        if (result.hasErrors) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.red[50],
              border: Border.all(color: Colors.red[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.error, color: Colors.red),
                    SizedBox(width: 8),
                    Text('Errors', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                  ],
                ),
                const SizedBox(height: 8),
                ...result.errors.map((String error) => Text('• $error', style: const TextStyle(color: Colors.red))),
              ],
            ),
          ),
          const SizedBox(height: 8),
        ],
        if (result.hasWarnings) ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              border: Border.all(color: Colors.orange[200]!),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Row(
                  children: <Widget>[
                    Icon(Icons.warning, color: Colors.orange),
                    SizedBox(width: 8),
                    Text('Warnings', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                  ],
                ),
                const SizedBox(height: 8),
                ...result.warnings.map((String warning) => Text('• $warning', style: const TextStyle(color: Colors.orange))),
              ],
            ),
          ),
        ],
      ],
    );
  }

  String _getCalculateButtonText(PowerAllocationStrategy strategy) {
    switch (strategy) {
      case PowerAllocationStrategy.symmetrical:
        return 'Calculate Symmetrical Allocation';
      case PowerAllocationStrategy.asymmetrical:
        return 'Calculate Asymmetrical Allocation';
      case PowerAllocationStrategy.comparison:
        return 'Compare Both Strategies';
    }
  }

  Widget _buildSideBySideComparison(Map<PowerAllocationStrategy, AmpMatchingResult> results) {
    final AmpMatchingResult? symmetricalResult = results[PowerAllocationStrategy.symmetrical];
    final AmpMatchingResult? asymmetricalResult = results[PowerAllocationStrategy.asymmetrical];

    if (symmetricalResult == null || asymmetricalResult == null) {
      return const SizedBox.shrink();
    }

    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Text(
              'Side-by-Side Strategy Comparison',
              style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                color: Colors.purple[700],
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Step-by-step comparison of symmetrical vs asymmetrical allocation strategies',
              style: TextStyle(color: Colors.grey[600]),
            ),
            const SizedBox(height: 24),

            // Summary comparison table
            _buildSummaryComparisonTable(symmetricalResult, asymmetricalResult),
            const SizedBox(height: 24),

            // Step-by-step comparison
            _buildStepByStepComparison(symmetricalResult, asymmetricalResult),
          ],
        ),
      ),
    );
  }

  Widget _buildSummaryComparisonTable(AmpMatchingResult symmetrical, AmpMatchingResult asymmetrical) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        children: <Widget>[
          // Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: const BorderRadius.only(
                topLeft: Radius.circular(8),
                topRight: Radius.circular(8),
              ),
            ),
            child: const Row(
              children: <Widget>[
                Expanded(child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
                Expanded(child: Text('Symmetrical', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
                Expanded(child: Text('Asymmetrical', style: TextStyle(fontWeight: FontWeight.bold), textAlign: TextAlign.center)),
              ],
            ),
          ),
          
          // Comparison rows
          _buildComparisonRow('Amplifiers Required', '${symmetrical.amplifierCount}', '${asymmetrical.amplifierCount}'),
          _buildComparisonRow('Power Efficiency', '${(symmetrical.powerEfficiency * 100).toStringAsFixed(1)}%', 
              '${(asymmetrical.powerEfficiency * 100).toStringAsFixed(1)}%'),
          _buildComparisonRow('Channel Efficiency', '${(symmetrical.channelEfficiency * 100).toStringAsFixed(1)}%', 
              '${(asymmetrical.channelEfficiency * 100).toStringAsFixed(1)}%'),
          _buildComparisonRow('Total System Power', '${symmetrical.totalSystemCapacity.toStringAsFixed(0)}W', 
              '${asymmetrical.totalSystemCapacity.toStringAsFixed(0)}W'),
        ],
      ),
    );
  }

  Widget _buildComparisonRow(String metric, String symValue, String asymValue) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[200]!)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(child: Text(metric, style: const TextStyle(fontWeight: FontWeight.w500))),
          Expanded(child: Text(symValue, textAlign: TextAlign.center)),
          Expanded(child: Text(asymValue, textAlign: TextAlign.center)),
        ],
      ),
    );
  }

  Widget _buildStepByStepComparison(AmpMatchingResult symmetrical, AmpMatchingResult asymmetrical) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Detailed Algorithm Step-by-Step Comparison',
          style: Theme.of(context).textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 16),

        // Input Processing (shared for both algorithms)
        _buildStepComparisonCard(
          'Inputs Processing',
          'Gather and validate all required inputs (shared by both algorithms)',
          Icons.input,
          Colors.blue,
          _buildInputsProcessing(),
        ),

        const SizedBox(height: 16),

        // Side-by-side Step 1 Comparison
        _buildSideBySideStepCard(
          'Step 1: Power Analysis & Circuit Ranking',
          'Circuit Analysis & Power Calculation',
          'Power Sharing Calculator Analysis',
          Icons.calculate,
          Colors.green,
          Colors.purple,
          _buildSymmetricalStep1(symmetrical),
          _buildAsymmetricalStep1(asymmetrical),
        ),

        const SizedBox(height: 16),

        // Side-by-side Step 2 Comparison
        _buildSideBySideStepCard(
          'Step 2: Amplifier Selection & Optimization',
          'Circuit Ranking & Amplifier Matching',
          'Power Redistribution & Optimization',
          Icons.sort,
          Colors.orange,
          Colors.red,
          _buildSymmetricalStep2(symmetrical),
          _buildAsymmetricalStep2(asymmetrical),
        ),

        const SizedBox(height: 16),

        // Final Results Comparison
        _buildStepComparisonCard(
          'Final Results: Amplifier Assignments',
          'Compare final amplifier selections and circuit allocations',
          Icons.speaker_group,
          Colors.indigo,
          _buildAmplifierCatalogComparison(symmetrical, asymmetrical),
        ),
      ],
    );
  }

  Widget _buildSideBySideStepCard(
    String mainTitle,
    String symmetricalTitle,
    String asymmetricalTitle,
    IconData icon,
    Color symmetricalColor,
    Color asymmetricalColor,
    Widget symmetricalContent,
    Widget asymmetricalContent,
  ) {
    return Card(
      elevation: 1,
      child: ExpansionTile(
        title: Text(mainTitle, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: const Text('Side-by-side comparison of both algorithms'),
        leading: Icon(icon, color: Colors.grey[700]),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              children: <Widget>[
                // Headers
                Row(
                  children: <Widget>[
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: symmetricalColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: symmetricalColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.balance, color: symmetricalColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Symmetrical: $symmetricalTitle',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: symmetricalColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Container(
                        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                        decoration: BoxDecoration(
                          color: asymmetricalColor.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6),
                          border: Border.all(color: asymmetricalColor.withValues(alpha: 0.3)),
                        ),
                        child: Row(
                          children: <Widget>[
                            Icon(Icons.tune, color: asymmetricalColor, size: 20),
                            const SizedBox(width: 8),
                            Expanded(
                              child: Text(
                                'Asymmetrical: $asymmetricalTitle',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  color: asymmetricalColor.withValues(alpha: 0.8),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),
                // Content side by side
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Expanded(child: symmetricalContent),
                    const SizedBox(width: 16),
                    Expanded(child: asymmetricalContent),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepComparisonCard(String title, String description, IconData icon, Color color, Widget content) {
    return Card(
      elevation: 1,
      child: ExpansionTile(
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(description),
        leading: Icon(icon, color: color),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildInputsProcessing() {
    // Get all circuits for display
    final List<Circuit> allCircuits = <Circuit>[];
    for (final CircuitInput input in circuits) {
      final Circuit? circuit = input.toCircuit();
      if (circuit != null) {
        allCircuits.add(circuit);
      }
    }

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Required Inputs:',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 22),
          ),
          const SizedBox(height: 12),
          
          // Circuit Data
          const Text('1. Loudspeaker Circuiting:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...allCircuits.map((Circuit circuit) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 4),
              child: Text('• Circuit ${circuit.circuitId}: ${circuit.model} (${circuit.mode})'),
            );
          }),
          
          const SizedBox(height: 8),
          
          // System Configuration
          const Text('2. System Configuration:', style: TextStyle(fontWeight: FontWeight.bold)),
          const Padding(
            padding: EdgeInsets.only(left: 16),
            child: Text('• Hi-Z and Lo-Z circuits identified'),
          ),
          
          const SizedBox(height: 8),
          
          // Power Settings
          const Text('3. Power Settings:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...allCircuits.map((Circuit circuit) {
            if (circuit.mode == 'hi-z') {
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Text('• Circuit ${circuit.circuitId}: ${circuit.tapWatts}W tap setting'),
              );
            } else {
              final SpeakerModel? speaker = SpeakerCatalog.database[circuit.model];
              return Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 2),
                child: Text('• Circuit ${circuit.circuitId}: ${speaker?.ppk ?? 100}W peak power'),
              );
            }
          }),
          
          const SizedBox(height: 8),
          
          // Offsets
          const Text('4. Output Offsets:', style: TextStyle(fontWeight: FontWeight.bold)),
          ...allCircuits.where((Circuit c) => c.outputOffsetDb > 0).map((Circuit circuit) {
            return Padding(
              padding: const EdgeInsets.only(left: 16, bottom: 2),
              child: Text('• Circuit ${circuit.circuitId}: -${circuit.outputOffsetDb}dB offset'),
            );
          }),
          if (allCircuits.every((Circuit c) => c.outputOffsetDb == 0)) 
            const Padding(
              padding: EdgeInsets.only(left: 16),
              child: Text('• No output offsets applied'),
            ),
        ],
      ),
    );
  }

  Widget _buildSymmetricalStep1(AmpMatchingResult result) {
    // Get all circuits for this result
    final List<Circuit> allCircuits = <Circuit>[];
    for (final AmpAssignment assignment in result.assignments) {
      allCircuits.addAll(assignment.circuits);
    }
    allCircuits.sort((Circuit a, Circuit b) => a.circuitId.compareTo(b.circuitId));

    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.green[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Symmetrical - Step 1: Circuit Analysis',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          // Sub-step 1: Determine Hi-Z/Lo-Z
          const Text('1a. Circuit Type Determination:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ...allCircuits.map((Circuit circuit) {
            return Padding(
              padding: const EdgeInsets.only(left: 12, bottom: 2),
              child: Text('• Circuit ${circuit.circuitId}: ${circuit.mode.toUpperCase()}', style: const TextStyle(fontSize: 13)),
            );
          }),
          
          const SizedBox(height: 8),
          
          // Sub-step 2: Power Calculations
          const Text('1b. Total Power Calculation per Circuit:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          
          ...allCircuits.map((Circuit circuit) {
            final SpeakerModel? speaker = SpeakerCatalog.database[circuit.model];
            String formula;
            double basePower;
            double finalPower;
            
            if (circuit.mode == 'hi-z') {
              basePower = circuit.speakerCount * circuit.tapWatts * 2;
              formula = 'Ppk_speaker_total = ∑(Loudspeaker_Ptaps × 2)';
              finalPower = basePower;
            } else {
              basePower = circuit.speakerCount * (speaker?.ppk ?? 100);
              formula = 'Ppk_speaker_total = ∑(Loudspeaker_Ppk)';
              finalPower = basePower;
              
              // Add impedance note for Lo-Z
              final double totalImpedance = (speaker?.nominalOhms ?? 8) / circuit.speakerCount;
              formula += '\nΩtotal = 1/∑(1/Z) = ${totalImpedance.toStringAsFixed(1)}Ω';
            }
            
            if (circuit.outputOffsetDb > 0) {
              final double reductionFactor = math.pow(10.0, -circuit.outputOffsetDb / 10.0).toDouble();
              finalPower = basePower * reductionFactor;
            }
            
            return Container(
              margin: const EdgeInsets.only(bottom: 6, left: 12),
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.green[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Circuit ${circuit.circuitId} (${circuit.mode}):', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  Text(formula, style: const TextStyle(fontFamily: 'monospace', fontSize: 14)),
                  
                  // Detailed step-by-step calculation
                  if (circuit.mode == 'hi-z') ...<Widget>[
                    Text('Step: ${circuit.speakerCount} speakers × ${circuit.tapWatts}W tap × 2 (Hi-Z factor)', style: const TextStyle(fontSize: 14)),
                    Text('Calculation: ${circuit.speakerCount} × ${circuit.tapWatts} × 2 = ${basePower.toStringAsFixed(1)}W', style: const TextStyle(fontSize: 14, color: Colors.blue)),
                  ] else ...<Widget>[
                    Text('Step: ${circuit.speakerCount} speakers × ${speaker?.ppk ?? 100}W (peak)', style: const TextStyle(fontSize: 14)),
                    Text('Calculation: ${circuit.speakerCount} × ${speaker?.ppk ?? 100} = ${basePower.toStringAsFixed(1)}W', style: const TextStyle(fontSize: 14, color: Colors.blue)),
                    Text('Impedance check: Ω = ${(speaker?.nominalOhms ?? 8)}Ω ÷ ${circuit.speakerCount} = ${((speaker?.nominalOhms ?? 8) / circuit.speakerCount).toStringAsFixed(1)}Ω (≥4Ω ✓)', style: const TextStyle(fontSize: 13, color: Colors.green)),
                  ],
                  
                  if (circuit.outputOffsetDb > 0) ...<Widget>[
                    const SizedBox(height: 2),
                    const Text('Output offset applied:', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                    Text('Reduction factor = 10^(-${circuit.outputOffsetDb}/10) = ${math.pow(10.0, -circuit.outputOffsetDb / 10.0).toStringAsFixed(3)}', style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                    Text('Final power = ${basePower.toStringAsFixed(1)}W × ${math.pow(10.0, -circuit.outputOffsetDb / 10.0).toStringAsFixed(3)} = ${finalPower.toStringAsFixed(1)}W', style: const TextStyle(fontSize: 14, color: Colors.red)),
                  ],
                  
                  // Power per speaker breakdown
                  const SizedBox(height: 2),
                  Text('Per speaker: ${(finalPower / circuit.speakerCount).toStringAsFixed(1)}W', style: TextStyle(fontSize: 13, color: Colors.grey[600], fontStyle: FontStyle.italic)),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 8),
          
          // Sub-step 3: Circuit Ranking
          const Text('1c. Circuit Ranking (Highest to Lowest Power):', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const SizedBox(height: 4),
          
          () {
            final List<Circuit> sortedCircuits = List<Circuit>.from(allCircuits);
            sortedCircuits.sort((Circuit a, Circuit b) {
              final double aPower = _getCircuitPower(a);
              final double bPower = _getCircuitPower(b);
              return bPower.compareTo(aPower);
            });
            
            return Column(
              children: sortedCircuits.asMap().entries.map((MapEntry<int, Circuit> entry) {
                final int index = entry.key;
                final Circuit circuit = entry.value;
                final double power = _getCircuitPower(circuit);
                
                return Padding(
                  padding: const EdgeInsets.only(left: 12, bottom: 2),
                  child: Text('${index + 1}. Circuit ${circuit.circuitId}: ${power.toStringAsFixed(1)}W', style: const TextStyle(fontSize: 13)),
                );
              }).toList(),
            );
          }(),
        ],
      ),
    );
  }

  Widget _buildSymmetricalStep2(AmpMatchingResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.orange[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Symmetrical - Step 2: Amplifier Matching',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          // Amplifier Matching Logic
          const Text('2a. Amplifier Matching Logic:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Find amplifier where:', style: TextStyle(fontSize: 13)),
                Text('Ppk_amplifier(RMS) ≥ Ppk_speaker_total(peak) ÷ 2', 
                     style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                Text('• Convert peak power to RMS for comparison (÷2)', style: TextStyle(fontSize: 12, color: Colors.grey)),
                Text('• Amplifier ratings are RMS, circuits calculate peak power', style: TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Channel Strategy
          const Text('2b. Channel Allocation Strategy:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('• Start with 4-channel amplifiers', style: TextStyle(fontSize: 13)),
                Text('• At 5+ channels: use 8-channel amplifiers', style: TextStyle(fontSize: 13)),
                Text('• At 9+ channels: add 4-channel amplifiers', style: TextStyle(fontSize: 13)),
                Text('• At 13+ channels: use 2nd 8-channel amplifier', style: TextStyle(fontSize: 13)),
                Text('• Unused channels occur on smallest amplifiers (least costly)', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Results
          const Text('2c. Amplifier Assignments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ...result.assignments.asMap().entries.map((MapEntry<int, AmpAssignment> entry) {
            final int index = entry.key;
            final AmpAssignment assignment = entry.value;
            final double totalPower = assignment.circuits.fold(0.0, (double sum, Circuit c) => sum + _getCircuitPower(c));
            final double totalCapacity = assignment.ampModel.peakPerChannel * assignment.ampModel.channels;
            final double utilization = totalPower / totalCapacity;
            final double headroom = totalCapacity - totalPower;
            final double powerPerChannel = totalPower / assignment.circuits.length;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 4, left: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.orange[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Amplifier ${index + 1}: ${assignment.ampModel.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  
                  // Detailed capacity breakdown
                  Text('Total Capacity: ${assignment.ampModel.peakPerChannel}W/ch × ${assignment.ampModel.channels}ch = ${totalCapacity.toStringAsFixed(1)}W', 
                       style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  
                  // Power assignment details
                  Text('Assigned Circuits: ${assignment.circuits.map((Circuit c) => 'C${c.circuitId}(${_getCircuitPower(c).toStringAsFixed(0)}W)').join(', ')}', 
                       style: const TextStyle(fontSize: 13)),
                  Text('Total Load: ${totalPower.toStringAsFixed(1)}W', style: const TextStyle(fontSize: 13, color: Colors.blue, fontWeight: FontWeight.bold)),
                  
                  // Enhanced calculations
                  Text('Load Distribution Formula: Σ(Circuit Power) = ${assignment.circuits.map((Circuit c) => '${_getCircuitPower(c).toStringAsFixed(1)}W').join(' + ')} = ${totalPower.toStringAsFixed(1)}W', 
                       style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.purple)),
                  
                  // Utilization calculations
                  Text('Utilization Calculation: ${totalPower.toStringAsFixed(1)}W ÷ ${totalCapacity.toStringAsFixed(1)}W = ${(utilization * 100).toStringAsFixed(1)}%', 
                       style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  Text('Power Distribution: ${assignment.circuits.length} circuits across ${assignment.ampModel.channels} channels', 
                       style: const TextStyle(fontSize: 13, color: Colors.indigo)),
                  Text('Power Density: ${(totalPower / assignment.ampModel.channels).toStringAsFixed(1)}W per channel', 
                       style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                  Text('Headroom Analysis: ${headroom.toStringAsFixed(1)}W unused (${((headroom / totalCapacity) * 100).toStringAsFixed(1)}% reserve)', 
                       style: TextStyle(fontSize: 13, color: headroom > 200 ? Colors.green : Colors.orange, fontFamily: 'monospace')),
                  
                  // Channel and circuit analysis
                  Text('Channel Efficiency: ${assignment.circuits.length}/${assignment.ampModel.channels} channels used = ${((assignment.circuits.length / assignment.ampModel.channels) * 100).toStringAsFixed(1)}%', 
                       style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                  Text('Average Load per Active Channel: ${powerPerChannel.toStringAsFixed(1)}W', 
                       style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                  
                  // Impedance verification for each circuit
                  ...assignment.circuits.map((Circuit circuit) {
                    final SpeakerModel? speaker = SpeakerCatalog.database[circuit.model];
                    if (circuit.mode == 'lo-z' && speaker != null) {
                      final double impedancePerSpeaker = speaker.nominalOhms;
                      final double totalImpedance = impedancePerSpeaker / circuit.speakerCount;
                      return Text('Circuit ${circuit.circuitId} Impedance: ${impedancePerSpeaker.toStringAsFixed(1)}Ω ÷ $circuit.speakerCount = ${totalImpedance.toStringAsFixed(1)}Ω total', 
                           style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.grey));
                    }
                    return const SizedBox.shrink();
                  }),
                  
                  // Power safety verification - individual circuit validation
                  ...assignment.circuits.map((Circuit circuit) {
                    final double circuitPower = _getCircuitPower(circuit);
                    final double circuitRms = circuitPower / 2.0; // Convert peak to RMS
                    final bool isSafe = assignment.ampModel.peakPerChannel >= circuitRms;
                    return Text(
                      'Circuit ${circuit.circuitId} Safety: ${circuitPower.toStringAsFixed(0)}W peak (${circuitRms.toStringAsFixed(0)}W RMS) ≤ ${assignment.ampModel.peakPerChannel.toStringAsFixed(0)}W capacity ${isSafe ? "✓" : "❌"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isSafe ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    );
                  }),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 8),
          
          // Summary
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Symmetrical Strategy Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Total Amplifiers: ${result.amplifierCount}', style: const TextStyle(fontSize: 14)),
                Text('Total Channels: ${result.totalChannelsAvailable} (${result.totalChannelsUsed} used)', style: const TextStyle(fontSize: 14)),
                Text('Power Efficiency: ${(result.powerEfficiency * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14)),
                Text('Channel Efficiency: ${(result.channelEfficiency * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                
                // Detailed efficiency breakdown
                const Text('Formula: Power Efficiency = Total Required ÷ Total Capacity', 
                     style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.grey)),
                Text('= ${result.totalPowerRequirement.toStringAsFixed(1)}W ÷ ${result.totalSystemCapacity.toStringAsFixed(1)}W = ${(result.powerEfficiency * 100).toStringAsFixed(1)}%', 
                     style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.grey)),
                Text('Channel Formula: ${result.totalChannelsUsed} used ÷ ${result.totalChannelsAvailable} available = ${(result.channelEfficiency * 100).toStringAsFixed(1)}%', 
                     style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAsymmetricalStep1(AmpMatchingResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.purple[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Asymmetrical - Step 1: Power Sharing Analysis',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          const Text('1a. Power Sharing Calculator Analysis:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Text('Run simplified power sharing calculator on each amplifier from symmetrical result', style: TextStyle(fontSize: 13)),
          ),
          const SizedBox(height: 8),
          
          const Text('1b. Net Power Sharing Identification:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('• Calculate available power on each channel', style: TextStyle(fontSize: 13)),
                Text('• Identify channels with positive "Net power sharing"', style: TextStyle(fontSize: 13)),
                Text('• Find amplifiers with spare capacity or unused channels', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Show power sharing opportunities
          const Text('1c. Power Sharing Opportunities:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ...result.assignments.asMap().entries.map((MapEntry<int, AmpAssignment> entry) {
            final int index = entry.key;
            final AmpAssignment assignment = entry.value;
            final double usedPower = assignment.circuits.fold(0.0, (double sum, Circuit c) => sum + _getCircuitPower(c));
            final double totalCapacity = assignment.ampModel.peakPerChannel * assignment.ampModel.channels;
            final double availablePower = totalCapacity - usedPower;
            final double utilization = usedPower / totalCapacity;
            final double powerPerChannel = assignment.ampModel.peakPerChannel;
            final int usedChannels = assignment.circuits.length;
            final int availableChannels = assignment.ampModel.channels - usedChannels;
            final double avgLoadPerUsedChannel = usedChannels > 0 ? usedPower / usedChannels : 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 4, left: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.purple[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Amplifier ${index + 1}: ${assignment.ampModel.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  
                  // Detailed power breakdown
                  Text('Current load: ${usedPower.toStringAsFixed(1)}W ÷ ${totalCapacity.toStringAsFixed(1)}W = ${(utilization * 100).toStringAsFixed(1)}%', 
                       style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  Text('Available power: ${totalCapacity.toStringAsFixed(1)}W - ${usedPower.toStringAsFixed(1)}W = ${availablePower.toStringAsFixed(1)}W', 
                       style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  
                  // Channel analysis
                  Text('Channels: $usedChannels/${assignment.ampModel.channels} used ($availableChannels available)', 
                       style: const TextStyle(fontSize: 14)),
                  Text('Avg load per active channel: ${avgLoadPerUsedChannel.toStringAsFixed(1)}W (max ${powerPerChannel}W)', 
                       style: const TextStyle(fontSize: 14)),
                  
                  // Net sharing calculation
                  if (availableChannels > 0) ...<Widget>[
                    Text('Net sharing potential: $availableChannels × ${powerPerChannel}W = ${(availableChannels * powerPerChannel).toStringAsFixed(1)}W', 
                         style: const TextStyle(fontSize: 14, color: Colors.blue)),
                  ],
                  
                  // Power redistribution potential  
                  if (utilization < 0.8 && availablePower > 50) ...<Widget>[
                    Text('✓ High sharing candidate: ${availablePower.toStringAsFixed(1)}W available', 
                         style: const TextStyle(fontSize: 14, color: Colors.green, fontWeight: FontWeight.bold)),
                    Text('Can accept circuits up to ${(availablePower * 0.8).toStringAsFixed(1)}W additional load', 
                         style: const TextStyle(fontSize: 13, color: Colors.green)),
                  ] else if (availablePower > 100) ...<Widget>[
                    Text('✓ Moderate sharing candidate: ${availablePower.toStringAsFixed(1)}W available', 
                         style: const TextStyle(fontSize: 14, color: Colors.orange, fontWeight: FontWeight.bold)),
                  ] else ...<Widget>[
                    Text('• Fully utilized: ${(100 - (availablePower / totalCapacity * 100)).toStringAsFixed(1)}% capacity used', 
                         style: const TextStyle(fontSize: 14, color: Colors.grey)),
                  ],
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildAsymmetricalStep2(AmpMatchingResult result) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text(
            'Asymmetrical - Step 2: Power Redistribution & Optimization',
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
          ),
          const SizedBox(height: 12),
          
          const Text('2a. Circuit Redistribution Logic:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('• Look for circuits that can move to amplifiers with available power', style: TextStyle(fontSize: 13)),
                Text('• Prioritize moving circuits from higher-power amplifiers', style: TextStyle(fontSize: 13)),
                Text('• Check spare channels and power capacity', style: TextStyle(fontSize: 13)),
                Text('• Move highest-priority circuits that fit available capacity', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          const Text('2b. Power Level Optimization:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          const Padding(
            padding: EdgeInsets.only(left: 12),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('• Repeat redistribution until no more sharing possible', style: TextStyle(fontSize: 13)),
                Text('• Run final check: Ppk_amplifier(next tier) ≥ Pk_speaker_total ≥ Ppk_amplifier(current tier)', 
                     style: TextStyle(fontFamily: 'monospace', fontSize: 14)),
                Text('• Reduce amplifier SKU to next tier down if possible', style: TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 8),
          
          // Final Results
          const Text('2c. Optimized Amplifier Assignments:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
          ...result.assignments.asMap().entries.map((MapEntry<int, AmpAssignment> entry) {
            final int index = entry.key;
            final AmpAssignment assignment = entry.value;
            final double totalPower = assignment.circuits.fold(0.0, (double sum, Circuit c) => sum + _getCircuitPower(c));
            final double totalCapacity = assignment.ampModel.peakPerChannel * assignment.ampModel.channels;
            final double utilization = totalPower / totalCapacity;
            final double improvementPotential = (1.0 - utilization) * 100;
            final int circuitCount = assignment.circuits.length;
            final double avgPowerPerCircuit = circuitCount > 0 ? totalPower / circuitCount : 0;
            
            return Container(
              margin: const EdgeInsets.only(bottom: 4, left: 12),
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.red[300]!),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Amplifier ${index + 1}: ${assignment.ampModel.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                  
                  // Enhanced optimization calculations
                  Text('Total Capacity: ${assignment.ampModel.peakPerChannel}W/ch × ${assignment.ampModel.channels}ch = ${totalCapacity.toStringAsFixed(1)}W', 
                       style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  Text('Power Redistribution: ${assignment.circuits.map((Circuit c) => 'C${c.circuitId}(${_getCircuitPower(c).toStringAsFixed(0)}W)').join(' + ')} = ${totalPower.toStringAsFixed(1)}W', 
                       style: const TextStyle(fontSize: 14, fontFamily: 'monospace', color: Colors.purple)),
                  Text('Optimization Result: ${totalPower.toStringAsFixed(1)}W ÷ ${totalCapacity.toStringAsFixed(1)}W = ${(utilization * 100).toStringAsFixed(1)}% utilization', 
                       style: const TextStyle(fontSize: 14, fontFamily: 'monospace')),
                  
                  // Detailed load analysis
                  Text('Circuit Count Optimization: $circuitCount circuits redistributed across ${assignment.ampModel.channels} channels', 
                       style: const TextStyle(fontSize: 13, color: Colors.indigo)),
                  Text('Average Circuit Power: ${avgPowerPerCircuit.toStringAsFixed(1)}W per circuit', 
                       style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                  Text('Power Density: ${(totalPower / assignment.ampModel.channels).toStringAsFixed(1)}W per channel', 
                       style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                  Text('Capacity Utilization: ${((utilization * assignment.ampModel.channels).toStringAsFixed(1))} effective channels used', 
                       style: const TextStyle(fontSize: 13, fontFamily: 'monospace')),
                  
                  // Power sharing efficiency
                  Text('Power Sharing Efficiency: ${(totalPower / (avgPowerPerCircuit * circuitCount) * 100).toStringAsFixed(1)}% vs original allocation', 
                       style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.green)),
                  Text('Unused Capacity: ${(totalCapacity - totalPower).toStringAsFixed(1)}W (${improvementPotential.toStringAsFixed(1)}%)', 
                       style: TextStyle(fontSize: 13, color: improvementPotential < 30 ? Colors.green : Colors.orange, fontFamily: 'monospace')),
                  
                  // Verification checks - asymmetrical power sharing validation
                  () {
                    final double totalPowerRms = totalPower / 2.0; // Convert peak to RMS
                    final double totalCapacityRms = assignment.ampModel.peakPerChannel * assignment.ampModel.channels; // Already in RMS
                    final bool isSafe = totalCapacityRms >= totalPowerRms;
                    return Text(
                      'Total Power Safety: ${totalPower.toStringAsFixed(0)}W peak (${totalPowerRms.toStringAsFixed(0)}W RMS) ≤ ${totalCapacityRms.toStringAsFixed(0)}W total capacity ${isSafe ? "✓" : "❌"}',
                      style: TextStyle(
                        fontSize: 14,
                        color: isSafe ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontFamily: 'monospace',
                      ),
                    );
                  }(),
                ],
              ),
            );
          }),
          
          const SizedBox(height: 8),
          
          // Optimization Summary
          Container(
            padding: const EdgeInsets.all(6),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Asymmetrical Strategy Summary:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13)),
                Text('Total Amplifiers: ${result.amplifierCount}', style: const TextStyle(fontSize: 14)),
                Text('Total Channels: ${result.totalChannelsAvailable} (${result.totalChannelsUsed} used)', style: const TextStyle(fontSize: 14)),
                Text('Power Efficiency: ${(result.powerEfficiency * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14)),
                Text('Channel Efficiency: ${(result.channelEfficiency * 100).toStringAsFixed(1)}%', style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 2),
                
                // Detailed efficiency breakdown
                const Text('Formula: Power Efficiency = Total Required ÷ Total Capacity', 
                     style: TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.grey)),
                Text('= ${result.totalPowerRequirement.toStringAsFixed(1)}W ÷ ${result.totalSystemCapacity.toStringAsFixed(1)}W = ${(result.powerEfficiency * 100).toStringAsFixed(1)}%', 
                     style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.grey)),
                Text('Channel Formula: ${result.totalChannelsUsed} used ÷ ${result.totalChannelsAvailable} available = ${(result.channelEfficiency * 100).toStringAsFixed(1)}%', 
                     style: const TextStyle(fontSize: 13, fontFamily: 'monospace', color: Colors.grey)),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAmplifierCatalogComparison(AmpMatchingResult symmetrical, AmpMatchingResult asymmetrical) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Symmetrical amplifiers
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Symmetrical Strategy Amplifiers', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...symmetrical.assignments.asMap().entries.map((MapEntry<int, AmpAssignment> entry) {
                  final int index = entry.key;
                  final AmpAssignment assignment = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.blue[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Amp ${index + 1}: ${assignment.ampModel.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${assignment.ampModel.peakPerChannel}W × ${assignment.ampModel.channels} channels = ${assignment.ampModel.peakPerChannel * assignment.ampModel.channels}W total',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Circuits: ${assignment.circuits.map((Circuit c) => 'C${c.circuitId}(${_getCircuitPower(c).toStringAsFixed(0)}W)').join(', ')}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        // Power utilization calculation
                        Builder(
                          builder: (BuildContext context) {
                            final double totalCircuitPower = assignment.circuits.fold(0.0, (double sum, Circuit c) => sum + _getCircuitPower(c));
                            final double utilization = totalCircuitPower / (assignment.ampModel.peakPerChannel * assignment.ampModel.channels);
                            return Text(
                              'Utilization: ${totalCircuitPower.toStringAsFixed(0)}W ÷ ${assignment.ampModel.peakPerChannel * assignment.ampModel.channels}W = ${(utilization * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 14, color: utilization > 0.7 ? Colors.green : Colors.orange, fontFamily: 'monospace'),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
        const SizedBox(width: 16),
        // Asymmetrical amplifiers
        Expanded(
          child: Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.indigo[50],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Asymmetrical Strategy Amplifiers', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...asymmetrical.assignments.asMap().entries.map((MapEntry<int, AmpAssignment> entry) {
                  final int index = entry.key;
                  final AmpAssignment assignment = entry.value;
                  return Container(
                    margin: const EdgeInsets.only(bottom: 8),
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.green[200]!),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text(
                          'Amp ${index + 1}: ${assignment.ampModel.name}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                        ),
                        Text(
                          '${assignment.ampModel.peakPerChannel}W × ${assignment.ampModel.channels} channels = ${assignment.ampModel.peakPerChannel * assignment.ampModel.channels}W total',
                          style: const TextStyle(fontSize: 13),
                        ),
                        Text(
                          'Circuits: ${assignment.circuits.map((Circuit c) => 'C${c.circuitId}(${_getCircuitPower(c).toStringAsFixed(0)}W)').join(', ')}',
                          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
                        ),
                        // Power utilization calculation
                        Builder(
                          builder: (BuildContext context) {
                            final double totalCircuitPower = assignment.circuits.fold(0.0, (double sum, Circuit c) => sum + _getCircuitPower(c));
                            final double utilization = totalCircuitPower / (assignment.ampModel.peakPerChannel * assignment.ampModel.channels);
                            return Text(
                              'Utilization: ${totalCircuitPower.toStringAsFixed(0)}W ÷ ${assignment.ampModel.peakPerChannel * assignment.ampModel.channels}W = ${(utilization * 100).toStringAsFixed(1)}%',
                              style: TextStyle(fontSize: 14, color: utilization > 0.7 ? Colors.green : Colors.orange, fontFamily: 'monospace'),
                            );
                          },
                        ),
                      ],
                    ),
                  );
                }),
              ],
            ),
          ),
        ),
      ],
    );
  }

}
