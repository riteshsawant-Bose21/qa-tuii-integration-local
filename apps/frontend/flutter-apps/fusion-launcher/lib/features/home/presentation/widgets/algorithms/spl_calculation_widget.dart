import 'package:flutter/material.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/speaker_product.dart';

class SplCalculationWidget extends StatefulWidget {
  const SplCalculationWidget({super.key});

  @override
  State<SplCalculationWidget> createState() => _SplCalculationWidgetState();
}

class _SplCalculationWidgetState extends State<SplCalculationWidget> {
  // Controllers
  final TextEditingController speakerHeightController = TextEditingController(
    text: '5',
  );
  final TextEditingController listenerHeightController = TextEditingController(
    text: '2',
  );
  final TextEditingController minSplController = TextEditingController(
    text: '70',
  );
  final TextEditingController maxSplController = TextEditingController(
    text: '80',
  );

  String selectedEnvironment = 'indoor';
  List<String> selectedMountingTypes = <String>['surface'];
  SplMultiMountResult? splResult;

  @override
  void dispose() {
    speakerHeightController.dispose();
    listenerHeightController.dispose();
    minSplController.dispose();
    maxSplController.dispose();
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
            text: 'SPL Calculation',
            gradient: LinearGradient(
              colors: <Color>[Colors.blue, Colors.purple],
            ),
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
          const SizedBox(height: 20),

          // Mounting Type Selection
          const FusionAppText(
            text: 'Mounting Type',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600),
          ),
          const SizedBox(height: 8),
          Wrap(
            spacing: 8.0,
            children:
                <String>['ceiling', 'surface', 'pendant'].map((String type) {
                  final bool isSelected = selectedMountingTypes.contains(type);
                  return FilterChip(
                    label: FusionAppText(text: type.toUpperCase()),
                    selected: isSelected,
                    onSelected: (bool selected) {
                      setState(() {
                        if (selected) {
                          if (!selectedMountingTypes.contains(type)) {
                            selectedMountingTypes.add(type);
                          }
                        } else {
                          selectedMountingTypes.remove(type);
                        }
                      });
                    },
                    selectedColor: Theme.of(
                      context,
                    ).primaryColor.withValues(alpha: 0.3),
                    checkmarkColor: Theme.of(context).primaryColor,
                  );
                }).toList(),
          ),
          const SizedBox(height: 20),

