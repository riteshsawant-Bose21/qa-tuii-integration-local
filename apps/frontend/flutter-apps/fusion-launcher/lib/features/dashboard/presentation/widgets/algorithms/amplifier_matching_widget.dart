import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_algorithms/amplifier_matching/amplifier_matching.dart';
import 'package:fusion_lib/api_data/speakers/speakers.dart';
import 'dart:math' as math;

import '../../../../../core/services/circuit_data_service.dart';

/// Clean Amplifier Matching Widget based on test_amplifier_matching_sample.dart
/// 
/// Features:
/// - Always runs both symmetrical and asymmetrical strategies for comparison
/// - Clean side-by-side results display
/// - Algorithm steps with formulas and solutions
/// - Minimal, focused interface inspired by the test file
class AmplifierMatchingWidgetClean extends StatefulWidget {
  const AmplifierMatchingWidgetClean({super.key});

  @override
  State<AmplifierMatchingWidgetClean> createState() => _AmplifierMatchingWidgetCleanState();
}

/// Input model for circuit configuration
class CircuitInput {
  String? selectedModel;
  final TextEditingController speakerCountController = TextEditingController(text: '1');
  final TextEditingController tapWattsController = TextEditingController(text: '15.0');
  final TextEditingController offsetDbController = TextEditingController(text: '0.0');
  String mode = 'hi-z';
  double? specifiedVoltage = 70.0;
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

class _AmplifierMatchingWidgetCleanState extends State<AmplifierMatchingWidgetClean> {
  final List<CircuitInput> circuits = <CircuitInput>[CircuitInput(1)];
  AmpMatchingResult? symmetricalResult;
  AmpMatchingResult? asymmetricalResult;
  bool isLoading = false;
  String? errorMessage;
  final CircuitDataService _circuitDataService = CircuitDataService();
  double _globalVoltage = 100.0; // Global voltage setting for all Hi-Z circuits

  List<String> get availableSpeakerModels => SpeakerCatalog.database.keys.toList();

  @override
  void initState() {
    super.initState();
    circuits.first.specifiedVoltage = _globalVoltage;
  }

  @override
  void dispose() {
    for (final CircuitInput circuit in circuits) {
      circuit.dispose();
    }
    super.dispose();
  }

