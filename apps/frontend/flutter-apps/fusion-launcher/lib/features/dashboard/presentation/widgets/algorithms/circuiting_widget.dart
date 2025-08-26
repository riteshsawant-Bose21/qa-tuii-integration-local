import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_algorithms/fusion_algorithms.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_gradient_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_form_field.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_gradient_text.dart';
import 'package:fusion_lib/fusion_algorithms/fusion_algorithms.dart';
import '../../../../../core/services/circuit_data_service.dart';

class SpeakerInputForCircuiting {
  String? selectedModel;
  final TextEditingController quantityController = TextEditingController(text: '1');
  final TextEditingController areaController = TextEditingController();
  String tapSetting = 'lo-z';

  void dispose() {
    quantityController.dispose();
    areaController.dispose();
  }
}

class CircuitingWidget extends StatefulWidget {
  const CircuitingWidget({super.key});

  @override
  State<CircuitingWidget> createState() => _CircuitingWidgetState();
}

class _CircuitingWidgetState extends State<CircuitingWidget> {
  final TextEditingController maxAmpPowerController = TextEditingController(text: '500');
  List<CircuitAssignment>? circuitResult;
  final List<SpeakerInputForCircuiting> speakers = <SpeakerInputForCircuiting>[
    SpeakerInputForCircuiting(),
  ];
  final CircuitDataService _circuitDataService = CircuitDataService();

