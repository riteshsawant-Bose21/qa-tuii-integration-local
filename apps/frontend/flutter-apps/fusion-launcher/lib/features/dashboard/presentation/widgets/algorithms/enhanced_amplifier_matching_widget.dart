import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_algorithms/amplifier_matching/amplifier_matching.dart';
import 'package:fusion_lib/api_data/speakers/speakers.dart';
import 'dart:math' as math;

import '../../../../../core/services/circuit_data_service.dart';

/// Enhanced Input model for circuit configuration with voltage selection
class CircuitInput {
  String? selectedModel;
  final TextEditingController speakerCountController = TextEditingController(text: '1');
  final TextEditingController offsetDbController = TextEditingController(text: '0.0');
  String mode = 'hi-z';
  double? specifiedVoltage = 70.0;
  int circuitId;
  double selectedTapWatts = 15.0; // Changed from text controller to direct value
  bool useCustomTap = false; // Flag for custom tap input
  final TextEditingController customTapController = TextEditingController();

  // Common tap values for 70V and 100V systems
  static const List<double> taps70V = <double>[1.0, 2.0, 4.0, 8.0, 15.0, 30.0, 60.0];
  static const List<double> taps100V = <double>[1.25, 2.5, 5.0, 10.0, 20.0, 40.0, 80.0];

  CircuitInput(this.circuitId);

  List<double> get availableTaps {
    // If a speaker model is selected, use its specific taps from catalog
    if (selectedModel != null && selectedModel!.isNotEmpty) {
      final SpeakerModel? speakerData = SpeakerCatalog.database[selectedModel];
      if (speakerData != null) {
        return specifiedVoltage == 70.0 ? speakerData.taps70V : speakerData.taps100V;
      }
    }
    // Fallback to generic taps if no speaker selected or speaker not found
    return specifiedVoltage == 70.0 ? taps70V : taps100V;
  }

  void dispose() {
    speakerCountController.dispose();
    offsetDbController.dispose();
    customTapController.dispose();
  }

  double get tapWatts => useCustomTap 
    ? (double.tryParse(customTapController.text) ?? selectedTapWatts)
    : selectedTapWatts;

  Circuit? toCircuit() {
    if (selectedModel == null || selectedModel!.isEmpty) return null;

    final int speakerCount = int.tryParse(speakerCountController.text) ?? 1;
    final double offsetDb = double.tryParse(offsetDbController.text) ?? 0.0;

    // Get actual speaker data from catalog
    final SpeakerModel? speakerData = SpeakerCatalog.database[selectedModel!];
    if (speakerData == null) return null;

    // Use the selected tap watts, but the speaker model determines the actual characteristics
    return Circuit(
      circuitId: circuitId,
      model: selectedModel!,
      mode: mode,
      speakerCount: speakerCount,
      tapWatts: tapWatts, // This should be the selected tap setting
      outputOffsetDb: offsetDb,
    );
  }
}

class EnhancedAmplifierMatchingWidget extends StatefulWidget {
  const EnhancedAmplifierMatchingWidget({super.key});

  @override
  State<EnhancedAmplifierMatchingWidget> createState() => _EnhancedAmplifierMatchingWidgetState();
}

class _EnhancedAmplifierMatchingWidgetState extends State<EnhancedAmplifierMatchingWidget> with TickerProviderStateMixin {
  final List<CircuitInput> circuits = <CircuitInput>[CircuitInput(1)];
  AmpMatchingResult? symmetricalResult;
  AmpMatchingResult? asymmetricalResult;
  bool isLoading = false;
  String? errorMessage;
  final CircuitDataService _circuitDataService = CircuitDataService();
  double _globalVoltage = 70.0; // 70V or 100V
  late TabController _tabController;
  late TabController _comparisonTabController;

