import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/constant_enums.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_checkbox_group.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import 'view_model/view_model.dart';

class SpeakerListeningAreaProperties extends StatefulWidget {
  const SpeakerListeningAreaProperties({super.key});

  @override
  State<SpeakerListeningAreaProperties> createState() => SpeakerListeningAreaPropertiesState();
}

class SpeakerListeningAreaPropertiesState extends State<SpeakerListeningAreaProperties> {
  final TextEditingController listeningAreaController = TextEditingController();
  final TextEditingController ceilingHeightController = TextEditingController();
  final TextEditingController customListeningHeightController = TextEditingController();

  @override
  void dispose() {
    ceilingHeightController.dispose();
    listeningAreaController.dispose();
    customListeningHeightController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    final SpeakerSelectionViewModel speakerSelectionViewModel = context.watch<SpeakerSelectionViewModel>();

    return Container(
      decoration: BoxDecoration(
        color: const Color(0xFF292826),
        borderRadius: BorderRadius.circular(16),
      ),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final ListeningArea? selectedListeningArea = projectViewModel.getCurrentSelectedListeningArea();

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

                    final ListeningHeightOption listeningHeightOption = ListeningHeightOption.getOptionByValue(selectedListeningArea.listeningHeight);

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
                                      projectViewModel.updateListeningArea(area: updatedLA);
                                    } else {
                                      listeningAreaController.text = selectedListeningArea.name;
                                    }
                                  },
                                ),
                              ),
                            ],
                          ),

                          BuildRowPropertyWidget(
                            label: "Type",
                            value: selectedListeningArea.venuType,
                            options: VenueOptions.values.map((VenueOptions option) => option.displayName).toList(),
                            onOptionSelected: (int selectedIndex) {
                              final String selectedType = VenueOptions.values[selectedIndex].displayName;
                              final ListeningArea updatedLA = selectedListeningArea.copyWith(venuType: selectedType);
                              projectViewModel.updateListeningArea(area: updatedLA);
                            },
                          ),
                          const SizedBox(height: 5),
                          BuildRowPropertyWidget(
                            label: "Listening Ht",
                            value: listeningHeightOption.displayName,
                            options: ListeningHeightOption.values.map((ListeningHeightOption option) => option.displayName).toList(),
                            onOptionSelected: (int selectedIndex) {
                              final ListeningHeightOption selectedOption = ListeningHeightOption.values[selectedIndex];
                              final double heightValue = ListeningHeightOption.getValue(selectedOption) ?? 3.0;
                              final ListeningArea updatedLA = selectedListeningArea.copyWith(listeningHeight: heightValue);
                              projectViewModel.updateListeningArea(area: updatedLA);
                            },
                          ),

                          if (listeningHeightOption == ListeningHeightOption.custom) ...<Widget>[
                            const SizedBox(height: 5),
                            BuildingPageTextField(
                              label: "Custom Height",
                              controller: customListeningHeightController,
                              hintText: "e.g. 4.5",
                              inputFormatters: <TextInputFormatter>[
                                FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                LengthLimitingTextInputFormatter(8),
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
                                    projectViewModel.updateListeningArea(area: updatedLA);
                                  }
                                } else {
                                  customListeningHeightController.text = selectedListeningArea.listeningHeight.toString();
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
                                final double? parsed = double.tryParse(value);
                                if (value.isNotEmpty && (parsed == null || parsed <= 0 || parsed > 1000)) {
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
                              projectViewModel.updateListeningArea(area: updatedLA);
                            },
                          ),
                          const SizedBox(height: 5),
                          BuildRowPropertyWidget(
                            label: "SPL Range",
                            value: SpeakerSplRangeOptions.getSplRange(selectedListeningArea.minSPL, selectedListeningArea.maxSPL).displayName,
                            options: SpeakerSplRangeOptions.values.map((SpeakerSplRangeOptions option) => option.displayName).toList(),
                            onOptionSelected: (int selectedIndex) {
                              final Map<String, double> splRangeValues = SpeakerSplRangeOptions.values[selectedIndex].splRangeValues;
                              final double minSPL = splRangeValues["min"]!;
                              final double maxSPL = splRangeValues["max"]!;
                              final ListeningArea updatedLA = selectedListeningArea.copyWith(minSPL: minSPL, maxSPL: maxSPL);
                              projectViewModel.updateListeningArea(area: updatedLA);
                            },
                          ),
                          const SizedBox(height: 10),

                          MouseRegion(
                            cursor: SystemMouseCursors.forbidden,
                            child: IgnorePointer(
                              child: FusionRadio<SignalType>(
                                selected: speakerSelectionViewModel.state.selectedSignalType,
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
                            ),
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
                    BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionViewModelState>(
                      builder: (BuildContext context, SpeakerSelectionViewModelState vmState) {
                        return Center(
                          child: MouseRegion(
                            cursor: SystemMouseCursors.forbidden,
                            child: IgnorePointer(
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
                                      final bool isSelected = vmState.mode == mode;

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
                          ),
                        );
                      },
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
                    BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionViewModelState>(
                      builder: (BuildContext context, SpeakerSelectionViewModelState vmState) {
                        return FusionCheckboxGroup<SpeakerMountingType>(
                          options: SpeakerMountingType.values,
                          selected: vmState.selectedMountingTypes.toList(),
                          labelBuilder: (BuildContext context, SpeakerMountingType option) {
                            return FusionAppText(
                              text: option.displayName,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
                            );
                          },
                          onChanged: (List<SpeakerMountingType> updated) => speakerSelectionViewModel.setMountingTypes(updated),
                        );
                      },
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
                    BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionViewModelState>(
                      builder: (BuildContext context, SpeakerSelectionViewModelState vmState) {
                        return FusionCheckboxGroup<SpeakerLowFrequency>(
                          options: SpeakerLowFrequency.values,
                          selected: vmState.selectedLowFrequencies.toList(),
                          labelBuilder: (BuildContext context, SpeakerLowFrequency option) {
                            return FusionAppText(
                              text: option.displayName,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
                            );
                          },
                          onChanged: (List<SpeakerLowFrequency> updated) => speakerSelectionViewModel.setLowFrequencies(updated),
                        );
                      },
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
                    BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionViewModelState>(
                      builder: (BuildContext context, SpeakerSelectionViewModelState vmState) {
                        return FusionCheckboxGroup<SpeakerColor>(
                          options: SpeakerColor.values,
                          selected: vmState.selectedColors.toList(),
                          labelBuilder: (BuildContext context, SpeakerColor option) {
                            return FusionAppText(
                              text: option.displayName,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: context.colorScheme.onSurface,
                              ),
                            );
                          },
                          onChanged: (List<SpeakerColor> updated) => speakerSelectionViewModel.setColors(updated),
                        );
                      },
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
                    BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionViewModelState>(
                      builder: (BuildContext context, SpeakerSelectionViewModelState vmState) {
                        final SpeakerWiring? selected = vmState.selectedWirings.isEmpty ? null : vmState.selectedWirings.first;
                        return FusionRadio<SpeakerWiring>(
                          selected: selected,
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
                            speakerSelectionViewModel.setWiring(value);
                          },
                        );
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
}

class BuildRowPropertyWidget extends StatelessWidget {
  final String label;
  final String value;
  final List<String> options;
  final ValueChanged<int> onOptionSelected;

  const BuildRowPropertyWidget({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onOptionSelected,
  });

  @override
  Widget build(BuildContext context) {
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
}
