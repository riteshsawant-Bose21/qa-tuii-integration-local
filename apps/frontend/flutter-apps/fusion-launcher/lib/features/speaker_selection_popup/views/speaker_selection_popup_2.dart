import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/speaker_selection_vm.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../add_output_device_drawer/viewmodel/add_output_device_vm.dart';
import '../../add_source_popup/view/widgets/common_widgets/add_sources_dropdown.dart';
import '../../create_zone_popup/view/widgets/CommonWidgets/create_zone_bordered_textfield.dart';
import '../../create_zone_popup/view/widgets/CommonWidgets/create_zone_label_field.dart';
import '../viewmodel/stepped_haptic_slider.dart';

class SpeakerSelectionPopup2 extends StatefulWidget {
  const SpeakerSelectionPopup2({super.key});

  static Future<void> show({required BuildContext context}) {
    return FusionDrawer.show<void>(
      context: context,
      semanticId: 'speaker_selection',
      title: 'SPEAKERS',
      width: 836,
      scrollable: false,
      content: const SpeakerSelectionPopup2(),
    );
  }

  @override
  State<SpeakerSelectionPopup2> createState() => _SpeakerSelectionPopup2State();
}

class _SpeakerSelectionPopup2State extends State<SpeakerSelectionPopup2> {
  final List<String> _areaOptions = <String>['Area 1', 'Area 2', 'Area 3'];
  String? _selectedArea = 'Area 1';

  final TextEditingController _ceilingHeightCtrl = TextEditingController(text: '3.0');
  final TextEditingController _floorHeightCtrl = TextEditingController(text: '0.0');
  final TextEditingController _searchController = TextEditingController();

  int _selectedProductIndex = -1;
  int _expandedProductIndex = -1;

  final List<Map<String, String>> _products = <Map<String, String>>[
    <String, String>{'name': 'PSM8300-1', 'price': '\$2,000.00'},
    <String, String>{'name': 'PSM8300-1', 'price': '\$2,000.00'},
    <String, String>{'name': 'PSM8300-1', 'price': '\$2,000.00'},
    <String, String>{'name': 'PSM8300-1', 'price': '\$2,000.00'},
    <String, String>{'name': 'PSM8300-1', 'price': '\$2,000.00'},
  ];