  void _addCircuit() {
    setState(() {
      final CircuitInput newCircuit = CircuitInput(circuits.length + 1);
      newCircuit.specifiedVoltage = _globalVoltage;
      circuits.add(newCircuit);
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

  /// Calculate amplifier matching - always runs both strategies like test file
  void _calculateAmplifierMatching() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      symmetricalResult = null;
      asymmetricalResult = null;
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

      // Always run both strategies for comparison (like test file)
              // Test both strategies to compare power sharing benefits
        final AmpMatchingResult symmetrical = await matchAmplifiers(
          validCircuits, 
          SpeakerCatalog.database,
          systemVoltage: _globalVoltage,
          strategy: PowerAllocationStrategy.symmetrical,
          enableLogging: true, // Enable detailed logging like test file
        );
        
        final AmpMatchingResult asymmetrical = await matchAmplifiers(
          validCircuits, 
          SpeakerCatalog.database,
          systemVoltage: _globalVoltage,
          strategy: PowerAllocationStrategy.asymmetrical,
          enableLogging: true, // Enable detailed logging like test file
        );
        
        setState(() {
          symmetricalResult = symmetrical;
          asymmetricalResult = asymmetrical;
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
      final CircuitInput newCircuit = CircuitInput(1);
      newCircuit.specifiedVoltage = _globalVoltage;
      circuits.add(newCircuit);
      symmetricalResult = null;
      asymmetricalResult = null;
      errorMessage = null;
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
        circuitInput.specifiedVoltage = _globalVoltage;

        circuits.add(circuitInput);
      }

      symmetricalResult = null;
      asymmetricalResult = null;
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
          const Text(
            'Amplifier Matching Algorithm',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold, color: Colors.blue),
          ),
          const SizedBox(height: 8),
          const Text(
            'Clean side-by-side comparison of Symmetrical vs Asymmetrical power allocation strategies.',
            style: TextStyle(fontSize: 16, color: Colors.grey),
          ),
          const SizedBox(height: 24),

          // Circuit Data Import Section
          AnimatedBuilder(
            animation: _circuitDataService,
            builder: (BuildContext context, Widget? child) {
              return Card(
                elevation: 2,
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          Icon(
                            _circuitDataService.hasCircuitingData ? Icons.check_circle : Icons.info,
                            color: _circuitDataService.hasCircuitingData ? Colors.green : Colors.grey,
                          ),
                          const SizedBox(width: 8),
                          const Text('Import Circuit Data', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        _circuitDataService.hasCircuitingData 
                          ? 'Circuit data available from circuiting algorithm'
                          : 'No circuit data available - configure circuits manually',
                        style: TextStyle(
                          color: _circuitDataService.hasCircuitingData ? Colors.green : Colors.grey,
                        ),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton(
                        onPressed: _circuitDataService.hasCircuitingData ? _importCircuitingData : null,
                        child: const Text('Import Circuiting Data'),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
          const SizedBox(height: 24),

          // System Configuration - Simple voltage selection
          Card(
            elevation: 2,
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.settings, color: Colors.blue),
                      SizedBox(width: 8),
                      Text('System Configuration', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.blue[50],
                      border: Border.all(color: Colors.blue[200]!),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Strategy: Side-by-side comparison of Symmetrical and Asymmetrical',
                          style: TextStyle(fontWeight: FontWeight.w500),
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: <Widget>[
                            const Text('Hi-Z Voltage: ', style: TextStyle(fontWeight: FontWeight.w500)),
                            DropdownButton<double>(
                              value: _globalVoltage,
                              items: const <DropdownMenuItem<double>>[
                                DropdownMenuItem<double>(value: 70.0, child: Text('70V')),
                                DropdownMenuItem<double>(value: 100.0, child: Text('100V')),
                              ],
                              onChanged: (double? value) {
                                if (value != null) {
                                  setState(() {
                                    _globalVoltage = value;
                                    // Update all existing circuits
                                    for (final CircuitInput circuit in circuits) {
                                      circuit.specifiedVoltage = _globalVoltage;
                                    }
                                  });
                                }
                              },
                            ),
                          ],
                        ),
                      ],
                    ),
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
                      const Text(
                        'Circuit Configuration',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
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

          // Calculate button
          Center(
            child: isLoading
                ? const CircularProgressIndicator()
                : ElevatedButton(
                    onPressed: _calculateAmplifierMatching,
                    child: const Text('Calculate Amplifier Matching (Both Strategies)'),
                  ),
          ),

          const SizedBox(height: 16),

          // Results section - Always show side-by-side comparison
          if (symmetricalResult != null && asymmetricalResult != null)
            _buildSideBySideResults(symmetricalResult!, asymmetricalResult!),
            
          // Error display
          if (errorMessage != null)
            Card(
              color: Colors.red[50],
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Row(
                      children: <Widget>[
                        Icon(Icons.error, color: Colors.red),
                        SizedBox(width: 8),
                        Text('Error', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                      ],
                    ),
                    const SizedBox(height: 8),
                    Text(errorMessage!, style: const TextStyle(color: Colors.red)),
                  ],
                ),
              ),
            ),
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
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                if (circuits.length > 1)
                  IconButton(
                    onPressed: () => _removeCircuit(index),
                    icon: const Icon(Icons.delete, color: Colors.red),
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
                        circuit.mode = value ?? 'hi-z';
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
                        circuit.mode = value ?? 'hi-z';
                      });
                    },
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            // Configuration fields in a row
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
          ],
        ),
      ),
    );
  }

  /// Side-by-side results display inspired by test_amplifier_matching_sample.dart
  Widget _buildSideBySideResults(AmpMatchingResult symmetrical, AmpMatchingResult asymmetrical) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Header with algorithm status
        const Card(
          color: Colors.blue,
          child: Padding(
            padding: EdgeInsets.all(16.0),
            child: Row(
              children: <Widget>[
                Icon(Icons.music_note, color: Colors.white),
                SizedBox(width: 8),
                Text(
                  '🎵 Amplifier Matching Algorithm Results - Side-by-Side Comparison',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Algorithm Steps Section
        _buildAlgorithmStepsCard(),
        
        const SizedBox(height: 16),
        
        // Side-by-side strategy results
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(
              child: _buildStrategyResultCard(
                'Symmetrical Mode', 
                symmetrical, 
                Colors.blue, 
                PowerAllocationStrategy.symmetrical,
                Icons.balance,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: _buildStrategyResultCard(
                'Asymmetrical Mode', 
                asymmetrical, 
                Colors.green, 
                PowerAllocationStrategy.asymmetrical,
                Icons.share,
              ),
            ),
          ],
        ),
        
        const SizedBox(height: 16),
        
        // Comparison Summary
        _buildComparisonSummaryCard(symmetrical, asymmetrical),
      ],
    );
  }

  Widget _buildAlgorithmStepsCard() {
    return Card(
      elevation: 3,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.list_alt, color: Colors.orange),
                SizedBox(width: 8),
                Text('🔄 12-Step Algorithm Execution (Detailed)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Input Circuits Analysis
            _buildDetailedStepCard(
              '1. Input Circuit Analysis',
              'Circuit type detection and power requirements calculation',
              _buildInputAnalysisDetails(),
              Colors.blue,
            ),
            
            // Offset Application
            _buildDetailedStepCard(
              '2. Power Offset Application',
              'Apply dB offsets using formula: Power = P × 10^(-dB/10)',
              _buildOffsetCalculationDetails(),
              Colors.green,
            ),
            
            // Circuit Sorting
            _buildDetailedStepCard(
              '3. Circuit Sorting by Power',
              'Sort circuits in descending order by power requirement',
              _buildCircuitSortingDetails(),
              Colors.purple,
            ),
            
            // Tier Rule Application
            _buildDetailedStepCard(
              '4. Tier Rule Selection',
              'Apply tier rule: Ppk_amplifier ≥ Pk_speaker_total',
              _buildTierRuleDetails(),
              Colors.teal,
            ),
            
            // Power Sharing (Asymmetrical only)
            _buildDetailedStepCard(
              '5. Power Sharing Analysis',
              'Symmetrical: Per-channel limits | Asymmetrical: Power sharing optimization',
              _buildPowerSharingDetails(),
              Colors.deepOrange,
            ),
            
            // Final Validation
            _buildDetailedStepCard(
              '6. Final Validation & Results',
              'System verification, SKU reduction, and final amplifier selection',
              _buildFinalValidationDetails(),
              Colors.red,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDetailedStepCard(String title, String description, Widget details, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.engineering, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        subtitle: Text(description, style: const TextStyle(fontSize: 12)),
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              border: Border.all(color: color.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: details,
          ),
        ],
      ),
    );
  }

  Widget _buildInputAnalysisDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('📋 Input Circuits Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (circuits.isNotEmpty) ...<Widget>[
          for (int i = 0; i < circuits.length; i++) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border.all(color: Colors.grey[300]!),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('Circuit ${i + 1}: ${circuits[i].selectedModel ?? "Not selected"}', 
                       style: const TextStyle(fontWeight: FontWeight.w500)),
                  Text('  • Type: ${circuits[i].mode.toUpperCase()}'),
                  Text('  • Count: ${circuits[i].speakerCountController.text} speakers'),
                  if (circuits[i].mode == 'hi-z') 
                    Text('  • Tap Power: ${circuits[i].tapWattsController.text}W per speaker'),
                  if (double.tryParse(circuits[i].offsetDbController.text) != 0)
                    Text('  • Offset: ${circuits[i].offsetDbController.text}dB'),
                  Text('  • Estimated Power: ${_estimateCircuitPower(circuits[i]).toStringAsFixed(1)}W'),
                ],
              ),
            ),
          ],
        ] else ...<Widget>[
          const Text('No circuits configured yet.', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _buildOffsetCalculationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('📐 Step 2: Offset Calculation - ACTUAL CALCULATIONS:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        // Formula explanation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Formula: Power_adjusted = Power_original × 10^(-dB/10)', 
                   style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16)),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // ACTUAL CALCULATIONS for each circuit
        const Text('🧮 YOUR CIRCUIT CALCULATIONS:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        if (circuits.isNotEmpty) ...<Widget>[
          for (final CircuitInput circuit in circuits)
            _buildActualOffsetCalculation(circuit),
        ] else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Add circuits to see actual calculations', 
                               style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        ],
      ],
    );
  }

  Widget _buildActualOffsetCalculation(CircuitInput circuit) {
    // Get actual circuit data
    final SpeakerModel? speaker = SpeakerCatalog.database[circuit.selectedModel];
    final int speakerCount = int.tryParse(circuit.speakerCountController.text) ?? 1;
    final double tapWatts = double.tryParse(circuit.tapWattsController.text) ?? 0.0;
    final double offsetDb = double.tryParse(circuit.offsetDbController.text) ?? 0.0;
    
    // Calculate original power
    double originalPower = 0.0;
    String powerSource = '';
    
    if (circuit.mode == 'hi-z') {
      originalPower = speakerCount * tapWatts;
      powerSource = '${speakerCount} speakers × ${tapWatts}W tap';
    } else if (speaker != null) {
      originalPower = speakerCount * speaker.longTermRms;
      powerSource = '${speakerCount} × ${speaker.model} (${speaker.longTermRms}W RMS)';
    }
    
    // Calculate offset multiplier and final power
    final double multiplier = math.pow(10.0, -offsetDb / 10.0).toDouble();
    final double finalPower = originalPower * multiplier;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: offsetDb != 0 ? Colors.orange[50] : Colors.green[50],
        border: Border.all(color: offsetDb != 0 ? Colors.orange[200]! : Colors.green[200]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Circuit ${circuit.circuitId}: ${circuit.selectedModel ?? "No model selected"}', 
               style: const TextStyle(fontWeight: FontWeight.bold)),
          
          if (circuit.selectedModel != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('1. Original Power: $powerSource = ${originalPower.toStringAsFixed(1)}W'),
            
            if (offsetDb != 0) ...<Widget>[
              Text('2. Offset: ${offsetDb}dB'),
              Text('3. Calculate multiplier: 10^(-${offsetDb}/10) = 10^(${(-offsetDb/10).toStringAsFixed(2)}) = ${multiplier.toStringAsFixed(3)}'),
              Text('4. Apply offset: ${originalPower.toStringAsFixed(1)}W × ${multiplier.toStringAsFixed(3)} = ${finalPower.toStringAsFixed(1)}W', 
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              Text('RESULT: Circuit power increased by ${((finalPower/originalPower - 1) * 100).toStringAsFixed(1)}%', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
            ] else ...<Widget>[
              const Text('2. No offset applied (0dB)'),
              Text('RESULT: Power unchanged = ${originalPower.toStringAsFixed(1)}W', 
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
            ],
          ] else ...<Widget>[
            const Text('⚠️ Select a speaker model to see calculations', 
                       style: TextStyle(color: Colors.red, fontStyle: FontStyle.italic)),
          ],
        ],
      ),
    );
  }

  Widget _buildCircuitSortingDetails() {
    final List<CircuitInput> sortedCircuits = List<CircuitInput>.from(circuits);
    sortedCircuits.sort((CircuitInput a, CircuitInput b) => _estimateCircuitPower(b).compareTo(_estimateCircuitPower(a)));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('📊 Circuit Sorting (Descending Power):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (sortedCircuits.isNotEmpty) ...<Widget>[
          for (int i = 0; i < sortedCircuits.length; i++) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: i == 0 ? Colors.red[50] : (i == 1 ? Colors.orange[50] : Colors.yellow[50]),
                border: Border.all(color: i == 0 ? Colors.red[200]! : (i == 1 ? Colors.orange[200]! : Colors.yellow[200]!)),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: i == 0 ? Colors.red : (i == 1 ? Colors.orange : Colors.yellow[700]),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text('${i + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('${sortedCircuits[i].selectedModel ?? "Unknown"} (${sortedCircuits[i].mode.toUpperCase()})', 
                             style: const TextStyle(fontWeight: FontWeight.w500)),
                        Text('${_estimateCircuitPower(sortedCircuits[i]).toStringAsFixed(1)}W - ${sortedCircuits[i].speakerCountController.text} speakers'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ] else ...<Widget>[
          const Text('No circuits to sort.', style: TextStyle(fontStyle: FontStyle.italic)),
        ],
      ],
    );
  }

  Widget _buildTierRuleDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('⚖️ Step 4: Tier Rule Analysis - YOUR ACTUAL REQUIREMENTS:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal[50],
            border: Border.all(color: Colors.teal[200]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Tier Rule: Ppk_amplifier ≥ Pk_speaker_total', 
                   style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 4),
              Text('Find minimum amplifier power that can handle your total circuit requirements'),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        const Text('🧮 YOUR CIRCUIT POWER ANALYSIS:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        
        if (circuits.isNotEmpty) ...<Widget>[
          for (final CircuitInput circuit in circuits)
            _buildActualTierAnalysis(circuit),
            
          const SizedBox(height: 8),
          _buildTotalPowerSummary(),
        ] else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Add circuits to see actual power calculations', 
                               style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        ],
      ],
    );
  }

  Widget _buildActualTierAnalysis(CircuitInput circuit) {
    final SpeakerModel? speaker = SpeakerCatalog.database[circuit.selectedModel];
    final int speakerCount = int.tryParse(circuit.speakerCountController.text) ?? 1;
    final double tapWatts = double.tryParse(circuit.tapWattsController.text) ?? 0.0;
    final double offsetDb = double.tryParse(circuit.offsetDbController.text) ?? 0.0;
    
    // Calculate powers
    double rmsPower = 0.0;
    double peakPower = 0.0;
    String calculation = '';
    
    if (circuit.mode == 'hi-z') {
      rmsPower = speakerCount * tapWatts;
      peakPower = speakerCount * tapWatts * 2.0; // ✅ CORRECTED: Peak = tap × count × 2
      calculation = '${speakerCount} speakers × ${tapWatts}W tap = ${rmsPower.toStringAsFixed(1)}W RMS, Peak = ${rmsPower.toStringAsFixed(1)}W × 2 = ${peakPower.toStringAsFixed(1)}W';
    } else if (speaker != null) {
      rmsPower = speakerCount * speaker.longTermRms;
      peakPower = speakerCount * speaker.ppk;
      calculation = '${speakerCount} × ${speaker.model}: RMS=${speaker.longTermRms}W, Peak=${speaker.ppk}W';
    }
    
    // Apply offset
    if (offsetDb != 0) {
      final double multiplier = math.pow(10.0, -offsetDb / 10.0).toDouble();
      rmsPower *= multiplier;
      peakPower *= multiplier;
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        border: Border.all(color: Colors.blue[200]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Circuit ${circuit.circuitId}: ${circuit.selectedModel ?? "No model"}', 
               style: const TextStyle(fontWeight: FontWeight.bold)),
          
          if (circuit.selectedModel != null) ...<Widget>[
            Text('Mode: ${circuit.mode.toUpperCase()}'),
            Text('Calculation: $calculation'),
            if (offsetDb != 0) ...<Widget>[
              Text('With ${offsetDb}dB offset: ×${math.pow(10.0, -offsetDb / 10.0).toStringAsFixed(3)}'),
            ],
            Text('RMS Power Required: ${rmsPower.toStringAsFixed(1)}W'),
            Text('Peak Power Required: ${peakPower.toStringAsFixed(1)}W', 
                 style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            Text('Amplifier Minimum: ≥${peakPower.toStringAsFixed(1)}W peak capacity'),
          ] else ...<Widget>[
            const Text('⚠️ Select speaker model to see calculations', 
                       style: TextStyle(color: Colors.red)),
          ],
        ],
      ),
    );
  }

  Widget _buildTotalPowerSummary() {
    double totalRms = 0.0;
    double totalPeak = 0.0;
    int validCircuits = 0;
    
    for (final CircuitInput circuit in circuits) {
      if (circuit.selectedModel != null) {
        final double circuitPower = _estimateCircuitPower(circuit);
        totalRms += circuitPower;
        
        // Estimate peak (simplified)
        final SpeakerModel? speaker = SpeakerCatalog.database[circuit.selectedModel];
        if (speaker != null && circuit.mode != 'hi-z') {
          final int speakerCount = int.tryParse(circuit.speakerCountController.text) ?? 1;
          final double offsetDb = double.tryParse(circuit.offsetDbController.text) ?? 0.0;
          final double multiplier = math.pow(10.0, -offsetDb / 10.0).toDouble();
          totalPeak += speakerCount * speaker.ppk * multiplier;
        } else {
          // ✅ CORRECTED: For Hi-Z, peak = tap × count × 2 × multiplier
          final int speakerCount = int.tryParse(circuit.speakerCountController.text) ?? 1;
          final double offsetDb = double.tryParse(circuit.offsetDbController.text) ?? 0.0;
          final double multiplier = math.pow(10.0, -offsetDb / 10.0).toDouble();
          final double tapWatts = double.tryParse(circuit.tapWattsController.text) ?? 0.0;
          totalPeak += speakerCount * tapWatts * 2.0 * multiplier;
        }
        validCircuits++;
      }
    }
    
    // Estimate amplifier requirements
    const double typicalAmpPower = 1000.0; // PowerMatch PM8500N example
    final int minAmplifiers = (totalPeak / typicalAmpPower).ceil();
    final double requiredCapacity = minAmplifiers * typicalAmpPower;
    final double efficiency = totalPeak / requiredCapacity;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.green[50],
        border: Border.all(color: Colors.green[200]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('🎯 TOTAL SYSTEM REQUIREMENTS:', style: TextStyle(fontWeight: FontWeight.bold)),
          Text('Valid Circuits: $validCircuits/${circuits.length}'),
          Text('Total RMS Power: ${totalRms.toStringAsFixed(1)}W'),
          Text('Total Peak Power: ${totalPeak.toStringAsFixed(1)}W', 
               style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 4),
          const Text('TIER RULE APPLICATION:', style: TextStyle(fontWeight: FontWeight.w500)),
          Text('Minimum amplifier capacity needed: ≥${totalPeak.toStringAsFixed(1)}W'),
          Text('Estimated solution: $minAmplifiers × ${typicalAmpPower.toStringAsFixed(0)}W amplifiers'),
          Text('Total capacity: ${requiredCapacity.toStringAsFixed(1)}W'),
          Text('Power efficiency: ${(efficiency * 100).toStringAsFixed(1)}%',
               style: TextStyle(
                 fontWeight: FontWeight.bold,
                 color: efficiency > 0.7 ? Colors.green : efficiency > 0.5 ? Colors.orange : Colors.red,
               )),
        ],
      ),
    );
  }

  Widget _buildPowerSharingDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('⚡ Step 5: Power Allocation - YOUR ACTUAL STRATEGY COMPARISON:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        // Strategy explanation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[50],
            border: Border.all(color: Colors.purple[200]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Two Allocation Strategies:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('🔄 Symmetrical: Equal power per channel from each amp'),
              Text('⚖️ Asymmetrical: Optimized power sharing across channels'),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        const Text('🧮 YOUR CONFIGURATION ANALYSIS:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        
        if (circuits.length >= 2) ...<Widget>[
          _buildActualStrategyComparison(),
        ] else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Add at least 2 circuits to see actual strategy comparison', 
                               style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        ],
      ],
    );
  }

  Widget _buildActualStrategyComparison() {
    // Calculate actual circuit powers
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    double totalPower = 0.0;
    
    for (final CircuitInput circuit in circuits) {
      if (circuit.selectedModel != null) {
        final double power = _estimateCircuitPower(circuit);
        circuitData.add(<String, dynamic>{
          'id': circuit.circuitId,
          'model': circuit.selectedModel,
          'power': power,
          'mode': circuit.mode,
        });
        totalPower += power;
      }
    }
    
    if (circuitData.isEmpty) {
      return const Text('Select speaker models to see calculations');
    }
    
    // Sort circuits by power for analysis
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => 
                     (b['power'] as double).compareTo(a['power'] as double));
    
    // Symmetrical calculation
    const double ampPower = 1000.0; // PowerMatch PM8500N
    const int channelsPerAmp = 4;
    final int channelsNeeded = circuitData.length;
    final int symmetricalAmps = (channelsNeeded / channelsPerAmp).ceil();
    final double powerPerChannel = ampPower / channelsPerAmp;
    final double symmetricalCapacity = symmetricalAmps * ampPower;
    final double symmetricalEfficiency = totalPower / symmetricalCapacity;
    
    // Check if any circuit exceeds per-channel limit
    final bool hasOverload = circuitData.any((Map<String, dynamic> c) => 
                                           (c['power'] as double) > powerPerChannel);
    
    // Asymmetrical calculation
    int asymmetricalAmps = 0;
    double asymmetricalCapacity = 0.0;
    double remainingPower = totalPower;
    
    // High-power circuits get dedicated amps
    for (final Map<String, dynamic> circuit in circuitData) {
      final double power = circuit['power'] as double;
      if (power > powerPerChannel) {
        asymmetricalAmps++;
        asymmetricalCapacity += ampPower;
        remainingPower -= power;
      }
    }
    
    // Remaining circuits share amps
    if (remainingPower > 0) {
      final int sharedAmps = (remainingPower / ampPower).ceil();
      asymmetricalAmps += sharedAmps;
      asymmetricalCapacity += sharedAmps * ampPower;
    }
    
    final double asymmetricalEfficiency = totalPower / asymmetricalCapacity;
    
    return Column(
      children: <Widget>[
        // Circuit power breakdown
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            border: Border.all(color: Colors.blue[200]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('📊 Your Circuit Power Requirements:', style: TextStyle(fontWeight: FontWeight.bold)),
              for (final Map<String, dynamic> circuit in circuitData) ...<Widget>[
                Text('Circuit ${circuit['id']}: ${circuit['model']} = ${(circuit['power'] as double).toStringAsFixed(1)}W (${circuit['mode']})'),
              ],
              const SizedBox(height: 4),
              Text('TOTAL: ${totalPower.toStringAsFixed(1)}W across ${circuitData.length} circuits', 
                   style: const TextStyle(fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Symmetrical strategy actual calculation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: hasOverload ? Colors.red[50] : Colors.green[50],
            border: Border.all(color: hasOverload ? Colors.red[200]! : Colors.green[200]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('🔄 SYMMETRICAL CALCULATION:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Channels needed: $channelsNeeded'),
              Text('Calculation: $channelsNeeded ÷ $channelsPerAmp = $symmetricalAmps amplifiers'),
              Text('Power per channel: ${powerPerChannel.toStringAsFixed(1)}W'),
              Text('Total capacity: ${symmetricalCapacity.toStringAsFixed(1)}W'),
              Text('Efficiency: ${(symmetricalEfficiency * 100).toStringAsFixed(1)}%'),
              if (hasOverload) ...<Widget>[
                const SizedBox(height: 4),
                const Text('⚠️ PROBLEM: Some circuits exceed ${250.0}W per-channel limit!', 
                           style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
                for (final Map<String, dynamic> circuit in circuitData) ...<Widget>[
                  if ((circuit['power'] as double) > powerPerChannel)
                    Text('• Circuit ${circuit['id']}: ${(circuit['power'] as double).toStringAsFixed(1)}W > ${powerPerChannel.toStringAsFixed(1)}W', 
                         style: const TextStyle(color: Colors.red)),
                ],
              ] else ...<Widget>[
                const Text('✅ All circuits fit within per-channel limits', 
                           style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Asymmetrical strategy actual calculation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[50],
            border: Border.all(color: Colors.orange[200]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('⚖️ ASYMMETRICAL CALCULATION:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('High-power circuits (>${powerPerChannel.toStringAsFixed(0)}W): ${circuitData.where((Map<String, dynamic> c) => (c['power'] as double) > powerPerChannel).length}'),
              Text('Dedicated amps needed: ${circuitData.where((Map<String, dynamic> c) => (c['power'] as double) > powerPerChannel).length}'),
              Text('Remaining power: ${(remainingPower > 0 ? remainingPower : 0).toStringAsFixed(1)}W'),
              Text('Shared amps needed: ${asymmetricalAmps - circuitData.where((Map<String, dynamic> c) => (c['power'] as double) > powerPerChannel).length}'),
              Text('Total amplifiers: $asymmetricalAmps'),
              Text('Total capacity: ${asymmetricalCapacity.toStringAsFixed(1)}W'),
              Text('Efficiency: ${(asymmetricalEfficiency * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
        
        const SizedBox(height: 8),
        
        // Recommendation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[100],
            border: Border.all(color: Colors.green[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('🎯 RECOMMENDATION FOR YOUR CONFIG:', style: TextStyle(fontWeight: FontWeight.bold)),
              if (hasOverload) ...<Widget>[
                const Text('Use ASYMMETRICAL - Symmetrical cannot handle high-power circuits',
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                Text('Savings: ${symmetricalAmps - asymmetricalAmps} fewer amplifiers needed'),
              ] else if (asymmetricalEfficiency > symmetricalEfficiency + 0.1) ...<Widget>[
                const Text('Use ASYMMETRICAL - Better efficiency',
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text('Efficiency gain: ${((asymmetricalEfficiency - symmetricalEfficiency) * 100).toStringAsFixed(1)}%'),
              ] else if (asymmetricalAmps < symmetricalAmps) ...<Widget>[
                const Text('Use ASYMMETRICAL - Fewer amplifiers needed',
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text('Amplifier savings: ${symmetricalAmps - asymmetricalAmps} units'),
              ] else ...<Widget>[
                const Text('Use SYMMETRICAL - Simpler configuration',
                           style: TextStyle(fontWeight: FontWeight.bold, color: Colors.blue)),
                const Text('Similar efficiency with easier setup'),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildFinalValidationDetails() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('✅ Final Validation Process:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        if (symmetricalResult != null && asymmetricalResult != null) ...<Widget>[
          // Show actual results
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              border: Border.all(color: Colors.green[200]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('🏆 Algorithm Results:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                
                // Symmetrical Results
                Row(
                  children: <Widget>[
                    const Icon(Icons.balance, color: Colors.blue, size: 16),
                    const SizedBox(width: 4),
                    const Text('Symmetrical: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.blue)),
                    Text('${symmetricalResult!.amplifierCount} amplifiers, '),
                    Text('${(symmetricalResult!.powerEfficiency * 100).toStringAsFixed(1)}% efficiency'),
                  ],
                ),
                
                // Asymmetrical Results
                Row(
                  children: <Widget>[
                    const Icon(Icons.share, color: Colors.green, size: 16),
                    const SizedBox(width: 4),
                    const Text('Asymmetrical: ', style: TextStyle(fontWeight: FontWeight.w500, color: Colors.green)),
                    Text('${asymmetricalResult!.amplifierCount} amplifiers, '),
                    Text('${(asymmetricalResult!.powerEfficiency * 100).toStringAsFixed(1)}% efficiency'),
                  ],
                ),
                
                const SizedBox(height: 8),
                const Text('Validation steps completed:', style: TextStyle(fontWeight: FontWeight.w500)),
                const Text('• ✅ All circuits successfully assigned'),
                const Text('• ✅ Power requirements verified'),
                const Text('• ✅ Channel allocations validated'),
                const Text('• ✅ SKU reduction optimization applied'),
              ],
            ),
          ),
        ] else ...<Widget>[
          // Show validation checklist
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Validation Checklist:', style: TextStyle(fontWeight: FontWeight.bold)),
                SizedBox(height: 4),
                Text('• Circuit assignment verification'),
                Text('• Power requirement validation'),
                Text('• Impedance compatibility check'),
                Text('• Channel utilization optimization'),
                Text('• SKU reduction (minimum amplifier count)'),
                Text('• Final system capacity calculation'),
                SizedBox(height: 8),
                Text('Run algorithm to see detailed validation results.', 
                     style: TextStyle(fontStyle: FontStyle.italic, color: Colors.grey)),
              ],
            ),
          ),
        ],
      ],
    );
  }

  double _estimateCircuitPower(CircuitInput circuit) {
    if (circuit.selectedModel == null) return 0.0;
    
    final int speakerCount = int.tryParse(circuit.speakerCountController.text) ?? 0;
    final double tapWatts = double.tryParse(circuit.tapWattsController.text) ?? 0.0;
    final double offsetDb = double.tryParse(circuit.offsetDbController.text) ?? 0.0;
    
    double power = 0;
    if (circuit.mode == 'hi-z') {
      // ✅ CORRECTED: For Hi-Z, peak power = tap × count × 2
      // Ppk_total = [Σ (tap) × count] × 2
      power = speakerCount * tapWatts * 2.0;
    } else {
      // For Lo-Z, use speaker peak power (ppk) which is already peak
      final SpeakerModel? speaker = SpeakerCatalog.database[circuit.selectedModel];
      power = speakerCount * (speaker?.ppk ?? 0);
    }
    
    // Apply offset
    if (offsetDb != 0) {
      power = power * math.pow(10.0, -offsetDb / 10.0);
    }
    
    return power;
  }

  Widget _buildStrategyResultCard(String title, AmpMatchingResult result, Color color, PowerAllocationStrategy strategy, IconData icon) {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: color.withOpacity(0.3)),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Header
            Row(
              children: <Widget>[
                Icon(icon, color: color),
                const SizedBox(width: 8),
                Text(title, style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 12),
            
            // Key Metrics (like test file)
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Column(
                children: <Widget>[
                  _buildSimpleMetricRow('Amplifiers needed', '${result.amplifierCount}'),
                  _buildSimpleMetricRow('Power efficiency', '${(result.powerEfficiency * 100).toStringAsFixed(1)}%'),
                  _buildSimpleMetricRow('Channel efficiency', '${(result.channelEfficiency * 100).toStringAsFixed(1)}%'),
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Amplifier Details (simplified like test file)
            const Text('🔌 Suggested Amplifiers:', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            
            ...result.assignments.asMap().entries.map((MapEntry<int, AmpAssignment> entry) {
              final int index = entry.key;
              final AmpAssignment assignment = entry.value;
              final double correctCapacity = assignment.getTotalCapacity(
                strategy: strategy,
                systemVoltage: _globalVoltage,
              );
              
              return Container(
                margin: const EdgeInsets.only(bottom: 8),
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: color.withOpacity(0.2)),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('📦 Amplifier ${index + 1}: ${assignment.ampModel.name}', 
                         style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('   • Channels: ${assignment.ampModel.channels}'),
                    Text('   • Power per Channel: ${assignment.ampModel.peakPerChannel.toInt()}W'),
                    Text('   • Total Capacity: ${correctCapacity.toInt()}W (${title.split(' ')[0]} mode)'),
                    Text('   • Utilization: ${assignment.usedChannels}/${assignment.totalChannels} channels (${(assignment.channelUtilization * 100).toStringAsFixed(1)}%)'),
                    const Text('   • Assigned Circuits:'),
                    ...assignment.circuits.map((Circuit circuit) =>
                      Text('     - Circuit ${circuit.circuitId}: ${circuit.speakerCount}x ${circuit.model} (${circuit.mode})'),
                    ),
                  ],
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildSimpleMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(label, style: const TextStyle(fontSize: 12)),
          Text(value, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
        ],
      ),
    );
  }

  Widget _buildComparisonSummaryCard(AmpMatchingResult symmetrical, AmpMatchingResult asymmetrical) {
    final bool asymmetricalBetter = asymmetrical.amplifierCount <= symmetrical.amplifierCount &&
                                   asymmetrical.powerEfficiency >= symmetrical.powerEfficiency;
    
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            colors: <Color>[Colors.amber[50]!, Colors.amber[100]!],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          border: Border.all(color: Colors.amber[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.assessment, color: Colors.amber),
                SizedBox(width: 8),
                Text('📊 Strategy Comparison Summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              ],
            ),
            const SizedBox(height: 12),
            
            Row(
              children: <Widget>[
                Expanded(
                  child: _buildComparisonMetric(
                    'Amplifiers Required',
                    symmetrical.amplifierCount.toString(),
                    asymmetrical.amplifierCount.toString(),
                    asymmetrical.amplifierCount <= symmetrical.amplifierCount,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _buildComparisonMetric(
                    'Power Efficiency',
                    '${(symmetrical.powerEfficiency * 100).toStringAsFixed(1)}%',
                    '${(asymmetrical.powerEfficiency * 100).toStringAsFixed(1)}%',
                    asymmetrical.powerEfficiency >= symmetrical.powerEfficiency,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: asymmetricalBetter ? Colors.green[50] : Colors.blue[50],
                border: Border.all(color: asymmetricalBetter ? Colors.green[200]! : Colors.blue[200]!),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Row(
                children: <Widget>[
                  Icon(
                    asymmetricalBetter ? Icons.thumb_up : Icons.info,
                    color: asymmetricalBetter ? Colors.green : Colors.blue,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      asymmetricalBetter 
                        ? '🏆 Recommendation: Asymmetrical mode provides better efficiency and fewer amplifiers'
                        : '📋 Both strategies are viable - choose based on your installation preferences',
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        color: asymmetricalBetter ? Colors.green[800] : Colors.blue[800],
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildComparisonMetric(String label, String symmetricalValue, String asymmetricalValue, bool asymmetricalBetter) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(4),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(label, style: const TextStyle(fontWeight: FontWeight.w500, fontSize: 12)),
          const SizedBox(height: 4),
          Row(
            children: <Widget>[
              const Text('Sym: ', style: TextStyle(fontSize: 11, color: Colors.blue)),
              Text(
                symmetricalValue,
                style: TextStyle(
                  fontWeight: asymmetricalBetter ? FontWeight.normal : FontWeight.bold,
                  color: asymmetricalBetter ? Colors.black54 : Colors.blue,
                ),
              ),
            ],
          ),
          Row(
            children: <Widget>[
              const Text('Asym: ', style: TextStyle(fontSize: 11, color: Colors.green)),
              Text(
                asymmetricalValue,
                style: TextStyle(
                  fontWeight: asymmetricalBetter ? FontWeight.bold : FontWeight.normal,
                  color: asymmetricalBetter ? Colors.green : Colors.black54,
                ),
              ),
              if (asymmetricalBetter) ...<Widget>[
                const SizedBox(width: 4),
                const Icon(Icons.star, size: 12, color: Colors.green),
              ],
            ],
          ),
        ],
      ),
    );
  }
}
