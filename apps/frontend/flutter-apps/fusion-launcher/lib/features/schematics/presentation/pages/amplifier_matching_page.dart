import 'dart:math';

import 'package:flutter/material.dart';

import '../../../../core/models/amplifer.dart';

class SpeakerForAmp {
  final String name;
  final String type;
  final double peakPower;
  final double impedance;
  final String imagePath;

  const SpeakerForAmp({
    required this.name,
    required this.type,
    required this.peakPower,
    required this.impedance,
    required this.imagePath,
  });
}

class SpeakerInstance {
  final SpeakerForAmp speaker;
  int quantity;

  SpeakerInstance({
    required this.speaker,
    this.quantity = 1,
  });
}

class CircuitForAmp {
  final String name;
  bool isHighZ;
  double offsetDb;
  final List<SpeakerInstance> speakers;
  double? calculatedPeakPower;
  double? calculatedImpedance;
  String? impedanceError;
  bool isExpanded;

  CircuitForAmp({
    required this.name,
    this.isHighZ = false,
    this.offsetDb = 0.0,
    List<SpeakerInstance>? speakers,
    this.calculatedPeakPower,
    this.calculatedImpedance,
    this.impedanceError,
    this.isExpanded = false,
  }) : speakers = speakers ?? <SpeakerInstance>[];
}

class AmplifierMatchingPage extends StatefulWidget {
  const AmplifierMatchingPage({super.key});

  @override
  AmplifierMatchingPageState createState() => AmplifierMatchingPageState();
}

class AmplifierMatchingPageState extends State<AmplifierMatchingPage> {
  final List<CircuitForAmp> _circuits = <CircuitForAmp>[];

  static const List<SpeakerForAmp> _availableSpeakers = <SpeakerForAmp>[
    SpeakerForAmp(
      name: 'DM8SE',
      type: 'Surface Mount',
      peakPower: 150.0,
      impedance: 8.0,
      imagePath: 'assets/images/speakers/designmax_dm8se.png',
    ),
    SpeakerForAmp(
      name: 'DM10S',
      type: 'Surface Mount',
      peakPower: 1200.0,
      impedance: 8.0,
      imagePath: 'assets/images/speakers/designmax_dm8se.png',
    ),

    SpeakerForAmp(
      name: 'DM6C',
      type: 'Ceiling Mount',
      peakPower: 125.0,
      impedance: 8.0,
      imagePath: 'assets/images/speakers/freespace_designmax_1.png',
    ),
    SpeakerForAmp(
      name: 'DM2C',
      type: 'Ceiling Mount',
      peakPower: 80.0,
      impedance: 16.0,
      imagePath: 'assets/images/speakers/freespace_designmax_1.png',
    ),
    SpeakerForAmp(
      name: 'DM3C',
      type: 'Ceiling Mount',
      peakPower: 120.0,
      impedance: 8.0,
      imagePath: 'assets/images/speakers/freespace_designmax_1.png',
    ),
    SpeakerForAmp(
      name: 'DM5C',
      type: 'Ceiling Mount',
      peakPower: 240.0,
      impedance: 8.0,
      imagePath: 'assets/images/speakers/freespace_designmax_1.png',
    ),
  ];

  static  final List<Amplifier> _availableAmplifiers = <Amplifier>[
    Amplifier(
      name: 'PSX1204D',
      channels: 4,
      powerPerChannel: 600,
      color: Colors.blue,
    ),
    Amplifier(
      name: 'PSX2404D',
      channels: 4,
      powerPerChannel: 1200,
      color: Colors.green,
    ),
    Amplifier(
      name: 'PSX4804D',
      channels: 4,
      powerPerChannel: 2400,
      color: Colors.orange,
    ),
  ];

  @override
  void initState() {
    super.initState();
    //_addCircuit();
  }

  void _addCircuit() {
    setState(() {
      _circuits.add(
        CircuitForAmp(
          name: 'Circuit ${_circuits.length + 1}',
          isExpanded: true,
        ),
      );
    });
  }

  void _removeCircuit(int index) {
    if (_circuits.isNotEmpty) {
      setState(() {
        _circuits.removeAt(index);
      });
    }
  }

