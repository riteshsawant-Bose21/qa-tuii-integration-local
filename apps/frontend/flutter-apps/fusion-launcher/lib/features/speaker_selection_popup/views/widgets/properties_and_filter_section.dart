import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/widgets/text_field.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/views/widgets/constant_enums.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/views/widgets/select_listening_area.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/speaker_product.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../viewmodel/add_speaker_view_model.dart';
import '../../viewmodel/product_query_view_model.dart';

class SpeakerListeningAreaProperties extends StatefulWidget {
  const SpeakerListeningAreaProperties({super.key});

  @override
  State<SpeakerListeningAreaProperties> createState() => SpeakerListeningAreaPropertiesState();
}

class SpeakerListeningAreaPropertiesState extends State<SpeakerListeningAreaProperties> {
  final TextEditingController listeningAreaController = TextEditingController();
  final TextEditingController ceilingHeightController = TextEditingController();
  final TextEditingController floorHeightController = TextEditingController(text: '0.0');
  final TextEditingController customListeningHeightController = TextEditingController();

  @override
  void dispose() {
    ceilingHeightController.dispose();
    floorHeightController.dispose();
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
              Divider(
                thickness: 0.5,
                height: 0,
                color: context.colorScheme.strokeLight,
              ),

              Flexible(
                child: SingleChildScrollView(
                  physics: const ClampingScrollPhysics(),
                  child: Column(
                    children: <Widget>[
                      if (!isFromBuildingPage) ...<Widget>[
                        SelectListeningArea(speakerSelectionViewModel: speakerSelectionViewModel),
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

                          ceilingHeightController.text = selectedListeningArea.ceilingHeight.toString() ?? '';
                          listeningAreaController.text = selectedListeningArea.name;

                          final ListeningHeightOption listeningHeightOption = ListeningHeightOption.getOptionByValue(
                            selectedListeningArea.listeningHeight,
                          );

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
                                      Icon(
                                        LucideIcons.maximize100,
                                        size: 16,
                                        color: context.colorScheme.onSurface,
                                      ),
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
                                              hintStyle: context.textTheme.bodySmall?.copyWith(
                                                color: context.colorScheme.onSurface.withAlpha(100),
                                              ),
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
                                              speakerSelectionViewModel.updateListeningAreaName(value);
                                              if (value.trim().isEmpty) {
                                                listeningAreaController.text = selectedListeningArea.name;
                                              }
                                            },
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),

                                  const SizedBox(height: 5),
                                  BuildRowPropertyWidget<String>(
                                    label: "Listener Height",
                                    value: listeningHeightOption.displayName,
                                    labelBuilder: (String option) => option,
                                    options: ListeningHeightOption.values.map((ListeningHeightOption e) => e.displayName).toList(),
                                    onOptionSelected: (int selectedIndex, String newValue) {
                                      final ListeningHeightOption? selectedOption = ListeningHeightOption.values.firstWhereOrNull(
                                        (ListeningHeightOption e) => e.displayName == newValue,
                                      );
                                      if (selectedOption != null) {
                                        speakerSelectionViewModel.setListenerHeight(selectedOption);
                                      }
                                    },
                                  ),

                                  if (listeningHeightOption == ListeningHeightOption.custom) ...<Widget>[
                                    const SizedBox(height: 5),
                                    BuildingPageTextField(
                                      label: "Custom Height",
                                      controller: customListeningHeightController,
                                      hintText: "e.g. ${ListeningHeightOption.maxListeningHeight}",
                                      inputFormatters: <TextInputFormatter>[
                                        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*$')),
                                        LengthLimitingTextInputFormatter(8),
                                      ],
                                      validator: (String? value) {
                                        if (value == null || value.isEmpty) return 'Required';
                                        final double? parsed = double.tryParse(value);
                                        if (parsed == null) return 'Invalid decimal';
                                        if (parsed <= 0) return 'Must be > 0';
                                        if (parsed > ListeningHeightOption.maxListeningHeight) return 'Too large';
                                        return null;
                                      },
                                      onFieldSubmitted: (String newValue) {
                                        final double? parsed = double.tryParse(newValue);
                                        if (parsed != null && parsed > 0 && parsed <= ListeningHeightOption.maxListeningHeight) {
                                          speakerSelectionViewModel.setCustomListeningHeight(parsed);
                                        } else {
                                          customListeningHeightController.text = selectedListeningArea.listeningHeight.toString();
                                          FusionToast.error(
                                            context,
                                            message: 'Please enter a valid listening height between 0 and ${ListeningHeightOption.maxListeningHeight} meters',
                                          );
                                        }
                                      },
                                      onChanged: (String value) {
                                        final double? parsed = double.tryParse(value);
                                        if (value.isNotEmpty && (parsed == null || parsed <= 0 || parsed > ListeningHeightOption.maxListeningHeight)) {
                                          customListeningHeightController.selection = TextSelection.fromPosition(
                                            TextPosition(offset: customListeningHeightController.text.length),
                                          );
                                        }
                                      },
                                    ),
                                  ],
                                  const SizedBox(height: 5),
                                  BuildingPageTextField(
                                    label: "Ceiling Height (m)",
                                    controller: ceilingHeightController,
                                    hintText: "e.g. ${ListeningHeightOption.maxListeningHeight}",
                                    fillColor: context.colorScheme.elevation1,
                                    inputFormatters: <TextInputFormatter>[
                                      FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                    ],
                                    onFieldSubmitted: (String newValue) {
                                      speakerSelectionViewModel.setCeilingHeight(newValue);
                                    },
                                  ),
                                  const SizedBox(height: 5),
                                  // BuildingPageTextField(
                                  //   label: "Floor Height (m)",
                                  //   controller: floorHeightController,
                                  //   hintText: "e.g. 0.0",
                                  //   fillColor: context.colorScheme.elevation1,
                                  //   inputFormatters: <TextInputFormatter>[
                                  //     FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
                                  //   ],
                                  //   onFieldSubmitted: (String newValue) {
                                  //     setState(() {});
                                  //   },
                                  // ),
                                  // const SizedBox(height: 5),
                                  BuildRowPropertyWidget<String>(
                                    label: "Environment",
                                    value: selectedListeningArea.environmentType?.displayName,
                                    options: SpeakerEnvironmentType.values.map((SpeakerEnvironmentType option) => option.displayName).toList(),
                                    labelBuilder: (String option) => option,
                                    onOptionSelected: (int selectedIndex, String newValue) {
                                      speakerSelectionViewModel.setEnvironmentType(selectedIndex);
                                    },
                                  ),
                                  // const SizedBox(height: 5),
                                  // BuildRowPropertyWidget<String>(
                                  //   label: "Background Noise",
                                  //   value: selectedListeningArea.backgroundNoise?.displayName,
                                  //   options: BackgroundNoise.values.map((BackgroundNoise option) => option.displayName).toList(),
                                  //   labelBuilder: (String option) => option,
                                  //   onOptionSelected: (int selectedIndex, String newValue) {
                                  //     speakerSelectionViewModel.setBackgroundNoise(selectedIndex);
                                  //   },
                                  // ),
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
                                    child: Container(
                                      padding: const EdgeInsets.all(4.0),
                                      decoration: BoxDecoration(
                                        color: context.colorScheme.elevation1,
                                        borderRadius: BorderRadius.circular(12),
                                      ),
                                      child: Row(
                                        spacing: 10,
                                        mainAxisSize: MainAxisSize.min,
                                        children: <Widget>[
                                          ...SpeakerSelectionMode.values.map((SpeakerSelectionMode mode) {
                                            final bool isSelected = selectedListeningArea?.speakerSelectionMode == mode;

                                            return GestureDetector(
                                              onTap: () {
                                                final List<SpeakerProduct> speakers = context.read<ProductQueryViewModel>().speakers;
                                                speakerSelectionViewModel.setSpeakerSelectionMode(context, mode, speakers);
                                              },
                                              child: SemanticHelper.container(
                                                testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_mode_${mode.name}"),
                                                child: Container(
                                                  width: 89,
                                                  padding: const EdgeInsets.all(8),
                                                  decoration: BoxDecoration(
                                                    color: isSelected ? context.colorScheme.elevation3 : null,
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
                                );
                              },
                            ),

                            if (selectedListeningArea != null) ...<Widget>[
                              const SizedBox(height: 10),
                              // Target SPL
                              BuildRowPropertyWidget<String>(
                                label: "Target SPL",
                                value: selectedListeningArea.splRange?.name,
                                options: SplRange.values.map((SplRange option) => option.name).toList(),
                                labelBuilder: (String option) => option,
                                onOptionSelected: (int selectedIndex, String newValue) {
                                  speakerSelectionViewModel.setSplRange(selectedIndex);
                                },
                              ),
                              const SizedBox(height: 20),

                              // ── SUGGEST MODE ──
                              if (speakerSelectionViewModel.isSuggestMode) ...<Widget>[
                                // Mounting
                                FusionAppText(
                                  text: 'Mounting',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.normal,
                                    color: context.colorScheme.elevation5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionViewModelState>(
                                  builder: (BuildContext context, SpeakerSelectionViewModelState vmState) {
                                    return SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_mounting_checkbox_group"),
                                      child: FusionRadio<MountingType>(
                                        semanticId: 'speaker_selection_mounting_checkbox_group',
                                        options: MountingType.values.toList(),
                                        selected: selectedListeningArea.mountingType,
                                        labelBuilder: (MountingType option) {
                                          return FusionAppText(
                                            semanticId: "speaker_selection_section_mounting_type_${option.name}",
                                            text: option.displayName,
                                            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                          );
                                        },
                                        onChanged: (MountingType? updated) => speakerSelectionViewModel.setMountingType(updated),
                                      ),
                                    );
                                  },
                                ),

                                // Low Frequency (no Mono in suggest mode)
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
                                    final List<LowFrequency> suggestOptions = speakerSelectionViewModel.getLowFrequencyOptions();
                                    return SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_low_frequency_checkbox_group"),
                                      child: FusionRadio<LowFrequency>(
                                        semanticId: 'speaker_selection_low_frequency_checkbox_group',
                                        options: suggestOptions,
                                        selected: selectedListeningArea.lowFrequency,
                                        labelBuilder: (LowFrequency option) {
                                          return FusionAppText(
                                            text: option.displayName,
                                            semanticId: "speaker_selection_section_low_frequency_${option.name}",
                                            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                          );
                                        },
                                        onChanged: (LowFrequency? updated) => speakerSelectionViewModel.setLowFrequency(updated),
                                      ),
                                    );
                                  },
                                ),
                              ]
                              // ── SELECT MODE ──
                              else ...<Widget>[
                                // Signal Type (Mono / Stereo)
                                MouseRegion(
                                  cursor: SystemMouseCursors.forbidden,
                                  child: SemanticHelper.container(
                                    testId: SemanticHelper.createTestId(SemanticTypes.container, "listening_area_signal_type_radio"),
                                    child: MouseRegion(
                                      cursor: SystemMouseCursors.forbidden,
                                      child: IgnorePointer(
                                        child: FusionRadio<SignalType>(
                                          // selected: selectedListeningArea.signalType,
                                          selected: SignalType.mono,
                                          options: SignalType.values,
                                          labelBuilder: (SignalType signalType) {
                                            return FusionAppText(
                                              text: signalType.name,
                                              style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                            );
                                          },
                                          // onChanged: (SignalType? updated) => speakerSelectionViewModel.setSignalType(updated),
                                        ),
                                      ),
                                    ),
                                  ),
                                ),

                                // Mounting
                                const SizedBox(height: 20),
                                FusionAppText(
                                  text: 'Mounting',
                                  style: context.textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.normal,
                                    color: context.colorScheme.elevation5,
                                  ),
                                ),
                                const SizedBox(height: 8),
                                BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionViewModelState>(
                                  builder: (BuildContext context, SpeakerSelectionViewModelState vmState) {
                                    return SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_mounting_checkbox_group"),
                                      child: FusionRadio<MountingType>(
                                        semanticId: 'speaker_selection_mounting_checkbox_group',
                                        options: MountingType.values.toList(),
                                        selected: selectedListeningArea.mountingType,
                                        labelBuilder: (MountingType option) {
                                          return FusionAppText(
                                            semanticId: "speaker_selection_section_mounting_type_${option.name}",
                                            text: option.displayName,
                                            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                          );
                                        },
                                        onChanged: (MountingType? updated) => speakerSelectionViewModel.setMountingType(updated),
                                      ),
                                    );
                                  },
                                ),

                                // Low Frequency (Mono only when Subwoofer is selected)
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
                                    final List<LowFrequency> selectOptions = speakerSelectionViewModel.getLowFrequencyOptions();
                                    return SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_low_frequency_checkbox_group"),
                                      child: FusionRadio<LowFrequency>(
                                        semanticId: 'speaker_selection_low_frequency_checkbox_group',
                                        options: selectOptions,
                                        selected: selectedListeningArea.lowFrequency,
                                        labelBuilder: (LowFrequency option) {
                                          return FusionAppText(
                                            text: option.displayName,
                                            semanticId: "speaker_selection_section_low_frequency_${option.name}",
                                            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                          );
                                        },
                                        onChanged: (LowFrequency? updated) => speakerSelectionViewModel.setLowFrequency(updated),
                                      ),
                                    );
                                  },
                                ),

                                // Color
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
                                      child: FusionRadio<SpeakerColor>(
                                        semanticId: 'speaker_selection_color_checkbox_group',
                                        options: SpeakerColor.values,
                                        selected: vmState.selectedColor,
                                        labelBuilder: (SpeakerColor option) {
                                          return FusionAppText(
                                            text: option.displayName,
                                            semanticId: "speaker_selection_section_color_${option.name}",
                                            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                          );
                                        },
                                        onChanged: (SpeakerColor? updated) => speakerSelectionViewModel.setColor(updated),
                                      ),
                                    );
                                  },
                                ),

                                // Wiring
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
                                    return SemanticHelper.container(
                                      testId: SemanticHelper.createTestId(SemanticTypes.container, "speaker_selection_section_wiring_radio_group"),
                                      child: FusionRadio<WiringType>(
                                        selected: selectedListeningArea.wiringType,
                                        options: WiringType.values,
                                        labelBuilder: (WiringType wiring) {
                                          return FusionAppText(
                                            text: wiring.name,
                                            style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.onSurface),
                                          );
                                        },
                                        onChanged: (WiringType value) => speakerSelectionViewModel.setWiringType(value),
                                      ),
                                    );
                                  },
                                ),
                              ],
                            ],
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
  final String Function(T option) labelBuilder;
  final Widget Function(T option)? valueBuilder;
  final String hint;

  const BuildRowPropertyWidget({
    super.key,
    required this.label,
    required this.value,
    required this.options,
    required this.onOptionSelected,
    required this.labelBuilder,
    this.valueBuilder,
    this.hint = "Select",
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        Expanded(
          child: FusionAppText(
            text: label,
            style: context.textTheme.l1Regular.copyWith(
              color: context.colorScheme.textPrimary,
            ),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: FusionNeumorphicDropdown<T>(
            popupOffset: const Offset(2, 4),
            popupWidth: 150,
            onChanged: (T newValue) {
              final int selectedIndex = options.indexOf(newValue);
              onOptionSelected(selectedIndex, newValue);
            },
            matchChildWidth: false,
            items: options,
            itemBuilder: (BuildContext context, T option) {
              if (valueBuilder != null) {
                return valueBuilder!(option);
              } else {
                return FusionAppText(
                  text: labelBuilder(option),
                  style: context.textTheme.bodySmall,
                );
              }
            },
            child: FusionContainer(
              borderRadius: 8,
              raised: true,
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: <Widget>[
                    Expanded(
                      child: Builder(
                        builder: (BuildContext context) {
                          if (valueBuilder != null && value != null) {
                            return valueBuilder!(value as T);
                          } else {
                            return FusionAppText(
                              text: value != null ? labelBuilder(value as T) : hint,
                              maxLine: 1,
                              style: context.textTheme.bodySmall?.copyWith(
                                color: value != null ? context.colorScheme.textPrimary : context.colorScheme.textPlaceholder,
                              ),
                            );
                          }
                        },
                      ),
                    ),
                    const SizedBox(width: 2),
                    Icon(
                      LucideIcons.chevronDown200,
                      color: context.colorScheme.textPrimary,
                      size: 16,
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
