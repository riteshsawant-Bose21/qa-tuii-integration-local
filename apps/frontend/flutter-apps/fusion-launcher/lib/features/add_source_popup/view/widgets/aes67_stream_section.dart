import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_app_button.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_popup_menu.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_svg_icon.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/mix_scenes.dart';
import 'package:fusion_lib/models/project_entities/non_processing/aes67_config.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../configuration_aes67/view/widgets/inputStreams/input_stream_dialog.dart';
import '../../../configuration_aes67/view/widgets/outputStreams/output_stream_dialog.dart';
import 'common_widgets/add_sources_dropdown.dart';

typedef StreamSelector<T> = Aes67Config? Function(T state);
typedef SignalTypeSelector<T> = SignalType Function(T state);
typedef ChannelSelector<T> = int? Function(T state);

typedef StreamChanged = void Function(Aes67Config stream);
typedef ChannelChanged = void Function(int channel);

enum Aes67StreamMode { input, output }

class Aes67StreamSection<T> extends StatefulWidget {
  final T state;
  final StreamSelector<T> selectedStreamSelector;
  final StreamChanged onStreamSelected;
  final Aes67StreamMode streamMode;

  const Aes67StreamSection({
    super.key,
    required this.state,
    required this.selectedStreamSelector,
    required this.onStreamSelected,
    this.streamMode = Aes67StreamMode.input,
  });

  @override
  State<Aes67StreamSection<T>> createState() => _Aes67StreamSectionState<T>();
}

class _Aes67StreamSectionState<T> extends State<Aes67StreamSection<T>> {
  bool hovered = false;