  void _addSpeakerToCircuit(int circuitIndex, SpeakerForAmp speaker) {
    final CircuitForAmp circuit = _circuits[circuitIndex];
    final int existingIndex = circuit.speakers.indexWhere((SpeakerInstance s) => s.speaker == speaker);

    setState(() {
      if (existingIndex >= 0) {
        circuit.speakers[existingIndex].quantity++;
      } else {
        circuit.speakers.add(SpeakerInstance(speaker: speaker));
      }
      _calculateCircuitPower(circuit);
    });
  }

  void _updateSpeakerQuantity(int circuitIndex, int speakerIndex, int quantity) {
    final CircuitForAmp circuit = _circuits[circuitIndex];
    setState(() {
      if (quantity <= 0) {
        circuit.speakers.removeAt(speakerIndex);
      } else {
        circuit.speakers[speakerIndex].quantity = quantity;
      }
      _calculateCircuitPower(circuit);
    });
  }

  void _updateCircuitSettings(int circuitIndex, {bool? isHighZ, double? offsetDb}) {
    setState(() {
      final CircuitForAmp circuit = _circuits[circuitIndex];
      if (isHighZ != null) circuit.isHighZ = isHighZ;
      if (offsetDb != null) circuit.offsetDb = offsetDb;
      _calculateCircuitPower(circuit);
    });
  }

  void _calculateCircuitPower(CircuitForAmp circuit) {
    double sumRms = 0.0;
    final List<double> impedances = <double>[];

    for (final SpeakerInstance speakerInstance in circuit.speakers) {
      final double totalPower = speakerInstance.speaker.peakPower * speakerInstance.quantity;
      sumRms += totalPower;

      if (!circuit.isHighZ) {
        for (int i = 0; i < speakerInstance.quantity; i++) {
          impedances.add(speakerInstance.speaker.impedance);
        }
      }
    }

    double rawPeak;
    double? combinedImpedance;
    String? impedanceError;

    if (circuit.isHighZ) {
      rawPeak = 2 * sumRms;
      combinedImpedance = null;
      impedanceError = null;
    } else {
      rawPeak = sumRms;

      if (impedances.isEmpty) {
        combinedImpedance = null;
        impedanceError = null;
      } else {
        double reciprocalSum = 0.0;
        for (final double z in impedances) {
          reciprocalSum += 1 / z;
        }
        combinedImpedance = reciprocalSum > 0 ? 1 / reciprocalSum : 0.0;

        if (combinedImpedance < 4.0) {
          impedanceError = 'Combined impedance ${combinedImpedance.toStringAsFixed(1)}Ω < 4Ω min';
        } else {
          impedanceError = null;
        }
      }
    }

    final double reducedPeak = rawPeak * pow(10, -circuit.offsetDb / 10);

    circuit.calculatedPeakPower = reducedPeak;
    circuit.calculatedImpedance = combinedImpedance;
    circuit.impedanceError = impedanceError;
  }

  double get _totalSystemPower {
    return _circuits.fold(0.0, (double sum, CircuitForAmp circuit) => sum + (circuit.calculatedPeakPower ?? 0.0));
  }

  Widget _buildSpeakerImage(SpeakerForAmp speaker, {double size = 60}) {
    return SizedBox(
      width: size,
      height: size,
      child: Image.asset(
        speaker.imagePath,
        fit: BoxFit.cover,
      ),
    );
  }

