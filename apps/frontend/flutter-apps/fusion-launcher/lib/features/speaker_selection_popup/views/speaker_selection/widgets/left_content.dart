part of '../speaker_selection_popup_2.dart';

class SpeakerSelectionLeftContent extends StatelessWidget {
  const SpeakerSelectionLeftContent({super.key});
  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      physics: const ClampingScrollPhysics(),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          // FusionOutlinedDropdown<String>(
          //   label: 'Listening Area',
          //   hint: 'Select listening area',
          //   value: _selectedArea,
          //   items: _areaOptions,
          //   itemLabelBuilder: (String v) => v,
          //   onChanged: (String v) => setState(() => _selectedArea = v),
          // ),

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
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) {
              return previous.selectModeArgs.useSubwoofer != current.selectModeArgs.useSubwoofer;
            },
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return Row(
                children: <Widget>[
                  FusionSwitch(
                    height: 24,
                    width: 44,
                    semanticId: "use_subwoofer",
                    value: state.selectModeArgs.useSubwoofer,
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
          const SizedBox(height: 20),
          BlocBuilder<SpeakerSelectionViewModel, SpeakerSelectionVmState>(
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              if (state.selectModeArgs.useSubwoofer == false) return const SizedBox.shrink();

              return Row(
                children: <Widget>[
                  FusionSwitch(
                    height: 24,
                    width: 44,
                    semanticId: "mono_subwoofer",
                    value: state.selectModeArgs.monoSubwoofer,
                    onChanged: context.read<SpeakerSelectionViewModel>().setMonoSubwoofer,
                  ),
                  const SizedBox(width: 8),
                  FusionAppText(
                    text: 'Mono Subwoofer',
                    style: context.textTheme.b3Regular.copyWith(
                      color: context.colorScheme.textPrimary,
                    ),
                  ),
                ],
              );
            },
          ),

          const SizedBox(height: 20),
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
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) {
              return previous.selectModeArgs.mountingTypes != current.selectModeArgs.mountingTypes;
            },
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return Row(
                spacing: 10,
                children: <Widget>[
                  ...MountingType.values.map(
                    (MountingType option) {
                      final bool isSelected = state.selectModeArgs.mountingTypes.contains(option);

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
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) {
              return previous.selectModeArgs.maxSplRange != current.selectModeArgs.maxSplRange;
            },
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return FusionRadioChipSelector<SpeakerMaxSplRange>(
                selected: state.selectModeArgs.maxSplRange,
                options: SpeakerMaxSplRange.values,
                labelBuilder: (SpeakerMaxSplRange option) => option.displayName,
                onChanged: context.read<SpeakerSelectionViewModel>().setMaxSplRange,
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
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) {
              return previous.selectModeArgs.lowFrequencyInHz != current.selectModeArgs.lowFrequencyInHz;
            },
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return SteppedHapticSlider(
                min: 50,
                max: 100,
                interval: 10, // creates stops at 50, 60, 70, 80, 90, 100
                initialValue: state.selectModeArgs.lowFrequencyInHz,
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
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) {
              return previous.selectModeArgs.speakerColorOption != current.selectModeArgs.speakerColorOption;
            },
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return FusionRadioChipSelector<SpeakerColorOption>(
                selected: state.selectModeArgs.speakerColorOption,
                options: SpeakerColorOption.values,
                labelBuilder: (SpeakerColorOption option) => option.displayName,
                onChanged: context.read<SpeakerSelectionViewModel>().setSpeakerColor,
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
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) {
              return previous.selectModeArgs.wiringType != current.selectModeArgs.wiringType;
            },
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return FusionRadioChipSelector<WiringType>(
                selected: state.selectModeArgs.wiringType,
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
            buildWhen: (SpeakerSelectionVmState previous, SpeakerSelectionVmState current) {
              return previous.selectModeArgs.audioChannel != current.selectModeArgs.audioChannel;
            },
            builder: (BuildContext context, SpeakerSelectionVmState state) {
              return FusionRadioChipSelector<AudioChannel>(
                selected: state.selectModeArgs.audioChannel,
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
                  ...ListeningHeightOption.values.map(
                    (ListeningHeightOption option) {
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

class _ModeChip extends StatelessWidget {
  final String label;
  final bool selected;
  final VoidCallback onTap;
  final double borderRadius;
  final EdgeInsetsGeometry? padding;
  final TextStyle? textStyle;

  const _ModeChip({
    required this.label,
    required this.selected,
    required this.onTap,
    this.borderRadius = 12,
    this.padding,
    this.textStyle,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: padding ?? const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: selected ? context.colorScheme.elevation3 : Colors.transparent,
          borderRadius: BorderRadius.circular(borderRadius),
        ),
        child: Center(
          child: FusionAppText(
            text: label,
            style: (textStyle ?? context.textTheme.b3Regular).copyWith(
              color: context.colorScheme.textPrimary,
            ),
          ),
        ),
      ),
    );
  }
}
