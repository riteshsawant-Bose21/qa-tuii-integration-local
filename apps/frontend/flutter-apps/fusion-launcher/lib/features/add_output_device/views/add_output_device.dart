import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/add_output_device/viewmodel/add_output_device_vm.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';

import '../../add_source_popup/view/widgets/aes67_stream_section.dart';
import '../../add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import '../../add_source_popup/view/widgets/common_widgets/add_sources_dropdown.dart';
import '../../create_zone_popup/view/widgets/CommonWidgets/create_zone_bordered_textfield.dart';
import '../../create_zone_popup/view/widgets/CommonWidgets/create_zone_label_field.dart';

class AddOutputDevice {
  AddOutputDevice._();

  static Future<void> show({
    required BuildContext context,
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
      onButtonPressed: () => addOutputDeviceVm.onSaveTap(context),
      // header: _AddOutputDeviceHeader(onBack: onBack),
      content: MultiBlocProvider(
        providers: <BlocProvider<dynamic>>[
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
          BlocBuilder<AddOutputDeviceViewModel, AddOutputDeviceVmState>(
            builder: (BuildContext context, AddOutputDeviceVmState state) {
              final AddOutputDeviceViewModel vm = context.read<AddOutputDeviceViewModel>();
              final List<Zone> zones = serviceLocator<ProjectViewModel>().getAllZones();
              final Zone? zone = serviceLocator<ProjectViewModel>().getZone(zoneId: state.zoneId ?? '');

              return FusionOutlinedDropdown<Zone>(
                value: zone,
                label: 'Select Zone',
                hint: 'Select Zone',
                items: zones,
                itemLabelBuilder: (Zone zone) => zone.name,
                onChanged: (Zone zone) => vm.setZoneId(zone.id),
              );
            },
          ),

          //
          const SizedBox(height: 20),
          FusionLabeledField(
            label: "Output Name",
            semanticId: 'output_name_label',
            child: FusionBorderedTextField(
              semanticId: 'output_name_textfield',
              hintText: 'Enter area name',
              contentPadding: const EdgeInsets.all(16),
              onChanged: context.read<AddOutputDeviceViewModel>().updateOutputDeviceName,
            ),
          ),

          //
          const SizedBox(height: 20),
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_type_dropdown'),
            child: BlocBuilder<AddOutputDeviceViewModel, AddOutputDeviceVmState>(
              builder: (BuildContext context, AddOutputDeviceVmState state) {
                final List<OutputProduct> outputProducts = context.watch<AddOutputDeviceViewModel>().outputProducts;

                return FusionOutlinedDropdown<OutputProduct>(
                  value: outputProducts.firstWhereOrNull((OutputProduct p) => p.id == state.outputProductId),
                  label: 'Output Type',
                  items: outputProducts,
                  hint: 'Select Output Type',
                  itemLabelBuilder: (OutputProduct outputDevice) => outputDevice.name,
                  onChanged: (OutputProduct? v) {
                    if (v == null) return;
                    context.read<AddOutputDeviceViewModel>().updateOutputProductId(v.id);
                  },
                );
              },
            ),
          ),

          //
          const SizedBox(height: 20),
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_audio_channel'),
            child: Column(
              children: <Widget>[
                Align(
                  alignment: Alignment.centerLeft,
                  child: FusionAppText(
                    text: "Audio Channel",
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
                      },
                    );
                  },
                ),
              ],
            ),
          ),

          // Connection-specific sections
          const SizedBox(height: 20),
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_connection_dropdown'),
            child: BlocBuilder<AddOutputDeviceViewModel, AddOutputDeviceVmState>(
              builder: (BuildContext context, AddOutputDeviceVmState state) {
                return FusionOutlinedDropdown<OutputConnectionType>(
                  value: state.connectionType,
                  label: "Connection",
                  items: context.watch<AddOutputDeviceViewModel>().supportedConnectionTypes,
                  hint: 'Select Connection',
                  itemLabelBuilder: (OutputConnectionType t) => t.displayName,
                  onChanged: context.read<AddOutputDeviceViewModel>().updateConnectionType,
                );
              },
            ),
          ),

          // Connection-specific sections
          BlocBuilder<AddOutputDeviceViewModel, AddOutputDeviceVmState>(
            builder: (BuildContext context, AddOutputDeviceVmState state) {
              if (state.connectionType != OutputConnectionType.aes67output) return const SizedBox.shrink();

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
                    streamMode: Aes67StreamMode.output,
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
          ),
        ],
      ),
    );
  }
}
