import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_gradient_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_form_field.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_gradient_text.dart';
import 'package:fusion_lib/fusion_algorithms/device_recommender/device_recommender.dart';
import 'package:fusion_lib/api_data/devices/devices.dart';

class DeviceRecommenderWidget extends StatefulWidget {
  const DeviceRecommenderWidget({super.key});

  @override
  State<DeviceRecommenderWidget> createState() => _DeviceRecommenderWidgetState();
}

class _DeviceRecommenderWidgetState extends State<DeviceRecommenderWidget> {
  // Form controllers
  final TextEditingController analogInputsController = TextEditingController(text: '0');
  final TextEditingController analogOutputsController = TextEditingController(text: '0');
  final TextEditingController networkInputsController = TextEditingController(text: '0');
  final TextEditingController networkOutputsController = TextEditingController(text: '0');
  final TextEditingController bluetoothInputsController = TextEditingController(text: '0');

  // Preference options
  bool preferWallIo = false;
  bool preferDistributed = false;

  // Results
  List<String>? recommendedDevices;
  bool isLoading = false;
  String? errorMessage;

  @override
  void dispose() {
    analogInputsController.dispose();
    analogOutputsController.dispose();
    networkInputsController.dispose();
    networkOutputsController.dispose();
    bluetoothInputsController.dispose();
    super.dispose();
  }

  void _calculateDeviceRecommendation() async {
    setState(() {
      isLoading = true;
      errorMessage = null;
      recommendedDevices = null;
    });

    try {
      // Parse input values
      final int analogInputs = int.tryParse(analogInputsController.text) ?? 0;
      final int analogOutputs = int.tryParse(analogOutputsController.text) ?? 0;
      final int networkInputs = int.tryParse(networkInputsController.text) ?? 0;
      final int networkOutputs = int.tryParse(networkOutputsController.text) ?? 0;
      final int bluetoothInputs = int.tryParse(bluetoothInputsController.text) ?? 0;

      // Validate inputs
      if (analogInputs < 0 || analogOutputs < 0 || networkInputs < 0 || 
          networkOutputs < 0 || bluetoothInputs < 0) {
        throw Exception('All input values must be non-negative');
      }

      if (analogInputs == 0 && analogOutputs == 0 && networkInputs == 0 && 
          networkOutputs == 0 && bluetoothInputs == 0) {
        throw Exception('At least one input/output value must be greater than 0');
      }

      // Create recommendation input
      final RecommendInput input = RecommendInput(
        analogInputs: int.tryParse(analogInputsController.text) ?? 0,
        analogOutputs: int.tryParse(analogOutputsController.text) ?? 0,
        networkInputs: int.tryParse(networkInputsController.text) ?? 0,
        networkOutputs: int.tryParse(networkOutputsController.text) ?? 0,
        bluetoothInputs: int.tryParse(bluetoothInputsController.text) ?? 0,
        preferWallIo: preferWallIo,
        preferDistributed: preferDistributed,
      );

      // Get device recommendations
      final List<String> devices = DeviceRecommender.recommendDevices(input);

      setState(() {
        recommendedDevices = devices;
        isLoading = false;
      });
    } catch (e) {
      setState(() {
        errorMessage = e.toString();
        isLoading = false;
      });
    }
  }

