// ignore_for_file: always_specify_types

import 'package:flutter/material.dart';
import 'package:fusion_lib/api_data/speakers/speaker_types.dart';
import 'package:fusion_lib/fusion_algorithms/amplifier_matching/amplifier_matching.dart';
import 'package:fusion_lib/api_data/speakers/speakers.dart';
import 'package:fusion_lib/api_data/amplifiers/amplifier_catalog.dart';
import 'package:fusion_lib/api_data/amplifiers/amplifier_types.dart';
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
  double? selectedTap;
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

  /// Add a high-power test circuit that exceeds amplifier capacity limits
  void _addHighPowerTestCircuit() {
    setState(() {
      final CircuitInput testCircuit = CircuitInput(circuits.length + 1);
      testCircuit.specifiedVoltage = _globalVoltage;
      
      // Find a speaker with high power (preferably > 1000W ppk)
      String? highPowerModel;
      for (final String model in availableSpeakerModels) {
        final SpeakerModel? speaker = SpeakerCatalog.database[model];
        if (speaker != null && speaker.ppk > 1000) {
          highPowerModel = model;
          break;
        }
      }
      
      // If no high-power speaker found, use the first available
      if (highPowerModel == null && availableSpeakerModels.isNotEmpty) {
        highPowerModel = availableSpeakerModels.first;
      }
      
      if (highPowerModel != null) {
        testCircuit.selectedModel = highPowerModel;
        testCircuit.mode = 'lo-z'; // Use Lo-Z for high power
        testCircuit.speakerCountController.text = '10'; // Many speakers to exceed limits
        testCircuit.tapWattsController.text = SpeakerCatalog.database[highPowerModel]?.ppk.toString() ?? '1000';
        testCircuit.offsetDbController.text = '0.0';
      }
      
      circuits.add(testCircuit);
      symmetricalResult = null;
      asymmetricalResult = null;
      errorMessage = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added high-power test circuit - this should trigger capacity warnings!'),
        backgroundColor: Colors.purple,
      ),
    );
  }

  /// Add a normal test circuit within amplifier capacity limits
  void _addNormalTestCircuit() {
    setState(() {
      final CircuitInput testCircuit = CircuitInput(circuits.length + 1);
      testCircuit.specifiedVoltage = _globalVoltage;
      
      // Find a speaker with moderate power (< 500W ppk)
      String? normalPowerModel;
      for (final String model in availableSpeakerModels) {
        final SpeakerModel? speaker = SpeakerCatalog.database[model];
        if (speaker != null && speaker.ppk < 500) {
          normalPowerModel = model;
          break;
        }
      }
      
      // If no moderate-power speaker found, use the first available
      if (normalPowerModel == null && availableSpeakerModels.isNotEmpty) {
        normalPowerModel = availableSpeakerModels.first;
      }
      
      if (normalPowerModel != null) {
        testCircuit.selectedModel = normalPowerModel;
        testCircuit.mode = 'lo-z';
        testCircuit.speakerCountController.text = '2'; // Few speakers
        testCircuit.tapWattsController.text = SpeakerCatalog.database[normalPowerModel]?.ppk.toString() ?? '100';
        testCircuit.offsetDbController.text = '0.0';
      }
      
      circuits.add(testCircuit);
      symmetricalResult = null;
      asymmetricalResult = null;
      errorMessage = null;
    });
    
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Added normal test circuit - this should pass capacity validation'),
        backgroundColor: Colors.green,
      ),
    );
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

          // Capacity Validation Warning Section
          if (symmetricalResult != null && asymmetricalResult != null)
            _buildCapacityValidationSection(symmetricalResult!, asymmetricalResult!),

          // Results section - Always show side-by-side comparison
          if (symmetricalResult != null && asymmetricalResult != null)
            _buildSideBySideResults(symmetricalResult!, asymmetricalResult!),
            
          // Error display
          if (errorMessage != null)
            Card(
              color: Colors.red[100],
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
              initialValue: circuit.selectedModel,
              items:
                  availableSpeakerModels.map((String model) {
                    return DropdownMenuItem<String>(
                      value: model,
                      child: Text(model),
                    );
                  }).toList(),
              onChanged: (String? value) {
                setState(() {
                  circuit.selectedModel = value;
                  // Auto-populate peak power for Lo-Z or first tap for Hi-Z
                  if (value != null) {
                    final SpeakerModel? speaker = SpeakerCatalog.database[value];
                    if (speaker != null) {
                      if (circuit.mode == 'lo-z') {
                        circuit.tapWattsController.text = speaker.ppk.toString();
                      } else if (circuit.mode == 'hi-z' && speaker.hiZTaps.isNotEmpty) {
                        circuit.selectedTap = speaker.hiZTaps.first;
                        circuit.tapWattsController.text = speaker.hiZTaps.first.toString();
                      }
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
                        // Auto-populate based on mode change
                        if (circuit.selectedModel != null) {
                          final SpeakerModel? speaker = SpeakerCatalog.database[circuit.selectedModel!];
                          if (speaker != null) {
                            if (circuit.mode == 'lo-z') {
                              circuit.tapWattsController.text = speaker.ppk.toString();
                            } else if (circuit.mode == 'hi-z' && speaker.hiZTaps.isNotEmpty) {
                              circuit.selectedTap = speaker.hiZTaps.first;
                              circuit.tapWattsController.text = speaker.hiZTaps.first.toString();
                            }
                          }
                        }
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
                        // Auto-populate based on mode change
                        if (circuit.selectedModel != null) {
                          final SpeakerModel? speaker = SpeakerCatalog.database[circuit.selectedModel!];
                          if (speaker != null) {
                            if (circuit.mode == 'lo-z') {
                              circuit.tapWattsController.text = speaker.ppk.toString();
                            } else if (circuit.mode == 'hi-z' && speaker.hiZTaps.isNotEmpty) {
                              circuit.selectedTap = speaker.hiZTaps.first;
                              circuit.tapWattsController.text = speaker.hiZTaps.first.toString();
                            }
                          }
                        }
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
                    child: _buildTapSelector(circuit),
                  )
                else
                  Expanded(
                    child: TextFormField(
                      controller: circuit.tapWattsController,
                      decoration: const InputDecoration(
                        labelText: 'Peak Power (P_pk)',
                        border: const OutlineInputBorder(),
                        suffixIcon: const Icon(Icons.auto_awesome, size: 16),
                      ),
                      keyboardType: TextInputType.number,
                      readOnly: true,
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

  /// Build capacity validation section to show warnings when amplifiers cannot fulfill circuit requirements
  Widget _buildCapacityValidationSection(AmpMatchingResult symmetrical, AmpMatchingResult asymmetrical) {
    final bool hasErrors = symmetrical.hasErrors || asymmetrical.hasErrors;
    final bool hasWarnings = symmetrical.hasWarnings || asymmetrical.hasWarnings;
    
    if (!hasErrors && !hasWarnings) {
      return const SizedBox.shrink(); // Don't show section if no issues
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const SizedBox(height: 16),
        
        // Critical Errors Section
        if (hasErrors) ...<Widget>[
          Card(
            color: Colors.red[50],
            elevation: 3,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.red[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.error_outline, color: Colors.red, size: 24),
                      SizedBox(width: 8),
                      Text(
                        '⚠️ CRITICAL: Amplifier Capacity Exceeded',
                        style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  
                  // Symmetrical errors
                  if (symmetrical.hasErrors) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('🔄 Symmetrical Mode Issues:', 
                               style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 4),
                          for (final String error in symmetrical.errors)
                            Text('• $error', style: TextStyle(color: Colors.red[800])),
                        ],
                      ),
                    ),
                    const SizedBox(height: 8),
                  ],
                  
                  // Asymmetrical errors
                  if (asymmetrical.hasErrors) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.red[100],
                        border: Border.all(color: Colors.red[200]!),
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('⚖️ Asymmetrical Mode Issues:', 
                               style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
                          const SizedBox(height: 4),
                          for (final String error in asymmetrical.errors)
                            Text('• $error', style: TextStyle(color: Colors.red[800])),
                        ],
                      ),
                    ),
                  ],
                  
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.orange[100],
                      border: Border.all(color: Colors.orange[300]!),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: const Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Text('💡 RECOMMENDATION:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
                        SizedBox(height: 4),
                        Text('• Reduce circuit power requirements (fewer speakers or lower power settings)'),
                        Text('• Use higher-capacity amplifiers if available'),
                        Text('• Consider splitting circuits across multiple amplifiers'),
                        Text('• Check if any circuits exceed individual amplifier limits'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
        
        // Warnings Section
        if (hasWarnings) ...<Widget>[
          Card(
            color: Colors.orange[50],
            elevation: 2,
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.orange[300]!),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  const Row(
                    children: <Widget>[
                      Icon(Icons.warning_amber, color: Colors.orange, size: 20),
                      SizedBox(width: 8),
                      Text(
                        '⚠️ Capacity Warnings',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.orange),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  
                  // Symmetrical warnings
                  if (symmetrical.hasWarnings) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        border: Border.all(color: Colors.orange[200]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('🔄 Symmetrical:', style: TextStyle(fontWeight: FontWeight.w500)),
                          for (final String warning in symmetrical.warnings)
                            Text('• $warning', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                    const SizedBox(height: 4),
                  ],
                  
                  // Asymmetrical warnings
                  if (asymmetrical.hasWarnings) ...<Widget>[
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.orange[100],
                        border: Border.all(color: Colors.orange[200]!),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const Text('⚖️ Asymmetrical:', style: TextStyle(fontWeight: FontWeight.w500)),
                          for (final String warning in asymmetrical.warnings)
                            Text('• $warning', style: const TextStyle(fontSize: 12)),
                        ],
                      ),
                    ),
                  ],
                ],
              ),
            ),
          ),
        ],
      ],
    );
  }

  /// Side-by-side results display with detailed technical calculations
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
                  '🎵 Amplifier Matching Algorithm Results - Side-by-Side Technical Analysis',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ],
            ),
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Amplifier Capacity Comparison Table
        _buildAmplifierCapacityTable(),
        
        const SizedBox(height: 16),
        
        // Side-by-side detailed technical analysis
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Left side - Symmetrical Mode
            Expanded(
              child: _buildDetailedTechnicalAnalysis(
                'SYMMETRICAL MODE', 
                symmetrical, 
                Colors.blue, 
                PowerAllocationStrategy.symmetrical,
                Icons.balance,
              ),
            ),
            const SizedBox(width: 16),
            // Right side - Asymmetrical Mode
            Expanded(
              child: _buildDetailedTechnicalAnalysis(
                'ASYMMETRICAL MODE', 
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
        // _buildComparisonSummaryCard(symmetrical, asymmetrical),
      ],
    );
  }

  /// Build detailed technical analysis for each mode with step-by-step calculations
  Widget _buildDetailedTechnicalAnalysis(String title, AmpMatchingResult result, Color color, PowerAllocationStrategy strategy, IconData icon) {
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
                Icon(icon, color: color, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    title, 
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Step 1: Input Circuit Analysis
            _buildTechnicalStepCard(
              'STEP 1: Input Circuit Analysis',
              _buildInputCircuitAnalysis(strategy),
              color,
            ),
            
            // Step 2: Power Calculation
            _buildTechnicalStepCard(
              'STEP 2: Power Calculation',
              _buildPowerCalculationStep(strategy),
              color,
            ),
            
            // Step 3: Circuit Sorting
            _buildTechnicalStepCard(
              'STEP 3: Circuit Sorting',
              _buildCircuitSortingStep(),
              color,
            ),
            
            // Step 4: Amplifier Tier Matching (Symmetrical only)
            if (strategy == PowerAllocationStrategy.symmetrical)
              _buildTechnicalStepCard(
                'STEP 4: Amplifier Tier Matching',
                _buildAmplifierTierMatchingStep(strategy),
                color,
              ),
            
            // Step 4: Power Sharing Analysis with Channel-Based Results Display (Asymmetrical only)
            if (strategy == PowerAllocationStrategy.asymmetrical)
              _buildTechnicalStepCard(
                'STEP 4: Power Sharing Analysis with Channel-Based Results Display',
                _buildChannelBasedResults(),
                color,
              ),
            
            
            // Step 5: Final Validation & Selection (Symmetrical only)
            if (strategy == PowerAllocationStrategy.symmetrical)
              _buildTechnicalStepCard(
                'STEP 5: Final Validation & Selection',
                _buildFinalValidationStep(result, strategy),
                color,
              ),
            
            // Step 5: Final Validation & Selection for Asymmetrical Mode
            if (strategy == PowerAllocationStrategy.asymmetrical)
              _buildTechnicalStepCard(
                'STEP 5: Final Validation & Selection for Asymmetrical Mode',
                _buildAsymmetricalFinalValidationStep(),
                color,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildTechnicalStepCard(String title, Widget content, Color color) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      child: ExpansionTile(
        leading: Icon(Icons.engineering, color: color),
        title: Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
        children: <Widget>[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: color.withOpacity(0.05),
              border: Border.all(color: color.withOpacity(0.2)),
              borderRadius: BorderRadius.circular(8),
            ),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildInputCircuitAnalysis(PowerAllocationStrategy strategy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('📋 Circuit Configuration:', style: TextStyle(fontWeight: FontWeight.bold)),
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

  Widget _buildPowerCalculationStep(PowerAllocationStrategy strategy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('📐 Power Calculation Formulas:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        // Formula explanation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.blue[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Hi-Z Formula: P_base = N_speakers × W_tap × 2', 
                   style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              Text('Lo-Z Formula: P_base = N_speakers × P_peak(speaker_model)', 
                   style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
              Text('Offset Formula: P_actual = P_base × 10^(-dB/10)', 
                   style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        const Text('🧮 Actual Calculations:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        if (circuits.isNotEmpty) ...<Widget>[
          for (final CircuitInput circuit in circuits)
            _buildActualPowerCalculation(circuit),
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

  Widget _buildActualPowerCalculation(CircuitInput circuit) {
    final SpeakerModel? speaker = SpeakerCatalog.database[circuit.selectedModel];
    final int speakerCount = int.tryParse(circuit.speakerCountController.text) ?? 1;
    final double tapWatts = double.tryParse(circuit.tapWattsController.text) ?? 0.0;
    final double offsetDb = double.tryParse(circuit.offsetDbController.text) ?? 0.0;
    
    // Calculate original power
    double originalPower = 0.0;
    String powerSource = '';
    
    if (circuit.mode == 'hi-z') {
      originalPower = speakerCount * tapWatts * 2.0; // Peak power
      powerSource = '${speakerCount} speakers × ${tapWatts}W tap × 2';
    } else if (speaker != null) {
      originalPower = speakerCount * speaker.ppk;
      powerSource = '${speakerCount} × ${speaker.model} (${speaker.ppk}W ppk)';
    }
    
    // Calculate offset multiplier and final power
    final double multiplier = math.pow(10.0, -offsetDb / 10.0).toDouble();
    final double finalPower = originalPower * multiplier;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: offsetDb != 0 ? Colors.orange[100] : Colors.green[100],
        border: Border.all(color: offsetDb != 0 ? Colors.orange[300]! : Colors.green[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Circuit ${circuit.circuitId}: ${circuit.selectedModel ?? "No model selected"}', 
               style: const TextStyle(fontWeight: FontWeight.bold)),
          
          if (circuit.selectedModel != null) ...<Widget>[
            const SizedBox(height: 4),
            Text('1. Base Power: $powerSource = ${originalPower.toStringAsFixed(1)}W'),
            
            if (offsetDb != 0) ...<Widget>[
              Text('2. Offset: ${offsetDb}dB'),
              Text('3. Multiplier: 10^(-${offsetDb}/10) = ${multiplier.toStringAsFixed(3)}'),
              Text('4. Final Power: ${originalPower.toStringAsFixed(1)}W × ${multiplier.toStringAsFixed(3)} = ${finalPower.toStringAsFixed(1)}W', 
                   style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
            ] else ...<Widget>[
              const Text('2. No offset applied (0dB)'),
              Text('Final Power: ${originalPower.toStringAsFixed(1)}W', 
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

  Widget _buildCircuitSortingStep() {
    final List<CircuitInput> sortedCircuits = List<CircuitInput>.from(circuits);
    sortedCircuits.sort((CircuitInput a, CircuitInput b) => _estimateCircuitPower(b).compareTo(_estimateCircuitPower(a)));
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('📊 Circuits sorted by power (highest to lowest):', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        if (sortedCircuits.isNotEmpty) ...<Widget>[
          for (int i = 0; i < sortedCircuits.length; i++) ...<Widget>[
            Container(
              padding: const EdgeInsets.all(8),
              margin: const EdgeInsets.only(bottom: 4),
              decoration: BoxDecoration(
                color: i == 0 ? Colors.red[100] : (i == 1 ? Colors.orange[100] : Colors.yellow[100]),
                border: Border.all(color: i == 0 ? Colors.red[300]! : (i == 1 ? Colors.orange[300]! : Colors.yellow[300]!)),
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

  Widget _buildAmplifierTierMatchingStep(PowerAllocationStrategy strategy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('🎯 Amplifier Tier Matching Algorithm:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal[100],
            border: Border.all(color: Colors.teal[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('Tier Rule: Ppk_amplifier (next tier up) ≥ Pk_speaker_total ≥ Ppk_amplifier (current tier)', 
                   style: TextStyle(fontFamily: 'monospace', fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 8),
              const Text('Channel Allocation Strategy:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• Start with 4-channel amplifier'),
              const Text('• At 5+ channels: Use 8-channel amplifier'),
              const Text('• At 9+ channels: Add 4-channel amplifier'),
              const Text('• At 13+ channels: Add 2nd 8-channel amplifier'),
              const Text('• Continue pattern: unused channels on smallest amplifiers'),
              const SizedBox(height: 8),
              const Text('Available Amplifier Tiers:', style: TextStyle(fontWeight: FontWeight.bold)),
              ...AmplifierCatalog.allModels.map((AmplifierModel amp) => 
                Text('• ${amp.name}: ${amp.symmetrical.watts}W/ch, ${amp.symmetrical.totalCapacity}W total, ${amp.channels} channels')),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        const Text('🧮 Amplifier Matching Process:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        
        if (circuits.isNotEmpty) ...<Widget>[
          _buildAmplifierMatchingProcess(strategy),
        ] else ...<Widget>[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: const Text('Add circuits to see amplifier matching process', 
                               style: TextStyle(fontStyle: FontStyle.italic)),
          ),
        ],
      ],
    );
  }

  /// Calculate optimal amplifier allocation with cost optimization
  /// Implements "fill existing amplifiers first" strategy for maximum efficiency
  List<Map<String, dynamic>> _calculateOptimalAmplifierAllocation(
    List<Map<String, dynamic>> circuitData, 
    AmplifierModel minRequiredTier,
  ) {
    final List<Map<String, dynamic>> amplifierAllocation = <Map<String, dynamic>>[];
    final List<AmplifierModel> amplifiers = AmplifierCatalog.allModels;
    
    // Sort circuits by power (highest first) - largest circuits are hardest to fit
    final List<Map<String, dynamic>> sortedCircuits = List<Map<String, dynamic>>.from(circuitData);
    sortedCircuits.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (b['power'] as double).compareTo(a['power'] as double));
    
    // Strategy: Fill existing amplifiers first, then create new ones
    int amplifierCount = 0;
    
    // Process circuits one by one, trying to fit them into existing amplifiers first
    for (final Map<String, dynamic> circuit in sortedCircuits) {
      bool assignedToExisting = false;
      
      // Try to assign to existing amplifiers that have available channels
      for (final Map<String, dynamic> amp in amplifierAllocation) {
        final int usedChannels = amp['usedChannels'] as int;
        final int totalChannels = amp['totalChannels'] as int;
        final AmplifierModel ampModel = amp['tierModel'] as AmplifierModel;
        
        // Check: 1) Available channels, 2) Per-channel capacity, 3) Total amplifier capacity
        final List<Map<String, dynamic>> assignedCircuits = amp['circuitsAssigned'] as List<Map<String, dynamic>>;
        final double currentTotalPower = assignedCircuits.fold(0.0, (double sum, Map<String, dynamic> c) => sum + (c['power'] as double));
        final double newTotalPower = currentTotalPower + (circuit['power'] as double);
        
        if (usedChannels < totalChannels && 
            (circuit['power'] as double) <= ampModel.asymmetrical.watts &&
            newTotalPower <= ampModel.asymmetrical.totalCapacity) {
          // This amplifier can handle this circuit and has available channels
          assignedCircuits.add(circuit);
          amp['usedChannels'] = usedChannels + 1;
          amp['unusedChannels'] = totalChannels - (usedChannels + 1);
          assignedToExisting = true;
          break;
        }
      }
      
      // If not assigned to existing amplifier, create a new one
      if (!assignedToExisting) {
        // Find the smallest amplifier that can handle this circuit
        AmplifierModel? selectedAmp;
        for (final AmplifierModel amp in amplifiers) {
          if ((circuit['power'] as double) <= amp.asymmetrical.watts) {
            selectedAmp = amp;
            break;
          }
        }
        
        if (selectedAmp == null) {
          // This should not happen as we already validated the circuits
          continue;
        }
        
        amplifierCount++;
        amplifierAllocation.add(<String, dynamic>{
          'amplifierNumber': amplifierCount,
          'tier': selectedAmp.name,
          'tierModel': selectedAmp,
          'totalChannels': selectedAmp.channels,
          'usedChannels': 1,
          'unusedChannels': selectedAmp.channels - 1,
          'circuitsAssigned': <Map<String, dynamic>>[circuit],
        });
      }
    }
    
    return amplifierAllocation;
  }

  /// Step 1: Initial Amplifier Selection & Power Sharing Analysis for Asymmetrical Mode
  Widget _buildAsymmetricalInitialAnalysis() {
    // Calculate circuit powers and sort by power (highest first)
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    double totalSystemPower = 0.0;
    
    for (final CircuitInput circuit in circuits) {
      final double circuitPower = _estimateCircuitPower(circuit);
      circuitData.add(<String, dynamic>{
        'circuit': circuit,
        'power': circuitPower,
        'model': circuit.selectedModel ?? 'Unknown',
        'speakerCount': int.tryParse(circuit.speakerCountController.text) ?? 0,
        'mode': circuit.mode.toUpperCase(),
      });
      totalSystemPower += circuitPower;
    }
    
    // Sort circuits by power (highest first)
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (b['power'] as double).compareTo(a['power'] as double));
    
    // Find minimum required amplifier tier
    final double maxCircuitPower = circuitData.isNotEmpty ? circuitData.first['power'] as double : 0.0;
    final List<AmplifierModel> amplifiers = AmplifierCatalog.allModels;
    
    AmplifierModel? selectedTier;
    for (final AmplifierModel amp in amplifiers) {
      if (maxCircuitPower <= amp.asymmetrical.watts) {
        selectedTier = amp;
        break;
      }
    }
    
    if (selectedTier == null) {
      return Column(
        children: <Widget>[
          const Text('❌ Error: No amplifier can handle the maximum circuit power'),
          Text('Maximum circuit power: ${maxCircuitPower.toStringAsFixed(1)}W'),
          Text('Maximum amplifier capacity: ${amplifiers.last.asymmetrical.watts}W'),
        ],
      );
    }
    
    return Column(
      children: <Widget>[
        // System Summary
        Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
              const Text('📊 Initial System Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Total Circuits: ${circuitData.length}'),
              Text('Total System Power: ${totalSystemPower.toStringAsFixed(1)}W'),
              Text('Maximum Circuit Power: ${maxCircuitPower.toStringAsFixed(1)}W'),
              Text('Selected Amplifier: ${selectedTier.name}'),
              Text('Asymmetrical Per-Channel Capacity: ${selectedTier.asymmetrical.watts}W'),
              Text('Total Asymmetrical Capacity: ${selectedTier.asymmetrical.totalCapacity}W'),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Circuit Details
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('📋 Circuits (Sorted by Power):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...circuitData.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                final int index = entry.key;
                final Map<String, dynamic> circuit = entry.value;
                return Padding(
                  padding: const EdgeInsets.symmetric(vertical: 2),
                  child: Text('${index + 1}. ${circuit['model']} (${circuit['mode']}) - ${(circuit['power'] as double).toStringAsFixed(1)}W - ${circuit['speakerCount']} speakers'),
                );
              }),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Initial Power Sharing Analysis
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
              const Text('⚡ Initial Power Sharing Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              _buildChannelBasedTable(circuitData, selectedTier),
            ],
          ),
        ),
      ],
    );
  }

  /// Step 2: Circuit Movement Optimization for Asymmetrical Mode
  Widget _buildCircuitMovementOptimization() {
    // Calculate circuit powers and sort by power (highest first)
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    double totalSystemPower = 0.0;
    
    for (final CircuitInput circuit in circuits) {
        final double circuitPower = _estimateCircuitPower(circuit);
      circuitData.add(<String, dynamic>{
        'circuit': circuit,
        'power': circuitPower,
        'model': circuit.selectedModel ?? 'Unknown',
        'speakerCount': int.tryParse(circuit.speakerCountController.text) ?? 0,
        'mode': circuit.mode.toUpperCase(),
      });
      totalSystemPower += circuitPower;
    }
    
    // Sort circuits by power (highest first)
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (b['power'] as double).compareTo(a['power'] as double));
    
    // Find minimum required amplifier tier
    final double maxCircuitPower = circuitData.isNotEmpty ? circuitData.first['power'] as double : 0.0;
    final List<AmplifierModel> amplifiers = AmplifierCatalog.allModels;
    
    AmplifierModel? selectedTier;
    for (final AmplifierModel amp in amplifiers) {
      if (maxCircuitPower <= amp.asymmetrical.watts) {
        selectedTier = amp;
        break;
      }
    }
    
    if (selectedTier == null) {
      return const Column(
        children: <Widget>[
          Text('❌ Error: No amplifier can handle the maximum circuit power'),
        ],
      );
    }
    
    // Simulate circuit movement optimization process
    final List<Map<String, dynamic>> optimizationSteps = <Map<String, dynamic>>[];
    
    // Step 1: Initial assignment
    optimizationSteps.add(<String, dynamic>{
      'step': 1,
      'description': 'Initial Assignment',
      'amplifiers': <Map<String, dynamic>>[
        <String, dynamic>{
          'name': selectedTier.name,
          'channels': List.generate(selectedTier.channels, (int index) => <String, dynamic>{
            'channelNumber': index + 1,
            'circuit': index < circuitData.length ? circuitData[index] : null,
            'power': index < circuitData.length ? circuitData[index]['power'] as double : 0.0,
          }),
          'netPowerSharing': _calculateNetPowerSharing(circuitData, selectedTier),
          'availableToShare': _calculateAvailableToShare(circuitData, selectedTier),
        },
      ],
    });
    
    // Step 2: Check for optimization opportunities
    final double netPowerSharing = _calculateNetPowerSharing(circuitData, selectedTier);
    final double availableToShare = _calculateAvailableToShare(circuitData, selectedTier);
    
    if (netPowerSharing > 0 && availableToShare > 0) {
      optimizationSteps.add(<String, dynamic>{
        'step': 2,
        'description': 'Optimization Analysis',
        'amplifiers': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': selectedTier.name,
            'channels': List.generate(selectedTier.channels, (int index) => <String, dynamic>{
              'channelNumber': index + 1,
              'circuit': index < circuitData.length ? circuitData[index] : null,
              'power': index < circuitData.length ? circuitData[index]['power'] as double : 0.0,
              'needsExtraPower': index < circuitData.length && (circuitData[index]['power'] as double) > selectedTier!.symmetrical.watts,
            }),
            'netPowerSharing': netPowerSharing,
            'availableToShare': availableToShare,
            'canOptimize': true,
          },
        ],
      });
      
      // Step 3: Show optimization result
      optimizationSteps.add(<String, dynamic>{
        'step': 3,
        'description': 'Optimization Complete',
        'amplifiers': <Map<String, dynamic>>[
          <String, dynamic>{
            'name': selectedTier.name,
            'channels': List.generate(selectedTier.channels, (int index) => <String, dynamic>{
              'channelNumber': index + 1,
              'circuit': index < circuitData.length ? circuitData[index] : null,
              'power': index < circuitData.length ? circuitData[index]['power'] as double : 0.0,
              'optimized': true,
            }),
            'netPowerSharing': netPowerSharing,
            'availableToShare': availableToShare,
            'optimizationApplied': true,
          },
        ],
      });
    }
    
    return Column(
      children: <Widget>[
        const Text('🔄 Circuit Movement Optimization Process', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('This step shows the step-by-step process of optimizing circuit assignments for maximum power sharing efficiency.'),
        const SizedBox(height: 16),
        
        // Optimization Steps
        ...optimizationSteps.map((Map<String, dynamic> step) => _buildOptimizationStep(step)),
        
        const SizedBox(height: 16),
        
        // Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.green[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('📊 Optimization Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Net Power Sharing: ${netPowerSharing.toStringAsFixed(1)}W'),
              Text('Available to Share: ${availableToShare.toStringAsFixed(1)}W'),
              Text('Optimization Status: ${netPowerSharing > 0 ? 'Applied' : 'No optimization needed'}'),
              Text('Final Amplifier: ${selectedTier.name}'),
            ],
          ),
        ),
      ],
    );
  }

  /// Build an optimization step display
  Widget _buildOptimizationStep(Map<String, dynamic> step) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Step ${step['step']}: ${step['description']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          
          // Amplifier details
          ...(step['amplifiers'] as List<Map<String, dynamic>>).map((Map<String, dynamic> amp) => Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Amplifier: ${amp['name']}', style: const TextStyle(fontWeight: FontWeight.w600)),
          const SizedBox(height: 4),
              
              // Channel details
              ...(amp['channels'] as List<Map<String, dynamic>>).map((Map<String, dynamic> channel) => Padding(
                padding: const EdgeInsets.only(left: 16, top: 2),
                child: Text('Ch ${channel['channelNumber']}: ${channel['circuit'] != null ? '${channel['circuit']['model']} (${(channel['power'] as double).toStringAsFixed(1)}W)' : 'N/A'}'),
              )),
              
              const SizedBox(height: 4),
              Text('Net Power Sharing: ${(amp['netPowerSharing'] as double).toStringAsFixed(1)}W'),
              Text('Available to Share: ${(amp['availableToShare'] as double).toStringAsFixed(1)}W'),
              
              if (amp['canOptimize'] == true)
                const Text('✅ Can optimize power sharing', style: TextStyle(color: Colors.green)),
              if (amp['optimizationApplied'] == true)
                const Text('✅ Optimization applied', style: TextStyle(color: Colors.green)),
              
              const SizedBox(height: 8),
            ],
               )),
        ],
      ),
    );
  }

  /// Calculate net power sharing for an amplifier
  double _calculateNetPowerSharing(List<Map<String, dynamic>> circuitData, AmplifierModel amplifier) {
    final double perChannelCapacity = amplifier.asymmetrical.watts.toDouble();
    double totalSymmSurplus = 0.0;
    double totalAsymmDeficit = 0.0;
    
    for (int i = 0; i < amplifier.channels; i++) {
      final double circuitPower = i < circuitData.length ? circuitData[i]['power'] as double : 0.0;
      final double symmSurplus = math.max(perChannelCapacity - circuitPower, 0.0);
      final double asymmDeficit = math.min(circuitPower - perChannelCapacity, 0.0);
      
      totalSymmSurplus += symmSurplus;
      totalAsymmDeficit += asymmDeficit;
    }
    
    return totalSymmSurplus + totalAsymmDeficit;
  }

  /// Calculate available power to share
  double _calculateAvailableToShare(List<Map<String, dynamic>> circuitData, AmplifierModel amplifier) {
    final double perChannelCapacity = amplifier.asymmetrical.watts.toDouble();
    double totalSymmSurplus = 0.0;
    
    for (int i = 0; i < amplifier.channels; i++) {
      final double circuitPower = i < circuitData.length ? circuitData[i]['power'] as double : 0.0;
      final double symmSurplus = math.max(perChannelCapacity - circuitPower, 0.0);
      totalSymmSurplus += symmSurplus;
    }
    
    return totalSymmSurplus;
  }

  /// Step 3: Final Tier Rule Validation for Asymmetrical Mode
  Widget _buildFinalTierRuleValidation() {
    // Calculate circuit powers and sort by power (highest first)
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    double totalSystemPower = 0.0;
    
    for (final CircuitInput circuit in circuits) {
      final double circuitPower = _estimateCircuitPower(circuit);
      circuitData.add(<String, dynamic>{
        'circuit': circuit,
        'power': circuitPower,
        'model': circuit.selectedModel ?? 'Unknown',
        'speakerCount': int.tryParse(circuit.speakerCountController.text) ?? 0,
        'mode': circuit.mode.toUpperCase(),
      });
      totalSystemPower += circuitPower;
    }
    
    // Sort circuits by power (highest first)
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (b['power'] as double).compareTo(a['power'] as double));
    
    // Find minimum required amplifier tier
    final double maxCircuitPower = circuitData.isNotEmpty ? circuitData.first['power'] as double : 0.0;
    final List<AmplifierModel> amplifiers = AmplifierCatalog.allModels;
    
    AmplifierModel? selectedTier;
    for (final AmplifierModel amp in amplifiers) {
      if (maxCircuitPower <= amp.asymmetrical.watts) {
        selectedTier = amp;
        break;
      }
    }
    
    if (selectedTier == null) {
      return const Column(
        children: <Widget>[
          Text('❌ Error: No amplifier can handle the maximum circuit power'),
        ],
      );
    }
    
    // Validate tier rule: Ppk_amplifier (next tier up) ≥ Pk_speaker_total ≥ Ppk_amplifier (current tier)
    final List<Map<String, dynamic>> validationResults = <Map<String, dynamic>>[];
    
    // Check current tier
    final bool currentTierValid = totalSystemPower >= selectedTier.symmetrical.totalCapacity;
    
    // Check next tier up
    AmplifierModel? nextTierUp;
    for (int i = 0; i < amplifiers.length; i++) {
      if (amplifiers[i] == selectedTier && i < amplifiers.length - 1) {
        nextTierUp = amplifiers[i + 1];
        break;
      }
    }
    
    final bool nextTierUpValid = nextTierUp == null || totalSystemPower <= nextTierUp.symmetrical.totalCapacity;
    
    validationResults.add(<String, dynamic>{
      'amplifier': selectedTier.name,
      'currentTierCapacity': selectedTier.symmetrical.totalCapacity,
      'nextTierUpCapacity': nextTierUp?.symmetrical.totalCapacity ?? 'N/A',
      'totalSystemPower': totalSystemPower,
      'currentTierValid': currentTierValid,
      'nextTierUpValid': nextTierUpValid,
      'overallValid': currentTierValid && nextTierUpValid,
    });
    
    // Check if downgrade is needed
    bool needsDowngrade = false;
    AmplifierModel? recommendedTier;
    
    if (!currentTierValid) {
      needsDowngrade = true;
      // Find the appropriate tier down
      for (int i = amplifiers.length - 1; i >= 0; i--) {
        if (amplifiers[i].symmetrical.totalCapacity >= totalSystemPower) {
          recommendedTier = amplifiers[i];
          break;
        }
      }
    }
    
    return Column(
      children: <Widget>[
        const Text('✅ Final Tier Rule Validation', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Validating tier rule: Ppk_amplifier (next tier up) ≥ Pk_speaker_total ≥ Ppk_amplifier (current tier)'),
        const SizedBox(height: 16),
        
        // Validation Results
        ...validationResults.map((Map<String, dynamic> result) => _buildValidationResult(result)),
        
        const SizedBox(height: 16),
        
        // Downgrade Recommendation
        if (needsDowngrade) ...<Widget>[
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
                const Text('⚠️ Tier Downgrade Required', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
        const SizedBox(height: 8),
                Text('Current tier ${selectedTier.name} cannot handle total system power.'),
                Text('Recommended tier: ${recommendedTier?.name ?? 'None available'}'),
                Text('Reason: Total system power (${totalSystemPower.toStringAsFixed(1)}W) > Current tier capacity (${selectedTier.symmetrical.totalCapacity}W)'),
              ],
            ),
          ),
          const SizedBox(height: 16),
        ],
        
        // Final Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: (currentTierValid && nextTierUpValid) ? Colors.green[50] : Colors.red[50],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: (currentTierValid && nextTierUpValid) ? Colors.green[200]! : Colors.red[200]!),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('📊 Final Validation Result:', style: TextStyle(fontWeight: FontWeight.bold, color: (currentTierValid && nextTierUpValid) ? Colors.green : Colors.red)),
              Text('Tier Rule Satisfied: ${(currentTierValid && nextTierUpValid) ? 'YES' : 'NO'}'),
              Text('Current Tier Valid: ${currentTierValid ? 'YES' : 'NO'}'),
              Text('Next Tier Up Valid: ${nextTierUpValid ? 'YES' : 'NO'}'),
              Text('Final Amplifier: ${needsDowngrade ? (recommendedTier?.name ?? 'None') : selectedTier.name}'),
            ],
          ),
        ),
      ],
    );
  }

  /// Build validation result display
  Widget _buildValidationResult(Map<String, dynamic> result) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: result['overallValid'] ? Colors.green[50] : Colors.red[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: result['overallValid'] ? Colors.green[200]! : Colors.red[200]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('Amplifier: ${result['amplifier']}', style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          Text('Current Tier Capacity: ${result['currentTierCapacity']}W'),
          Text('Next Tier Up Capacity: ${result['nextTierUpCapacity']}W'),
          Text('Total System Power: ${(result['totalSystemPower'] as double).toStringAsFixed(1)}W'),
          const SizedBox(height: 8),
          Text('Current Tier Valid: ${result['currentTierValid'] ? '✅ YES' : '❌ NO'}'),
          Text('Next Tier Up Valid: ${result['nextTierUpValid'] ? '✅ YES' : '❌ NO'}'),
          Text('Overall Valid: ${result['overallValid'] ? '✅ YES' : '❌ NO'}'),
        ],
      ),
    );
  }

  /// Step 4: Channel-Based Results Display for Asymmetrical Mode
  Widget _buildChannelBasedResults() {
    // Calculate circuit powers and sort by power (highest first) - Step 3: Circuit Sorting
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    double totalSystemPower = 0.0;
    
    for (final CircuitInput circuit in circuits) {
      final double circuitPower = _estimateCircuitPower(circuit);
      circuitData.add(<String, dynamic>{
        'circuit': circuit,
        'power': circuitPower,
        'model': circuit.selectedModel ?? 'Unknown',
        'speakerCount': int.tryParse(circuit.speakerCountController.text) ?? 0,
        'mode': circuit.mode.toUpperCase(),
      });
      totalSystemPower += circuitPower;
    }
    
    // Sort circuits by power (highest first) - Step 3: Circuit Sorting
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (b['power'] as double).compareTo(a['power'] as double));
    
    // Calculate optimal amplifier combination with cost optimization (same as symmetrical mode)
    final List<Map<String, dynamic>> amplifierAllocation = _calculateOptimalAmplifierAllocation(circuitData, AmplifierCatalog.psx1204d);
    
    if (amplifierAllocation.isEmpty) {
      return const Column(
        children: <Widget>[
          Text('❌ Error: No amplifiers could be allocated'),
        ],
      );
    }
    
    // Apply circuit movement optimization logic
    final List<Map<String, dynamic>> optimizedAllocation = _applyCircuitMovementOptimization(amplifierAllocation, circuitData);
    
    // Build power sharing analysis for each amplifier
    final List<Widget> amplifierAnalysisWidgets = <Widget>[];
    
    for (int ampIndex = 0; ampIndex < optimizedAllocation.length; ampIndex++) {
      final Map<String, dynamic> amplifier = optimizedAllocation[ampIndex];
      final AmplifierModel ampModel = amplifier['tierModel'] as AmplifierModel;
      final List<Map<String, dynamic>> assignedCircuits = amplifier['circuitsAssigned'] as List<Map<String, dynamic>>;
      
      // Calculate power sharing for this specific amplifier using AmplifierCatalog data
      final Widget ampAnalysis = _buildAmplifierPowerSharingAnalysis(ampModel, assignedCircuits, ampIndex + 1);
      amplifierAnalysisWidgets.add(ampAnalysis);
    }
    
    return Column(
      children: <Widget>[
        const Text('📊 Mixed Amplifier Power Sharing Analysis', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        const Text('Complete power sharing analysis for each amplifier with circuit movement optimization'),
        const SizedBox(height: 16),

        // Mixed Amplifier Allocation Information
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
              const Text('🔧 Mixed Amplifier Allocation (Cost Optimized):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total Amplifiers Required: ${optimizedAllocation.length}'),
              const SizedBox(height: 8),
              ...optimizedAllocation.map((Map<String, dynamic> amp) => Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('• ${amp['tier']} (${amp['usedChannels']}/${amp['totalChannels']} channels used)'),
                  Text('  Circuits: ${(amp['circuitsAssigned'] as List).map((c) => '${c['model']} (${c['power'].toStringAsFixed(1)}W)').join(', ')}'),
                  const SizedBox(height: 4),
                ],
              )),
              const SizedBox(height: 8),
              const Text('Strategy: Fill existing amplifiers first, then add new ones for cost optimization'),
              const SizedBox(height: 8),
              const Text('Circuit Movement Optimization Applied:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('• Moved circuits from higher-power amplifiers to amplifiers with available power sharing'),
              const Text('• Optimized until no amplifiers have sufficient "Net power sharing" for additional circuits'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        // Individual amplifier power sharing analysis
        ...amplifierAnalysisWidgets,
      ],
    );
  }

  /// Apply circuit movement optimization logic
  List<Map<String, dynamic>> _applyCircuitMovementOptimization(List<Map<String, dynamic>> amplifierAllocation, List<Map<String, dynamic>> circuitData) {
    // Create a copy to avoid modifying the original
    final List<Map<String, dynamic>> optimizedAllocation = <Map<String, dynamic>>[];
    for (final Map<String, dynamic> amp in amplifierAllocation) {
      optimizedAllocation.add(<String, dynamic>{
        'amplifierNumber': amp['amplifierNumber'],
        'tier': amp['tier'],
        'tierModel': amp['tierModel'],
        'totalChannels': amp['totalChannels'],
        'usedChannels': amp['usedChannels'],
        'unusedChannels': amp['unusedChannels'],
        'circuitsAssigned': List<Map<String, dynamic>>.from(amp['circuitsAssigned'] as List),
      });
    }
    
    bool movedCircuit = true;
    int iterations = 0;
    const int maxIterations = 10; // Prevent infinite loops
    
    while (movedCircuit && iterations < maxIterations) {
      movedCircuit = false;
      iterations++;
      
      // Calculate Net Power Sharing for each amplifier
      for (final Map<String, dynamic> amp in optimizedAllocation) {
        final AmplifierModel ampModel = amp['tierModel'] as AmplifierModel;
        final List<Map<String, dynamic>> assignedCircuits = amp['circuitsAssigned'] as List<Map<String, dynamic>>;
        
        // Calculate power sharing for this amplifier
        final double perChannelCapacity = ampModel.symmetrical.watts.toDouble();
        double totalSymmSurplus = 0.0;
        double totalAsymmDeficit = 0.0;
        
        for (int i = 0; i < ampModel.channels; i++) {
          final double actualPowerNeeded = i < assignedCircuits.length ? assignedCircuits[i]['power'] as double : 0.0;
          final double symmSurplus = math.max(perChannelCapacity - actualPowerNeeded, 0.0);
          final double asymmDeficit = math.min(perChannelCapacity - actualPowerNeeded, 0.0);
          totalSymmSurplus += symmSurplus;
          totalAsymmDeficit += asymmDeficit;
        }
        
        final double netPowerSharing = totalSymmSurplus + totalAsymmDeficit;
        amp['netPowerSharing'] = netPowerSharing;
        amp['availableToShare'] = math.max(totalSymmSurplus, 0.0);
      }
      
      // Look for circuits to move
      for (final Map<String, dynamic> sourceAmp in optimizedAllocation) {
        final double sourceNetPowerSharing = sourceAmp['netPowerSharing'] as double;
        final int sourceUsedChannels = sourceAmp['usedChannels'] as int;
        final int sourceTotalChannels = sourceAmp['totalChannels'] as int;
        
        // Only consider amplifiers with positive Net Power Sharing and available channels
        if (sourceNetPowerSharing > 0 && sourceUsedChannels < sourceTotalChannels) {
          // Look for circuits on higher-power amplifiers that could be moved
          for (final Map<String, dynamic> targetAmp in optimizedAllocation) {
            if (targetAmp == sourceAmp) continue;
            
            final List<Map<String, dynamic>> targetCircuits = targetAmp['circuitsAssigned'] as List<Map<String, dynamic>>;
            if (targetCircuits.isEmpty) continue;
            
            // Find the highest power circuit on the target amplifier
            final Map<String, dynamic> highestCircuit = targetCircuits.reduce((Map<String, dynamic> a, Map<String, dynamic> b) => 
              (a['power'] as double) > (b['power'] as double) ? a : b);
            
            final double circuitPower = highestCircuit['power'] as double;
            
            // Check if this circuit can be moved to the source amplifier
            // Must check: 1) Per-channel capacity, 2) Net power sharing, 3) Total amplifier capacity
            final AmplifierModel sourceAmpModel = sourceAmp['tierModel'] as AmplifierModel;
            final List<Map<String, dynamic>> sourceCircuits = sourceAmp['circuitsAssigned'] as List<Map<String, dynamic>>;
            
            // Calculate current total power on source amplifier
            final double currentSourcePower = sourceCircuits.fold(0.0, (double sum, Map<String, dynamic> circuit) => sum + (circuit['power'] as double));
            final double newTotalPower = currentSourcePower + circuitPower;
            
            if (circuitPower <= sourceNetPowerSharing && 
                circuitPower <= sourceAmpModel.asymmetrical.watts &&
                newTotalPower <= sourceAmpModel.asymmetrical.totalCapacity) {
              // Move the circuit
              targetCircuits.remove(highestCircuit);
              (sourceAmp['circuitsAssigned'] as List<Map<String, dynamic>>).add(highestCircuit);
              
              // Update channel counts
              sourceAmp['usedChannels'] = (sourceAmp['usedChannels'] as int) + 1;
              sourceAmp['unusedChannels'] = (sourceAmp['unusedChannels'] as int) - 1;
              targetAmp['usedChannels'] = (targetAmp['usedChannels'] as int) - 1;
              targetAmp['unusedChannels'] = (targetAmp['unusedChannels'] as int) + 1;
              
              movedCircuit = true;
              break;
            }
          }
        }
        if (movedCircuit) break;
      }
    }
    
    return optimizedAllocation;
  }

  /// Build power sharing analysis for a specific amplifier using AmplifierCatalog data
  Widget _buildAmplifierPowerSharingAnalysis(AmplifierModel amplifier, List<Map<String, dynamic>> assignedCircuits, int amplifierNumber) {
    // Use AmplifierCatalog data properly
    final int channelCount = amplifier.channels;
    final double perChannelCapacity = amplifier.symmetrical.watts.toDouble(); // L = per-channel limit
    final double totalCapacity = amplifier.asymmetrical.totalCapacity.toDouble();
    final double asymmetricalShareablePerChannel = amplifier.asymmetrical.watts.toDouble();
    
    // Create channel data for this amplifier
    final List<Map<String, dynamic>> channelData = <Map<String, dynamic>>[];
    double totalSymmSurplus = 0.0;
    double totalAsymmDeficit = 0.0;
    
    for (int i = 0; i < channelCount; i++) {
      final double actualPowerNeeded = i < assignedCircuits.length ? assignedCircuits[i]['power'] as double : 0.0;
      
      // STEP 6: Asymmetrical Analysis formulas (from sample.md)
      final double symmSurplus = math.max(perChannelCapacity - actualPowerNeeded, 0.0);
      final double asymmDeficit = math.min(perChannelCapacity - actualPowerNeeded, 0.0);
      
      // Accumulate totals
      totalSymmSurplus += symmSurplus;
      totalAsymmDeficit += asymmDeficit;
      
      final Map<String, dynamic> channel = <String, dynamic>{
        'channelNumber': i + 1,
        'circuit': i < assignedCircuits.length ? assignedCircuits[i] : null,
        'actualPowerNeeded': actualPowerNeeded,
        'symmSurplus': symmSurplus,
        'asymmDeficit': asymmDeficit,
        'needsExtraPower': asymmDeficit < 0,
      };
      channelData.add(channel);
    }
    
    // Calculate global values from individual channel totals
    final double netPowerSharing = totalSymmSurplus + totalAsymmDeficit;
    final double availableToShare = math.max(totalSymmSurplus, 0.0);
    
    // Count channels needing extra power
    int channelsNeedingPower = 0;
    for (final Map<String, dynamic> channel in channelData) {
      if (channel['needsExtraPower'] as bool) {
        channelsNeedingPower++;
      }
    }
    
    final double sharePerNeeding = channelsNeedingPower > 0 ? availableToShare / channelsNeedingPower : 0.0;
    
    // Complete channel data with remaining calculations
    for (int i = 0; i < channelCount; i++) {
      final Map<String, dynamic> channel = channelData[i];
      final double actualPowerNeeded = channel['actualPowerNeeded'] as double;
      final bool needsExtraPower = channel['needsExtraPower'] as bool;
      
      // STEP 7: Power Distribution Calculation formulas (from sample.md)
      final double powerAvailable = needsExtraPower ? perChannelCapacity + sharePerNeeding : perChannelCapacity;
      final double limitPowerDelivered = math.min(powerAvailable, asymmetricalShareablePerChannel);
      final double powerDelivered = math.min(limitPowerDelivered, actualPowerNeeded);
      
      // STEP 8: Headroom Calculations formulas (from sample.md)
      final double channelHeadroom = powerDelivered > 0 ? 10 * math.log(asymmetricalShareablePerChannel / powerDelivered) / math.ln10 : 0.0;
      final double loudspeakerHeadroom = powerDelivered > 0 ? 10 * math.log(actualPowerNeeded / powerDelivered) / math.ln10 : 0.0;
      
      // Update existing channel data with remaining calculations
      channel['netPowerSharing'] = netPowerSharing; // Global value for all channels
      channel['availableToShare'] = availableToShare; // Global value for all channels
      channel['sharePerNeeding'] = sharePerNeeding; // Global value for all channels
      channel['powerAvailable'] = powerAvailable;
      channel['limitPowerDelivered'] = limitPowerDelivered;
      channel['powerDelivered'] = powerDelivered;
      channel['channelHeadroom'] = channelHeadroom;
      channel['loudspeakerHeadroom'] = loudspeakerHeadroom;
    }
    
    // Calculate system totals for this amplifier
    final double totalActualPower = channelData.fold(0.0, (double sum, Map<String, dynamic> ch) => sum + (ch['actualPowerNeeded'] as double));
    final double totalPowerDelivered = channelData.fold(0.0, (double sum, Map<String, dynamic> ch) => sum + (ch['powerDelivered'] as double));
    final double totalAmpHeadroom = totalPowerDelivered > 0 ? 10 * math.log(totalCapacity / totalPowerDelivered) / math.ln10 : 0.0;
    final bool systemHasEnoughPower = totalPowerDelivered >= totalActualPower;
    
    // Update effective headroom with global totalAmpHeadroom
    for (final Map<String, dynamic> channel in channelData) {
      final double channelHeadroom = channel['channelHeadroom'] as double;
      channel['effectiveHeadroom'] = math.min(channelHeadroom, totalAmpHeadroom);
    }
    
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Amplifier Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.blue[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.blue[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('🔧 Amplifier $amplifierNumber: ${amplifier.name}', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 8),
                Text('Per-Channel Limit (L): ${perChannelCapacity.toStringAsFixed(1)}W'),
                Text('Asymmetrical Shareable Per Channel: ${asymmetricalShareablePerChannel.toStringAsFixed(1)}W'),
                Text('Total Capacity: ${totalCapacity.toStringAsFixed(1)}W'),
                const SizedBox(height: 8),
                Text('Total Symm Surplus: ${totalSymmSurplus.toStringAsFixed(1)}W'),
                Text('Total Asymm Deficit: ${totalAsymmDeficit.toStringAsFixed(1)}W'),
                Text('Net Power Sharing: ${netPowerSharing.toStringAsFixed(1)}W'),
                Text('Available to Share: ${availableToShare.toStringAsFixed(1)}W'),
                Text('Channels Needing Power: $channelsNeedingPower'),
                Text('Share Per Needing: ${sharePerNeeding.toStringAsFixed(1)}W'),
                Text('Total Amp Headroom: ${totalAmpHeadroom.toStringAsFixed(1)} dB'),
              ],
            ),
          ),
          
          const SizedBox(height: 12),
          
          // Channel-based table for this amplifier
          _buildCompleteChannelTable(channelData, amplifier),
          
          const SizedBox(height: 12),
          
          // Final Validation for this amplifier
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: systemHasEnoughPower ? Colors.green[50] : Colors.red[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: systemHasEnoughPower ? Colors.green[200]! : Colors.red[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('🔍 Amplifier $amplifierNumber Validation:', style: TextStyle(fontWeight: FontWeight.bold, color: systemHasEnoughPower ? Colors.green : Colors.red)),
                const SizedBox(height: 8),
                Text('Power Conservation: ${totalPowerDelivered.toStringAsFixed(1)}W ≤ ${totalCapacity.toStringAsFixed(1)}W ${totalPowerDelivered <= totalCapacity ? '✓' : '❌'}'),
                Text('Power Sufficiency: ${systemHasEnoughPower ? 'All circuits receive sufficient power ✓' : 'Some circuits insufficient power ❌'}'),
                Text('Net Power Sharing: ${netPowerSharing.toStringAsFixed(1)}W ≥ 0 ${netPowerSharing >= 0 ? '✓' : '❌'}'),
                const SizedBox(height: 8),
                Text('Result: ${systemHasEnoughPower ? '✅ VALIDATION PASSED' : '❌ VALIDATION FAILED'}'),
              ],
            ),
          ),
        ],
      ),
    );
  }

  /// Build complete channel table with all metrics
  Widget _buildCompleteChannelTable(List<Map<String, dynamic>> channelData, AmplifierModel amplifier) {
    final int channelCount = amplifier.channels;
    
    return Column(
      children: <Widget>[
        // Table Header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: <Widget>[
              const Expanded(flex: 2, child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
              ...List.generate(channelCount, (int index) => Expanded(
                child: Text('Ch ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        ),
        
        // Table Rows
        _buildTableRow('Actual Power Needed', channelData.map((Map<String, dynamic> ch) => ch['actualPowerNeeded'] as double).toList()),
        _buildTableRow('Symm Surplus', channelData.map((Map<String, dynamic> ch) => ch['symmSurplus'] as double).toList()),
        _buildTableRow('Asymm Deficit', channelData.map((Map<String, dynamic> ch) => ch['asymmDeficit'] as double).toList()),
        _buildTableRow('Needs Extra Power', channelData.map((Map<String, dynamic> ch) => (ch['needsExtraPower'] as bool) ? 'YES' : '').toList()),
        _buildTableRow('Power Available', channelData.map((Map<String, dynamic> ch) => ch['powerAvailable'] as double).toList()),
        _buildTableRow('Limit Power Delivered', channelData.map((Map<String, dynamic> ch) => ch['limitPowerDelivered'] as double).toList()),
        _buildTableRow('Power Delivered', channelData.map((Map<String, dynamic> ch) => ch['powerDelivered'] as double).toList()),
        _buildTableRow('Channel Headroom (dB)', channelData.map((Map<String, dynamic> ch) => ch['channelHeadroom'] as double).toList()),
        _buildTableRow('Effective Headroom (dB)', channelData.map((Map<String, dynamic> ch) => ch['effectiveHeadroom'] as double).toList()),
        _buildTableRow('Loudspeaker Headroom (dB)', channelData.map((Map<String, dynamic> ch) => ch['loudspeakerHeadroom'] as double).toList()),
      ],
    );
  }

  /// Build a table row for the channel-based display (updated to handle mixed types)
  Widget _buildTableRow(String metric, List<dynamic> values) {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        border: Border(bottom: BorderSide(color: Colors.grey[300]!)),
      ),
      child: Row(
        children: <Widget>[
          Expanded(flex: 2, child: Text(metric)),
          ...values.map((value) => Expanded(
            child: Text(_formatValue(value)),
          )),
        ],
      ),
    );
  }

  /// Format values for display
  String _formatValue(dynamic value) {
    if (value == null) return 'N/A';
    if (value is bool) return value ? 'X' : '';
    if (value is double) {
      if (value == 0.0) return 'N/A';
      return value.toStringAsFixed(1);
    }
    if (value is String) return value.isEmpty ? 'N/A' : value;
    return value.toString();
  }

  /// Build channel-based table for power sharing analysis
  Widget _buildChannelBasedTable(List<Map<String, dynamic>> circuitData, AmplifierModel amplifier) {
    final int channelCount = amplifier.channels;
    final double perChannelCapacity = amplifier.asymmetrical.watts.toDouble();
    
    // Create channel data
    final List<Map<String, dynamic>> channelData = <Map<String, dynamic>>[];
    for (int i = 0; i < channelCount; i++) {
      final Map<String, dynamic> channel = <String, dynamic>{
        'channelNumber': i + 1,
        'circuit': i < circuitData.length ? circuitData[i] : null,
        'actualPowerNeeded': i < circuitData.length ? circuitData[i]['power'] as double : 0.0,
        'symmSurplus': perChannelCapacity - (i < circuitData.length ? circuitData[i]['power'] as double : 0.0),
        'asymmDeficit': (i < circuitData.length ? circuitData[i]['power'] as double : 0.0) - perChannelCapacity,
        'powerAvailable': perChannelCapacity,
        'powerDelivered': i < circuitData.length ? circuitData[i]['power'] as double : 0.0,
        'channelHeadroom': 0.0,
        'effectiveHeadroom': 0.0,
        'loudspeakerHeadroom': 0.0,
      };
      channelData.add(channel);
    }
    
    // Calculate totals
    final double totalActualPower = channelData.fold(0.0, (double sum, Map<String, dynamic> ch) => sum + (ch['actualPowerNeeded'] as double));
    final double totalSymmSurplus = channelData.fold(0.0, (double sum, Map<String, dynamic> ch) => sum + (ch['symmSurplus'] as double));
    final double totalAsymmDeficit = channelData.fold(0.0, (double sum, Map<String, dynamic> ch) => sum + (ch['asymmDeficit'] as double));
    final double netPowerSharing = totalSymmSurplus + totalAsymmDeficit;
    final double availableToShare = totalSymmSurplus;
    
    return Column(
      children: <Widget>[
        // Table Header
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Row(
            children: <Widget>[
              const Expanded(flex: 2, child: Text('Metric', style: TextStyle(fontWeight: FontWeight.bold))),
              ...List.generate(channelCount, (int index) => Expanded(
                child: Text('Ch ${index + 1}', style: const TextStyle(fontWeight: FontWeight.bold)),
              )),
            ],
          ),
        ),
        
        // Table Rows
        _buildTableRow('Actual Power Needed', channelData.map((Map<String, dynamic> ch) => ch['actualPowerNeeded'] as double).toList()),
        _buildTableRow('Symm Surplus', channelData.map((Map<String, dynamic> ch) => ch['symmSurplus'] as double).toList()),
        _buildTableRow('Asymm Deficit', channelData.map((Map<String, dynamic> ch) => ch['asymmDeficit'] as double).toList()),
        _buildTableRow('Power Available', channelData.map((Map<String, dynamic> ch) => ch['powerAvailable'] as double).toList()),
        _buildTableRow('Power Delivered', channelData.map((Map<String, dynamic> ch) => ch['powerDelivered'] as double).toList()),
        _buildTableRow('Channel Headroom', channelData.map((Map<String, dynamic> ch) => ch['channelHeadroom'] as double).toList()),
        _buildTableRow('Effective Headroom', channelData.map((Map<String, dynamic> ch) => ch['effectiveHeadroom'] as double).toList()),
        _buildTableRow('Loudspeaker Headroom', channelData.map((Map<String, dynamic> ch) => ch['loudspeakerHeadroom'] as double).toList()),
        
        const SizedBox(height: 8),
        
        // Summary
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(4),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Net Power Sharing: ${netPowerSharing.toStringAsFixed(1)}W'),
              Text('Available to Share: ${availableToShare.toStringAsFixed(1)}W'),
              Text('Total System Power: ${totalActualPower.toStringAsFixed(1)}W'),
              Text('Amplifier Capacity: ${amplifier.asymmetrical.totalCapacity}W'),
              Text('System Validation: ${totalActualPower <= amplifier.asymmetrical.totalCapacity ? 'YES' : 'NO'}'),
            ],
          ),
        ),
      ],
    );
  }


  Widget _buildAmplifierMatchingProcess(PowerAllocationStrategy strategy) {
    // Calculate circuit powers and sort by power (highest first)
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    double totalSystemPower = 0.0;
    
    for (final CircuitInput circuit in circuits) {
      if (circuit.selectedModel != null) {
        final double power = _estimateCircuitPower(circuit);
        circuitData.add(<String, dynamic>{
          'id': circuit.circuitId,
          'model': circuit.selectedModel,
          'power': power,
          'mode': circuit.mode,
          'speakerCount': int.tryParse(circuit.speakerCountController.text) ?? 1,
        });
        totalSystemPower += power;
      }
    }
    
    if (circuitData.isEmpty) {
      return const Text('No valid circuits to match');
    }
    
    // Sort circuits by power (highest first) - largest circuits are hardest to fit
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => 
                     (b['power'] as double).compareTo(a['power'] as double));
    
    // Use amplifier data from library
    final List<AmplifierModel> amplifierTiers = AmplifierCatalog.allModels;
    
    // Find appropriate amplifier tier for total system power
    // CORRECTED LOGIC: Find the smallest amplifier that can handle both total power AND per-channel power
    AmplifierModel? selectedTier;
    
    // First, check if any single circuit exceeds the largest amplifier's per-channel capacity
    final double maxCircuitPower = circuitData.isNotEmpty ? circuitData.first['power'] as double : 0.0;
    final AmplifierModel largestAmp = amplifierTiers.last;
    
    if (maxCircuitPower > largestAmp.symmetrical.watts) {
      // Single circuit exceeds largest amplifier's per-channel capacity
      selectedTier = null; // Will show error
    } else {
      // Find the smallest amplifier that can handle both total and per-channel requirements
      for (final AmplifierModel tier in amplifierTiers) {
        if (totalSystemPower <= tier.symmetrical.totalCapacity && 
            maxCircuitPower <= tier.symmetrical.watts) {
          selectedTier = tier;
          break;
        }
      }
    }
    
    if (selectedTier == null) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.red[100],
          border: Border.all(color: Colors.red[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text('❌ SYSTEM EXCEEDS MAXIMUM AMPLIFIER CAPACITY', 
                 style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red)),
            const SizedBox(height: 4),
            if (maxCircuitPower > largestAmp.symmetrical.watts) ...<Widget>[
              Text('Largest Circuit: ${maxCircuitPower.toStringAsFixed(1)}W > ${largestAmp.symmetrical.watts}W per-channel (${largestAmp.name})'),
              const Text('Recommendation: Reduce individual circuit power or split into multiple circuits'),
            ] else ...<Widget>[
              Text('Total Power: ${totalSystemPower.toStringAsFixed(1)}W > ${AmplifierCatalog.psx4804d.symmetrical.totalCapacity}W (${AmplifierCatalog.psx4804d.name})'),
              const Text('Recommendation: Reduce circuit power requirements or use multiple amplifiers'),
            ],
          ],
        ),
      );
    }
    
    // Calculate optimal amplifier combination with cost optimization
    final List<Map<String, dynamic>> amplifierAllocation = _calculateOptimalAmplifierAllocation(circuitData, selectedTier);
    
    return Column(
      children: <Widget>[
        // System Summary
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[100],
            border: Border.all(color: Colors.blue[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('📊 System Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              Text('Total Circuits: ${circuitData.length}'),
              Text('Total System Power: ${totalSystemPower.toStringAsFixed(1)}W'),
              Text('Selected Amplifier Tier: ${selectedTier.name}'),
              Text('Total Amplifiers Needed: ${amplifierAllocation.length}'),
              Text('Total Channels Needed: ${circuitData.length}'),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Circuit Details
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
              const Text('🔌 Circuit Details (Sorted by Power):', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...circuitData.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
                final int index = entry.key;
                final Map<String, dynamic> circuit = entry.value;
                return Container(
                  margin: const EdgeInsets.only(bottom: 4),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.grey[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Row(
                    children: <Widget>[
                      Container(
                        width: 24,
                        height: 24,
                        decoration: BoxDecoration(
                          color: index == 0 ? Colors.red : (index == 1 ? Colors.orange : Colors.yellow[700]),
                          shape: BoxShape.circle,
                        ),
                        child: Center(
                          child: Text('${index + 1}', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12)),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            Text('Circuit ${circuit['id']}: ${circuit['model']} (${circuit['mode'].toUpperCase()})', 
                                 style: const TextStyle(fontWeight: FontWeight.w500)),
                            Text('${(circuit['power'] as double).toStringAsFixed(1)}W - ${circuit['speakerCount']} speakers'),
                          ],
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Amplifier Allocation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            border: Border.all(color: Colors.purple[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('🎯 Amplifier Allocation:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              ...amplifierAllocation.map((Map<String, dynamic> amp) {
                final List<Map<String, dynamic>> circuitsAssigned = amp['circuitsAssigned'] as List<Map<String, dynamic>>;
                return Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    border: Border.all(color: Colors.purple[300]!),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Amplifier ${amp['amplifierNumber']}: ${amp['tier']}', 
                           style: const TextStyle(fontWeight: FontWeight.bold)),
                      Text('Channels: ${amp['usedChannels']}/${amp['totalChannels']} used (${amp['unusedChannels']} unused)'),
                      if (circuitsAssigned.isNotEmpty) ...<Widget>[
                        const SizedBox(height: 4),
                        const Text('Assigned Circuits:', style: TextStyle(fontWeight: FontWeight.w500)),
                        ...circuitsAssigned.map((Map<String, dynamic> circuit) =>
                          Text('  • Circuit ${circuit['id']}: ${circuit['model']} (${(circuit['power'] as double).toStringAsFixed(1)}W)'),
                        ),
                      ],
                    ],
                  ),
                );
              }),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Tier Rule Validation
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal[100],
            border: Border.all(color: Colors.teal[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text('✅ Tier Rule Validation:', style: TextStyle(fontWeight: FontWeight.bold)),
              const Text('Rule: Ppk_amplifier (next tier up) ≥ Pk_speaker_total ≥ Ppk_amplifier (current tier)'),
              Text('Total System Power: ${totalSystemPower.toStringAsFixed(1)}W'),
              Text('Selected Tier: ${selectedTier.name} (${selectedTier.symmetrical.totalCapacity}W total)'),
              Text('Validation: ${selectedTier.symmetrical.totalCapacity}W ≥ ${totalSystemPower.toStringAsFixed(1)}W ✅'),
              const SizedBox(height: 4),
              const Text('Channel Strategy: Unused channels allocated to smallest amplifiers for cost optimization ✅'),
              const SizedBox(height: 4),
              Text('Amplifier Types Used: ${amplifierAllocation.map((Map<String, dynamic> amp) => amp['tier']).toSet().join(', ')}'),
            ],
          ),
        ),
      ],
    );
  }



  Widget _buildPowerSharingStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('⚡ Asymmetrical Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple[100],
            border: Border.all(color: Colors.purple[300]!),
            borderRadius: BorderRadius.circular(6),
          ),
          child: const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Corrected Asymmetrical Power Sharing Formulas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('Symm_Surplus_i = Max[(L - P_actual,i), 0]', style: TextStyle(fontFamily: 'monospace')),
              Text('Asymm_Deficit_i = Min[(L - P_actual,i), 0]', style: TextStyle(fontFamily: 'monospace')),
              Text('NetPower_Sharing = Total_Symm_Surplus + Total_Asymm_Deficit', style: TextStyle(fontFamily: 'monospace')),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        const Text('🧮 Power Sharing Calculations:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        
        // Always show power sharing analysis (even for single circuits)
        _buildPowerSharingCalculation(),
      ],
    );
  }

  Widget _buildPowerSharingCalculation() {
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
      return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
        child: const Text('Select speaker models to see calculations', 
                               style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    
    // Sort circuits by power for analysis
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => 
                     (b['power'] as double).compareTo(a['power'] as double));
    
    return Column(
      children: <Widget>[
        // Test PSX-2404D Analysis (as per sample.md)
        _buildAmplifierAnalysis(AmplifierCatalog.psx2404d.name, 
          AmplifierCatalog.psx2404d.symmetrical.watts.toDouble(), 
          AmplifierCatalog.psx2404d.symmetrical.totalCapacity.toDouble(), 
          AmplifierCatalog.psx2404d.asymmetrical.watts.toDouble(), 
          circuitData, totalPower),
        
        const SizedBox(height: 16),
        
        // Test PSX-4804D Analysis (as per sample.md)
        _buildAmplifierAnalysis(AmplifierCatalog.psx4804d.name, 
          AmplifierCatalog.psx4804d.symmetrical.watts.toDouble(), 
          AmplifierCatalog.psx4804d.symmetrical.totalCapacity.toDouble(), 
          AmplifierCatalog.psx4804d.asymmetrical.watts.toDouble(), 
          circuitData, totalPower),
      ],
    );
  }

  Widget _buildAmplifierAnalysis(String ampName, double perChannelLimit, double totalCapacity, double asymmetricalShareable, List<Map<String, dynamic>> circuitData, double totalPower) {
    // Calculate surplus and deficit for each channel using CORRECTED formulas
    final List<Map<String, dynamic>> channelAnalysis = <Map<String, dynamic>>[];
    double totalSymmSurplus = 0.0;
    final double totalAsymmDeficit = 0.0;
    
    for (int i = 0; i < 4; i++) {
      final double channelPower = i < circuitData.length ? circuitData[i]['power'] as double : 0.0;
      
      // CORRECTED FORMULAS from sample.md
      final double symmSurplus = math.max(perChannelLimit - channelPower, 0.0); // Positive or zero
      final double asymmDeficit = math.min(perChannelLimit - channelPower, 0.0); // Negative or zero
      
      channelAnalysis.add(<String, dynamic>{
        'channel': i + 1,
        'power': channelPower,
        'symmSurplus': symmSurplus,
        'asymmDeficit': asymmDeficit,
        'needsSharing': asymmDeficit < 0,
        'circuitModel': i < circuitData.length ? circuitData[i]['model'] : 'Empty',
      });
      
      totalSymmSurplus += symmSurplus;
      // totalAsymmDeficit += asymmDeficit; // Unused variable
    }
    
    // CORRECTED NetPower_Sharing formula
    final double netPowerSharing = totalSymmSurplus + totalAsymmDeficit;
    final bool canShare = netPowerSharing >= 0;
    
    // Calculate power distribution
    final int channelsNeedingPower = channelAnalysis.where((Map<String, dynamic> ch) => ch['needsSharing'] as bool).length;
    final double sharePerNeeding = channelsNeedingPower > 0 ? totalSymmSurplus / channelsNeedingPower : 0.0;
    
    // Calculate power delivered to each channel
    final List<Map<String, dynamic>> powerDelivered = <Map<String, dynamic>>[];
    double totalDelivered = 0.0;
    
    for (final Map<String, dynamic> channel in channelAnalysis) {
      final double powerNeeded = channel['power'] as double;
      final bool needsSharing = channel['needsSharing'] as bool;
      
      // Power available to channel
      final double powerAvailable = needsSharing ? 
        perChannelLimit + sharePerNeeding : 
        perChannelLimit;
      
      // Limit power delivered (asymmetrical max)
      final double limitPowerDelivered = math.min(powerAvailable, asymmetricalShareable);
      
      // Power delivered to channel
      final double powerDeliveredToChannel = math.min(limitPowerDelivered, powerNeeded);
      
      powerDelivered.add(<String, dynamic>{
        'channel': channel['channel'],
        'powerNeeded': powerNeeded,
        'powerAvailable': powerAvailable,
        'limitPowerDelivered': limitPowerDelivered,
        'powerDelivered': powerDeliveredToChannel,
        'sufficient': powerDeliveredToChannel >= powerNeeded,
      });
      
      totalDelivered += powerDeliveredToChannel;
    }
    
    // Calculate headroom
    final double totalAmpHeadroom = 10 * math.log(totalCapacity / totalDelivered) / math.ln10;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: canShare ? Colors.green[50] : Colors.red[50],
        border: Border.all(color: canShare ? Colors.green[300]! : Colors.red[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('📊 $ampName Analysis:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Per-channel limit: ${perChannelLimit.toInt()}W'),
          Text('Total capacity: ${totalCapacity.toInt()}W'),
          Text('Asymmetrical shareable: ${asymmetricalShareable.toInt()}W'),
        
        const SizedBox(height: 12),
        
          // Channel Analysis Table
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Channel Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...channelAnalysis.map((Map<String, dynamic> channel) => 
                  Text('Ch${channel['channel']}: ${(channel['power'] as double).toStringAsFixed(1)}W | '
                       'Symm Surplus: ${(channel['symmSurplus'] as double).toStringAsFixed(1)}W | '
                       'Asymm Deficit: ${(channel['asymmDeficit'] as double).toStringAsFixed(1)}W | '
                       '${channel['needsSharing'] ? "Needs Sharing ✅" : "OK ❌"}')),
              ],
            ),
          ),
          
                const SizedBox(height: 8),
                
          // Power Sharing Summary
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.blue[100],
              border: Border.all(color: Colors.blue[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                const Text('Power Sharing Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Total Symm Surplus: ${totalSymmSurplus.toStringAsFixed(1)}W'),
                Text('Total Asymm Deficit: ${totalAsymmDeficit.toStringAsFixed(1)}W'),
                Text('Net Power Sharing: ${netPowerSharing.toStringAsFixed(1)}W'),
                Text('Available to Share: ${totalSymmSurplus.toStringAsFixed(1)}W'),
                Text('Channels Needing Power: $channelsNeedingPower'),
                Text('Share Per Needing: ${sharePerNeeding.toStringAsFixed(1)}W'),
              ],
            ),
          ),
          
          const SizedBox(height: 8),
          
          // Power Delivered Analysis
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              border: Border.all(color: Colors.orange[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                const Text('Power Delivered Analysis:', style: TextStyle(fontWeight: FontWeight.bold)),
                for (final Map<String, dynamic> delivery in powerDelivered) ...<Widget>[
                  Text('Ch${delivery['channel']}: ${(delivery['powerDelivered'] as double).toStringAsFixed(1)}W delivered '
                       '(${(delivery['powerNeeded'] as double).toStringAsFixed(1)}W needed) '
                       '${delivery['sufficient'] ? "✅" : "❌"}'),
                ],
                Text('Total Delivered: ${totalDelivered.toStringAsFixed(1)}W'),
                Text('Total Amp Headroom: ${totalAmpHeadroom.toStringAsFixed(1)}dB'),
              ],
            ),
          ),
          
                  const SizedBox(height: 8),
          
          // Final Validation
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: canShare ? Colors.green[100] : Colors.red[100],
              border: Border.all(color: canShare ? Colors.green[300]! : Colors.red[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('Final Validation:', style: TextStyle(fontWeight: FontWeight.bold, color: canShare ? Colors.green[800] : Colors.red[800])),
                Text('Total Power: ${totalPower.toStringAsFixed(1)}W ≤ ${totalCapacity.toInt()}W ${totalPower <= totalCapacity ? "✅" : "❌"}'),
                Text('Max Circuit: ${circuitData.isNotEmpty ? (circuitData.first['power'] as double).toStringAsFixed(1) : "0"}W ≤ ${asymmetricalShareable.toInt()}W ${circuitData.isNotEmpty && (circuitData.first['power'] as double) <= asymmetricalShareable ? "✅" : "❌"}'),
                Text('Net Power Sharing: ${netPowerSharing.toStringAsFixed(1)}W ≥ 0 ${netPowerSharing >= 0 ? "✅" : "❌"}'),
                Text('Result: ${canShare ? "✅ SUCCESS - $ampName can handle this configuration" : "❌ FAILED - $ampName cannot handle this configuration"}', 
                     style: TextStyle(fontWeight: FontWeight.bold, color: canShare ? Colors.green[800] : Colors.red[800])),
              ],
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildPowerDistributionStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('📊 Power Distribution Calculation:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
            color: Colors.cyan[100],
            border: Border.all(color: Colors.cyan[300]!),
        borderRadius: BorderRadius.circular(6),
      ),
          child: const Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
              Text('Power Distribution Formulas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('Share_Per_Needing = Available_To_Share / N_needing', style: TextStyle(fontFamily: 'monospace')),
              Text('Power_Available_i = L + Share_Per_Needing (for needing channels)', style: TextStyle(fontFamily: 'monospace')),
              Text('Limit_Power_Delivered_i = Min(Power_Available_i, Asymmetrical_Shareable)', style: TextStyle(fontFamily: 'monospace')),
              Text('Power_Delivered_i = Min(Limit_Power_Delivered_i, Actual_Power_Needed_i)', style: TextStyle(fontFamily: 'monospace')),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        const Text('🧮 Power Distribution Analysis:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        
        // Show detailed power distribution calculations
        _buildPowerDistributionAnalysis(),
      ],
    );
  }

  Widget _buildPowerDistributionAnalysis() {
    // Calculate actual circuit powers
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    
    for (final CircuitInput circuit in circuits) {
      if (circuit.selectedModel != null) {
        final double power = _estimateCircuitPower(circuit);
        circuitData.add(<String, dynamic>{
          'id': circuit.circuitId,
          'model': circuit.selectedModel,
          'power': power,
          'mode': circuit.mode,
        });
      }
    }
    
    if (circuitData.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(6),
        ),
        child: const Text('Select speaker models to see power distribution analysis', 
                         style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    
    // Sort circuits by power for analysis
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => 
                     (b['power'] as double).compareTo(a['power'] as double));
    
    return Column(
      children: <Widget>[
        // PSX-2404D Power Distribution Analysis
        _buildPowerDistributionForAmplifier(AmplifierCatalog.psx2404d.name, 
          AmplifierCatalog.psx2404d.symmetrical.watts.toDouble(), 
          AmplifierCatalog.psx2404d.asymmetrical.watts.toDouble(), 
          circuitData),
        
        const SizedBox(height: 16),
        
        // PSX-4804D Power Distribution Analysis
        _buildPowerDistributionForAmplifier(AmplifierCatalog.psx4804d.name, 
          AmplifierCatalog.psx4804d.symmetrical.watts.toDouble(), 
          AmplifierCatalog.psx4804d.asymmetrical.watts.toDouble(), 
          circuitData),
      ],
    );
  }

  Widget _buildPowerDistributionForAmplifier(String ampName, double perChannelLimit, double asymmetricalShareable, List<Map<String, dynamic>> circuitData) {
    // Calculate surplus and deficit for each channel
    final List<Map<String, dynamic>> channelAnalysis = <Map<String, dynamic>>[];
    double totalSymmSurplus = 0.0;
    // double totalAsymmDeficit = 0.0; // Unused variable
    
    for (int i = 0; i < 4; i++) {
      final double channelPower = i < circuitData.length ? circuitData[i]['power'] as double : 0.0;
      
      final double symmSurplus = math.max(perChannelLimit - channelPower, 0.0);
      final double asymmDeficit = math.min(perChannelLimit - channelPower, 0.0);
      
      channelAnalysis.add(<String, dynamic>{
        'channel': i + 1,
        'power': channelPower,
        'symmSurplus': symmSurplus,
        'asymmDeficit': asymmDeficit,
        'needsSharing': asymmDeficit < 0,
        'circuitModel': i < circuitData.length ? circuitData[i]['model'] : 'Empty',
      });
      
      totalSymmSurplus += symmSurplus;
      // totalAsymmDeficit += asymmDeficit; // Unused variable
    }
    
    // final double netPowerSharing = totalSymmSurplus + totalAsymmDeficit; // Unused variable
    final int channelsNeedingPower = channelAnalysis.where((Map<String, dynamic> ch) => ch['needsSharing'] as bool).length;
    final double sharePerNeeding = channelsNeedingPower > 0 ? totalSymmSurplus / channelsNeedingPower : 0.0;
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.cyan[50],
        border: Border.all(color: Colors.cyan[300]!),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text('📊 $ampName Power Distribution:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Per-channel limit: ${perChannelLimit.toInt()}W'),
          Text('Asymmetrical shareable: ${asymmetricalShareable.toInt()}W'),
          
          const SizedBox(height: 12),
          
          // Power Distribution Calculations
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Power Distribution Calculations:', style: TextStyle(fontWeight: FontWeight.bold)),
                Text('Total Symm Surplus: ${totalSymmSurplus.toStringAsFixed(1)}W'),
                Text('Channels Needing Power: $channelsNeedingPower'),
                Text('Share Per Needing: ${sharePerNeeding.toStringAsFixed(1)}W'),
                const SizedBox(height: 8),
                
                ...channelAnalysis.map((Map<String, dynamic> channel) => 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Ch${channel['channel']}: ${(channel['power'] as double).toStringAsFixed(1)}W needed'),
                      if (channel['needsSharing'] as bool) ...<Widget>[
                        Text('  Power Available: ${perChannelLimit.toInt()}W + ${sharePerNeeding.toStringAsFixed(1)}W = ${(perChannelLimit + sharePerNeeding).toStringAsFixed(1)}W'),
                        Text('  Limit Power Delivered: Min(${(perChannelLimit + sharePerNeeding).toStringAsFixed(1)}W, ${asymmetricalShareable.toInt()}W) = ${math.min(perChannelLimit + sharePerNeeding, asymmetricalShareable).toStringAsFixed(1)}W'),
                        Text('  Power Delivered: Min(${math.min(perChannelLimit + sharePerNeeding, asymmetricalShareable).toStringAsFixed(1)}W, ${(channel['power'] as double).toStringAsFixed(1)}W) = ${math.min(math.min(perChannelLimit + sharePerNeeding, asymmetricalShareable), channel['power'] as double).toStringAsFixed(1)}W'),
          ] else ...<Widget>[
                        Text('  Power Available: ${perChannelLimit.toInt()}W (no sharing needed)'),
                        Text('  Power Delivered: Min(${perChannelLimit.toInt()}W, ${(channel['power'] as double).toStringAsFixed(1)}W) = ${math.min(perChannelLimit, channel['power'] as double).toStringAsFixed(1)}W'),
                      ],
            const SizedBox(height: 4),
          ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeadroomCalculationsStep() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('📏 Headroom Calculations:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
            color: Colors.indigo[100],
            border: Border.all(color: Colors.indigo[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
          child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
              Text('Headroom Calculation Formulas:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              SizedBox(height: 8),
              Text('Channel_Headroom_i = 10 × log₁₀(Asymmetrical_Shareable / Power_Delivered_i)', style: TextStyle(fontFamily: 'monospace')),
              Text('Total_Amp_Headroom = 10 × log₁₀(Total_Capacity / Total_Delivered)', style: TextStyle(fontFamily: 'monospace')),
              Text('Effective_Headroom_i = Min(Channel_Headroom_i, Total_Amp_Headroom)', style: TextStyle(fontFamily: 'monospace')),
              Text('Loudspeaker_Headroom_i = 10 × log₁₀(Power_Needed_Without_Offset / Power_Delivered_i)', style: TextStyle(fontFamily: 'monospace')),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        const Text('🧮 Headroom Analysis:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
        
        // Show headroom calculations
        _buildHeadroomAnalysis(),
      ],
    );
  }

  Widget _buildHeadroomAnalysis() {
    // Calculate actual circuit powers
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    
    for (final CircuitInput circuit in circuits) {
      if (circuit.selectedModel != null) {
        final double power = _estimateCircuitPower(circuit);
        circuitData.add(<String, dynamic>{
          'id': circuit.circuitId,
          'model': circuit.selectedModel,
          'power': power,
          'mode': circuit.mode,
        });
      }
    }
    
    if (circuitData.isEmpty) {
      return Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
        child: const Text('Select speaker models to see headroom analysis', 
                         style: TextStyle(fontStyle: FontStyle.italic)),
      );
    }
    
    return Column(
              children: <Widget>[
        // PSX-2404D Headroom Analysis
        _buildHeadroomForAmplifier(AmplifierCatalog.psx2404d.name, 
          AmplifierCatalog.psx2404d.symmetrical.watts.toDouble(), 
          AmplifierCatalog.psx2404d.symmetrical.totalCapacity.toDouble(), 
          AmplifierCatalog.psx2404d.asymmetrical.watts.toDouble(), 
          circuitData),
        
        const SizedBox(height: 16),
        
        // PSX-4804D Headroom Analysis
        _buildHeadroomForAmplifier(AmplifierCatalog.psx4804d.name, 
          AmplifierCatalog.psx4804d.symmetrical.watts.toDouble(), 
          AmplifierCatalog.psx4804d.symmetrical.totalCapacity.toDouble(), 
          AmplifierCatalog.psx4804d.asymmetrical.watts.toDouble(), 
          circuitData),
      ],
    );
  }

  Widget _buildHeadroomForAmplifier(String ampName, double perChannelLimit, double totalCapacity, double asymmetricalShareable, List<Map<String, dynamic>> circuitData) {
    // Calculate power delivered (simplified version)
    double totalDelivered = 0.0;
    final List<Map<String, dynamic>> headroomAnalysis = <Map<String, dynamic>>[];
    
    for (int i = 0; i < 4; i++) {
      final double channelPower = i < circuitData.length ? circuitData[i]['power'] as double : 0.0;
      final double powerDelivered = math.min(channelPower, asymmetricalShareable);
      
      totalDelivered += powerDelivered;
      
      if (channelPower > 0) {
        final double channelHeadroom = 10 * math.log(asymmetricalShareable / powerDelivered) / math.ln10;
        headroomAnalysis.add(<String, dynamic>{
          'channel': i + 1,
          'powerDelivered': powerDelivered,
          'channelHeadroom': channelHeadroom,
          'circuitModel': circuitData[i]['model'],
        });
      }
    }
    
    final double totalAmpHeadroom = 10 * math.log(totalCapacity / totalDelivered) / math.ln10;
    
    return Container(
      padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
        color: Colors.indigo[50],
        border: Border.all(color: Colors.indigo[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
          Text('📏 $ampName Headroom Analysis:', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          Text('Total Capacity: ${totalCapacity.toInt()}W'),
          Text('Total Delivered: ${totalDelivered.toStringAsFixed(1)}W'),
          Text('Total Amp Headroom: ${totalAmpHeadroom.toStringAsFixed(1)}dB'),
          
          const SizedBox(height: 12),
          
          // Individual Channel Headroom
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(4),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text('Individual Channel Headroom:', style: TextStyle(fontWeight: FontWeight.bold)),
                const SizedBox(height: 4),
                ...headroomAnalysis.map((Map<String, dynamic> channel) => 
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text('Ch${channel['channel']}: ${(channel['powerDelivered'] as double).toStringAsFixed(1)}W delivered'),
                      Text('  Channel Headroom: ${(channel['channelHeadroom'] as double).toStringAsFixed(1)}dB'),
                      Text('  Effective Headroom: Min(${(channel['channelHeadroom'] as double).toStringAsFixed(1)}dB, ${totalAmpHeadroom.toStringAsFixed(1)}dB) = ${math.min(channel['channelHeadroom'] as double, totalAmpHeadroom).toStringAsFixed(1)}dB'),
                      const SizedBox(height: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildFinalValidationStep(AmpMatchingResult result, PowerAllocationStrategy strategy) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('✅ Final Results:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
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
              const Text('🏆 Algorithm Results:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              
              Text('Selected Amplifiers: ${result.amplifierCount}'),
              Text('Power Efficiency: ${(result.powerEfficiency * 100).toStringAsFixed(1)}%'),
              Text('Channel Efficiency: ${(result.channelEfficiency * 100).toStringAsFixed(1)}%'),
              
              const SizedBox(height: 8),
              const Text('Validation Status:', style: TextStyle(fontWeight: FontWeight.w500)),
              Text('Errors: ${result.errors.length}'),
              Text('Warnings: ${result.warnings.length}'),
              
              if (result.hasErrors) ...<Widget>[
                const SizedBox(height: 4),
                const Text('❌ Configuration has errors - see details above', 
                         style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
              ] else if (result.hasWarnings) ...<Widget>[
                const SizedBox(height: 4),
                const Text('⚠️ Configuration has warnings - see details above', 
                         style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold)),
              ] else ...<Widget>[
                const SizedBox(height: 4),
                const Text('✅ Configuration validated successfully', 
                         style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
              ],
                ],
              ),
            ),
            
            const SizedBox(height: 12),
            
        // Amplifier assignments
        const Text('🔌 Amplifier Assignments:', style: TextStyle(fontWeight: FontWeight.bold)),
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
              border: Border.all(color: Colors.grey[300]!),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Text('📦 Amplifier ${index + 1}: ${assignment.ampModel.name}', 
                         style: const TextStyle(fontWeight: FontWeight.w500)),
                    Text('   • Channels: ${assignment.ampModel.channels}'),
                    Text('   • Power per Channel: ${assignment.ampModel.symmetrical.watts.toInt()}W'),
                Text('   • Total Capacity: ${correctCapacity.toInt()}W (${strategy == PowerAllocationStrategy.symmetrical ? "Symmetrical" : "Asymmetrical"} mode)'),
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

  Widget _buildTapSelector(CircuitInput circuit) {
    if (circuit.selectedModel == null) {
      return TextFormField(
        controller: circuit.tapWattsController,
        decoration: const InputDecoration(
          labelText: 'Tap Watts',
          border: OutlineInputBorder(),
          hintText: 'Select speaker model first',
        ),
        keyboardType: TextInputType.number,
        readOnly: true,
      );
    }

    final SpeakerModel? speaker = SpeakerCatalog.database[circuit.selectedModel!];
    if (speaker == null || speaker.hiZTaps.isEmpty) {
      return TextFormField(
        controller: circuit.tapWattsController,
        decoration: const InputDecoration(
          labelText: 'Tap Watts',
          border: OutlineInputBorder(),
          hintText: 'No taps available',
        ),
        keyboardType: TextInputType.number,
        readOnly: true,
      );
    }

    return DropdownButtonFormField<double>(
      value: circuit.selectedTap,
      items: speaker.hiZTaps.map((double tap) {
        return DropdownMenuItem<double>(
          value: tap,
          child: Text('${tap.toStringAsFixed(1)}W'),
        );
      }).toList(),
      onChanged: (double? value) {
        setState(() {
          circuit.selectedTap = value;
          if (value != null) {
            circuit.tapWattsController.text = value.toString();
          }
        });
      },
      decoration: const InputDecoration(
        labelText: 'Tap Watts',
        border: OutlineInputBorder(),
      ),
    );
  }

  /// Build final validation step for asymmetrical mode using mixed amplifier allocation
  Widget _buildAsymmetricalFinalValidationStep() {
    // Calculate circuit powers and sort by power (highest first)
    final List<Map<String, dynamic>> circuitData = <Map<String, dynamic>>[];
    double totalSystemPower = 0.0;
    
    for (final CircuitInput circuit in circuits) {
      final double circuitPower = _estimateCircuitPower(circuit);
      circuitData.add(<String, dynamic>{
        'circuit': circuit,
        'power': circuitPower,
        'model': circuit.selectedModel ?? 'Unknown',
        'speakerCount': int.tryParse(circuit.speakerCountController.text) ?? 0,
        'mode': circuit.mode.toUpperCase(),
      });
      totalSystemPower += circuitPower;
    }
    
    // Sort circuits by power (highest first)
    circuitData.sort((Map<String, dynamic> a, Map<String, dynamic> b) => (b['power'] as double).compareTo(a['power'] as double));
    
    // Calculate optimal amplifier combination with cost optimization
    final List<Map<String, dynamic>> amplifierAllocation = _calculateOptimalAmplifierAllocation(circuitData, AmplifierCatalog.psx1204d);
    
    if (amplifierAllocation.isEmpty) {
      return const Column(
        children: <Widget>[
          Text('❌ Error: No amplifiers could be allocated'),
        ],
      );
    }
    
    // Apply circuit movement optimization logic
    final List<Map<String, dynamic>> optimizedAllocation = _applyCircuitMovementOptimization(amplifierAllocation, circuitData);
    
    // Calculate overall system metrics
    final int totalAmplifiers = optimizedAllocation.length;
    final int totalChannelsUsed = optimizedAllocation.fold(0, (int sum, Map<String, dynamic> amp) => sum + (amp['usedChannels'] as int));
    final int totalChannelsAvailable = optimizedAllocation.fold(0, (int sum, Map<String, dynamic> amp) => sum + (amp['totalChannels'] as int));
    final double channelEfficiency = totalChannelsAvailable > 0 ? totalChannelsUsed / totalChannelsAvailable : 0.0;
    
    // Calculate power efficiency (total delivered vs total capacity)
    final double totalSystemCapacity = optimizedAllocation.fold(0.0, (double sum, Map<String, dynamic> amp) => 
      sum + ((amp['tierModel'] as AmplifierModel).asymmetrical.totalCapacity.toDouble()));
    final double powerEfficiency = totalSystemCapacity > 0 ? totalSystemPower / totalSystemCapacity : 0.0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text('✅ Final Mixed Amplifier Allocation Results:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        // Overall system summary
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
              const Text('🏆 System Summary:', style: TextStyle(fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              Text('Total Amplifiers Required: $totalAmplifiers'),
              Text('Total System Power: ${totalSystemPower.toStringAsFixed(1)}W'),
              Text('Total System Capacity: ${totalSystemCapacity.toStringAsFixed(1)}W'),
              Text('Power Efficiency: ${(powerEfficiency * 100).toStringAsFixed(1)}%'),
              Text('Channel Efficiency: ${(channelEfficiency * 100).toStringAsFixed(1)}%'),
              const SizedBox(height: 8),
              const Text('✅ Mixed amplifier allocation with circuit movement optimization applied', 
                       style: TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
            ],
          ),
        ),
        
        const SizedBox(height: 12),
        
        // Individual amplifier details
        const Text('🔌 Mixed Amplifier Assignments:', style: TextStyle(fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        
        ...optimizedAllocation.asMap().entries.map((MapEntry<int, Map<String, dynamic>> entry) {
          final int index = entry.key;
          final Map<String, dynamic> amplifier = entry.value;
          final AmplifierModel ampModel = amplifier['tierModel'] as AmplifierModel;
          final List<Map<String, dynamic>> assignedCircuits = amplifier['circuitsAssigned'] as List<Map<String, dynamic>>;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              border: Border.all(color: Colors.grey[300]!),
              borderRadius: BorderRadius.circular(6),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text('📦 Amplifier ${index + 1}: ${ampModel.name}', 
                     style: const TextStyle(fontWeight: FontWeight.w600)),
                const SizedBox(height: 4),
                Text('   • Channels: ${amplifier['usedChannels']}/${amplifier['totalChannels']} used'),
                Text('   • Symmetrical Per-Channel: ${ampModel.symmetrical.watts}W'),
                Text('   • Asymmetrical Per-Channel: ${ampModel.asymmetrical.watts}W'),
                Text('   • Total Capacity: ${ampModel.asymmetrical.totalCapacity}W'),
                Text('   • Channel Utilization: ${((amplifier['usedChannels'] as int) / (amplifier['totalChannels'] as int) * 100).toStringAsFixed(1)}%'),
                const SizedBox(height: 4),
                const Text('   • Assigned Circuits:', style: TextStyle(fontWeight: FontWeight.w500)),
                ...assignedCircuits.map((Map<String, dynamic> circuit) =>
                  Text('     - ${circuit['model']}: ${circuit['speakerCount']} speakers (${circuit['power'].toStringAsFixed(1)}W)'),
                ),
              ],
            ),
          );
        }),
        
        const SizedBox(height: 12),
        
      ],
    );
  }

  /// Build amplifier capacity comparison table
  Widget _buildAmplifierCapacityTable() {
    return Card(
      elevation: 3,
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Row(
              children: <Widget>[
                Icon(Icons.table_chart, color: Colors.blue, size: 24),
                SizedBox(width: 8),
                Text(
                  '📊 Amplifier Capacity Comparison Table',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Table header
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue[100],
                borderRadius: BorderRadius.circular(6),
              ),
              child: const Row(
                children: <Widget>[
                  Expanded(flex: 2, child: Text('Amplifier Model', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Channels', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Symmetrical\nPer-Channel', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Asymmetrical\nPer-Channel', style: TextStyle(fontWeight: FontWeight.bold))),
                  Expanded(child: Text('Total\nCapacity', style: TextStyle(fontWeight: FontWeight.bold))),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Table rows for each amplifier
            ...AmplifierCatalog.allModels.map((AmplifierModel amplifier) => Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.grey[200]!),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    flex: 2,
                    child: Text(
                      amplifier.name,
                      style: const TextStyle(fontWeight: FontWeight.w600),
                    ),
                  ),
                  Expanded(
                    child: Text('${amplifier.channels}'),
                  ),
                  Expanded(
                    child: Text('${amplifier.symmetrical.watts}W'),
                  ),
                  Expanded(
                    child: Text(
                      '${amplifier.asymmetrical.watts}W',
                      style: const TextStyle(fontWeight: FontWeight.w600, color: Colors.green),
                    ),
                  ),
                  Expanded(
                    child: Text('${amplifier.asymmetrical.totalCapacity}W'),
                  ),
                ],
              ),
            )),
            
            const SizedBox(height: 16),
            
            // Explanation
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.orange[50],
                borderRadius: BorderRadius.circular(6),
                border: Border.all(color: Colors.orange[200]!),
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text('📝 Capacity Definitions:', style: TextStyle(fontWeight: FontWeight.bold)),
                  SizedBox(height: 8),
                  Text('• Symmetrical Per-Channel: Fixed power per channel (cannot be shared)'),
                  Text('• Asymmetrical Per-Channel: Maximum power a single channel can withdraw (can be shared)'),
                  Text('• Total Capacity: Maximum total power the amplifier can deliver'),
                  SizedBox(height: 8),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
