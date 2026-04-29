import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/add_output_device_drawer/viewmodel/add_output_device_vm.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/CommonWidgets/zone_name_field_with_color.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../add_source_popup/view/widgets/aes67_stream_section.dart';
import '../../add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import '../../add_source_popup/view/widgets/common_widgets/add_sources_dropdown.dart';
import '../../create_zone_popup/view/widgets/CommonWidgets/create_zone_bordered_textfield.dart';
import '../../create_zone_popup/view/widgets/CommonWidgets/create_zone_label_field.dart';
import '../../create_zone_popup/view_model/create_zone_viewmodel.dart';
import '../../create_zone_popup/view_model/create_zone_viewmodel_state.dart';

class AddOutputDeviceDrawer {
  AddOutputDeviceDrawer._();

  static Future<void> show({
    required BuildContext context,
    required CreateZoneViewModel vm,
    required String zoneColor,
    required String zoneName,
    required VoidCallback onBack,
  }) {
    final AddOutputDeviceViewModel addOutputDeviceVm = AddOutputDeviceViewModel();

    return FusionDrawer.show<void>(
      context: context,
      semanticId: 'add_output_device',
      title: 'Add Output Device',
      showBackButton: true,
      buttonLabel: 'Save',
      buttonEnabledNotifier: addOutputDeviceVm.isSaveEnabled,
      onButtonPressed: addOutputDeviceVm.onSaveTap,
      // header: _AddOutputDeviceHeader(onBack: onBack),
      content: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
          BlocProvider<CreateZoneViewModel>.value(value: vm),
          BlocProvider<AddOutputDeviceViewModel>.value(value: addOutputDeviceVm),
        ],
        child: _AddOutputDeviceContent(
          zoneColor: zoneColor,
          zoneName: zoneName,
        ),
      ),
    ).whenComplete(addOutputDeviceVm.close);
  }
}

class _AddOutputDeviceContent extends StatelessWidget {
  final String zoneColor;
  final String zoneName;

  const _AddOutputDeviceContent({
    required this.zoneColor,
    required this.zoneName,
  });
  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 16, 24, 24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          BlocBuilder<CreateZoneViewModel, CreateZoneViewModelState>(
            buildWhen: (CreateZoneViewModelState p, CreateZoneViewModelState c) => p.zoneName != c.zoneName || p.zoneColor != c.zoneColor,
            builder: (BuildContext context, CreateZoneViewModelState state) {
              return ZoneNameFieldWithColor(
                zoneName: state.zoneName,
                zoneColor: state.zoneColor,
                onNameChanged: context.read<CreateZoneViewModel>().setZoneName,
                onColorChanged: context.read<CreateZoneViewModel>().setZoneColor,
              );
            },
          ),
          const SizedBox(height: 20),
          _outputNameField(context, 'Output Name'),
          const SizedBox(height: 20),
          _outputTypes(context, 'Output Type'),
          const SizedBox(height: 20),
          _audioChannelToggle(context, "Audio Channel"),
          const SizedBox(height: 20),
          _connectionDropdown(context, "Connection"),

