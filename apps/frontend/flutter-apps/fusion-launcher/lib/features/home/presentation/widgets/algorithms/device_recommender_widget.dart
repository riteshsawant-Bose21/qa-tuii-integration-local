import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_algorithms/device_recommender/device_recommender.dart';

class DeviceRecommenderWidget extends StatefulWidget {
  const DeviceRecommenderWidget({super.key});

  @override
  State<DeviceRecommenderWidget> createState() => _DeviceRecommenderWidgetState();
}

class _DeviceRecommenderWidgetState extends State<DeviceRecommenderWidget>
    with TickerProviderStateMixin {
  late AnimationController _animationController;
  late Animation<double> _fadeAnimation;
  late Animation<Offset> _slideAnimation;

  // Analog Input state
  Map<String, int> analogInputs = <String, int>{
    'mics': 0,
    'line': 0,
    'rca': 0,
    'jack35': 0,
  };

  // Analog Output state (separated into line vs speakers)
  Map<String, int> analogOutputs = <String, int>{
    'lineOut': 0,      // Line-level outputs
    'speakers': 0,     // Loudspeaker/amplified outputs
  };

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 600),
      vsync: this,
    );
    _fadeAnimation = Tween<double>(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _slideAnimation = Tween<Offset>(
      begin: const Offset(0, -0.1),
      end: Offset.zero,
    ).animate(
      CurvedAnimation(parent: _animationController, curve: Curves.easeInOut),
    );
    _animationController.forward();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  String recommend() {
    try {
      // Calculate totals from the analog inputs map
      final int totalAnalogInputs = analogInputs['mics']! + analogInputs['line']! + analogInputs['rca']! + analogInputs['jack35']!;
      final int totalLineOutputs = analogOutputs['lineOut']!;
      final int totalLoudspeakerOutputs = analogOutputs['speakers']!;

      // Return empty if no inputs/outputs
      if (totalAnalogInputs == 0 && totalLineOutputs == 0 && totalLoudspeakerOutputs == 0) {
        return "Configure analog inputs and outputs to get recommendations";
      }

      // Create analog recommendation input using the new library
      final AnalogRecommendInput input = AnalogRecommendInput(
        analogInputs: totalAnalogInputs,
        lineOutputs: totalLineOutputs,
        loudspeakerOutputs: totalLoudspeakerOutputs,
      );

      // Get device recommendations from the new analog algorithm
      final List<String> devices = DeviceRecommender.recommendAnalogDevices(input);
      
      if (devices.isEmpty) {
        return "No suitable device configuration found";
      }
      
      return "Recommend: ${devices.join(' + ')}";
    } catch (e) {
      return "Error calculating recommendation: ${e.toString()}";
    }
  }

  void _clearAll() {
    setState(() {
      analogInputs = <String, int>{
        'mics': 0,
        'line': 0,
        'rca': 0,
        'jack35': 0,
      };
      analogOutputs = <String, int>{
        'lineOut': 0,
        'speakers': 0,
      };
    });
  }

  Widget _buildCompactSection({
    required String title,
    required List<Widget> children,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 8),
        ...children,
        const SizedBox(height: 16),
      ],
    );
  }

  Widget _buildCompactCounter(String label, int count, String key, IconData icon, {bool isOutput = false}) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(8),
        color: Colors.white,
      ),
      child: Row(
        children: <Widget>[
          Icon(icon, size: 20, color: Colors.grey.shade700),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
            ),
          ),
          Row(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              SizedBox(
                width: 32,
                height: 32,
                child: OutlinedButton(
                  onPressed: count > 0 ? () {
                    setState(() {
                      if (isOutput) {
                        analogOutputs[key] = (analogOutputs[key]! - 1).clamp(0, double.infinity).toInt();
                      } else {
                        analogInputs[key] = (analogInputs[key]! - 1).clamp(0, double.infinity).toInt();
                      }
                    });
                  } : null,
                  style: OutlinedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                  ),
                  child: const Text('-', style: TextStyle(fontSize: 16)),
                ),
              ),
              const SizedBox(width: 8),
              Container(
                width: 40,
                alignment: Alignment.center,
                child: Text(
                  count.toString(),
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
              ),
              const SizedBox(width: 8),
              SizedBox(
                width: 32,
                height: 32,
                child: ElevatedButton(
                  onPressed: () {
                    setState(() {
                      if (isOutput) {
                        analogOutputs[key] = analogOutputs[key]! + 1;
                      } else {
                        analogInputs[key] = analogInputs[key]! + 1;
                      }
                    });
                  },
                  style: ElevatedButton.styleFrom(
                    padding: EdgeInsets.zero,
                    minimumSize: const Size(32, 32),
                  ),
                  child: const Text('+', style: TextStyle(fontSize: 16)),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalAnalogIn = analogInputs['mics']! + analogInputs['line']! + analogInputs['rca']! + analogInputs['jack35']!;
    final int totalLineOut = analogOutputs['lineOut']!;
    final int totalSpeakers = analogOutputs['speakers']!;

    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            // Left Panel - Input Controls
            Expanded(
              flex: 2,
              child: SingleChildScrollView(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    // Title
                    SlideTransition(
                      position: _slideAnimation,
                      child: FadeTransition(
                        opacity: _fadeAnimation,
                        child: const Text(
                          'Analog I/O Calculator',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Analog Inputs Section
                    _buildCompactSection(
                      title: 'Analog Inputs',
                      children: <Widget>[
                        _buildCompactCounter('Mics', analogInputs['mics']!, 'mics', Icons.mic),
                        _buildCompactCounter('Line', analogInputs['line']!, 'line', Icons.music_note),
                        _buildCompactCounter('RCA', analogInputs['rca']!, 'rca', Icons.album),
                        _buildCompactCounter('3.5mm', analogInputs['jack35']!, 'jack35', Icons.radio),
                      ],
                    ),

                    // Analog Outputs Section (separated into line vs speakers)
                    _buildCompactSection(
                      title: 'Analog Outputs',
                      children: <Widget>[
                        _buildCompactCounter('Line Outputs', analogOutputs['lineOut']!, 'lineOut', Icons.volume_up, isOutput: true),
                        _buildCompactCounter('Loudspeakers', analogOutputs['speakers']!, 'speakers', Icons.speaker, isOutput: true),
                      ],
                    ),

                    // Clear Button
                    const SizedBox(height: 16),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: _clearAll,
                        child: const Text('Clear All'),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            const SizedBox(width: 24),

            // Right Panel - Live Recommendations
            Expanded(
              flex: 3,
              child: SizedBox(
                height: MediaQuery.of(context).size.height - 32,
                child: Card(
                  elevation: 4,
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        const Text(
                          'Live Recommendation',
                          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                        ),
                        const SizedBox(height: 16),

                        // Recommendation Result
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(16),
                          decoration: BoxDecoration(
                            color: Colors.blue.shade50,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.blue.shade200),
                          ),
                          child: Text(
                            recommend(),
                            style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
                            textAlign: TextAlign.center,
                          ),
                        ),

                        const SizedBox(height: 20),

                        // I/O Summary
                        Expanded(
                          child: SingleChildScrollView(
                            child: Container(
                              padding: const EdgeInsets.all(16),
                              decoration: BoxDecoration(
                                color: Colors.grey.shade50,
                                borderRadius: BorderRadius.circular(8),
                              ),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  const Text(
                                    'Current Configuration',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 12),
                            _buildSummaryRow('Analog Inputs', '$totalAnalogIn (Mic: ${analogInputs['mics']}, Line: ${analogInputs['line']}, RCA: ${analogInputs['rca']}, 3.5mm: ${analogInputs['jack35']})'),
                            _buildSummaryRow('Line Outputs', '$totalLineOut'),
                            _buildSummaryRow('Loudspeaker Outputs', '$totalSpeakers'),
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  
                                  const Text(
                                    'Scaling Algorithm Rules',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._buildScalingRules(),
                                  
                                  const SizedBox(height: 16),
                                  const Divider(),
                                  const SizedBox(height: 16),
                                  
                                  const Text(
                                    'Device Capabilities',
                                    style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                                  ),
                                  const SizedBox(height: 8),
                                  ..._buildCapabilitiesList(),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ],
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

  Widget _buildSummaryRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            '$label: ',
            style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCapabilityRow(String capability) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 1),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const Text('• ', style: TextStyle(fontSize: 13)),
          Expanded(
            child: Text(
              capability,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }

  List<Widget> _buildScalingRules() {
    final List<Widget> widgets = <Widget>[];
    
    final List<String> rules = <String>[
      '1. Always start with 4ch PowerSmart',
      '2. Input Scaling: More inputs than outputs → FM6 + PowerPure',
      '3. Equal Scaling: Equal inputs/outputs → PowerSmart series',
      '4. Output Scaling: More outputs than inputs → PowerSmart series',
    ];

    for (final String rule in rules) {
      widgets.add(_buildCapabilityRow(rule));
    }

    return widgets;
  }

  List<Widget> _buildCapabilitiesList() {
    final List<Widget> widgets = <Widget>[];
    
    // Add device capabilities with new analog I/O format
    final List<String> capabilities = <String>[
      '4ch PowerSmart → 4 Inputs + 4 Line Outputs + 4 Loudspeaker Outputs',
      '8ch PowerSmart → 8 Inputs + 8 Line Outputs + 8 Loudspeaker Outputs',
      'FM6 → 4 Inputs + 4 Line Outputs + 0 Loudspeaker Outputs',
      'FM8Y → 4 Inputs + 8 Line Outputs + 0 Loudspeaker Outputs',
    ];

    for (final String capability in capabilities) {
      widgets.add(_buildCapabilityRow(capability));
    }

    return widgets;
  }
}