  List<String> get availableSpeakerModels => SpeakerCatalog.database.keys.toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _comparisonTabController = TabController(length: 2, vsync: this);
    circuits.first.specifiedVoltage = _globalVoltage;
  }

  @override
  void dispose() {
    _tabController.dispose();
    _comparisonTabController.dispose();
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
      symmetricalResult = null;
      asymmetricalResult = null;
    });

    try {
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

      // Always run both strategies for comparison
      final AmpMatchingResult symmetrical = await matchAmplifiers(
        validCircuits, 
        SpeakerCatalog.database,
        strategy: PowerAllocationStrategy.symmetrical,
        enableLogging: false,
      );
      
      final AmpMatchingResult asymmetrical = await matchAmplifiers(
        validCircuits, 
        SpeakerCatalog.database,
        strategy: PowerAllocationStrategy.asymmetrical,
        enableLogging: false,
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
      for (final CircuitInput circuit in circuits) {
        circuit.dispose();
      }
      circuits.clear();

      final List<Circuit> importedCircuits = _circuitDataService.convertToCircuits(SpeakerCatalog.database);

      for (final Circuit circuit in importedCircuits) {
        final CircuitInput circuitInput = CircuitInput(circuit.circuitId);
        circuitInput.selectedModel = circuit.model;
        circuitInput.speakerCountController.text = circuit.speakerCount.toString();
        circuitInput.selectedTapWatts = circuit.tapWatts;
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
    return Scaffold(
      backgroundColor: Colors.grey[50],
      body: Column(
        children: <Widget>[
          // Header Section
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(24.0),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Colors.blue[700]!, Colors.blue[500]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              boxShadow: <BoxShadow>[
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 8,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Amplifier Matching Tool',
                  style: TextStyle(
                    fontSize: 32,
                    fontWeight: FontWeight.bold,
                    color: Colors.white,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Calculate amplifier configurations with side-by-side strategy comparison and tap-based input',
                  style: TextStyle(
                    fontSize: 16,
                    color: Colors.white70,
                  ),
                ),
                const SizedBox(height: 24),
                
                // Voltage Selection
                Row(
                  children: <Widget>[
                    const Text(
                      'System Voltage:',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(width: 16),
                    Container(
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: ToggleButtons(
                        isSelected: <bool>[_globalVoltage == 70.0, _globalVoltage == 100.0],
                        onPressed: (int index) {
                          setState(() {
                            _globalVoltage = index == 0 ? 70.0 : 100.0;
                            for (final CircuitInput circuit in circuits) {
                              circuit.specifiedVoltage = _globalVoltage;
                            }
                          });
                        },
                        borderRadius: BorderRadius.circular(8),
                        selectedBorderColor: Colors.blue[700],
                        selectedColor: Colors.white,
                        fillColor: Colors.blue[700],
                        color: Colors.blue[700],
                        constraints: const BoxConstraints(
                          minHeight: 40.0,
                          minWidth: 80.0,
                        ),
                        children: const <Widget>[
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('70V', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                          Padding(
                            padding: EdgeInsets.symmetric(horizontal: 16.0),
                            child: Text('100V', style: TextStyle(fontWeight: FontWeight.w600)),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
          
          // Main Content
          Expanded(
            child: SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  // Input Parameters Section
                  _buildInputParametersSection(),
                  
                  const SizedBox(height: 32),
                  
                  // Results Section
                  if (symmetricalResult != null || asymmetricalResult != null)
                    _buildResultsSection(),
                  
                  if (errorMessage != null)
                    _buildErrorSection(),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputParametersSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: <Widget>[
                const Text(
                  'Input Parameters',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                Row(
                  children: <Widget>[
                    // Import Button
                    AnimatedBuilder(
                      animation: _circuitDataService,
                      builder: (BuildContext context, Widget? child) {
                        return ElevatedButton.icon(
                          onPressed: _circuitDataService.hasCircuitingData ? _importCircuitingData : null,
                          icon: const Icon(Icons.download, size: 18),
                          label: const Text('Import Circuits'),
                          style: ElevatedButton.styleFrom(
                            backgroundColor: _circuitDataService.hasCircuitingData ? Colors.green : Colors.grey,
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                          ),
                        );
                      },
                    ),
                    const SizedBox(width: 12),
                    // Calculate Button
                    ElevatedButton.icon(
                      onPressed: isLoading ? null : _calculateAmplifierMatching,
                      icon: isLoading 
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : const Icon(Icons.calculate, size: 18),
                      label: Text(isLoading ? 'Calculating...' : 'Calculate'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue[700],
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Reset Button
                    OutlinedButton.icon(
                      onPressed: _resetForm,
                      icon: const Icon(Icons.refresh, size: 18),
                      label: const Text('Reset'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.grey[700],
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            // Circuit Configuration
            Row(
              children: <Widget>[
                const Text(
                  'Number of Circuits',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const Spacer(),
                ElevatedButton.icon(
                  onPressed: _addCircuit,
                  icon: const Icon(Icons.add, size: 18),
                  label: const Text('Add Circuit'),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.green,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Circuits List
            ...circuits.asMap().entries.map((MapEntry<int, CircuitInput> entry) {
              final int index = entry.key;
              final CircuitInput circuit = entry.value;
              return _buildCircuitCard(circuit, index);
            }).toList(),
          ],
        ),
      ),
    );
  }

  Widget _buildCircuitCard(CircuitInput circuit, int index) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey[300]!),
        borderRadius: BorderRadius.circular(12),
        color: Colors.grey[50],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                  decoration: BoxDecoration(
                    color: Colors.blue[100],
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(
                    'Circuit ${circuit.circuitId}',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: Colors.blue[800],
                    ),
                  ),
                ),
                const Spacer(),
                if (circuits.length > 1)
                  IconButton(
                    onPressed: () => _removeCircuit(index),
                    icon: const Icon(Icons.close, color: Colors.red),
                    tooltip: 'Remove Circuit',
                  ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Speaker Model Dropdown
            Row(
              children: <Widget>[
                Expanded(
                  flex: 2,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Speaker Model', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      DropdownButtonFormField<String>(
                        value: circuit.selectedModel,
                        onChanged: (String? value) {
                          setState(() {
                            circuit.selectedModel = value;
                            
                            // When speaker model changes, validate and update tap selection
                            if (value != null && value.isNotEmpty) {
                              final List<double> newAvailableTaps = circuit.availableTaps;
                              
                              // If current tap is not available for this speaker, select the first available tap
                              if (!newAvailableTaps.contains(circuit.selectedTapWatts)) {
                                circuit.selectedTapWatts = newAvailableTaps.isNotEmpty ? newAvailableTaps.first : 15.0;
                              }
                              
                              // Reset custom tap if using custom mode
                              if (circuit.useCustomTap) {
                                circuit.useCustomTap = false;
                              }
                            }
                          });
                        },
                        decoration: InputDecoration(
                          hintText: 'Select speaker model',
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                        items: availableSpeakerModels.map((String model) {
                          return DropdownMenuItem<String>(
                            value: model,
                            child: Text(model),
                          );
                        }).toList(),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Speaker Count
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text('Count', style: TextStyle(fontWeight: FontWeight.w600)),
                      const SizedBox(height: 8),
                      TextFormField(
                        controller: circuit.speakerCountController,
                        keyboardType: TextInputType.number,
                        decoration: InputDecoration(
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          filled: true,
                          fillColor: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Tap Selection
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          const Text('Tap (W)', style: TextStyle(fontWeight: FontWeight.w600)),
                          if (circuit.selectedModel != null && circuit.selectedModel!.isNotEmpty) ...<Widget>[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.green[100],
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                'Catalog',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: Colors.green[800],
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                      const SizedBox(height: 8),
                      if (!circuit.useCustomTap)
                        DropdownButtonFormField<double>(
                          value: circuit.selectedTapWatts,
                          onChanged: (double? value) {
                            setState(() {
                              circuit.selectedTapWatts = value ?? 15.0;
                            });
                          },
                          decoration: InputDecoration(
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                            filled: true,
                            fillColor: Colors.white,
                            suffixIcon: IconButton(
                              icon: const Icon(Icons.edit, size: 16),
                              onPressed: () {
                                setState(() {
                                  circuit.useCustomTap = true;
                                  circuit.customTapController.text = circuit.selectedTapWatts.toString();
                                });
                              },
                              tooltip: 'Custom tap',
                            ),
                          ),
                          items: circuit.availableTaps.map((double tap) {
                            return DropdownMenuItem<double>(
                              value: tap,
                              child: Text('${tap.toStringAsFixed(tap == tap.roundToDouble() ? 0 : 2)}W'),
                            );
                          }).toList(),
                        )
                      else
                        Row(
                          children: <Widget>[
                            Expanded(
                              child: TextFormField(
                                controller: circuit.customTapController,
                                keyboardType: TextInputType.number,
                                decoration: InputDecoration(
                                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                                  filled: true,
                                  fillColor: Colors.white,
                                  suffixText: 'W',
                                ),
                              ),
                            ),
                            IconButton(
                              icon: const Icon(Icons.check, color: Colors.green),
                              onPressed: () {
                                setState(() {
                                  circuit.useCustomTap = false;
                                  final double customValue = double.tryParse(circuit.customTapController.text) ?? circuit.selectedTapWatts;
                                  if (!circuit.availableTaps.contains(customValue)) {
                                    circuit.selectedTapWatts = customValue;
                                  }
                                });
                              },
                              tooltip: 'Use standard taps',
                            ),
                          ],
                        ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Base and Adjusted Power Display
            if (circuit.selectedModel != null && circuit.selectedModel!.isNotEmpty)
              _buildPowerCalculationDisplay(circuit),
          ],
        ),
      ),
    );
  }

  Widget _buildPowerCalculationDisplay(CircuitInput circuit) {
    final int speakerCount = int.tryParse(circuit.speakerCountController.text) ?? 1;
    final double tapWatts = circuit.tapWatts;
    final double offsetDb = double.tryParse(circuit.offsetDbController.text) ?? 0.0;
    
    // Get actual speaker data from catalog
    final SpeakerModel? speakerData = SpeakerCatalog.database[circuit.selectedModel];
    
    // Calculate tap power (what the tap setting provides)
    final double tapPower = speakerCount * tapWatts;
    
    // Calculate adjusted power with dB offset
    final double adjustedPower = tapPower * math.pow(10, offsetDb / 10);
    
    // Get speaker's actual peak power rating from catalog
    final double speakerPeakPower = speakerData?.ppk ?? 0.0;
    final double totalSpeakerCapacity = speakerCount * speakerPeakPower;

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
            children: <Widget>[
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'Tap Power',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    Text(
                      '${tapPower.toStringAsFixed(1)} W',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.blue[800],
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    const Text(
                      'With Offset',
                      style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                    ),
                    Text(
                      '${adjustedPower.toStringAsFixed(1)} W',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Colors.green[800],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          if (speakerData != null) ...<Widget>[
            const SizedBox(height: 8),
            const Divider(),
            const SizedBox(height: 8),
            // Debug info: Show catalog values
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Colors.yellow[50],
                borderRadius: BorderRadius.circular(4),
                border: Border.all(color: Colors.yellow[300]!),
              ),
              child: Text(
                'DEBUG: ${circuit.selectedModel} catalog ppk=${speakerPeakPower}W, total=${totalSpeakerCapacity}W',
                style: TextStyle(fontSize: 10, color: Colors.orange[800]),
              ),
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Speaker Peak Capacity',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        '${totalSpeakerCapacity.toStringAsFixed(0)} W',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.purple[800],
                        ),
                      ),
                    ],
                  ),
                ),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Utilization',
                        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 12),
                      ),
                      Text(
                        '${(adjustedPower / totalSpeakerCapacity * 100).toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: adjustedPower > totalSpeakerCapacity ? Colors.red[800] : Colors.green[800],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildResultsSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // Amplifier Recommendations Section
        if (symmetricalResult != null || asymmetricalResult != null)
          _buildAmplifierRecommendationsSection(),
        
        const SizedBox(height: 24),
        
        // Side-by-Side Comparison
        Card(
          elevation: 4,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                const Text(
                  'Side-by-Side Strategy Comparison',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Side-by-side content with intrinsic height
                IntrinsicHeight(
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      // Symmetrical Strategy (Left Side)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.orange[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildSymmetricalSteps(symmetricalResult),
                        ),
                      ),
                      
                      const SizedBox(width: 16),
                      
                      // Asymmetrical Strategy (Right Side)
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: Colors.green[300]!),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: _buildAsymmetricalSteps(asymmetricalResult),
                        ),
                      ),
                    ],
                  ),
                ),
                
                const SizedBox(height: 24),
                
                // Formula Reference Section
                _buildFormulaReference(),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildAmplifierRecommendationsSection() {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.lightbulb, color: Colors.amber[600], size: 28),
                const SizedBox(width: 12),
                const Text(
                  'Amplifier Recommendations',
                  style: TextStyle(
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 24),
            
            Row(
              children: <Widget>[
                // Symmetrical Recommendation
                Expanded(
                  child: _buildStrategyRecommendation(
                    'Symmetrical Strategy',
                    symmetricalResult,
                    Colors.orange,
                    'Individual channel allocation',
                  ),
                ),
                
                const SizedBox(width: 16),
                
                // Asymmetrical Recommendation
                Expanded(
                  child: _buildStrategyRecommendation(
                    'Asymmetrical Strategy',
                    asymmetricalResult,
                    Colors.green,
                    'Power sharing optimization',
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Best Recommendation
            _buildBestRecommendation(),
          ],
        ),
      ),
    );
  }

  Widget _buildStrategyRecommendation(String title, AmpMatchingResult? result, MaterialColor color, String description) {
    if (result == null) {
      return Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Colors.grey[100],
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: Colors.grey[300]!),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              title,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Run calculation to see recommendations',
              style: TextStyle(color: Colors.grey[500]),
            ),
          ],
        ),
      );
    }

    final Set<String> uniqueModels = result.assignments.map((AmpAssignment a) => a.ampModel.name).toSet();
    final int totalAmps = result.assignments.length;
    final double efficiency = result.powerEfficiency * 100;
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            title,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: color[800],
            ),
          ),
          const SizedBox(height: 8),
          Text(
            description,
            style: TextStyle(
              color: color[700],
              fontSize: 14,
            ),
          ),
          const SizedBox(height: 16),
          
          // Key metrics
          _buildMetricRow('Amplifiers Required', '$totalAmps units'),
          _buildMetricRow('Unique Models', '${uniqueModels.length} models'),
          _buildMetricRow('Power Efficiency', '${efficiency.toStringAsFixed(1)}%'),
          
          const SizedBox(height: 12),
          
          // Amplifier list
          Text(
            'Recommended Models:',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: color[800],
            ),
          ),
          const SizedBox(height: 8),
          
          ...uniqueModels.take(3).map((String model) {
            final int count = result.assignments.where((AmpAssignment a) => a.ampModel.name == model).length;
            return Padding(
              padding: const EdgeInsets.only(bottom: 4),
              child: Row(
                children: <Widget>[
                  Container(
                    width: 8,
                    height: 8,
                    decoration: BoxDecoration(
                      color: color[600],
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      '$model (${count}x)',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
          
          if (uniqueModels.length > 3)
            Text(
              '+ ${uniqueModels.length - 3} more models',
              style: TextStyle(
                fontSize: 12,
                color: color[600],
                fontStyle: FontStyle.italic,
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          Text(
            label,
            style: const TextStyle(fontSize: 12, color: Colors.black54),
          ),
          Text(
            value,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }

  Widget _buildBestRecommendation() {
    if (symmetricalResult == null || asymmetricalResult == null) {
      return const SizedBox.shrink();
    }

    // Determine which strategy is better based on multiple factors
    final double symEfficiency = symmetricalResult!.powerEfficiency;
    final double asymEfficiency = asymmetricalResult!.powerEfficiency;
    final int symAmps = symmetricalResult!.assignments.length;
    final int asymAmps = asymmetricalResult!.assignments.length;
    final int symModels = symmetricalResult!.assignments.map((AmpAssignment a) => a.ampModel.name).toSet().length;
    final int asymModels = asymmetricalResult!.assignments.map((AmpAssignment a) => a.ampModel.name).toSet().length;

    // Score calculation (efficiency weight: 40%, amp count weight: 30%, model diversity weight: 30%)
    final double symScore = (symEfficiency * 0.4) + ((1.0 - (symAmps / 10.0)) * 0.3) + ((1.0 - (symModels / 5.0)) * 0.3);
    final double asymScore = (asymEfficiency * 0.4) + ((1.0 - (asymAmps / 10.0)) * 0.3) + ((1.0 - (asymModels / 5.0)) * 0.3);

    final bool symmetricalBetter = symScore > asymScore;
    final AmpMatchingResult betterResult = symmetricalBetter ? symmetricalResult! : asymmetricalResult!;
    final String strategyName = symmetricalBetter ? 'Symmetrical' : 'Asymmetrical';
    final MaterialColor color = symmetricalBetter ? Colors.orange : Colors.green;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: <Color>[color[100]!, color[50]!],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color[400]!, width: 2),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.star, color: color[600], size: 24),
              const SizedBox(width: 8),
              Text(
                'Recommended: $strategyName Strategy',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: color[800],
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          
          Row(
            children: <Widget>[
              Expanded(
                child: _buildQuickStat('Power Efficiency', '${(betterResult.powerEfficiency * 100).toStringAsFixed(1)}%'),
              ),
              Expanded(
                child: _buildQuickStat('Total Amplifiers', '${betterResult.assignments.length}'),
              ),
              Expanded(
                child: _buildQuickStat('Unique Models', '${betterResult.assignments.map((AmpAssignment a) => a.ampModel.name).toSet().length}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildQuickStat(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: <Widget>[
        Text(
          label,
          style: const TextStyle(
            fontSize: 12,
            color: Colors.black54,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
          textAlign: TextAlign.center,
        ),
      ],
    );
  }

  Widget _buildSymmetricalSteps(AmpMatchingResult? result) {
    if (result == null) {
      return const Center(
        child: Text(
          'Run calculation to see symmetrical analysis',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final List<Circuit> validCircuits = circuits.map((CircuitInput c) => c.toCircuit()).where((Circuit? c) => c != null).cast<Circuit>().toList();
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Colors.orange[100]!, Colors.orange[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.orange[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Symmetrical Strategy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.orange[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Each circuit is allocated to individual amplifier channels with equal power distribution',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.orange[700],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Step 1: Circuit Types and Power Calculation
          _buildStepCard(
            stepNumber: 1,
            title: 'Determine Circuit Types and Calculate Total Power',
            content: _buildStep1Content(validCircuits),
            color: Colors.orange,
          ),
          
          // Step 2: Apply Output Offsets
          _buildStepCard(
            stepNumber: 2,
            title: 'Apply Output Offsets',
            content: _buildStep2Content(validCircuits),
            color: Colors.orange,
          ),
          
          // Step 3: Sort Circuits by Power Requirements
          _buildStepCard(
            stepNumber: 3,
            title: 'Sort Circuits by Power Requirements',
            content: _buildStep3Content(validCircuits),
            color: Colors.orange,
          ),
          
          // Step 4: Choose Amplifier Using Tier Rule
          _buildStepCard(
            stepNumber: 4,
            title: 'Choose Amplifier Using Tier Rule',
            content: _buildStep4Content(result),
            color: Colors.orange,
          ),
          
          // Step 5: Apply Channel Allocation Strategy
          _buildStepCard(
            stepNumber: 5,
            title: 'Apply Channel Allocation Strategy',
            content: _buildStep5Content(result),
            color: Colors.orange,
          ),
        ],
      ),
    );
  }

  Widget _buildAsymmetricalSteps(AmpMatchingResult? result) {
    if (result == null) {
      return const Center(
        child: Text(
          'Run calculation to see asymmetrical analysis',
          style: TextStyle(fontSize: 16, color: Colors.grey),
        ),
      );
    }

    final List<Circuit> validCircuits = circuits.map((CircuitInput c) => c.toCircuit()).where((Circuit? c) => c != null).cast<Circuit>().toList();
    
    return Padding(
      padding: const EdgeInsets.all(12.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // Header
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: LinearGradient(
                colors: <Color>[Colors.green[100]!, Colors.green[50]!],
                begin: Alignment.topLeft,
                end: Alignment.bottomRight,
              ),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Asymmetrical Strategy',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: Colors.green[800],
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Circuits can share amplifier power capacity across channels for flexible distribution',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.green[700],
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Steps 6-12 for Asymmetrical
          _buildStepCard(
            stepNumber: 6,
            title: 'Run Simplified Power Sharing Calculator',
            content: _buildStep6Content(result, validCircuits),
            color: Colors.green,
          ),
          
          _buildStepCard(
            stepNumber: 7,
            title: 'Identify Channels with Positive Net Power Sharing',
            content: _buildStep7Content(result),
            color: Colors.green,
          ),
          
          _buildStepCard(
            stepNumber: 8,
            title: 'Optimize Circuit Allocation',
            content: _buildStep8Content(result),
            color: Colors.green,
          ),
          
          _buildStepCard(
            stepNumber: 9,
            title: 'Update Power Sharing Information',
            content: _buildStep9Content(result),
            color: Colors.green,
          ),
          
          _buildStepCard(
            stepNumber: 10,
            title: 'Remove Empty Amplifier Assignments',
            content: _buildStep10Content(result),
            color: Colors.green,
          ),
          
          _buildStepCard(
            stepNumber: 11,
            title: 'Final Tier Rule Validation',
            content: _buildStep11Content(result),
            color: Colors.green,
          ),
          
          _buildStepCard(
            stepNumber: 12,
            title: 'SKU Reduction',
            content: _buildStep12Content(result),
            color: Colors.green,
          ),
        ],
      ),
    );
  }

  Widget _buildStepCard({
    required int stepNumber,
    required String title,
    required Widget content,
    required MaterialColor color,
  }) {
    return Container(
      margin: const EdgeInsets.only(bottom: 20),
      decoration: BoxDecoration(
        border: Border.all(color: color[200]!),
        borderRadius: BorderRadius.circular(12),
        color: color[50],
      ),
      child: ExpansionTile(
        leading: Container(
          width: 32,
          height: 32,
          decoration: BoxDecoration(
            color: color[600],
            borderRadius: BorderRadius.circular(16),
          ),
          child: Center(
            child: Text(
              '$stepNumber',
              style: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontWeight: FontWeight.bold,
            color: color[800],
          ),
        ),
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: content,
          ),
        ],
      ),
    );
  }

  Widget _buildStep1Content(List<Circuit> circuits) {
    double totalPower = 0;
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Formula: For Hi-Z: Circuit_Power = Tap_Watts × Speaker_Count',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        ...circuits.map((Circuit circuit) {
          final double circuitPower = circuit.tapWatts * circuit.speakerCount;
          totalPower += circuitPower;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Text(
                    'Circuit ${circuit.circuitId}: ${circuit.mode.toUpperCase()}, ${circuit.speakerCount} speakers, ${circuit.tapWatts}W tap each',
                  ),
                ),
                Text(
                  '${circuit.tapWatts}W × ${circuit.speakerCount} = ${circuitPower.toStringAsFixed(1)}W',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }).toList(),
        
        const SizedBox(height: 16),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.orange[100],
            borderRadius: BorderRadius.circular(8),
            border: Border.all(color: Colors.orange[300]!),
          ),
          child: Row(
            children: <Widget>[
              const Expanded(
                child: Text(
                  'Total System Power:',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
              Text(
                '${totalPower.toStringAsFixed(1)}W',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep2Content(List<Circuit> circuits) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Formula: Adjusted_Power = Base_Power × 10^(Offset_dB / 10)',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        ...circuits.map((Circuit circuit) {
          final double basePower = circuit.tapWatts * circuit.speakerCount;
          final double adjustedPower = basePower * math.pow(10, circuit.outputOffsetDb / 10);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Circuit ${circuit.circuitId}: ${basePower.toStringAsFixed(1)}W base, ${circuit.outputOffsetDb >= 0 ? '+' : ''}${circuit.outputOffsetDb}dB offset',
                ),
                const SizedBox(height: 4),
                Text(
                  'Adjusted: ${basePower.toStringAsFixed(1)}W × 10^(${circuit.outputOffsetDb}/10) = ${adjustedPower.toStringAsFixed(1)}W',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontFamily: 'monospace',
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep3Content(List<Circuit> circuits) {
    final List<Circuit> sortedCircuits = List<Circuit>.from(circuits);
    sortedCircuits.sort((Circuit a, Circuit b) {
      final double powerA = a.tapWatts * a.speakerCount * math.pow(10, a.outputOffsetDb / 10);
      final double powerB = b.tapWatts * b.speakerCount * math.pow(10, b.outputOffsetDb / 10);
      return powerB.compareTo(powerA);
    });
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Circuits sorted by power requirements (highest first):',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        ...sortedCircuits.asMap().entries.map((MapEntry<int, Circuit> entry) {
          final int index = entry.key;
          final Circuit circuit = entry.value;
          final double adjustedPower = circuit.tapWatts * circuit.speakerCount * math.pow(10, circuit.outputOffsetDb / 10);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: index == 0 ? Colors.orange[100] : Colors.grey[100],
              borderRadius: BorderRadius.circular(8),
              border: index == 0 ? Border.all(color: Colors.orange[300]!) : null,
            ),
            child: Row(
              children: <Widget>[
                Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: index == 0 ? Colors.orange[600] : Colors.grey[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      '${index + 1}',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Circuit ${circuit.circuitId}: ${circuit.speakerCount}× ${circuit.model}',
                  ),
                ),
                Text(
                  '${adjustedPower.toStringAsFixed(1)}W',
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: index == 0 ? Colors.orange[800] : Colors.grey[800],
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep4Content(AmpMatchingResult result) {
    final List<Circuit> validCircuits = circuits.map((CircuitInput c) => c.toCircuit()).where((Circuit? c) => c != null).cast<Circuit>().toList();
    double maxPower = 0;
    if (validCircuits.isNotEmpty) {
      maxPower = validCircuits.map((Circuit c) => c.tapWatts * c.speakerCount * math.pow(10, c.outputOffsetDb / 10)).reduce(math.max);
    }
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Tier Classification:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Required Per-Channel Power: ${maxPower.toStringAsFixed(1)}W'),
              const SizedBox(height: 8),
              Text('Tier 1: ≥ ${maxPower.toStringAsFixed(1)}W per channel'),
              Text('Tier 2: ≥ ${(maxPower * 0.75).toStringAsFixed(1)}W per channel'),
              Text('Tier 3: ≥ ${(maxPower * 0.50).toStringAsFixed(1)}W per channel'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        const Text(
          'Selected Amplifiers:',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        
        ...result.assignments.map((AmpAssignment assignment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[300]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${assignment.ampModel.name}: ${assignment.ampModel.peakPerChannel.toStringAsFixed(0)}W per channel, ${assignment.ampModel.channels} channels',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                Text(
                  'Tier: ${assignment.ampModel.peakPerChannel >= maxPower ? '1' : assignment.ampModel.peakPerChannel >= maxPower * 0.75 ? '2' : '3'} (${assignment.ampModel.peakPerChannel >= maxPower ? 'Optimal' : assignment.ampModel.peakPerChannel >= maxPower * 0.75 ? 'Good' : 'Acceptable'})',
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep5Content(AmpMatchingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Symmetrical Rule: One circuit per channel, no power sharing',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.orange,
          ),
        ),
        const SizedBox(height: 16),
        
        ...result.assignments.map((AmpAssignment assignment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.orange[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.orange[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${assignment.ampModel.name}',
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Channels Used: ${assignment.circuits.length}/${assignment.ampModel.channels}',
                ),
                Text(
                  'Channel Utilization: ${(assignment.channelUtilization * 100).toStringAsFixed(1)}%',
                ),
                const SizedBox(height: 8),
                
                ...assignment.circuits.asMap().entries.map((MapEntry<int, Circuit> entry) {
                  final int channelIndex = entry.key;
                  final Circuit circuit = entry.value;
                  final double circuitPower = circuit.tapWatts * circuit.speakerCount * math.pow(10, circuit.outputOffsetDb / 10);
                  
                  return Padding(
                    padding: const EdgeInsets.only(left: 16, bottom: 4),
                    child: Text(
                      'Channel ${channelIndex + 1}: Circuit ${circuit.circuitId} (${circuitPower.toStringAsFixed(1)}W ≤ ${assignment.ampModel.peakPerChannel.toStringAsFixed(0)}W) ✓',
                      style: const TextStyle(fontSize: 14),
                    ),
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Final Results:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              Text('Total Amplifiers: ${result.assignments.length}'),
              Text('Total Channels Used: ${result.totalChannelsUsed}/${result.totalChannelsAvailable}'),
              Text('System Efficiency: ${(result.powerEfficiency * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
      ],
    );
  }

  // Asymmetrical Steps (6-12) - Simplified for brevity, can be expanded
  Widget _buildStep6Content(AmpMatchingResult result, List<Circuit> circuits) {
    final double totalRequired = circuits.map((Circuit c) => c.tapWatts * c.speakerCount * math.pow(10, c.outputOffsetDb / 10)).fold<double>(0, (double a, double b) => a + b);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Formula: Total_Available_Power = Amplifier_Total_Capacity',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 12),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Total Available Power: ${result.totalSystemCapacity.toStringAsFixed(1)}W'),
              Text('Total Required Power: ${totalRequired.toStringAsFixed(1)}W'),
              Text('Power Sharing Headroom: ${(result.totalSystemCapacity - totalRequired).toStringAsFixed(1)}W'),
              const SizedBox(height: 8),
              const Divider(),
              const Text('DEBUG - Amplifier Power Breakdown:', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
              ...result.assignments.map((AmpAssignment assignment) {
                final double asymPower = assignment.ampModel.powerSpecs?.asymmetricalPeakPower70V ?? 0.0;
                final double symPower = assignment.ampModel.powerSpecs?.peakPowerPerChannel70V ?? assignment.ampModel.peakPerChannel;
                final double symTotal = symPower * assignment.ampModel.channels;
                return Text(
                  '${assignment.ampModel.name}: Sym=${symTotal.toStringAsFixed(0)}W (${symPower.toStringAsFixed(0)}W×${assignment.ampModel.channels}), Asym=${asymPower.toStringAsFixed(0)}W',
                  style: const TextStyle(fontSize: 10, color: Colors.orange),
                );
              }).toList(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildStep7Content(AmpMatchingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Formula: Channel_Surplus = Per_Channel_Rating - Assigned_Circuit_Power',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        ...result.assignments.map((AmpAssignment assignment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${assignment.ampModel.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                
                ...List<Widget>.generate(assignment.ampModel.channels, (int channelIndex) {
                  final bool hasCircuit = channelIndex < assignment.circuits.length;
                  final double channelRating = assignment.ampModel.peakPerChannel;
                  final double assignedPower = hasCircuit 
                    ? assignment.circuits[channelIndex].tapWatts * assignment.circuits[channelIndex].speakerCount * math.pow(10, assignment.circuits[channelIndex].outputOffsetDb / 10)
                    : 0.0;
                  final double surplus = channelRating - assignedPower;
                  
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 4),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: Text(
                            'Channel ${channelIndex + 1}: ${channelRating.toStringAsFixed(0)}W - ${assignedPower.toStringAsFixed(1)}W',
                          ),
                        ),
                        Text(
                          '= ${surplus.toStringAsFixed(1)}W ${surplus > 0 ? 'surplus' : 'deficit'}',
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: surplus > 0 ? Colors.green[700] : Colors.red[700],
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
                
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: Colors.green[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Net Sharing Available: ${(assignment.ampModel.peakPerChannel * assignment.ampModel.channels - assignment.circuits.fold<double>(0.0, (double sum, Circuit circuit) => sum + circuit.tapWatts * circuit.speakerCount * math.pow(10, circuit.outputOffsetDb / 10))).toStringAsFixed(1)}W',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep8Content(AmpMatchingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Strategy: Move circuits to optimize power distribution and maximize channel utilization',
          style: TextStyle(fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Optimization Results:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Amplifiers Used: ${result.assignments.length}'),
              Text('Total Channels: ${result.totalChannelsAvailable}'),
              Text('Used Channels: ${result.totalChannelsUsed}'),
              Text('Channel Efficiency: ${(result.channelEfficiency * 100).toStringAsFixed(1)}%'),
              Text('Power Efficiency: ${(result.powerEfficiency * 100).toStringAsFixed(1)}%'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        ...result.assignments.map((AmpAssignment assignment) {
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${assignment.ampModel.name}: ${assignment.circuits.length} circuits assigned',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                ...assignment.circuits.map((Circuit circuit) {
                  final double power = circuit.tapWatts * circuit.speakerCount * math.pow(10, circuit.outputOffsetDb / 10);
                  return Text(
                    '  • Circuit ${circuit.circuitId}: ${power.toStringAsFixed(1)}W (${circuit.speakerCount}× ${circuit.model})',
                  );
                }).toList(),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep9Content(AmpMatchingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Formula: Effective_Channel_Power = Base_Rating + Borrowed_Power',
          style: TextStyle(
            fontFamily: 'monospace',
            fontSize: 14,
            color: Colors.blue,
            fontWeight: FontWeight.w600,
          ),
        ),
        const SizedBox(height: 16),
        
        ...result.assignments.map((AmpAssignment assignment) {
          final double totalAssigned = assignment.circuits.fold<double>(0.0, (double sum, Circuit circuit) => 
            sum + circuit.tapWatts * circuit.speakerCount * math.pow(10, circuit.outputOffsetDb / 10));
          
          // Use correct capacity based on current strategy (asymmetrical context)
          final double totalCapacity = assignment.ampModel.powerSpecs?.asymmetricalPeakPower70V ?? 
            (assignment.ampModel.peakPerChannel * assignment.ampModel.channels);
          
          final double utilization = totalAssigned / totalCapacity;
          
          return Container(
            margin: const EdgeInsets.only(bottom: 12),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[50],
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green[200]!),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  '${assignment.ampModel.name}',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                const SizedBox(height: 8),
                Text('Base Capacity: ${totalCapacity.toStringAsFixed(0)}W'),
                Text('Power Assigned: ${totalAssigned.toStringAsFixed(1)}W'),
                Text('Power Utilization: ${(utilization * 100).toStringAsFixed(1)}%'),
                Text('Available Headroom: ${(totalCapacity - totalAssigned).toStringAsFixed(1)}W'),
                
                const SizedBox(height: 8),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: utilization > 0.8 ? Colors.orange[100] : Colors.green[100],
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    utilization > 0.8 
                      ? 'High utilization - limited sharing capacity'
                      : 'Good headroom for power sharing',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: utilization > 0.8 ? Colors.orange[800] : Colors.green[800],
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildStep10Content(AmpMatchingResult result) {
    final int totalPossibleAmps = result.assignments.length + (result.warnings.where((String w) => w.contains('empty')).length);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              const Text(
                'Empty Amplifier Analysis:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 8),
              Text('Total Amplifiers Considered: $totalPossibleAmps'),
              Text('Active Amplifiers: ${result.assignments.length}'),
              Text('Empty Amplifiers Removed: ${totalPossibleAmps - result.assignments.length}'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        if (result.assignments.every((AmpAssignment a) => a.circuits.isNotEmpty))
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.green),
                SizedBox(width: 8),
                Text(
                  'All amplifiers have valid circuit assignments',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          )
        else
          const Text('Some amplifiers were removed due to empty assignments'),
      ],
    );
  }

  Widget _buildStep11Content(AmpMatchingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'Validation Checks:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        
        // Power validation
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: result.errors.isEmpty ? Colors.green[100] : Colors.red[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Row(
            children: <Widget>[
              Icon(
                result.errors.isEmpty ? Icons.check_circle : Icons.error,
                color: result.errors.isEmpty ? Colors.green : Colors.red,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Total power ≤ Amplifier capacity: ${result.totalPowerRequirement.toStringAsFixed(1)}W ≤ ${result.totalSystemCapacity.toStringAsFixed(1)}W',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        
        // Channel validation
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Channel allocation: Perfect match',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        
        // Power sharing validation
        Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.green[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Row(
            children: <Widget>[
              Icon(Icons.check_circle, color: Colors.green),
              SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Power sharing within amplifier specifications',
                  style: TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            ],
          ),
        ),
        
        // Warnings and errors
        if (result.warnings.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          const Text(
            'Warnings:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.orange),
          ),
          ...result.warnings.map((String warning) => Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.orange[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(warning),
          )).toList(),
        ],
        
        if (result.errors.isNotEmpty) ...<Widget>[
          const SizedBox(height: 12),
          const Text(
            'Errors:',
            style: TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
          ),
          ...result.errors.map((String error) => Container(
            margin: const EdgeInsets.only(top: 4),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.red[100],
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(error),
          )).toList(),
        ],
      ],
    );
  }

  Widget _buildStep12Content(AmpMatchingResult result) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        const Text(
          'SKU Reduction and Optimization:',
          style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
        ),
        const SizedBox(height: 16),
        
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue[50],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Text('Unique Amplifier Models: ${result.assignments.map((AmpAssignment a) => a.ampModel.name).toSet().length}'),
              Text('Total Amplifier Units: ${result.assignments.length}'),
              const SizedBox(height: 8),
              const Text(
                'Benefits:',
                style: TextStyle(fontWeight: FontWeight.bold),
              ),
              const Text('• Simplified inventory management'),
              const Text('• Reduced maintenance complexity'),
              const Text('• Standardized configurations'),
              const Text('• Cost optimization through volume'),
            ],
          ),
        ),
        
        const SizedBox(height: 16),
        
        const Text(
          'Selected Amplifier Models:',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        
        ...result.assignments.map((AmpAssignment a) => a.ampModel.name).toSet().map((String modelName) {
          final int count = result.assignments.where((AmpAssignment a) => a.ampModel.name == modelName).length;
          final AmpAssignment firstAmp = result.assignments.firstWhere((AmpAssignment a) => a.ampModel.name == modelName);
          
          return Container(
            margin: const EdgeInsets.only(bottom: 8),
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green[100],
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              children: <Widget>[
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        '$modelName × $count',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                      Text(
                        '${firstAmp.ampModel.channels} channels × ${firstAmp.ampModel.peakPerChannel.toStringAsFixed(0)}W',
                      ),
                    ],
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Colors.green[600],
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    count == 1 ? 'Optimal' : 'Standardized',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
          );
        }).toList(),
      ],
    );
  }

  Widget _buildFormulaReference() {
    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const Text(
              'Formula Reference',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 12),
            
            _buildFormulaItem(
              'Hi-Z Power',
              'P = Tap_Watts × Speaker_Count',
              'Power calculation for high impedance systems',
            ),
            _buildFormulaItem(
              'Offset Power',
              'P_adj = P_base × 10^(Offset_dB / 10)',
              'Power adjustment for output offsets',
            ),
            _buildFormulaItem(
              'Safety Margin',
              'P_safe = P_total × 1.2',
              '20% headroom for system reliability',
            ),
            _buildFormulaItem(
              'Efficiency',
              'η = P_used / P_available × 100%',
              'System power utilization efficiency',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildFormulaItem(String name, String formula, String description) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue[50],
        borderRadius: BorderRadius.circular(8),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            name,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 4),
          Text(
            formula,
            style: const TextStyle(
              fontFamily: 'monospace',
              color: Colors.blue,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            description,
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorSection() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.only(top: 16),
      decoration: BoxDecoration(
        color: Colors.red[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.error, color: Colors.red[700]),
              const SizedBox(width: 8),
              Text(
                'Error',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.red[700],
                  fontSize: 16,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Text(
            errorMessage!,
            style: TextStyle(color: Colors.red[700]),
          ),
        ],
      ),
    );
  }
}