          _aes67Config(context),
        ],
      ),
    );
  }

  Widget _outputNameField(BuildContext context, String text) {
    return FusionLabeledField(
      label: text,
      semanticId: 'output_name_label',
      child: FusionBorderedTextField(
        semanticId: 'output_name_textfield',
        hintText: 'Enter area name',
        contentPadding: const EdgeInsets.all(16),
        onChanged: context.read<AddOutputDeviceViewModel>().updateOutputDeviceName,
      ),
    );
  }

  Widget _outputTypes(BuildContext context, String text) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_type_dropdown'),
      child: BlocBuilder<AddOutputDeviceViewModel, AddOutputDeviceVmState>(
        buildWhen: (AddOutputDeviceVmState previous, AddOutputDeviceVmState current) => previous.outputType != current.outputType,
        builder: (BuildContext context, AddOutputDeviceVmState state) {
          return FusionOutlinedDropdown<OutputDeviceType>(
            value: state.outputType,
            label: text,
            items: OutputDeviceType.values,
            hint: 'Select Output Type',
            itemLabelBuilder: (OutputDeviceType t) => t.displayName,
            onChanged: (OutputDeviceType? v) {
              if (v == null) return;
              context.read<AddOutputDeviceViewModel>().updateOutputType(v);
            },
          );
        },
      ),
    );
  }

  Widget _audioChannelToggle(BuildContext context, String text) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_audio_channel'),
      child: Column(
        children: <Widget>[
          Align(
            alignment: Alignment.centerLeft,
            child: FusionAppText(
              text: text,
              style: Theme.of(context).textTheme.l1Medium.copyWith(
                color: context.colorScheme.onSurface,
              ),
            ),
          ),
          const SizedBox(height: 8),
          BlocBuilder<AddOutputDeviceViewModel, AddOutputDeviceVmState>(
            buildWhen: (AddOutputDeviceVmState previous, AddOutputDeviceVmState current) => previous.audioChannel != current.audioChannel,
            builder: (BuildContext context, AddOutputDeviceVmState state) {
              return FusionRadioChipSelector<AudioChannel>(
                selected: state.audioChannel,
                options: AudioChannel.values,
                labelBuilder: (AudioChannel ch) => ch.displayName,
                onChanged: (AudioChannel ch) {
                  context.read<AddOutputDeviceViewModel>().updateAudioChannel(ch);
                  // _onChanged();
                },
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _connectionDropdown(BuildContext context, String text) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_connection_dropdown'),
      child: BlocBuilder<AddOutputDeviceViewModel, AddOutputDeviceVmState>(
        buildWhen: (AddOutputDeviceVmState previous, AddOutputDeviceVmState current) => previous.connection != current.connection,
        builder: (BuildContext context, AddOutputDeviceVmState state) {
          return FusionOutlinedDropdown<OutputDeviceConnectionType>(
            value: state.connection,
            label: text,
            items: OutputDeviceConnectionType.values,
            hint: 'Select Connection',
            itemLabelBuilder: (OutputDeviceConnectionType t) => t.displayName,
            onChanged: (OutputDeviceConnectionType v) {
              context.read<AddOutputDeviceViewModel>().updateConnection(v);
            },
          );
        },
      ),
    );
  }

  Widget _aes67Config(BuildContext context) {
    return BlocBuilder<AddOutputDeviceViewModel, AddOutputDeviceVmState>(
      builder: (BuildContext context, AddOutputDeviceVmState state) {
        if (state.connection != OutputDeviceConnectionType.aes67) return const SizedBox.shrink();

        final AddOutputDeviceViewModel addOutputDeviceVm = context.read<AddOutputDeviceViewModel>();

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            const SizedBox(height: 20),
            // ── AES67 Stream & Channel assignment ────
            Aes67StreamSection<AddOutputDeviceVmState>(
              state: state,
              selectedStreamSelector: (AddOutputDeviceVmState s) => s.selectedStream,
              onStreamSelected: addOutputDeviceVm.setSelectedStream,
            ),
            const SizedBox(height: 20),
            ChannelAssignmentSection<AddOutputDeviceVmState>(
              state: state,
              selectedStreamSelector: (AddOutputDeviceVmState s) => s.selectedStream,
              selectedSignalTypeSelector: (AddOutputDeviceVmState s) => s.audioChannel == AudioChannel.stereo ? SignalType.stereo : SignalType.mono,
              selectedMonoChannelSelector: (AddOutputDeviceVmState s) => s.selectedMonoChannel,
              selectedLeftChannelSelector: (AddOutputDeviceVmState s) => s.selectedLeftChannel,
              selectedRightChannelSelector: (AddOutputDeviceVmState s) => s.selectedRightChannel,
              onMonoChannelChanged: addOutputDeviceVm.setSelectedMonoChannel,
              onLeftChannelChanged: addOutputDeviceVm.setSelectedLeftChannel,
              onRightChannelChanged: addOutputDeviceVm.setSelectedRightChannel,
            ),
          ],
        );
      },
    );
  }
}

class _AddOutputDeviceHeader extends StatelessWidget {
  final VoidCallback onBack;
  const _AddOutputDeviceHeader({required this.onBack});

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_drawer_header'),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          Padding(
            padding: const EdgeInsets.only(top: 24, bottom: 16, left: 24, right: 24),
            child: Row(
              children: <Widget>[
                // ← Back
                SemanticHelper.button(
                  testId: SemanticHelper.createTestId(SemanticTypes.button, 'add_output_device_back_button'),
                  child: GestureDetector(
                    onTap: onBack,
                    child: MouseRegion(
                      cursor: SystemMouseCursors.click,
                      child: FusionIcon.icon(
                        Icons.arrow_back_ios,
                        size: 16,
                        color: context.colorScheme.iconWhite,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                // Title
                Expanded(
                  child: FusionAppText(
                    text: 'ADD OUTPUT DEVICE',
                    semanticId: 'add_output_device_header_title',
                    style: Theme.of(context).textTheme.l1Regular.withColor(context.colorScheme.textBody),
                  ),
                ),
                // ✕ Close
                SemanticHelper.button(
                  testId: SemanticHelper.createTestId(SemanticTypes.button, 'add_output_device_close_button'),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).maybePop(),
                    child: FusionIcon.icon(
                      Icons.close,
                      size: 16,
                      color: context.colorScheme.iconWhite,
                    ),
                  ),
                ),
              ],
            ),
          ),
          Divider(height: 1, thickness: 1, color: context.colorScheme.strokeLight),
        ],
      ),
    );
  }
}