          Row(
            children: <Widget>[
              Expanded(
                child: FusionTextFormField(
                  semanticId: 'speaker_height',
                  title: 'Speaker Height (m)',
                  hintText: 'e.g., 2.4',
                  controller: speakerHeightController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FusionTextFormField(
                  semanticId: 'listener_height',
                  title: 'Listener Height (m)',
                  hintText: 'e.g., 0.6',
                  controller: listenerHeightController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: <Widget>[
              Expanded(
                child: FusionTextFormField(
                  semanticId: 'min_spl',
                  title: 'Min SPL (dB)',
                  hintText: 'Minimum SPL',
                  controller: minSplController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: FusionTextFormField(
                  semanticId: 'max_spl',
                  title: 'Max SPL (dB)',
                  hintText: 'Maximum SPL',
                  controller: maxSplController,
                  keyboardType: TextInputType.number,
                  isRequired: true,
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          Row(
            children: <Widget>[
              Expanded(
                child: FusionDropdownButtonFormField(
                  value: selectedEnvironment,
                  options: const <String>['indoor', 'outdoor'],
                  hintText: 'Select Environment',
                  semanticKey: "environment_dropdown",
                  onChanged: (String? value) {
                    if (value != null) {
                      setState(() {
                        selectedEnvironment = value;
                      });
                    }
                  },
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          FusionGradientButton(
            accessLabel: 'calculate_spl',
            label: 'Calculate SPL',
            onTap: _calculateSpl,
            gradient: const LinearGradient(
              colors: <Color>[Colors.blue, Colors.purple],
            ),
            isLoading: false,
            isActive: selectedMountingTypes.isNotEmpty,
            width: double.infinity,
            height: 50,
          ),

          const SizedBox(height: 20),

          if (splResult != null) _buildSplResults(),
        ],
      ),
    );
  }

  Widget _buildSplResults() {
    return Container(
      padding: const EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Theme.of(context).cardColor,
        borderRadius: BorderRadius.circular(12.0),
        border: Border.all(color: Colors.blue.withValues(alpha: 0.3)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const FusionAppText(
            text: 'SPL Calculation Results',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          for (final SplPerMountResult result in splResult!.results)
            Card(
              child: Padding(
                padding: const EdgeInsets.all(12.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    FusionAppText(
                      text: 'Mounting: ${result.mountingType.toUpperCase()}',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: <Widget>[
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FusionAppText(
                                text: 'Distance: ${result.distance.toStringAsFixed(2)}m',
                              ),
                              FusionAppText(
                                text: 'SPL Loss: ${result.splLoss.toStringAsFixed(2)}dB',
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),

                    // SPL Requirements
                    Container(
                      padding: const EdgeInsets.all(8.0),
                      decoration: BoxDecoration(
                        color: Colors.grey.withValues(alpha: 0.05),
                        borderRadius: BorderRadius.circular(8.0),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const FusionAppText(
                            text: 'SPL Requirements:',
                            style: TextStyle(fontWeight: FontWeight.w600),
                          ),
                          const SizedBox(height: 4),
                          FusionAppText(
                            text: 'Minimum: ${result.splRequiredMin.toStringAsFixed(1)}dB',
                          ),
                          FusionAppText(
                            text: 'Target: ${result.splRequiredMid.toStringAsFixed(1)}dB',
                          ),
                          FusionAppText(
                            text: 'Maximum: ${result.splRequiredMax.toStringAsFixed(1)}dB',
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 12),

                    // Speaker Recommendations
                    const FusionAppText(
                      text: 'Speaker Recommendations:',
                      style: TextStyle(
                        fontWeight: FontWeight.w600,
                        fontSize: 15,
                      ),
                    ),
                    const SizedBox(height: 8),

                    if (result.recommendedModelsMin.isNotEmpty) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.green.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: Colors.green.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const FusionAppText(
                              text: 'Minimum SPL:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.green,
                              ),
                            ),
                            ...result.recommendedModelsMin.map(
                              (String model) => FusionAppText(text: '• $model'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (result.recommendedModelsMid.isNotEmpty) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.blue.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: Colors.blue.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const FusionAppText(
                              text: 'Target SPL:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.blue,
                              ),
                            ),
                            ...result.recommendedModelsMid.map(
                              (String model) => FusionAppText(text: '• $model'),
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(height: 4),
                    ],

                    if (result.recommendedModelsMax.isNotEmpty) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.orange.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: Colors.orange.withValues(alpha: 0.3),
                          ),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: <Widget>[
                            const FusionAppText(
                              text: 'Maximum SPL:',
                              style: TextStyle(
                                fontWeight: FontWeight.w500,
                                color: Colors.orange,
                              ),
                            ),
                            ...result.recommendedModelsMax.map(
                              (String model) => FusionAppText(text: '• $model'),
                            ),
                          ],
                        ),
                      ),
                    ],

                    if (result.recommendedModelsMin.isEmpty && result.recommendedModelsMid.isEmpty && result.recommendedModelsMax.isEmpty) ...<Widget>[
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(8.0),
                        decoration: BoxDecoration(
                          color: Colors.red.withValues(alpha: 0.1),
                          borderRadius: BorderRadius.circular(6.0),
                          border: Border.all(
                            color: Colors.red.withValues(alpha: 0.3),
                          ),
                        ),
                        child: const FusionAppText(
                          text: 'No suitable speakers found for this configuration',
                          style: TextStyle(
                            color: Colors.red,
                            fontStyle: FontStyle.italic,
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  void _calculateSpl() {
    try {
      if (selectedMountingTypes.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: FusionAppText(
              text: 'Please select at least one mounting type',
            ),
          ),
        );
        return;
      }

      final SplInput input = SplInput(
        mountingType: selectedMountingTypes,
        speakerHeight: double.parse(speakerHeightController.text),
        listenerHeight: double.parse(listenerHeightController.text),
        environment: selectedEnvironment,
        targetSplRange: <double>[
          double.parse(minSplController.text),
          double.parse(maxSplController.text),
        ],
      );

      final SplMultiMountResult result = calculateSpl(input, <SpeakerProduct>[]);
      setState(() {
        splResult = result;
      });
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: FusionAppText(text: 'Error: ${e.toString()}')),
      );
    }
  }
}