  @override
  Widget build(BuildContext context) {
    final Aes67Config? selectedStream = widget.selectedStreamSelector(widget.state);
    final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
    final List<Aes67Config> streams =
        widget.streamMode == Aes67StreamMode.output ? projectViewModel.getAllAes67OutputStreams() : projectViewModel.getAllAes67InputStreams();

    void showAddStreamDialog() {
      if (widget.streamMode == Aes67StreamMode.output) {
        OutputStreamDialog.show(
          context,
          onSave: (Aes67Config stream) {
            projectViewModel.addAes67OutputStream(stream: stream);
            final List<Aes67Config> updatedStreams = projectViewModel.getAllAes67OutputStreams();
            final Aes67Config matchedStream = updatedStreams.firstWhere(
              (Aes67Config s) => s.id == stream.id,
              orElse: () => stream,
            );
            widget.onStreamSelected(matchedStream);
          },
        );
        return;
      }

      InputStreamDialog.show(
        context,
        onSave: (Aes67Config stream) {
          projectViewModel.addAes67InputStream(stream: stream);
          final List<Aes67Config> updatedStreams = projectViewModel.getAllAes67InputStreams();
          final Aes67Config matchedStream = updatedStreams.firstWhere(
            (Aes67Config s) => s.id == stream.id,
            orElse: () => stream,
          );
          widget.onStreamSelected(matchedStream);
        },
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        FusionAppText(
          text: 'Stream',
          style: context.textTheme.l1Medium.copyWith(
            color: context.colorScheme.textPrimary,
          ),
        ),
        const SizedBox(height: 8),
        FusionPopupMenu<dynamic>(
          items: <dynamic>[...streams, const AddStreamAction()],
          tooltip: 'Stream',
          semanticsId: 'stream_popup_menu',
          popupOffset: const Offset(0, 4),
          itemPadding: const EdgeInsets.symmetric(horizontal: 8, vertical: 10),
          matchChildWidth: true,
          onSelected: (dynamic option) {
            if (option is AddStreamAction) {
              showAddStreamDialog();
              return;
            }

            widget.onStreamSelected(option as Aes67Config);
          },
          itemBuilder: (BuildContext context, dynamic option) {
            if (option is AddStreamAction) {
              return Column(
                children: <Widget>[
                  Divider(height: 1, color: context.colorScheme.strokeLight),
                  const SizedBox(height: 8),
                  SizedBox(
                    width: double.infinity,
                    child: FusionAppButton(
                      style: FusionAppButtonStyle.primary,
                      semanticId: 'add_stream_button',
                      text: 'ADD STREAM',
                      height: 42,
                      onPressed: showAddStreamDialog,
                    ),
                  ),
                ],
              );
            }

            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 8),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: (option as Aes67Config).name,
                      maxLine: 1,
                      style: context.textTheme.b3Regular.copyWith(
                        color: context.colorScheme.textPrimary,
                      ),
                    ),
                  ),
                  if (option == selectedStream) Icon(Icons.check, size: 14, color: context.colorScheme.iconWhite),
                ],
              ),
            );
          },
          child: MouseRegion(
            onEnter: (_) => setState(() => hovered = true),
            onExit: (_) => setState(() => hovered = false),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: hovered ? context.colorScheme.elevation2 : Colors.transparent,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: context.colorScheme.strokeLight,
                  width: 1,
                ),
              ),
              child: Row(
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      maxLine: 1,
                      text: selectedStream?.name ?? 'Select Stream',
                      style: context.textTheme.b3Regular.copyWith(
                        color: selectedStream?.name != null ? context.colorScheme.textPrimary : context.colorScheme.textPlaceholder,
                      ),
                    ),
                  ),
                  FusionIcon.icon(
                    LucideIcons.chevronDown200,
                    size: 20,
                    color: context.colorScheme.iconWhite,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }
}
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  Channel assignment
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ChannelAssignmentSection<T> extends StatelessWidget {
  final T state;
  final StreamSelector<T> selectedStreamSelector;
  final SignalTypeSelector<T> selectedSignalTypeSelector;
  final ChannelSelector<T> selectedMonoChannelSelector;
  final ChannelSelector<T> selectedLeftChannelSelector;
  final ChannelSelector<T> selectedRightChannelSelector;
  final ChannelChanged onMonoChannelChanged;
  final ChannelChanged onLeftChannelChanged;
  final ChannelChanged onRightChannelChanged;

  const ChannelAssignmentSection({
    super.key,
    required this.state,
    required this.selectedStreamSelector,
    required this.selectedSignalTypeSelector,
    required this.selectedMonoChannelSelector,
    required this.selectedLeftChannelSelector,
    required this.selectedRightChannelSelector,
    required this.onMonoChannelChanged,
    required this.onLeftChannelChanged,
    required this.onRightChannelChanged,
  });

  @override
  Widget build(BuildContext context) {
    final Aes67Config? selectedStream = selectedStreamSelector(state);
    final SignalType selectedSignalType = selectedSignalTypeSelector(state);
    final int? selectedMonoChannel = selectedMonoChannelSelector(state);
    final int? selectedLeftChannel = selectedLeftChannelSelector(state);
    final int? selectedRightChannel = selectedRightChannelSelector(state);

    final List<String> channelOptions = selectedStream?.channelConfigs.map((Aes67ChannelConfig c) => c.label ?? 'Ch ${c.channelNumber}').toList() ?? <String>[];

    String? channelLabel(int? channelNumber) {
      if (channelNumber == null || channelNumber < 1 || channelNumber > channelOptions.length || channelOptions.isEmpty) {
        return null;
      }
      return channelOptions[channelNumber - 1];
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        if (selectedSignalType == SignalType.mono && channelOptions.isNotEmpty)
          FusionOutlinedDropdown<String>(
            label: 'Channel 1',
            hint: 'Assign',
            value: channelLabel(selectedMonoChannel),
            items: channelOptions,
            itemLabelBuilder: (String option) => option,
            onChanged: (String value) {
              final int index = channelOptions.indexOf(value);
              onMonoChannelChanged(index + 1);
            },
          ),
        if (selectedSignalType == SignalType.stereo && channelOptions.isNotEmpty) ...<Widget>[
          FusionOutlinedDropdown<String>(
            label: 'Channel 1 (Left)',
            hint: 'Assign',
            value: channelLabel(selectedLeftChannel),
            items: channelOptions,
            itemLabelBuilder: (String option) => option,
            onChanged: (String value) {
              final int index = channelOptions.indexOf(value);
              onLeftChannelChanged(index + 1);
            },
          ),
          const SizedBox(height: 20),
          FusionOutlinedDropdown<String>(
            label: 'Channel 2 (Right)',
            hint: 'Assign',
            value: channelLabel(selectedRightChannel),
            items: channelOptions,
            itemLabelBuilder: (String option) => option,
            onChanged: (String value) {
              final int index = channelOptions.indexOf(value);
              onRightChannelChanged(index + 1);
            },
          ),
        ],
      ],
    );
  }
}

class AddStreamAction {
  const AddStreamAction();
}
