import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/parts/constant_enums.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/parts/select_listening_area.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/drop_down.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/text_field.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../view_model/add_speaker_view_model.dart';

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
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(16),
      ),
      child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
        builder: (BuildContext context, ProjectViewModelState state) {
          final SpeakerSelectionViewModel speakerSelectionViewModel = context.watch<SpeakerSelectionViewModel>();
          final ListeningArea? selectedListeningArea = speakerSelectionViewModel.selectedListeningArea;

          final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
          final bool isFromBuildingPage = speakerSelectionViewModel.isFromBuildingPage;

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
                    SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "close_dropdown_button"),
                      child: MouseRegion(
                        cursor: SystemMouseCursors.click,
                        child: GestureDetector(
                          onTap: () => Navigator.of(context).pop(),
                          child: const Padding(
                            padding: EdgeInsets.all(2.0),
                            child: Icon(LucideIcons.x200, size: 16),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Divider(thickness: 0.5, height: 0, color: context.colorScheme.strokeLight),

              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: <Widget>[
                      if (!isFromBuildingPage) ...<Widget>[
                        SelectListeningArea(
                          speakerSelectionViewModel: speakerSelectionViewModel,
                        ),
                        const SizedBox(height: 10),
                      ],

                      Builder(
                        builder: (BuildContext context) {
                          if (selectedListeningArea == null) {
                            return Column(
                              children: <Widget>[
                                Center(
                                  child: Padding(
                                    padding: const EdgeInsets.symmetric(vertical: 60),
                                    child: FusionAppText(
                                      text: "Select listening area\nto view properties",
                                      textAlign: TextAlign.center,
                                      style: context.textTheme.labelSmall?.copyWith(
                                        color: context.colorScheme.onSurface.withAlpha(100),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            );
                          }

                          ceilingHeightController.text = selectedListeningArea.ceilingHeight;
                          listeningAreaController.text = selectedListeningArea.name;

                          final ListeningHeightOption listeningHeightOption = ListeningHeightOption.getOptionByValue(selectedListeningArea.listeningHeight);

                          return SemanticHelper.container(
                            testId: SemanticHelper.createTestId(SemanticTypes.container, "listening_area_properties_section"),
                            child: Padding(
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
                                        child: SemanticHelper.formControl(
                                          testId: SemanticHelper.createTestId(SemanticTypes.textInput, "listening_area_name_input"),
                                          child: TextFormField(
                                            controller: listeningAreaController,
                                            maxLength: 24,
                                            decoration: InputDecoration(
                                              counterText: '',
                                              hintText: 'Enter area name',
                                              hintStyle: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface.withAlpha(100)),
                                              border: InputBorder.none,
                                              enabledBorder: InputBorder.none,
                                              focusedBorder: InputBorder.none,
                                              focusedErrorBorder: InputBorder.none,
                                              errorBorder: InputBorder.none,
                                              disabledBorder: InputBorder.none,
                                              focusColor: Colors.transparent,
                                              hoverColor: Colors.transparent,
                                              contentPadding: const EdgeInsets.symmetric(horizontal: 4, vertical: 10),
                                              isDense: true,
                                              fillColor: Colors.transparent,
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
                                      ),
                                    ],
                                  ),

                                  BuildRowPropertyWidget<String>(
                                    label: "Type",
                                    value: selectedListeningArea.venuType?.name ?? '',
                                    options: VenueType.values.map((VenueType option) => option.name).toList(),
                                    labelBuilder: (String option) {
                                      return FusionAppText(
                                        text: option,
                                        style: Theme.of(context).textTheme.labelMedium,
                                      );
                                    },

                                    onOptionSelected: (int selectedIndex, String newValue) {
                                      final VenueType selectedType = VenueType.values[selectedIndex];
                                      final ListeningArea updatedLA = selectedListeningArea.copyWith(venuType: selectedType);
                                      projectViewModel.updateListeningArea(area: updatedLA);
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  BuildRowPropertyWidget<String>(
                                    label: "Listening Ht",
                                    value: listeningHeightOption.displayName,
                                    labelBuilder: (String option) {
                                      return FusionAppText(
                                        text: option,
                                        style: Theme.of(context).textTheme.labelMedium,
                                      );
                                    },
                                    options: ListeningHeightOption.values.map((ListeningHeightOption option) => option.displayName).toList(),
                                    onOptionSelected: (int selectedIndex, String newValue) {
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
                                  BuildRowPropertyWidget<String>(
                                    label: "SPL Range",
                                    value: selectedListeningArea.splRange?.name ?? "",
                                    options: SplRange.values.map((SplRange option) => option.name).toList(),
                                    labelBuilder: (String option) {
                                      return FusionAppText(
                                        text: option,
                                        style: Theme.of(context).textTheme.labelMedium,
                                      );
                                    },
                                    onOptionSelected: (int selectedIndex, String newValue) {
                                      final Map<String, double> splRangeValues = SplRange.values[selectedIndex].splRangeValues;
                                      final double minSPL = splRangeValues["min"]!;
                                      final double maxSPL = splRangeValues["max"]!;
                                      final ListeningArea updatedLA = selectedListeningArea.copyWith(
                                        minSPL: minSPL,
                                        maxSPL: maxSPL,
                                        splRange: SplRange.values[selectedIndex],
                                      );
                                      projectViewModel.updateListeningArea(area: updatedLA);
                                    },
                                  ),
                                  const SizedBox(height: 10),

                                  SemanticHelper.container(
                                    testId: SemanticHelper.createTestId(SemanticTypes.container, "listening_area_signal_type_radio"),
                                    child: MouseRegion(
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
                                  ),
                                ],
                              ),
                            ),
                          );
                        },
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
                                return SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_mode_section"),
                                  child: Center(
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
                                                  child: SemanticHelper.container(
                                                    testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_mode_${mode.name}"),
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
                                                  ),
                                                );
                                              }),
                                            ],
                                          ),
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
                                return SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_mounting_checkbox_group"),
                                  child: FusionCheckboxGroup<MountingType>(
                                    options: MountingType.values.toList(),
                                    selected: (selectedListeningArea?.mountingTypes ?? <MountingType>{}).toList(),
                                    labelBuilder: (BuildContext context, MountingType option) {
                                      return FusionAppText(
                                        semanticId: "speaker_selection_section_mounting_type_${option.name}",
                                        text: option.name,
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.onSurface,
                                        ),
                                      );
                                    },
                                    onChanged: (List<MountingType> updated) => speakerSelectionViewModel.setMountingTypes(updated),
                                  ),
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
                                return SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_low_frequency_checkbox_group"),
                                  child: FusionCheckboxGroup<LowFrequency>(
                                    options: LowFrequency.values,
                                    selected: (selectedListeningArea?.lowFrequencies ?? <LowFrequency>{}).toList(),
                                    labelBuilder: (BuildContext context, LowFrequency option) {
                                      return FusionAppText(
                                        text: option.name,
                                        semanticId: "speaker_selection_section_low_frequency_${option.name}",
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.onSurface,
                                        ),
                                      );
                                    },
                                    onChanged: (List<LowFrequency> updated) => speakerSelectionViewModel.setLowFrequencies(updated),
                                  ),
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
                                return SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_color_checkbox_group"),
                                  child: FusionCheckboxGroup<SpeakerColor>(
                                    options: SpeakerColor.values,
                                    selected: vmState.selectedColors.toList(),
                                    labelBuilder: (BuildContext context, SpeakerColor option) {
                                      return FusionAppText(
                                        text: option.displayName,
                                        semanticId: "speaker_selection_section_color_${option.name}",
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.onSurface,
                                        ),
                                      );
                                    },
                                    onChanged: (List<SpeakerColor> updated) => speakerSelectionViewModel.setColors(updated),
                                  ),
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
                                final WiringType? wiringType = selectedListeningArea?.wiringType;

                                return SemanticHelper.container(
                                  testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_section_wiring_radio_group"),
                                  child: FusionRadio<WiringType>(
                                    selected: wiringType,
                                    options: WiringType.values,
                                    labelBuilder: (WiringType wiring) {
                                      return FusionAppText(
                                        text: wiring.name,
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.onSurface,
                                        ),
                                      );
                                    },
                                    onChanged: (WiringType value) {
                                      speakerSelectionViewModel.setWiringType(value);
                                    },
                                  ),
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );
  }
}

class BuildRowPropertyWidget<T> extends StatelessWidget {
  final String label;
  final T? value;
  final List<T> options;
  // final ValueChanged<int, T> onOptionSelected;
  final void Function(int selectedIndex, T value) onOptionSelected;
  final Widget Function(T option) labelBuilder;
  final Widget Function(T option)? valueBuilder;

  const BuildRowPropertyWidget({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onOptionSelected,
    required this.labelBuilder,
    this.valueBuilder,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.bodyMedium?.copyWith(
              color: context.colorScheme.onSurface,
              fontWeight: FontWeight.normal,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: BuildingPageDronDown<T>(
            value: value,
            hintText: "Select ${label.toLowerCase()}",
            items: options,
            onSelect: (T newValue) {
              final int selectedIndex = options.indexOf(newValue);
              onOptionSelected(selectedIndex, newValue);
            },
            labelBuilder: labelBuilder,
            valueBuilder: valueBuilder,
          ),
        ),
      ],
    );
  }
}