  @override
  void dispose() {
    _ceilingHeightCtrl.dispose();
    _floorHeightCtrl.dispose();
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SpeakerSelectionViewModel>(
      create: (BuildContext context) => SpeakerSelectionViewModel(),
      child: Container(
        width: double.infinity,
        constraints: BoxConstraints(maxHeight: MediaQuery.of(context).size.height),
        color: context.colorScheme.elevation1,
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            Expanded(child: _buildLeftPanel(context)),
            const SizedBox(width: 10),
            Expanded(child: _buildRightPanel(context)),
          ],
        ),
      ),
    );
  }

  Widget _buildLeftPanel(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionOutlinedDropdown<String>(
            label: 'Listening Area',
            hint: 'Select listening area',
            value: _selectedArea,
            items: _areaOptions,
            itemLabelBuilder: (String v) => v,
            onChanged: (String v) => setState(() => _selectedArea = v),
          ),

          ///
          /// ======== Listener Height Selection =======
          ///
          const SizedBox(height: 20),
          const Row(
            children: <Widget>[
              Expanded(
                child: FusionLabeledField(
                  label: "Ceiling Height (M)",
                  semanticId: 'ceiling_height_label',
                  child: FusionBorderedTextField(
                    semanticId: 'ceiling_height_textfield',
                    hintText: 'Enter ceiling height',
                    contentPadding: EdgeInsets.all(16),
                    // onChanged: context.read<AddOutputDeviceViewModel>().updateOutputDeviceName,
                  ),
                ),
              ),
              SizedBox(width: 10),
              Expanded(
                child: FusionLabeledField(
                  label: "Floor Height (M)",
                  semanticId: 'floor_height_label',
                  child: FusionBorderedTextField(
                    semanticId: 'floor_height_textfield',
                    hintText: 'Enter floor height',
                    contentPadding: EdgeInsets.all(16),
                    // onChanged: context.read<AddOutputDeviceViewModel>().updateOutputDeviceName,
                  ),
                ),
              ),
            ],
          ),

          ///
          /// ======== Listener Height Selection =======
          ///
          const SizedBox(height: 20),
          const _ListenerHeightSelection(),

          /// ======== Environment Selection =======
          const SizedBox(height: 20),
          const _EnvironmentSelection(),

          const SizedBox(height: 20),
          Divider(height: 1, color: context.colorScheme.strokeLight),
          const SizedBox(height: 20),
          Container(
            height: 68,
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: context.colorScheme.elevation2,
              borderRadius: BorderRadius.circular(16),
            ),
            child: BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
              buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.speakerSelectionMode != current.speakerSelectionMode,
              builder: (BuildContext context, SpeakerSelectionVmState state) {
                final SpeakerSelectionMode selectionMode = state.speakerSelectionMode;

                return Row(
                  children: <Widget>[
                    Expanded(
                      child: _ModeChip(
                        label: 'Select Speaker',
                        selected: selectionMode == SpeakerSelectionMode.select,
                        onTap: () => context.read<SpeakerSelectionViewModel>().setSpeakerSelectionMode(SpeakerSelectionMode.select),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: _ModeChip(
                        label: 'Suggest Speaker',
                        selected: selectionMode == SpeakerSelectionMode.suggest,
                        onTap: () => context.read<SpeakerSelectionViewModel>().setSpeakerSelectionMode(SpeakerSelectionMode.suggest),
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          /// ======== Mounting Type Selection =======
          const SizedBox(height: 20),
          const _MountingTypeSelection(),

          /// ======== Maximum SPL Selection =======
          const SizedBox(height: 20),
          const _MaxSplSelection(),

          const SizedBox(height: 20),
          const _LowFrequencySelection(),

          const SizedBox(height: 20),
          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.useSubwoofer != current.useSubwoofer,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return Row(
                children: <Widget>[
                  FusionSwitch(
                    height: 24,
                    width: 44,
                    semanticId: "use_subwoofer",
                    value: state.useSubwoofer,
                    onChanged: context.read<SpeakerSelectionViewModel>().setUseSubwoofer,
                  ),
                  const SizedBox(width: 8),
                  FusionAppText(
                    text: 'Use Subwoofer',
                    style: context.textTheme.b3Regular.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),

          /// ======== Colour Selection =======
          const SizedBox(height: 20),
          const _ColourSelection(),

          /// ======== Wiring Selection =======
          const SizedBox(height: 20),
          const _WiringSelection(),

          /// ======== Audio Channel Selection =======
          const SizedBox(height: 20),
          const _ChannelsSelection(),
        ],
      ),
    );
  }

  Widget _buildRightPanel(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: context.colorScheme.elevation2,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: Column(
          children: <Widget>[
            Container(
              width: double.infinity,
              height: 88,
              alignment: Alignment.center,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: context.colorScheme.strokeLight),
              ),
              child: FusionAppText(
                text: _selectedProductIndex == -1 ? 'No speaker selected yet' : _products[_selectedProductIndex]['name']!,
                style: context.textTheme.b3Regular.copyWith(color: context.colorScheme.textPlaceholder),
              ),
            ),
            const SizedBox(height: 10),
            _SearchBar(controller: _searchController),
            const SizedBox(height: 10),
            Expanded(
              child: ListView.separated(
                itemCount: _products.length,
                separatorBuilder: (_, __) => Divider(height: 1, color: context.colorScheme.strokeLight),
                itemBuilder: (BuildContext context, int index) {
                  final Map<String, String> product = _products[index];
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 10),
                    child: Column(
                      children: <Widget>[
                        Row(
                          children: <Widget>[
                            Container(
                              width: 44,
                              height: 44,
                              decoration: BoxDecoration(
                                color: context.colorScheme.elevation3,
                                borderRadius: BorderRadius.circular(22),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  FusionAppText(text: product['name']!, style: context.textTheme.b3Medium.copyWith(color: context.colorScheme.textPrimary)),
                                  const SizedBox(height: 2),
                                  FusionAppText(text: product['price']!, style: context.textTheme.b3Regular.copyWith(color: context.colorScheme.textPrimary)),
                                ],
                              ),
                            ),
                            SizedBox(
                              width: 86,
                              child: FusionNeumorphicButton(
                                semanticId: 'speaker_select_btn_$index',
                                onTap: () => setState(() => _selectedProductIndex = index),
                                text: _selectedProductIndex == index ? 'Selected' : 'Select',
                                textStyle: context.textTheme.b3Regular,
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 8),
                        Align(
                          alignment: Alignment.centerLeft,
                          child: GestureDetector(
                            onTap: () {
                              setState(() {
                                _expandedProductIndex = _expandedProductIndex == index ? -1 : index;
                              });
                            },
                            child: MouseRegion(
                              cursor: SystemMouseCursors.click,
                              child: FusionAppText(
                                text: _expandedProductIndex == index ? 'Hide Specifications ^' : 'Show Specifications v',
                                style: context.textTheme.labelSmall?.copyWith(color: context.colorScheme.textPrimary),
                              ),
                            ),
                          ),
                        ),
                        if (_expandedProductIndex == index) ...<Widget>[
                          const SizedBox(height: 8),
                          Divider(height: 1, color: context.colorScheme.strokeLight),
                          const SizedBox(height: 10),
                          const _SpecGrid(),
                        ],
                      ],
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ListenerHeightSelection extends StatelessWidget {
  const _ListenerHeightSelection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_audio_channel'),
      child: Column(
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: _SectionTitle(
              title: "Listener Height (M)",
            ),
          ),
          const SizedBox(height: 8),

          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.listeningHeightOption != current.listeningHeightOption,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return Row(
                spacing: 10,
                children: <Widget>[
                  ...SpeakerListenerHeightOption.values.map(
                    (SpeakerListenerHeightOption option) {
                      final bool isSelected = state.listeningHeightOption == option;

                      return Expanded(
                        child: Column(
                          spacing: 8,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () => context.read<SpeakerSelectionViewModel>().setListeningHeightOption(option),
                              child: Container(
                                height: 52,
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected ? context.colorScheme.elevation2 : context.colorScheme.elevation1,
                                  border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                                ),
                                child: FusionIcon.svg(
                                  option.icon,
                                  size: 24,
                                  color: isSelected ? context.colorScheme.iconWhite : context.colorScheme.iconDefault,
                                ),
                              ),
                            ),

                            FusionAppText(
                              text: option.displayName,
                              maxLine: 1,
                              style: context.textTheme.l1Regular.copyWith(
                                color: context.colorScheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _EnvironmentSelection extends StatelessWidget {
  const _EnvironmentSelection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'speaker_environment_selection'),
      child: Column(
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: _SectionTitle(
              title: "Environment",
            ),
          ),
          const SizedBox(height: 8),

          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.environmentType != current.environmentType,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return Row(
                spacing: 10,
                children: <Widget>[
                  ...SpeakerEnvironmentType.values.map(
                    (SpeakerEnvironmentType option) {
                      final bool isSelected = state.environmentType == option;

                      return Expanded(
                        child: Column(
                          spacing: 8,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () => context.read<SpeakerSelectionViewModel>().setEnvironmentType(option),
                              child: Container(
                                height: 52,
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected ? context.colorScheme.elevation2 : context.colorScheme.elevation1,
                                  border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                                ),
                                child: FusionIcon.svg(
                                  option.icon,
                                  size: 24,
                                  color: isSelected ? context.colorScheme.iconWhite : context.colorScheme.iconDefault,
                                ),
                              ),
                            ),

                            FusionAppText(
                              text: option.displayName,
                              maxLine: 1,
                              style: context.textTheme.l1Regular.copyWith(
                                color: context.colorScheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MountingTypeSelection extends StatelessWidget {
  const _MountingTypeSelection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'speaker_mounting_selection'),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: <Widget>[
                const _SectionTitle(title: "Mounting"),
                const SizedBox(width: 4),
                FusionAppText(
                  text: '(Multi-select)',
                  style: context.textTheme.l1Regular.copyWith(
                    color: context.colorScheme.textBody,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),

          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.mountingTypes != current.mountingTypes,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return Row(
                spacing: 10,
                children: <Widget>[
                  ...MountingType.values.map(
                    (MountingType option) {
                      final bool isSelected = state.mountingTypes.contains(option);

                      return Expanded(
                        child: Column(
                          spacing: 8,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () => context.read<SpeakerSelectionViewModel>().setMountingType(option),
                              child: Container(
                                height: 52,
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected ? context.colorScheme.elevation2 : context.colorScheme.elevation1,
                                  border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                                ),
                                child: FusionIcon.svg(
                                  option.icon,
                                  size: 24,
                                  color: isSelected ? context.colorScheme.iconWhite : context.colorScheme.iconDefault,
                                ),
                              ),
                            ),

                            FusionAppText(
                              text: option.displayName,
                              maxLine: 1,
                              style: context.textTheme.l1Regular.copyWith(
                                color: context.colorScheme.textPrimary,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _MaxSplSelection extends StatelessWidget {
  const _MaxSplSelection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'speaker_max_spl_selection'),
      child: Column(
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: _SectionTitle(title: "Maximum SPL (1W/1m)"),
          ),
          const SizedBox(height: 8),

          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.maxSplRange != current.maxSplRange,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return Row(
                spacing: 10,
                children: <Widget>[
                  ...SpeakerMaxSplRange.values.map(
                    (SpeakerMaxSplRange option) {
                      final bool isSelected = state.maxSplRange == option;

                      return Expanded(
                        child: Column(
                          spacing: 8,
                          children: <Widget>[
                            GestureDetector(
                              onTap: () => context.read<SpeakerSelectionViewModel>().setMaxSplRange(option),
                              child: Container(
                                height: 52,
                                width: double.infinity,
                                padding: const EdgeInsets.all(16),
                                alignment: Alignment.center,
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(12),
                                  color: isSelected ? context.colorScheme.elevation2 : context.colorScheme.elevation1,
                                  border: Border.all(color: context.colorScheme.strokeLight, width: 1),
                                ),
                                child: FusionAppText(
                                  text: option.displayName,
                                  maxLine: 1,
                                  style: context.textTheme.l1Regular.copyWith(
                                    color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.textBody,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }
}

class _LowFrequencySelection extends StatelessWidget {
  const _LowFrequencySelection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'speaker_low_frequency_selection'),
      child: Column(
        children: <Widget>[
          const Align(
            alignment: Alignment.centerLeft,
            child: _SectionTitle(title: "Low Frequency (Hz)"),
          ),
          const SizedBox(height: 8),

          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.lowFrequencyInHz != current.lowFrequencyInHz,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return SteppedHapticSlider(
                min: 50,
                max: 100,
                interval: 10, // creates stops at 50, 60, 70, 80, 90, 100
                initialValue: 70,
                onChanged: (double value) => context.read<SpeakerSelectionViewModel>().setLowFrequencyInHz(value),
                hapticFeedbackType: HapticFeedbackType.vibrate,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ColourSelection extends StatelessWidget {
  const _ColourSelection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'speaker_colour_selection'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle(title: 'Colour'),
          const SizedBox(height: 8),
          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.speakerColorOption != current.speakerColorOption,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return FusionRadioChipSelector<SpeakerColorOption>(
                selected: state.speakerColorOption,
                options: SpeakerColorOption.values,
                labelBuilder: (SpeakerColorOption option) => option.displayName,
                onChanged: context.read<SpeakerSelectionViewModel>().setSpeakerColorOption,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _WiringSelection extends StatelessWidget {
  const _WiringSelection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'speaker_wiring_selection'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle(title: 'Wiring'),
          const SizedBox(height: 8),
          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.wiringType != current.wiringType,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return FusionRadioChipSelector<WiringType>(
                selected: state.wiringType,
                options: WiringType.values,
                labelBuilder: (WiringType option) => option.displayName,
                onChanged: context.read<SpeakerSelectionViewModel>().setWiringType,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _ChannelsSelection extends StatelessWidget {
  const _ChannelsSelection();

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'speaker_channels_selection'),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          const _SectionTitle(title: 'Channels'),
          const SizedBox(height: 8),
          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) => previous.audioChannel != current.audioChannel,
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return FusionRadioChipSelector<AudioChannel>(
                selected: state.audioChannel,
                options: AudioChannel.values,
                labelBuilder: (AudioChannel option) => option.displayName,
                onChanged: context.read<SpeakerSelectionViewModel>().setAudioChannel,
              );
            },
          ),
        ],
      ),
    );
  }
}

class _SectionTitle extends StatelessWidget {
  final String title;
  const _SectionTitle({required this.title});

  @override
  Widget build(BuildContext context) {
    return FusionAppText(
      text: title,
      style: context.textTheme.l1Medium.copyWith(
        color: context.colorScheme.textPrimary,
      ),
    );
  }
}

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;

  const _ModeChip({required this.label, required this.selected, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? context.colorScheme.elevation3 : Colors.transparent,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: FusionAppText(
            text: label,
            style: context.textTheme.b3Regular.copyWith(color: context.colorScheme.textPrimary),
          ),
        ),
      ),
    );
  }
}

class _SearchBar extends StatelessWidget {
  final TextEditingController controller;
  const _SearchBar({required this.controller});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 44,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: context.colorScheme.strokeLight),
      ),
      child: Row(
        children: <Widget>[
          Icon(LucideIcons.search200, size: 16, color: context.colorScheme.iconWhite),
          const SizedBox(width: 8),
          Expanded(
            child: TextField(
              controller: controller,
              style: context.textTheme.b3Regular.copyWith(color: context.colorScheme.textPrimary),
              decoration: const InputDecoration(
                border: InputBorder.none,
                isDense: true,
                hintText: 'Search Speaker...',
              ),
            ),
          ),
          Icon(LucideIcons.arrowUpDown200, size: 16, color: context.colorScheme.iconWhite),
        ],
      ),
    );
  }
}

class _SpecGrid extends StatelessWidget {
  const _SpecGrid();

  @override
  Widget build(BuildContext context) {
    return const Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SpecItem(label: 'L x W x H', value: '22.4cm | 14.7cm | 8.3cm'),
              _SpecItem(label: 'Mounting', value: 'Surface'),
              _SpecItem(label: 'Environment', value: 'Indoor'),
              _SpecItem(label: 'Power Handling', value: 'RMS 100 W, Peak 200 W'),
              _SpecItem(label: 'Sensitivity', value: '86 dB @ 1W @ 1m'),
              _SpecItem(label: 'Peak Power', value: '200 Watts'),
            ],
          ),
        ),
        SizedBox(width: 16),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: <Widget>[
              _SpecItem(label: 'Frequency Response', value: '60-20000 Hz'),
              _SpecItem(label: 'HF Size', value: 'N/A'),
              _SpecItem(label: 'LF Size', value: 'N/A'),
              _SpecItem(label: 'Max. SPL', value: '101.0 dB SPL @ continuous'),
              _SpecItem(label: 'Long Term Power', value: '100 Watts'),
            ],
          ),
        ),
      ],
    );
  }
}

class _SpecItem extends StatelessWidget {
  final String label;
  final String value;

  const _SpecItem({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: label,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.textPlaceholder,
              fontSize: 9,
            ),
          ),
          const SizedBox(height: 2),
          FusionAppText(
            text: value,
            style: context.textTheme.labelSmall?.copyWith(
              color: context.colorScheme.textPrimary,
              fontSize: 10,
            ),
          ),
        ],
      ),
    );
  }
}
