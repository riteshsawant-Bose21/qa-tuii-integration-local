import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/constants.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_checkbox_group.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/service_locator.dart';

class SpeakerListeningAreaProperties extends StatefulWidget {
  final List<SpeakerMountingType> selectedSpeakerMountingTypes;
  final ValueChanged<List<SpeakerMountingType>> onMountingChanged;

  final List<SpeakerLowFrequency> selectedLowFrequencies;
  final ValueChanged<List<SpeakerLowFrequency>> onLowFrequencyChanged;

  final List<SpeakerColor> selectedColors;
  final ValueChanged<List<SpeakerColor>> onColorChanged;

  final SpeakerWiring? selectedWiring;
  final ValueChanged<SpeakerWiring?> onWiringChanged;

  const SpeakerListeningAreaProperties({
    super.key,
    required this.selectedSpeakerMountingTypes,
    required this.onMountingChanged,
    required this.selectedLowFrequencies,
    required this.onLowFrequencyChanged,
    required this.selectedColors,
    required this.onColorChanged,
    required this.selectedWiring,
    required this.onWiringChanged,
  });

  @override
  State<SpeakerListeningAreaProperties> createState() => SpeakerListeningAreaPropertiesState();
}

class SpeakerListeningAreaPropertiesState extends State<SpeakerListeningAreaProperties> {
  final List<String> venueOptions = <String>["Indoor", "Indoor + Outdoor"];
  final List<String> listeningHeightOptions = <String>["Sitting", "Standing", "Custom"];
  // Map display options to actual values
  final Map<String, double> listeningHeightValues = <String, double>{"Sitting": 3.0, "Standing": 6.0, "Custom": 1.0};

  final List<String> splRangeOptions = <String>[
    "Background Music",
    "Paging",
    "Foreground Music",
    "Moderate live sound reinforcement",
    "High-SPL live sound reinforcement",
  ];

  final TextEditingController ceilingHeightController = TextEditingController();
  final TextEditingController listeningAreaController = TextEditingController();
  final TextEditingController customListeningHeightController = TextEditingController();

  final SpeakerSelectionMode SpeakerselectionMode = SpeakerSelectionMode.select;
  final SignalType _selectedSignalType = SignalType.mono;