  Widget _buildSpeakerLibrary() {
    return Container(
      width: 200,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        border: Border(right: BorderSide(color: Colors.grey.shade200)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Speaker Library',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade800,
            ),
          ),
          const SizedBox(height: 16),
          Expanded(
            child: ListView.builder(
              itemCount: _availableSpeakers.length,
              itemBuilder: (BuildContext context, int index) {
                final SpeakerForAmp speaker = _availableSpeakers[index];
                return Container(
                  margin: const EdgeInsets.only(bottom: 12),
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(6),
                    border: Border.all(color: Colors.grey.shade300),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Row(
                        children: <Widget>[
                          _buildSpeakerImage(speaker, size: 40),
                          const SizedBox(width: 8),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                Text(
                                  speaker.name,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  speaker.type,
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: Colors.grey.shade600,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: <Widget>[
                          Text(
                            '${speaker.peakPower.toInt()}W',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          Text(
                            '${speaker.impedance.toInt()}Ω',
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Drag to circuits →',
                        style: TextStyle(
                          fontSize: 10,
                          color: Colors.grey.shade500,
                          fontStyle: FontStyle.italic,
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCircuitCard(int index) {
    final CircuitForAmp circuit = _circuits[index];

    final bool hasWarning = circuit.impedanceError != null && circuit.impedanceError!.contains('CRITICAL');
    final bool isOversized = circuit.impedanceError != null && circuit.impedanceError!.contains('OVERSIZED');

    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color:
              isOversized
                  ? Colors.red.shade400
                  : hasWarning
                  ? Colors.red.shade300
                  : Colors.grey.shade300,
          width: (hasWarning || isOversized) ? 2 : 1,
          strokeAlign: BorderSide.strokeAlignOutside,
        ),
      ),
      child: Column(
        children: <Widget>[
          GestureDetector(
            onTap: () => setState(() => circuit.isExpanded = !circuit.isExpanded),
            child: Container(
              padding: const EdgeInsets.all(16),
              child: Row(
                children: <Widget>[
                  Icon(
                    circuit.isExpanded ? Icons.expand_less : Icons.expand_more,
                    color: Colors.grey.shade600,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Text(
                              circuit.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: circuit.isHighZ ? Colors.orange.shade100 : Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(3),
                              ),
                              child: Text(
                                circuit.isHighZ ? 'High-Z' : 'Low-Z',
                                style: TextStyle(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w500,
                                  color: circuit.isHighZ ? Colors.orange.shade700 : Colors.blue.shade700,
                                ),
                              ),
                            ),
                            if (circuit.offsetDb != 0) ...<Widget>[
                              const SizedBox(width: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                decoration: BoxDecoration(
                                  color: Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(3),
                                ),
                                child: Text(
                                  '-${circuit.offsetDb}dB',
                                  style: TextStyle(
                                    fontSize: 10,
                                    fontWeight: FontWeight.w500,
                                    color: Colors.grey.shade700,
                                  ),
                                ),
                              ),
                            ],
                            if (isOversized) ...<Widget>[
                              const SizedBox(width: 8),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade100,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Icon(Icons.error, size: 12, color: Colors.red.shade700),
                                    const SizedBox(width: 4),
                                    Text(
                                      'OVERSIZED',
                                      style: TextStyle(
                                        fontSize: 10,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.red.shade700,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ],
                          ],
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: <Widget>[
                            if (circuit.calculatedPeakPower != null)
                              Text(
                                'Power: ${circuit.calculatedPeakPower!.toStringAsFixed(1)}W',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            if (!circuit.isHighZ && circuit.calculatedImpedance != null) ...<Widget>[
                              const SizedBox(width: 16),
                              Text(
                                'Impedance: ${circuit.calculatedImpedance!.toStringAsFixed(1)}Ω',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: Colors.grey.shade700,
                                ),
                              ),
                            ],
                          ],
                        ),
                        if (circuit.speakers.isNotEmpty) ...<Widget>[
                          const SizedBox(height: 8),
                          Wrap(
                            spacing: 4,
                            children:
                                circuit.speakers.map((SpeakerInstance speakerInstance) {
                                  return Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: <Widget>[
                                      _buildSpeakerImage(speakerInstance.speaker, size: 16),
                                      const SizedBox(width: 4),
                                      Text(
                                        '${speakerInstance.quantity}x',
                                        style: const TextStyle(fontSize: 11),
                                      ),
                                    ],
                                  );
                                }).toList(),
                          ),
                        ],
                      ],
                    ),
                  ),
                  // if (_circuits.length > 1)
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: Colors.red.shade400),
                    onPressed: () => _removeCircuit(index),
                    constraints: const BoxConstraints(minWidth: 32, minHeight: 32),
                  ),
                ],
              ),
            ),
          ),
          if (circuit.isExpanded) ...<Widget>[
            Divider(height: 1, color: Colors.grey.shade300),
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  _buildCircuitSettings(index),
                  const SizedBox(height: 16),
                  _buildCircuitSpeakers(index),
                  const SizedBox(height: 16),
                  _buildSpeakerDropZone(index),
                  if (circuit.impedanceError != null) ...<Widget>[
                    const SizedBox(height: 12),
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.red.shade50,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.red.shade200),
                      ),
                      child: Row(
                        children: <Widget>[
                          Icon(Icons.warning_amber, size: 14, color: Colors.red.shade600),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              circuit.impedanceError!,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.red.shade700,
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
          ],
        ],
      ),
    );
  }

  Widget _buildCircuitSettings(int circuitIndex) {
    final CircuitForAmp circuit = _circuits[circuitIndex];
    final TextEditingController offsetController = TextEditingController(text: circuit.offsetDb.toString());

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Settings',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 12),
        Row(
          children: <Widget>[
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Text(
                    'Impedance Mode',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.grey.shade600,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Container(
                    decoration: BoxDecoration(
                      borderRadius: BorderRadius.circular(4),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: <Widget>[
                        _buildToggleButton('Low-Z', !circuit.isHighZ, () {
                          _updateCircuitSettings(circuitIndex, isHighZ: false);
                        }),
                        _buildToggleButton('High-Z', circuit.isHighZ, () {
                          _updateCircuitSettings(circuitIndex, isHighZ: true);
                        }),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Offset (dB)',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 6),
                SizedBox(
                  width: 80,
                  child: TextField(
                    controller: offsetController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: const TextStyle(fontSize: 12),
                    onSubmitted: (String value) {
                      final double offsetDb = double.tryParse(value) ?? 0.0;
                      _updateCircuitSettings(circuitIndex, offsetDb: offsetDb);
                    },
                    decoration: InputDecoration(
                      hintText: '0.0',
                      hintStyle: TextStyle(fontSize: 11, color: Colors.grey.shade500),
                      prefixText: "- ",
                      prefixStyle: TextStyle(fontSize: 12, color: Colors.grey.shade600),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      enabledBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade300),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(4),
                        borderSide: BorderSide(color: Colors.grey.shade600),
                      ),
                      filled: true,
                      fillColor: Colors.white,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ],
    );
  }

  Widget _buildCircuitSpeakers(int circuitIndex) {
    final CircuitForAmp circuit = _circuits[circuitIndex];

    if (circuit.speakers.isEmpty) {
      return Text(
        'No speakers added',
        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          'Speakers:',
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w500,
            color: Colors.grey.shade700,
          ),
        ),
        const SizedBox(height: 8),
        ...circuit.speakers.asMap().entries.map((MapEntry<int, SpeakerInstance> entry) {
          final int speakerIndex = entry.key;
          final SpeakerInstance speakerInstance = entry.value;
          final SpeakerForAmp speaker = speakerInstance.speaker;

          return Container(
            margin: const EdgeInsets.only(bottom: 6),
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              borderRadius: BorderRadius.circular(4),
              border: Border.all(color: Colors.grey.shade200),
            ),
            child: Row(
              children: <Widget>[
                _buildSpeakerImage(speaker, size: 24),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      Text(
                        speaker.name,
                        style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w500),
                      ),
                      Text(
                        '${speaker.peakPower.toInt()}W / ${speaker.impedance.toInt()}Ω',
                        style: TextStyle(fontSize: 10, color: Colors.grey.shade600),
                      ),
                    ],
                  ),
                ),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    IconButton(
                      icon: Icon(Icons.remove, size: 14, color: Colors.grey.shade600),
                      onPressed: () => _updateSpeakerQuantity(circuitIndex, speakerIndex, speakerInstance.quantity - 1),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: EdgeInsets.zero,
                    ),
                    SizedBox(
                      width: 24,
                      child: Text(
                        speakerInstance.quantity.toString(),
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                      ),
                    ),
                    IconButton(
                      icon: Icon(Icons.add, size: 14, color: Colors.grey.shade600),
                      onPressed: () => _updateSpeakerQuantity(circuitIndex, speakerIndex, speakerInstance.quantity + 1),
                      constraints: const BoxConstraints(minWidth: 24, minHeight: 24),
                      padding: EdgeInsets.zero,
                    ),
                  ],
                ),
              ],
            ),
          );
        }),
      ],
    );
  }

