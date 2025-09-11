import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_algorithms/fusion_algorithms.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_gradient_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_form_field.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_gradient_text.dart';

class SpeakerInput {
  String? selectedModel;
  final TextEditingController speakerHeightController = TextEditingController(text: '3.7');
  final TextEditingController listenerHeightController = TextEditingController(text: '1.8');

  void dispose() {
    speakerHeightController.dispose();
    listenerHeightController.dispose();
  }
}

class TapSettingWidget extends StatefulWidget {
  const TapSettingWidget({super.key});

  @override
  State<TapSettingWidget> createState() => _TapSettingWidgetState();
}

class _TapSettingWidgetState extends State<TapSettingWidget> {
  TapCalculationResult? tapResult;
  final List<SpeakerInput> speakers = <SpeakerInput>[
    SpeakerInput(),
  ];

  // Circuit configuration
  String circuitType = 'hi-z';
  final TextEditingController voltageController = TextEditingController(text: '100');

  @override
  void dispose() {
    voltageController.dispose();
    for (final SpeakerInput input in speakers) {
      input.dispose();
    }
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const FusionGradientText(
            text: 'Tap Setting Calculation',
            gradient: LinearGradient(colors: <Color>[Colors.orange, Colors.red]),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.orange.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: <Widget>[
                Text(
                  'Algorithm Overview',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                SizedBox(height: 8),
                Text(
                  'This algorithm calculates optimal tap settings for distributed speakers:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Text(
                  '1. Analyzes speaker specifications and placement',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '2. Calculates coverage area and power requirements',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '3. Recommends optimal tap wattage for each speaker',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '4. Ensures balanced audio distribution',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          // Circuit Configuration
          const Text(
            'Circuit Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          Row(
            children: <Widget>[
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: circuitType,
                  decoration: const InputDecoration(
                    labelText: 'Circuit Type',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: 'hi-z', child: Text('Hi-Z')),
                    DropdownMenuItem<String>(value: 'lo-z', child: Text('Lo-Z')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      circuitType = newValue ?? 'hi-z';
                    });
                  },
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: DropdownButtonFormField<String>(
                  value: voltageController.text,
                  decoration: const InputDecoration(
                    labelText: 'Voltage (V)',
                    border: OutlineInputBorder(),
                    contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  ),
                  items: const <DropdownMenuItem<String>>[
                    DropdownMenuItem<String>(value: '100', child: Text('100V')),
                    DropdownMenuItem<String>(value: '70', child: Text('70V')),
                  ],
                  onChanged: (String? newValue) {
                    setState(() {
                      voltageController.text = newValue ?? '100';
                    });
                  },
                  validator: (String? value) {
                    if (value == null || value.isEmpty) {
                      return 'Please select voltage';
                    }
                    return null;
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          // Speaker Input Forms
          const Text(
            'Speaker Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ...speakers.asMap().entries.map((MapEntry<int, SpeakerInput> entry) {
            final int index = entry.key;
            final SpeakerInput input = entry.value;

            return Card(
              margin: const EdgeInsets.only(bottom: 16.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Text(
                          'Speaker ${index + 1}',
                          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                        ),
                        const Spacer(),
                        if (speakers.length > 1)
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red),
                            onPressed: () => _removeSpeaker(index),
                          ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Speaker Model *', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: input.selectedModel,
                                decoration: const InputDecoration(
                                  hintText: 'Select speaker model',
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items:
                                    speakerDatabase.keys.map((String model) {
                                      final SpeakerModel speaker = speakerDatabase[model]!;
                                      return DropdownMenuItem<String>(
                                        value: model,
                                        child: Text('$model (${speaker.mountingType}, ${speaker.maxSpl}dB)'),
                                      );
                                    }).toList(),
                                onChanged: (String? newValue) {
                                  setState(() {
                                    input.selectedModel = newValue;
                                  });
                                },
                                validator: (String? value) => value == null ? 'Please select a speaker model' : null,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FusionTextFormField(
                            title: 'Speaker Height (m)',
                            hintText: 'e.g., 3.7',
                            controller: input.speakerHeightController,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: FusionTextFormField(
                            title: 'Listener Height (m)',
                            hintText: 'e.g., 1.8',
                            controller: input.listenerHeightController,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 16),

          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addSpeaker,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Another Speaker'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FusionGradientButton(
                  label: 'Calculate Tap Settings',
                  onTap: _calculateTapSetting,
                  gradient: const LinearGradient(
                    colors: <Color>[Colors.orange, Colors.red],
                  ),
                  isLoading: false,
                  isActive: true,
                  height: 50,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (tapResult != null) _buildTapResults(),
        ],
      ),
    );
  }

  Widget _buildTapResults() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.orange.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'Tap Setting Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.orange.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${tapResult!.results.length} speakers',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          for (int i = 0; i < tapResult!.results.length; i++)
            Card(
              margin: const EdgeInsets.only(bottom: 12.0),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Row(
                      children: <Widget>[
                        Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Center(
                            child: Text(
                              '${i + 1}',
                              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                i < speakers.length ? (speakers[i].selectedModel ?? 'Unknown Model') : 'Unknown Model',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                'Distance: ${tapResult!.results[i].distanceMeters.toStringAsFixed(2)}m',
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: tapResult!.results[i].powerWatts > 0 ? Colors.green.withValues(alpha: 0.2) : Colors.red.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Text(
                            tapResult!.results[i].powerWatts > 0 ? '${tapResult!.results[i].powerWatts.toStringAsFixed(1)}W' : 'N/A',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: tapResult!.results[i].powerWatts > 0 ? Colors.green : Colors.red,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 12),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(12.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        children: <Widget>[
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('SPL Loss:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text('${tapResult!.results[i].splLoss.toStringAsFixed(2)}dB'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Attenuation:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text('${tapResult!.results[i].attenuationDb.toStringAsFixed(2)}dB'),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Circuit Type:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(circuitType.toUpperCase()),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Voltage:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text('${voltageController.text}V'),
                            ],
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Explanation for the tap setting
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: tapResult!.results[i].powerWatts > 0 ? Colors.blue.withValues(alpha: 0.1) : Colors.red.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: tapResult!.results[i].powerWatts > 0 ? Colors.blue.withValues(alpha: 0.3) : Colors.red.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        tapResult!.results[i].powerWatts > 0
                            ? '💡 Recommended tap setting based on speaker height and distance calculations'
                            : '⚠️ No suitable tap found - speaker may not be in database or parameters invalid',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: tapResult!.results[i].powerWatts > 0 ? Colors.blue[700] : Colors.red[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

          const SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
            ),
            child: Column(
              children: <Widget>[
                const Text(
                  'System Summary',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Reference Distance:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('${tapResult!.referenceDistance.toStringAsFixed(2)}m', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Number of Speakers:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text('${tapResult!.results.length}', style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    const Text('Calculation Method:', style: TextStyle(fontWeight: FontWeight.w500)),
                    Text(tapResult!.calculationMethod, style: const TextStyle(fontWeight: FontWeight.bold)),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  void _addSpeaker() {
    setState(() {
      speakers.add(SpeakerInput());
    });
  }

  void _removeSpeaker(int index) {
    setState(() {
      speakers[index].dispose();
      speakers.removeAt(index);
    });
  }

  void _calculateTapSetting() {
    try {
      // Validate circuit configuration
      if (voltageController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter voltage')),
        );
        return;
      }

      // Validate circuit type early
      if (circuitType.toLowerCase() == 'lo-z') {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Tap calculations are only valid for Hi-Z circuits. '
              'Lo-Z circuits use direct impedance matching and do not require tap settings.',
            ),
            duration: Duration(seconds: 5),
          ),
        );
        return;
      }

      final List<SpeakerTapInput> inputs = <SpeakerTapInput>[];
      final int voltage = int.parse(voltageController.text);

      for (final SpeakerInput input in speakers) {
        if (input.selectedModel == null || input.speakerHeightController.text.isEmpty || input.listenerHeightController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all speaker fields')),
          );
          return;
        }

        inputs.add(
          SpeakerTapInput(
            model: input.selectedModel!,
            speakerHeight: double.parse(input.speakerHeightController.text),
            listenerHeight: double.parse(input.listenerHeightController.text),
            voltage: voltage,
            circuitType: circuitType, // Pass the circuit type to the algorithm
          ),
        );
      }

      final TapCalculationResult result = recommendTapsForSpeakers(inputs);
      setState(() {
        tapResult = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