  @override
  void dispose() {
    ceilingHeightController.dispose();
    listeningAreaController.dispose();
    customListeningHeightController.dispose();

    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel viewModel = serviceLocator<ProjectViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF292826),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final ListeningArea? selectedListeningArea = viewModel.getCurrentSelectedListeningArea();

          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: "Select Speaker",
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          color: context.colorScheme.onSurface,
                        ),
                      ),
                    ),
                    MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: GestureDetector(
                        onTap: () => Navigator.of(context).pop(),
                        child: const Padding(
                          padding: EdgeInsets.all(2.0),
                          child: Icon(LucideIcons.x200, size: 16),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const Divider(thickness: 0.5, height: 0),

              Flexible(
                child: Builder(
                  builder: (BuildContext context) {
                    if (selectedListeningArea == null) {
                      return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: <Widget>[
                            FusionAppText(
                              text: "Select listening area\nto view properties",
                              textAlign: TextAlign.center,
                              style: context.textTheme.labelSmall?.copyWith(
                                color: context.colorScheme.onSurface.withAlpha(100),
                              ),
                            ),
                          ],
                        ),
                      );
                    }

                    ceilingHeightController.text = selectedListeningArea.ceilingHeight;
                    listeningAreaController.text = selectedListeningArea.name;

                    // Determine display value and if custom is selected based on listeningHeight double value
                    String displayValue;
                    bool isCustomListeningHeight = false;

                    if (selectedListeningArea.listeningHeight == 3.0) {
                      displayValue = "Sitting";
                    } else if (selectedListeningArea.listeningHeight == 6.0) {
                      displayValue = "Standing";
                    } else {
                      displayValue = "Custom";
                      isCustomListeningHeight = true;
                      customListeningHeightController.text = selectedListeningArea.listeningHeight.toString();
                    }

                    return Padding(
                      padding: const EdgeInsets.all(16.0).copyWith(top: 0),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          Row(
                            children: <Widget>[
                              Icon(LucideIcons.maximize100, size: 16, color: context.colorScheme.onSurface),
                              const SizedBox(width: 8),
                              Expanded(
                                child: TextFormField(
                                  controller: listeningAreaController,
                                  maxLength: 24,
                                  decoration: InputDecoration(
                                    counterText: "",
                                    hintText: 'Enter area name',
                                    hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
                                    border: InputBorder.none,
                                    contentPadding: EdgeInsets.zero,
                                  ),
                                  style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),

                                  onFieldSubmitted: (String value) {
                                    if (value.trim().isNotEmpty) {
                                      final ListeningArea updatedLA = selectedListeningArea.copyWith(name: value.trim());
                                      viewModel.updateListeningArea(area: updatedLA);
                                    } else {
                                      // Reset to previous value if empty
                                      listeningAreaController.text = selectedListeningArea.name;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          _buildLAPropertyRow(
                            context: context,
                            label: "Type",
                            value: selectedListeningArea.venuType,
                            options: venueOptions,
                            onOptionSelected: (int selectedIndex) {
                              final String selectedType = venueOptions[selectedIndex];
                              final ListeningArea updatedLA = selectedListeningArea.copyWith(venuType: selectedType);
                              viewModel.updateListeningArea(area: updatedLA);
                            },
                          ),
                          const SizedBox(height: 5),
                          _buildLAPropertyRow(
                            context: context,
                            label: "Listening Ht",
                            value: displayValue,
                            options: listeningHeightOptions,
                            onOptionSelected: (int selectedIndex) {
                              final String selectedOption = listeningHeightOptions[selectedIndex];
                              final double heightValue = listeningHeightValues[selectedOption] ?? 3.0;

                              final ListeningArea updatedLA = selectedListeningArea.copyWith(listeningHeight: heightValue);
                              viewModel.updateListeningArea(area: updatedLA);
                            },
                          ),

                          // Show custom listening height text field if "Custom" is selected
                          if (isCustomListeningHeight) ...<Widget>[
                            const SizedBox(height: 5),
                            BuildingPageTextField(
                              label: "Custom Height",
                              controller: customListeningHeightController,
                              hintText: "e.g. 4.5",
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                LengthLimitingTextInputFormatter(8), // Limit to reasonable length
                              ],
                              validator: (String? value) {
                                if (value == null || value.isEmpty) return 'Required';
                                final double? parsed = double.tryParse(value);
                                if (parsed == null) return 'Invalid decimal';
                                if (parsed <= 0) return 'Must be > 0';
                                if (parsed > 1000) return 'Too large';
                                return null;
                              },
                              onFieldSubmitted: (String newValue) {
                                final double? parsed = double.tryParse(newValue);

                                if (parsed != null && parsed > 0 && parsed <= 1000) {
                                  final double? customHeight = double.tryParse(newValue);
                                  if (customHeight != null && customHeight > 0) {
                                    final ListeningArea updatedLA = selectedListeningArea.copyWith(listeningHeight: customHeight);
                                    viewModel.updateListeningArea(area: updatedLA);
                                  }
                                } else {
                                  // Reset to previous valid value if invalid
                                  customListeningHeightController.text = selectedListeningArea.listeningHeight.toString();

                                  // Show error feedback
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(
                                        'Please enter a valid decimal value between 0.1 and 1000',
                                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                          color: Colors.white,
                                        ),
                                      ),
                                      backgroundColor: Theme.of(context).colorScheme.error,
                                      duration: const Duration(seconds: 2),
                                    ),
                                  );
                                }
                              },
                              onChanged: (String value) {
                                // Real-time validation feedback
                                final double? parsed = double.tryParse(value);
                                if (value.isNotEmpty && (parsed == null || parsed <= 0 || parsed > 1000)) {
                                  // Visual feedback for invalid input
                                  customListeningHeightController.selection = TextSelection.fromPosition(
                                    TextPosition(offset: customListeningHeightController.text.length),
                                  );
                                }
                              },
                            ),
                          ],
                          const SizedBox(height: 5),
                          BuildingPageTextField(
                            label: "Ceiling Ht",
                            controller: ceilingHeightController,
                            hintText: "e.g., 10 ft",
                            inputFormatters: <TextInputFormatter>[FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
                            onFieldSubmitted: (String newValue) {
                              final ListeningArea updatedLA = selectedListeningArea.copyWith(ceilingHeight: newValue);
                              viewModel.updateListeningArea(area: updatedLA);
                            },
                          ),
                          const SizedBox(height: 5),
                          _buildLAPropertyRow(
                            context: context,
                            label: "SPL Range",
                            value: _getCurrentSplRange(selectedListeningArea.minSPL, selectedListeningArea.maxSPL),
                            options: splRangeOptions,
                            onOptionSelected: (int selectedIndex) {
                              // Set min/max SPL values based on selection
                              double minSPL, maxSPL;
                              switch (selectedIndex) {
                                case 0: // Background Music
                                  minSPL = 60.0;
                                  maxSPL = 70.0;
                                  break;
                                case 1: // Paging
                                  minSPL = 70.0;
                                  maxSPL = 80.0;
                                  break;
                                case 2: // Foreground Music
                                  minSPL = 75.0;
                                  maxSPL = 90.0;
                                  break;
                                case 3: // Moderate live sound reinforcement
                                  minSPL = 90.0;
                                  maxSPL = 100.0;
                                  break;
                                case 4: // High-SPL live sound reinforcement
                                  minSPL = 100.0;
                                  maxSPL = 120.0;
                                  break;
                                default:
                                  minSPL = 60.0;
                                  maxSPL = 70.0;
                              }

                              final ListeningArea updatedLA = selectedListeningArea.copyWith(
                                minSPL: minSPL,
                                maxSPL: maxSPL,
                              );
                              viewModel.updateListeningArea(area: updatedLA);
                            },
                          ),

                          const SizedBox(height: 5),

                          FusionRadio<SignalType>(
                            selected: _selectedSignalType,
                            options: SignalType.values,
                            labelBuilder: (SignalType signalType) {
                              return FusionAppText(
                                text: signalType.name,
                                style: context.textTheme.bodySmall?.copyWith(
                                  color: context.colorScheme.onSurface,
                                ),
                              );
                            },
                            onChanged: (SignalType value) {
                              // if (value != null) {
                              //   setState(() {
                              //     _selectedSignalType = value;
                              //   });
                              // }
                            },
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),

              const SizedBox(height: 5),
              const Divider(thickness: 0.5, height: 0),
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    Center(
                      child: Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: context.colorScheme.surface,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Row(
                          spacing: 10,
                          mainAxisSize: MainAxisSize.min,
                          children: <Widget>[
                            ...SpeakerSelectionMode.values.map((SpeakerSelectionMode mode) {
                              final bool isSelected = SpeakerselectionMode == mode;

                              return GestureDetector(
                                onTap: () {
                                  // setState(() {
                                  //   SpeakerselectionMode = mode;
                                  // });
                                },
                                child: Container(
                                  width: 89,
                                  padding: const EdgeInsets.all(8),
                                  decoration: BoxDecoration(
                                    color: isSelected ? context.colorScheme.surfaceBright : null,
                                    borderRadius: BorderRadius.circular(8),
                                  ),
                                  child: Center(
                                    child: FusionAppText(
                                      text: mode.displayName,
                                      style: context.textTheme.bodySmall?.copyWith(
                                        color: context.colorScheme.onSurface,
                                        fontWeight: FontWeight.normal,
                                      ),
                                    ),
                                  ),
                                ),
                              );
                            }),
                          ],
                        ),
                      ),
                    ),

                    const SizedBox(height: 10),
                    FusionAppText(
                      text: 'Mounting',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FusionCheckboxGroup<SpeakerMountingType>(
                      options: SpeakerMountingType.values,
                      selected: widget.selectedSpeakerMountingTypes,
                      labelBuilder: (BuildContext context, SpeakerMountingType option) {
                        return FusionAppText(
                          text: option.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      },
                      onChanged: (List<SpeakerMountingType> updated) => widget.onMountingChanged(updated),
                    ),

                    const SizedBox(height: 24),
                    FusionAppText(
                      text: 'Low Frequency',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FusionCheckboxGroup<SpeakerLowFrequency>(
                      options: SpeakerLowFrequency.values,
                      selected: widget.selectedLowFrequencies,
                      labelBuilder: (BuildContext context, SpeakerLowFrequency option) {
                        return FusionAppText(
                          text: option.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      },
                      onChanged: (List<SpeakerLowFrequency> updated) => widget.onLowFrequencyChanged(updated),
                    ),

                    const SizedBox(height: 24),
                    FusionAppText(
                      text: 'Color',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FusionCheckboxGroup<SpeakerColor>(
                      options: SpeakerColor.values,
                      selected: widget.selectedColors,
                      labelBuilder: (BuildContext context, SpeakerColor option) {
                        return FusionAppText(
                          text: option.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      },
                      onChanged: (List<SpeakerColor> updated) => widget.onColorChanged(updated),
                    ),

                    const SizedBox(height: 24),
                    FusionAppText(
                      text: 'Wiring',
                      style: context.textTheme.bodySmall?.copyWith(
                        fontWeight: FontWeight.normal,
                        color: context.colorScheme.onSurface,
                      ),
                    ),

                    const SizedBox(height: 8),

                    FusionRadio<SpeakerWiring>(
                      selected: widget.selectedWiring,
                      options: SpeakerWiring.values,
                      labelBuilder: (SpeakerWiring wiring) {
                        return FusionAppText(
                          text: wiring.displayName,
                          style: context.textTheme.bodySmall?.copyWith(
                            color: context.colorScheme.onSurface,
                          ),
                        );
                      },
                      onChanged: (SpeakerWiring value) {
                        final bool isSame = widget.selectedWiring == value;
                        widget.onWiringChanged(isSame ? null : value);
                      },
                    ),
                  ],
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  /// Builds a dropdown row displaying a property label and its selectable value.
  Widget _buildLAPropertyRow({
    required BuildContext context,
    required String label,
    required String value,
    List<String> options = const <String>[],
    required Function(int selectedIndex) onOptionSelected,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.bodySmall?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BuildingPageDronDown(
            value: value,
            hintText: "Select type",
            options: options,
            onSelect: (String newValue) {
              final int selectedIndex = options.indexOf(newValue);
              onOptionSelected(selectedIndex);
            },
          ),
        ),
      ],
    );
  }

  /// Helper method to determine current SPL range based on min/max values
  String _getCurrentSplRange(double minSPL, double maxSPL) {
    if (minSPL == 60.0 && maxSPL == 70.0) {
      return "Background Music";
    } else if (minSPL == 70.0 && maxSPL == 80.0) {
      return "Paging";
    } else if (minSPL == 75.0 && maxSPL == 90.0) {
      return "Foreground Music";
    } else if (minSPL == 90.0 && maxSPL == 100.0) {
      return "Moderate live sound reinforcement";
    } else if (minSPL == 100.0 && maxSPL == 120.0) {
      return "High-SPL live sound reinforcement";
    } else {
      return "Background Music"; // Default fallback
    }
  }
}