  Widget _buildSpeakerDropZone(int circuitIndex) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(6),
        border: Border.all(color: Colors.blue.shade200, style: BorderStyle.solid),
      ),
      child: Row(
        children: <Widget>[
          Wrap(
            spacing: 8,
            children:
                _availableSpeakers.map((SpeakerForAmp speaker) {
                  return GestureDetector(
                    onTap: () => _addSpeakerToCircuit(circuitIndex, speaker),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.blue.shade300),
                      ),
                      child: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          _buildSpeakerImage(speaker, size: 16),
                          const SizedBox(width: 4),
                          Text(
                            speaker.name.split(' ').take(2).join(' '),
                            style: TextStyle(
                              fontSize: 10,
                              color: Colors.blue.shade700,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          const SizedBox(width: 4),
                          Icon(Icons.add_circle_outline, color: Colors.blue.shade600, size: 16),
                        ],
                      ),
                    ),
                  );
                }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildToggleButton(String label, bool isSelected, VoidCallback onTap) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
        decoration: BoxDecoration(
          color: isSelected ? Colors.grey.shade800 : Colors.transparent,
          borderRadius: BorderRadius.circular(3),
        ),
        child: Text(
          label,
          style: TextStyle(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: isSelected ? Colors.white : Colors.grey.shade600,
          ),
        ),
      ),
    );
  }

  Widget _buildTotalPowerDisplay() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: const BoxDecoration(
        color: Colors.orange,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: <Widget>[
          const Text(
            'Total Power',
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Colors.white,
            ),
          ),
          Text(
            '${_totalSystemPower.toStringAsFixed(1)} W',
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Amplifier Matching'),
        backgroundColor: Colors.white,
        foregroundColor: Colors.grey.shade800,
        elevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: <Widget>[
          if (_circuits.isNotEmpty)
            TextButton.icon(
              icon: Icon(Icons.add, size: 16, color: Colors.grey.shade600),
              label: Text(
                'Add Circuit',
                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
              ),
              onPressed: _addCircuit,
            ),
        ],
      ),
      body: Column(
        children: <Widget>[
          Expanded(
            child: Row(
              children: <Widget>[
                // _buildSpeakerLibrary(),
                if (_circuits.isEmpty) ...<Widget>[
                  Expanded(
                    child: Center(
                      child: TextButton.icon(
                        icon: Icon(Icons.add, size: 18, color: Colors.grey.shade600),
                        label: Text(
                          'Add Circuit',
                          style: TextStyle(fontSize: 16, color: Colors.grey.shade600),
                        ),
                        onPressed: _addCircuit,
                      ),
                    ),
                  ),
                ] else
                  Expanded(
                    child: ListView.builder(
                      padding: const EdgeInsets.all(16),
                      itemCount: _circuits.length,
                      itemBuilder: (BuildContext context, int index) => _buildCircuitCard(index),
                    ),
                  ),
                _buildAmplifiersDisplay(),
              ],
            ),
          ),
          // _buildTotalPowerDisplay(),
        ],
      ),
    );
  }

  /// Returns a list of AmplifierAssignment using the same logic
  /// you already have in your state.
  List<AmplifierAssignment> _calculateAmplifierRequirements() {
    if (_circuits.isEmpty) return <AmplifierAssignment>[];

    final List<CircuitForAmp> sortedCircuits = List<CircuitForAmp>.from(_circuits)
      ..sort((CircuitForAmp a, CircuitForAmp b) => (b.calculatedPeakPower ?? 0).compareTo(a.calculatedPeakPower ?? 0));

    final List<AmplifierAssignment> assignments = <AmplifierAssignment>[];
    final List<CircuitForAmp> remainingCircuits = List<CircuitForAmp>.from(sortedCircuits);

    while (remainingCircuits.isNotEmpty) {
      final CircuitForAmp highestPowerCircuit = remainingCircuits.first;
      final double circuitPower = highestPowerCircuit.calculatedPeakPower ?? 0;

      Amplifier? selectedAmp;

      for (final Amplifier amp in _availableAmplifiers) {
        if (amp.powerPerChannel >= circuitPower) {
          selectedAmp = amp;
          break;
        }
      }

      if (selectedAmp == null) {
        selectedAmp = _availableAmplifiers.last;
        // Mark the circuit as oversized for UI warnings
        highestPowerCircuit.impedanceError =
            'OVERSIZED: Circuit requires ${circuitPower.toStringAsFixed(1)}W but maximum amplifier capacity is ${selectedAmp.powerPerChannel.toStringAsFixed(0)}W per channel';
      }

      final List<CircuitForAmp> assignedToThisAmp = <CircuitForAmp>[highestPowerCircuit];
      remainingCircuits.removeAt(0);

      int usedChannels = 1;
      double totalAssignedPower = circuitPower;

      while (usedChannels < selectedAmp.channels && remainingCircuits.isNotEmpty) {
        bool foundFit = false;

        for (int i = 0; i < remainingCircuits.length; i++) {
          final CircuitForAmp circuit = remainingCircuits[i];
          final double power = circuit.calculatedPeakPower ?? 0;

          if (power <= selectedAmp.powerPerChannel) {
            assignedToThisAmp.add(circuit);
            remainingCircuits.removeAt(i);
            usedChannels++;
            totalAssignedPower += power;
            foundFit = true;
            break;
          }
        }

        if (!foundFit) break;
      }

      assignments.add(
        AmplifierAssignment(
          amplifier: selectedAmp,
          assignedCircuits: assignedToThisAmp,
          usedChannels: usedChannels,
          totalAssignedPower: totalAssignedPower,
        ),
      );
    }

    return assignments;
  }

  /// Builds a scrolling column of your recommended amps.
  /// You can place this widget in your main `Row` on the right side.
  Widget _buildAmplifiersDisplay() {
    final List<AmplifierAssignment> assignments = _calculateAmplifierRequirements();

    return Container(
      width: 240,
      padding: const EdgeInsets.all(16),
      margin: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: Colors.grey.shade300,
          style: BorderStyle.solid,
        ),
      ),
      child:
          assignments.isEmpty || _totalSystemPower == 0
              ? Center(
                child: Text(
                  'Add speakers to see amplifier recommendations',
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                  ),
                  textAlign: TextAlign.center,
                ),
              )
              : Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Row(
                    children: <Widget>[
                      Icon(Icons.memory, size: 18, color: Colors.grey.shade600),
                      const SizedBox(width: 8),
                      Text(
                        'Amplifiers',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade800,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Expanded(
                    child: ListView.builder(
                      itemCount: assignments.length,
                      itemBuilder: (BuildContext ctx, int i) {
                        final AmplifierAssignment a = assignments[i];

                        final bool hasOversizedCircuits = a.assignedCircuits.any(
                          (CircuitForAmp circuit) => circuit.impedanceError != null && circuit.impedanceError!.contains('OVERSIZED'),
                        );

                        return Container(
                          margin: const EdgeInsets.only(bottom: 12),
                          child: Material(
                            color: hasOversizedCircuits ? Colors.red.shade100 : Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            elevation: 1,
                            child: Padding(
                              padding: const EdgeInsets.all(12),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Row(
                                    children: <Widget>[
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: hasOversizedCircuits ? Colors.red.shade500 : a.amplifier.color,
                                          borderRadius: BorderRadius.circular(3),
                                        ),
                                        child: Text(
                                          'AMP ${i + 1}',
                                          style: const TextStyle(
                                            fontSize: 9,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      Expanded(
                                        child: Text(
                                          a.amplifier.name.replaceAll('PowerMatch ', ''),
                                          style: TextStyle(
                                            fontSize: 13,
                                            fontWeight: FontWeight.w600,
                                            color: a.amplifier.color.shade700,
                                          ),
                                          maxLines: 1,
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      ),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  Row(
                                    children: <Widget>[
                                      _buildSpecBadge('${a.amplifier.powerPerChannel.toStringAsFixed(0)}W/ch', Colors.orange.shade100, Colors.orange.shade700),
                                      const SizedBox(width: 6),
                                      _buildSpecBadge('${a.amplifier.channels}ch', Colors.blue.shade100, Colors.blue.shade700),
                                    ],
                                  ),
                                  const SizedBox(height: 8),
                                  _buildStatRow(
                                    'Channels',
                                    '${a.usedChannels}/${a.amplifier.channels}',
                                    Icons.settings_input_component,
                                    Colors.blue.shade600,
                                  ),
                                  const SizedBox(height: 4),
                                  _buildStatRow(
                                    'Power',
                                    '${a.totalAssignedPower.toStringAsFixed(0)}W / ${a.amplifier.totalPower.toStringAsFixed(0)}W',
                                    Icons.flash_on,
                                    Colors.orange.shade600,
                                  ),
                                  // const SizedBox(height: 4),
                                  // _buildStatRow(
                                  //   'Efficiency',
                                  //   '${a.efficiency.toStringAsFixed(1)}%',
                                  //   Icons.eco,
                                  //   a.efficiency > 80 ? Colors.green.shade600 : Colors.amber.shade600,
                                  // ),
                                  if (a.assignedCircuits.isNotEmpty) ...<Widget>[
                                    const SizedBox(height: 8),
                                    Text(
                                      'Circuits:',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.w600,
                                        color: Colors.grey.shade700,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Wrap(
                                      spacing: 4,
                                      runSpacing: 4,
                                      children:
                                          a.assignedCircuits.map((CircuitForAmp circuit) {
                                            return Container(
                                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                              decoration: BoxDecoration(
                                                color: Colors.grey.shade100,
                                                borderRadius: BorderRadius.circular(8),
                                              ),
                                              child: Text(
                                                circuit.name.replaceAll('Circuit ', 'C'),
                                                style: TextStyle(
                                                  fontSize: 9,
                                                  fontWeight: FontWeight.w500,
                                                  color: Colors.grey.shade700,
                                                ),
                                              ),
                                            );
                                          }).toList(),
                                    ),
                                  ],
                                  if (a.unusedChannels > 0) ...<Widget>[
                                    const SizedBox(height: 6),
                                    Container(
                                      padding: const EdgeInsets.all(6),
                                      decoration: BoxDecoration(
                                        color: Colors.amber.shade50,
                                        borderRadius: BorderRadius.circular(4),
                                        border: Border.all(color: Colors.amber.shade200),
                                      ),
                                      child: Row(
                                        children: <Widget>[
                                          Icon(Icons.info_outline, size: 12, color: Colors.amber.shade700),
                                          const SizedBox(width: 4),
                                          Expanded(
                                            child: Text(
                                              '${a.unusedChannels} unused',
                                              style: TextStyle(
                                                fontSize: 10,
                                                color: Colors.amber.shade700,
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
                      },
                    ),
                  ),
                  _buildTotalPowerDisplay(),
                ],
              ),
    );
  }

  // Helper methods (add these to your class):
  Widget _buildSpecBadge(String text, Color bgColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w600,
          color: textColor,
        ),
      ),
    );
  }

  Widget _buildStatRow(String label, String value, IconData icon, Color color) {
    return Row(
      children: <Widget>[
        Icon(icon, size: 12, color: color),
        const SizedBox(width: 4),
        Text(
          '$label: ',
          style: TextStyle(
            fontSize: 11,
            color: Colors.grey.shade600,
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w500,
              color: color,
            ),
          ),
        ),
      ],
    );
  }
}



class AmplifierAssignment {
  final Amplifier amplifier;
  final List<CircuitForAmp> assignedCircuits;
  final int usedChannels;
  final double totalAssignedPower;

  AmplifierAssignment({
    required this.amplifier,
    required this.assignedCircuits,
    required this.usedChannels,
    required this.totalAssignedPower,
  });

  double get efficiency => (totalAssignedPower / amplifier.totalPower) * 100;

  int get unusedChannels => amplifier.channels - usedChannels;
}