  void _clearAll() {
    setState(() {
      analogInputsController.text = '0';
      analogOutputsController.text = '0';
      networkInputsController.text = '0';
      networkOutputsController.text = '0';
      bluetoothInputsController.text = '0';
      preferWallIo = false;
      preferDistributed = false;
      recommendedDevices = null;
      errorMessage = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Header
            const FusionGradientText(
              text: 'Device Recommender',
              gradient: LinearGradient(colors: <Color>[Colors.blue, Colors.purple]),
              fontSize: 28,
              fontWeight: FontWeight.bold,
            ),
            const SizedBox(height: 8),
            Text(
              'Get intelligent DSP device recommendations based on your I/O requirements',
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: Colors.grey[600],
              ),
            ),
            const SizedBox(height: 24),

            // Input Section
            _buildInputSection(),
            
            const SizedBox(height: 24),

            // Action Buttons
            _buildActionButtons(),

            const SizedBox(height: 24),

            // Results Section
            if (isLoading) _buildLoadingSection(),
            if (errorMessage != null) _buildErrorSection(),
            if (recommendedDevices != null) _buildResultsSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildInputSection() {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Text(
              'System Requirements',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            const SizedBox(height: 16),
            
            // Analog I/O Section
            Text(
              'Analog I/O',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: FusionTextFormField(
                    controller: analogInputsController,
                    title: 'Analog Inputs',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FusionTextFormField(
                    controller: analogOutputsController,
                    title: 'Analog Outputs',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Network I/O Section
            Text(
              'Network I/O',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Expanded(
                  child: FusionTextFormField(
                    controller: networkInputsController,
                    title: 'Network Inputs',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: FusionTextFormField(
                    controller: networkOutputsController,
                    title: 'Network Outputs',
                    hintText: '0',
                    keyboardType: TextInputType.number,
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Bluetooth Section
            Text(
              'Bluetooth',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            FusionTextFormField(
              controller: bluetoothInputsController,
              title: 'Bluetooth Inputs',
              hintText: '0',
              keyboardType: TextInputType.number,
            ),
            
            const SizedBox(height: 16),
            
            // Preferences Section
            Text(
              'Preferences',
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 8),
            Row(
              children: <Widget>[
                Checkbox(
                  value: preferWallIo,
                  onChanged: (bool? value) {
                    setState(() {
                      preferWallIo = value ?? false;
                    });
                  },
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      const Text(
                        'Prefer Wall I/O Solutions',
                        style: TextStyle(fontWeight: FontWeight.w500),
                      ),
                      Text(
                        'When enabled, prefers Wall I/O plates over FM6+FM8Y combinations where applicable',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildActionButtons() {
    return Row(
      children: <Widget>[
        Expanded(
          child: FusionGradientButton(
            label: isLoading ? 'Calculating...' : 'Get Recommendations',
            onTap: _calculateDeviceRecommendation,
            gradient: const LinearGradient(colors: <Color>[Colors.blue, Colors.purple]),
          ),
        ),
        const SizedBox(width: 16),
        Expanded(
          child: OutlinedButton(
            onPressed: _clearAll,
            child: const Text('Clear All'),
          ),
        ),
      ],
    );
  }

  Widget _buildLoadingSection() {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            children: <Widget>[
              CircularProgressIndicator(),
              SizedBox(height: 16),
              Text('Calculating device recommendations...'),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildErrorSection() {
    return Card(
      color: Colors.red.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.error, color: Colors.red.shade600),
                const SizedBox(width: 8),
                Text(
                  'Error',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.red.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              errorMessage!,
              style: TextStyle(color: Colors.red.shade700),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultsSection() {
    return Card(
      color: Colors.green.shade50,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Row(
              children: <Widget>[
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                Text(
                  'Recommended Devices',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Colors.green.shade600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            
            // Device List
            ...recommendedDevices!.map((String device) => _buildDeviceCard(device)),
            
            const SizedBox(height: 16),
            
            // Summary
            _buildSummarySection(),
            
            const SizedBox(height: 16),
            
            // Info section
            _buildInfoSection(),
          ],
        ),
      ),
    );
  }

  Widget _buildDeviceCard(String device) {
    // Get device specifications
    DeviceSpec? deviceSpec;
    try {
      deviceSpec = DeviceCatalog.getAllDevices().firstWhere((DeviceSpec d) => d.name == device);
    } catch (e) {
      // Handle case where device name doesn't match exactly (like "Wall I/O")
      if (device.contains('Wall I/O')) {
        // For Wall I/O, we can provide generic info since it's not in our device table
        deviceSpec = null;
      }
    }

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border.all(color: Colors.green.shade300),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        children: <Widget>[
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: Colors.green.shade100,
              borderRadius: BorderRadius.circular(20),
            ),
            child: Icon(
              _getDeviceIcon(device),
              color: Colors.green.shade600,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  device,
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
                if (deviceSpec != null)
                  Text(
                    '${deviceSpec.analogInputs} analog in, ${deviceSpec.analogOutputs} analog out${deviceSpec.networkIO > 0 ? ', ${deviceSpec.networkIO} network I/O' : ''}',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  )
                else if (device.contains('Wall I/O'))
                  Text(
                    'Distributed I/O processing',
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 12,
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  IconData _getDeviceIcon(String device) {
    if (device.contains('PowerSmart')) {
      return Icons.power;
    } else if (device.contains('FM6')) {
      return Icons.router; // Fusion Mini with network capabilities
    } else if (device.contains('FM8Y')) {
      return Icons.hub; // Fusion Mini with analog + network capabilities
    } else if (device.contains('Wall I/O')) {
      return Icons.construction;
    }
    return Icons.device_hub;
  }

  Widget _buildSummarySection() {
    final int deviceCount = recommendedDevices!.length;
    final Set<String> uniqueDevices = recommendedDevices!.toSet();
    
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.blue.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Text(
            'Summary',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.blue.shade700,
            ),
          ),
          const SizedBox(height: 8),
          Text('Total devices recommended: $deviceCount'),
          Text('Unique device types: ${uniqueDevices.length}'),
          if (uniqueDevices.length != deviceCount)
            const Text('Multiple units of the same type are recommended for your requirements'),
        ],
      ),
    );
  }

  Widget _buildInfoSection() {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.amber.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.amber.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              Icon(Icons.info, color: Colors.amber.shade700, size: 16),
              const SizedBox(width: 8),
              Text(
                'Algorithm Info',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  color: Colors.amber.shade700,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          const Text(
            'This recommendation follows core principles:',
            style: TextStyle(fontSize: 12),
          ),
          const SizedBox(height: 4),
          const Text(
            '• I/O Affinity: Processing close to source/destination',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
            '• Minimum Processing: Smallest processor(s) for the workload',
            style: TextStyle(fontSize: 12),
          ),
          const Text(
              '• Distributed Processing: When beneficial over centralized',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              '• Bluetooth inputs are treated as analog inputs',
              style: TextStyle(fontSize: 12),
            ),
            const Text(
              '• FM6/FM8Y (Fusion Mini) devices handle both analog and network I/O',
              style: TextStyle(fontSize: 12),
            ),
        ],
      ),
    );
  }
}