  @override
  void dispose() {
    maxAmpPowerController.dispose();
    for (final SpeakerInputForCircuiting input in speakers) {
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
            text: 'Automatic Circuiting',
            gradient: LinearGradient(colors: <Color>[Colors.green, Colors.teal]),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),

          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16.0),
            decoration: BoxDecoration(
              color: Colors.green.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12.0),
              border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
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
                  'This algorithm automatically groups speakers and assigns optimal circuit configurations:',
                  style: TextStyle(fontSize: 14),
                ),
                SizedBox(height: 12),
                Text(
                  '1. Groups speakers by area and model',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '2. Calculates parallel impedance for each group',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '3. Applies lo-z/hi-z rules (≥4Ω = lo-z, <4Ω = hi-z)',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
                Text(
                  '4. Validates power limits and assigns circuits',
                  style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500),
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          FusionTextFormField(
            title: 'Max Amplifier Power (W)',
            hintText: 'Enter maximum amplifier power',
            controller: maxAmpPowerController,
            keyboardType: TextInputType.number,
            isRequired: true,
          ),

          const SizedBox(height: 20),

          // Speaker Input Forms
          const Text(
            'Speaker Configuration',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),

          ...speakers.asMap().entries.map((MapEntry<int, SpeakerInputForCircuiting> entry) {
            final int index = entry.key;
            final SpeakerInputForCircuiting input = entry.value;

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
                          'Speaker Group ${index + 1}',
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
                        const SizedBox(width: 12),
                        Expanded(
                          child: FusionTextFormField(
                            title: 'Quantity',
                            hintText: '4',
                            controller: input.quantityController,
                            keyboardType: TextInputType.number,
                            isRequired: true,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    Row(
                      children: <Widget>[
                        Expanded(
                          child: FusionTextFormField(
                            title: 'Area/Zone',
                            hintText: 'e.g., Main Hall',
                            controller: input.areaController,
                            isRequired: true,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              const Text('Tap Setting', style: TextStyle(fontWeight: FontWeight.w500)),
                              const SizedBox(height: 8),
                              DropdownButtonFormField<String>(
                                value: input.tapSetting,
                                decoration: const InputDecoration(
                                  border: OutlineInputBorder(),
                                  contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                ),
                                items: const <DropdownMenuItem<String>>[
                                  DropdownMenuItem<String>(value: 'lo-z', child: Text('Lo-Z')),
                                  DropdownMenuItem<String>(value: 'hi-z', child: Text('Hi-Z')),
                                ],
                                onChanged: (String? newValue) {
                                  setState(() {
                                    input.tapSetting = newValue ?? 'lo-z';
                                  });
                                },
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
          }),

          const SizedBox(height: 16),

          Row(
            children: <Widget>[
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: _addSpeaker,
                  icon: const Icon(Icons.add),
                  label: const Text('Add Speaker Group'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: FusionGradientButton(
                  label: 'Calculate Circuiting',
                  onTap: _calculateCircuiting,
                  gradient: const LinearGradient(
                    colors: <Color>[Colors.green, Colors.teal],
                  ),
                  isLoading: false,
                  isActive: true,
                  height: 50,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          if (circuitResult != null) _buildCircuitingResults(),
        ],
      ),
    );
  }

  Widget _buildCircuitingResults() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.green.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          Row(
            children: <Widget>[
              const Text(
                'Circuiting Results',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
                decoration: BoxDecoration(
                  color: Colors.green.withValues(alpha: 0.2),
                  borderRadius: BorderRadius.circular(12.0),
                ),
                child: Text(
                  '${circuitResult!.length} circuits',
                  style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),

          for (int i = 0; i < circuitResult!.length; i++)
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
                            color: Colors.green.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(20.0),
                          ),
                          child: Center(
                            child: Text(
                              '${circuitResult![i].circuitId}',
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
                                'Circuit ${circuitResult![i].circuitId}',
                                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                circuitResult![i].area,
                                style: TextStyle(fontSize: 14, color: Colors.grey[600]),
                              ),
                            ],
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 12.0, vertical: 6.0),
                          decoration: BoxDecoration(
                            color: circuitResult![i].mode == 'lo-z' ? Colors.blue.withValues(alpha: 0.2) : Colors.orange.withValues(alpha: 0.2),
                            borderRadius: BorderRadius.circular(16.0),
                          ),
                          child: Text(
                            circuitResult![i].mode.toUpperCase(),
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.bold,
                              color: circuitResult![i].mode == 'lo-z' ? Colors.blue : Colors.orange,
                            ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 16),

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
                              const Text('Speaker Model:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(circuitResult![i].model),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: <Widget>[
                              const Text('Area:', style: TextStyle(fontWeight: FontWeight.w500)),
                              Text(circuitResult![i].area),
                            ],
                          ),
                          if (circuitResult![i].totalPower != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text('Total Power:', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text('${circuitResult![i].totalPower!.toStringAsFixed(1)}W'),
                              ],
                            ),
                          ],
                          if (circuitResult![i].impedance != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text('Impedance:', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text('${circuitResult![i].impedance!.toStringAsFixed(2)}Ω'),
                              ],
                            ),
                          ],
                          if (circuitResult![i].tapWatts != null) ...<Widget>[
                            const SizedBox(height: 8),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: <Widget>[
                                const Text('Tap Setting:', style: TextStyle(fontWeight: FontWeight.w500)),
                                Text('${circuitResult![i].tapWatts!.toStringAsFixed(1)}W'),
                              ],
                            ),
                          ],
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Circuit mode explanation
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: circuitResult![i].mode == 'lo-z' ? Colors.blue.withValues(alpha: 0.1) : Colors.orange.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(6.0),
                        border: Border.all(
                          color: circuitResult![i].mode == 'lo-z' ? Colors.blue.withValues(alpha: 0.3) : Colors.orange.withValues(alpha: 0.3),
                        ),
                      ),
                      child: Text(
                        circuitResult![i].mode == 'lo-z'
                            ? '💡 Lo-Z circuit: Impedance ≥ 4Ω, suitable for direct amplifier connection'
                            : '💡 Hi-Z circuit: Impedance < 4Ω, using distributed voltage line',
                        style: TextStyle(
                          fontSize: 12,
                          fontStyle: FontStyle.italic,
                          color: circuitResult![i].mode == 'lo-z' ? Colors.blue[700] : Colors.orange[700],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _addSpeaker() {
    setState(() {
      speakers.add(SpeakerInputForCircuiting());
    });
  }

  void _removeSpeaker(int index) {
    setState(() {
      speakers[index].dispose();
      speakers.removeAt(index);
    });
  }

  void _calculateCircuiting() {
    try {
      if (maxAmpPowerController.text.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Please enter maximum amplifier power')),
        );
        return;
      }

      final double maxPower = double.parse(maxAmpPowerController.text);
      final List<InputSpeaker> inputSpeakers = <InputSpeaker>[];

      for (final SpeakerInputForCircuiting input in speakers) {
        if (input.selectedModel == null || input.quantityController.text.isEmpty || input.areaController.text.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Please fill in all speaker fields')),
          );
          return;
        }

        inputSpeakers.add(
          InputSpeaker(
            model: input.selectedModel!,
            quantity: int.parse(input.quantityController.text),
            area: input.areaController.text,
            tapSetting: input.tapSetting,
          ),
        );
      }

      final List<CircuitAssignment> result = automaticCircuiting(inputSpeakers, maxPower);
      setState(() {
        circuitResult = result;
      });

      // Share results with other widgets through the service
      if (result.isNotEmpty) {
        _circuitDataService.updateCircuitingResults(result, maxPower);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Circuit results shared! Available for amplifier matching.'),
            backgroundColor: Colors.green,
            duration: Duration(seconds: 3),
          ),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: ${e.toString()}')),
      );
    }
  }
}
