import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/create_zone_popup/view/widgets/zone_name_field_with_color.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../../add_source_popup/view/widgets/common_widgets/Fusion_radio_chip_selector.dart';
import '../../../add_source_popup/view/widgets/common_widgets/add_sources_dropdown.dart';
import '../../view_model/create_zone_viewmodel.dart';
import '../../view_model/create_zone_viewmodel_state.dart';
import 'CommonWidgets/create_zone_bordered_textfield.dart';
import 'CommonWidgets/create_zone_label_field.dart';

enum OutputType {
  mediaRecorder,
  amplifier,
  speaker,
  mixer;

  String get displayName => switch (this) {
    OutputType.mediaRecorder => 'Media Recorder',
    OutputType.amplifier => 'Amplifier',
    OutputType.speaker => 'Speaker',
    OutputType.mixer => 'Mixer',
  };
}

enum AudioChannel {
  mono,
  stereo;

  String get displayName => switch (this) {
    AudioChannel.mono => 'Mono',
    AudioChannel.stereo => 'Stereo',
  };
}

enum ConnectionType {
  analogOutput,
  digitalOutput,
  aes67,
  bluetooth;

  String get displayName => switch (this) {
    ConnectionType.analogOutput => 'Analog Output',
    ConnectionType.digitalOutput => 'Digital Output',
    ConnectionType.aes67 => 'AES67',
    ConnectionType.bluetooth => 'Bluetooth',
  };
}

// ─── Data model ──────────────────────────────────────────────

class OutputDeviceFormData {
  final String outputName;
  final OutputType outputType;
  final AudioChannel audioChannel;
  final ConnectionType connectionType;

  const OutputDeviceFormData({
    required this.outputName,
    required this.outputType,
    required this.audioChannel,
    required this.connectionType,
  });
}

// ─── Header: ← ADD OUTPUT DEVICE ·············· ✕ ───────────

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

// ─── Form content (no Expanded, no footer) ───────────────────

class _AddOutputDeviceContent extends StatefulWidget {
  final String zoneColor;
  final String zoneName;

  /// Updated whenever form validity changes — drives Save button state.
  final ValueNotifier<bool> saveEnabledNotifier;

  /// Called with latest valid data so show() can forward it on save.
  final void Function(OutputDeviceFormData?) onDataChanged;

  const _AddOutputDeviceContent({
    required this.zoneColor,
    required this.zoneName,
    required this.saveEnabledNotifier,
    required this.onDataChanged,
  });

  @override
  State<_AddOutputDeviceContent> createState() => _AddOutputDeviceContentState();
}

class _AddOutputDeviceContentState extends State<_AddOutputDeviceContent> {
  final TextEditingController _nameCtrl = TextEditingController();
  OutputType? _outputType;
  AudioChannel? _audioChannel;
  ConnectionType? _connection;

  bool get _canSave => _nameCtrl.text.trim().isNotEmpty && _outputType != null && _audioChannel != null && _connection != null;

  void _onChanged() {
    final bool valid = _canSave;
    widget.saveEnabledNotifier.value = valid;
    widget.onDataChanged(
      valid
          ? OutputDeviceFormData(
            outputName: _nameCtrl.text.trim(),
            outputType: _outputType!,
            audioChannel: _audioChannel!,
            connectionType: _connection!,
          )
          : null,
    );
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    super.dispose();
  }

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
        ],
      ),
    );
  }

  Widget _outputNameField(BuildContext context, String text) {
    return FusionLabeledField(
      label: text,
      semanticId: 'output_name_label',
      child: FusionBorderedTextField(
        controller: _nameCtrl,
        semanticId: 'output_name_textfield',
        hintText: 'Enter area name',
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }

  Widget _outputTypes(BuildContext context, String text) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_type_dropdown'),
      child: FusionOutlinedDropdown<OutputType>(
        value: _outputType,
        label: text,
        items: OutputType.values,
        hint: 'Select Output Type',
        itemLabelBuilder: (OutputType t) => t.displayName,
        onChanged: (OutputType? v) {
          if (v == null) return;
          setState(() => _outputType = v);
          _onChanged();
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
          FusionRadioChipSelector<AudioChannel>(
            selected: _audioChannel,
            options: AudioChannel.values,
            labelBuilder: (AudioChannel ch) => ch.displayName,
            onChanged: (AudioChannel ch) {
              setState(() => _audioChannel = ch);
              _onChanged();
            },
          ),
        ],
      ),
    );
  }

  Widget _connectionDropdown(BuildContext context, String text) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, 'add_output_device_connection_dropdown'),
      child: FusionOutlinedDropdown<ConnectionType>(
        value: _connection,
        label: text,
        items: ConnectionType.values,
        hint: 'Select Connection',
        itemLabelBuilder: (ConnectionType t) => t.displayName,
        onChanged: (ConnectionType v) {
          setState(() => _connection = v);
          _onChanged();
        },
      ),
    );
  }
}

// ─── Public API ───────────────────────────────────────────────

class AddOutputDeviceDrawer {
  AddOutputDeviceDrawer._();

  static Future<void> show({
    required BuildContext context,
    required String zoneColor,
    required String zoneName,
    required void Function(OutputDeviceFormData data) onSave,
    required VoidCallback onBack,
    required CreateZoneViewModel vm, // ← add this
  }) {
    final ValueNotifier<bool> saveEnabled = ValueNotifier<bool>(false);
    OutputDeviceFormData? _latestData;

    return FusionDrawer.show<void>(
      context: context,
      semanticId: 'add_output_device',
      title: 'Add Output Device',
      buttonLabel: 'Save',
      buttonEnabledNotifier: saveEnabled,
      onButtonPressed: () {
        if (_latestData != null) {
          onSave(_latestData!);
          Navigator.of(context).maybePop();
        }
      },
      header: _AddOutputDeviceHeader(onBack: onBack),
      content: BlocProvider<CreateZoneViewModel>.value(
        value: vm,
        child: _AddOutputDeviceContent(
          zoneColor: zoneColor,
          zoneName: zoneName,
          saveEnabledNotifier: saveEnabled,
          onDataChanged: (OutputDeviceFormData? data) => _latestData = data,
        ),
      ),
    );
  }
}
