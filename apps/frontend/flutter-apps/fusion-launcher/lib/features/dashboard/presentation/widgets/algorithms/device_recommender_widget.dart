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

  // Input state
  Map<String, int> inputs = <String, int>{
    'mics': 0,
    'line': 0,
    'rca': 0,
    'jack35': 0,
    'aes67In': 0,
    'danteIn': 0,
  };

  // Output state
  Map<String, int> outputs = <String, int>{
    'speakers': 0,
    'lineOut': 0,
    'aes67Out': 0,
    'danteOut': 0,
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
      // Calculate totals from the inputs map
      final int totalAnalogInputs = inputs['mics']! + inputs['line']! + inputs['rca']! + inputs['jack35']!;
      final int totalNetworkInputs = inputs['aes67In']! + inputs['danteIn']!;
      final int totalAnalogOutputs = outputs['speakers']! + outputs['lineOut']!;
      final int totalNetworkOutputs = outputs['aes67Out']! + outputs['danteOut']!;
      final int bluetoothInputs = 0; // Bluetooth removed from UI

      // Return empty if no inputs/outputs
      if (totalAnalogInputs == 0 && totalAnalogOutputs == 0 && totalNetworkInputs == 0 && 
          totalNetworkOutputs == 0 && bluetoothInputs == 0) {
        return "Configure inputs and outputs to get recommendations";
      }

      // Create recommendation input using the library
      final RecommendInput input = RecommendInput(
        analogInputs: totalAnalogInputs,
        analogOutputs: totalAnalogOutputs,
        networkInputs: totalNetworkInputs,
        networkOutputs: totalNetworkOutputs,
        bluetoothInputs: bluetoothInputs,
      );

      // Get device recommendations from the library
      final List<String> devices = DeviceRecommender.recommendDevices(input);
      
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
      inputs = <String, int>{
        'mics': 0,
        'line': 0,
        'rca': 0,
        'jack35': 0,
        'aes67In': 0,
        'danteIn': 0,
      };
      outputs = <String, int>{
        'speakers': 0,
        'lineOut': 0,
        'aes67Out': 0,
        'danteOut': 0,
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
                        outputs[key] = (outputs[key]! - 1).clamp(0, double.infinity).toInt();
                      } else {
                        inputs[key] = (inputs[key]! - 1).clamp(0, double.infinity).toInt();
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
                        outputs[key] = outputs[key]! + 1;
                      } else {
                        inputs[key] = inputs[key]! + 1;
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

  Widget _buildIconCounter({
    required String label,
    required int count,
    required VoidCallback onIncrement,
    required VoidCallback onDecrement,
    required IconData icon,
    double height = 160.0, // Add height parameter with default
  }) {
    return SizedBox(
      height: height,
      width: double.infinity, // Ensures it fills the grid cell
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey.shade300),
          borderRadius: BorderRadius.circular(16),
          color: Colors.white,
          boxShadow: <BoxShadow>[
            BoxShadow(
              color: Colors.grey.shade200,
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: <Widget>[
            Icon(icon, size: height < 140 ? 24 : 32, color: Colors.grey.shade700), // Smaller icon for smaller cards
            Text(
              label,
              style: TextStyle(fontSize: height < 140 ? 10 : 12, fontWeight: FontWeight.w500),
              textAlign: TextAlign.center,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              count.toString(),
              style: TextStyle(fontSize: height < 140 ? 16 : 20, fontWeight: FontWeight.bold),
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                SizedBox(
                  width: height < 140 ? 28 : 32,
                  height: height < 140 ? 28 : 32,
                  child: OutlinedButton(
                    onPressed: count > 0 ? onDecrement : null,
                    style: OutlinedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(height < 140 ? 28 : 32, height < 140 ? 28 : 32),
                    ),
                    child: Text('-', style: TextStyle(fontSize: height < 140 ? 14 : 16)),
                  ),
                ),
                const SizedBox(width: 8),
                SizedBox(
                  width: height < 140 ? 28 : 32,
                  height: height < 140 ? 28 : 32,
                  child: ElevatedButton(
                    onPressed: onIncrement,
                    style: ElevatedButton.styleFrom(
                      padding: EdgeInsets.zero,
                      minimumSize: Size(height < 140 ? 28 : 32, height < 140 ? 28 : 32),
                    ),
                    child: Text('+', style: TextStyle(fontSize: height < 140 ? 14 : 16)),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required List<Widget> children,
    int crossAxisCount = 4,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Text(
          title,
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w600),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: crossAxisCount,
          mainAxisSpacing: 16,
          crossAxisSpacing: 16,
          childAspectRatio: crossAxisCount <= 2 ? 1.8 : 1.2, // Adjust aspect ratio based on column count
          children: children,
        ),
        const SizedBox(height: 32),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final int totalAnalogIn = inputs['mics']! + inputs['line']! + inputs['rca']! + inputs['jack35']!;
    final int totalAnalogOut = outputs['speakers']! + outputs['lineOut']!;
    final int totalNetworkIn = inputs['aes67In']! + inputs['danteIn']!;
    final int totalNetworkOut = outputs['aes67Out']! + outputs['danteOut']!;

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
                          'DSP Calculator',
                          style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),

                    // Analog Inputs Section - Compact
                    _buildCompactSection(
                      title: 'Analog Inputs',
                      children: <Widget>[
                        _buildCompactCounter('Mics', inputs['mics']!, 'mics', Icons.mic),
                        _buildCompactCounter('Line', inputs['line']!, 'line', Icons.music_note),
                        _buildCompactCounter('RCA', inputs['rca']!, 'rca', Icons.album),
                        _buildCompactCounter('3.5mm', inputs['jack35']!, 'jack35', Icons.radio),
                      ],
                    ),

                    // Network Inputs Section - Compact
                    _buildCompactSection(
                      title: 'Network Inputs',
                      children: <Widget>[
                        _buildCompactCounter('AES67', inputs['aes67In']!, 'aes67In', Icons.network_check),
                        _buildCompactCounter('Dante', inputs['danteIn']!, 'danteIn', Icons.network_check),
                      ],
                    ),

                    // Outputs Section - Compact
                    _buildCompactSection(
                      title: 'Outputs',
                      children: <Widget>[
                        _buildCompactCounter('Speakers', outputs['speakers']!, 'speakers', Icons.speaker, isOutput: true),
                        _buildCompactCounter('Line Out', outputs['lineOut']!, 'lineOut', Icons.album, isOutput: true),
                        _buildCompactCounter('AES67 Out', outputs['aes67Out']!, 'aes67Out', Icons.network_check, isOutput: true),
                        _buildCompactCounter('Dante Out', outputs['danteOut']!, 'danteOut', Icons.network_check, isOutput: true),
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
              child: Container(
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
                            _buildSummaryRow('Analog Inputs', '$totalAnalogIn (Mic: ${inputs['mics']}, Line: ${inputs['line']}, RCA: ${inputs['rca']}, 3.5mm: ${inputs['jack35']})'),
                            _buildSummaryRow('Analog Outputs', '$totalAnalogOut (Speakers: ${outputs['speakers']}, Line: ${outputs['lineOut']})'),
                            _buildSummaryRow('Network Inputs', '$totalNetworkIn (AES67: ${inputs['aes67In']}, Dante: ${inputs['danteIn']})'),
                            _buildSummaryRow('Network Outputs', '$totalNetworkOut (AES67: ${outputs['aes67Out']}, Dante: ${outputs['danteOut']})'),                                  const SizedBox(height: 16),
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

  List<Widget> _buildCapabilitiesList() {
    final List<Widget> widgets = <Widget>[];
    
    // DSP Devices section
    widgets.add(
      const Text(
        'DSP Devices:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
    widgets.add(const SizedBox(height: 4));

    // Add DSP device capabilities
    final List<String> dspCapabilities = <String>[
      '4ch PowerSmart → Analog I/O: 8 (4 in, 4 speaker out), Network I/O: 8 (4 in, 4 out)',
      '8ch PowerSmart → Analog I/O: 16 (8 in, 8 speaker out), Network I/O: 16 (8 in, 8 out)',
      'FM6 → Analog I/O: 8 (4 in, 4 out), Network I/O: 0',
      'FM8Y → Analog I/O: 12 (4 in, 8 out), Network I/O: 16 (8 in, 8 out)',
    ];

    for (final String capability in dspCapabilities) {
      widgets.add(_buildCapabilityRow(capability));
    }

    // Add separator
    widgets.add(const SizedBox(height: 12));

    // Add other devices header
    widgets.add(
      const Text(
        'Other Devices:',
        style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
      ),
    );
    widgets.add(const SizedBox(height: 4));

    // Add other device capabilities
    final List<String> otherCapabilities = <String>[
      'FusionConnect → Analog I/O: 48 (24 in, 24 out), Network I/O: 0',
      'PowerPure Amplifier → Analog I/O: 4 (0 in, 4 speaker out), Network I/O: 0',
    ];

    for (final String capability in otherCapabilities) {
      widgets.add(_buildCapabilityRow(capability));
    }

    return widgets;
  }
}
