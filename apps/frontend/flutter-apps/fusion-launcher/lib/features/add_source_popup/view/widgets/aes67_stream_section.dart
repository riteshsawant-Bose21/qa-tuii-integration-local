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
import '../../../configuration_aes67/viewModel/input_stream_viewmodel/input_stream_viewmodel.dart';
import '../../view_model/add_source_viewmodel.dart';
import 'common_widgets/add_sources_dropdown.dart';

class Aes67StreamSection extends StatefulWidget {
  final AddSourceViewModelState state;

  const Aes67StreamSection({required this.state});

  @override
  State<Aes67StreamSection> createState() => _Aes67StreamSectionState();
}

class _Aes67StreamSectionState extends State<Aes67StreamSection> {
  bool hovered = false;
  @override
  Widget build(BuildContext context) {
    return BlocBuilder<AddSourceViewModel, AddSourceViewModelState>(
      builder: (BuildContext context, AddSourceViewModelState state) {
        final List<Aes67Config> streams = context.read<ProjectViewModel>().getAllAes67InputStreams();

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
                  InputStreamDialog.show(
                    context,
                    onSave: (Aes67Config stream) {
                      context.read<ProjectViewModel>().addAes67InputStream(stream: stream);
                      final List<Aes67Config> updatedStreams = context.read<ProjectViewModel>().getAllAes67InputStreams();
                      final Aes67Config matchedStream = updatedStreams.firstWhere(
                        (Aes67Config s) => s.id == stream.id,
                        orElse: () => stream,
                      );
                      context.read<AddSourceViewModel>().setSelectedStream(matchedStream);
                      context.read<InputStreamViewmodel>().init(existingStream: matchedStream);
                    },
                  );
                  return;
                }

                context.read<AddSourceViewModel>().setSelectedStream(option as Aes67Config);
                context.read<InputStreamViewmodel>().init(existingStream: option);
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
                          onPressed: () {
                            InputStreamDialog.show(
                              context,
                              onSave: (Aes67Config stream) {
                                context.read<ProjectViewModel>().addAes67InputStream(stream: stream);
                                final List<Aes67Config> updatedStreams = context.read<ProjectViewModel>().getAllAes67InputStreams();
                                final Aes67Config matchedStream = updatedStreams.firstWhere(
                                  (Aes67Config s) => s.id == stream.id,
                                  orElse: () => stream,
                                );
                                context.read<AddSourceViewModel>().setSelectedStream(matchedStream);
                                context.read<InputStreamViewmodel>().init(existingStream: matchedStream);
                              },
                            );
                          },
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
                      if (option == state.selectedStream) Icon(Icons.check, size: 14, color: context.colorScheme.iconWhite),
                    ],
                  ),
                );
              },
              child: MouseRegion(
                onEnter: (_) => setState(() => hovered = true),
                onExit: (_) => setState(() => hovered = false),
                child: Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
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
                          text: state.selectedStream?.name ?? 'Select Stream',
                          style: context.textTheme.b3Regular.copyWith(
                            color: state.selectedStream?.name != null ? context.colorScheme.textPrimary : context.colorScheme.textPlaceholder,
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
      },
    );
  }
}
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
//  Channel assignment
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

class ChannelAssignmentSection extends StatelessWidget {
  final AddSourceViewModelState state;

  const ChannelAssignmentSection({required this.state});

  @override
  Widget build(BuildContext context) {
    final AddSourceViewModel addSourceViewModel = context.read<AddSourceViewModel>();

    return BlocBuilder<InputStreamViewmodel, InputStreamState>(
      builder: (BuildContext context, InputStreamState inputState) {
        final Aes67Config? selectedStream = state.selectedStream;

        final List<String> channelOptions =
            selectedStream?.channelConfigs.map((Aes67ChannelConfig c) => c.label ?? 'Ch ${c.channelNumber}').toList() ?? <String>[];

        String? channelLabel(int? channelNumber) {
          if (channelNumber == null || channelNumber < 1 || channelNumber > channelOptions.length || channelOptions.isEmpty) {
            return null;
          }
          return channelOptions[channelNumber - 1];
        }

        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            if (state.selectedSignalType == SignalType.mono && channelOptions.isNotEmpty)
              FusionOutlinedDropdown<String>(
                label: 'Channel 1',
                hint: 'Assign',
                value: channelLabel(state.selectedMonoChannel),
                items: channelOptions,
                itemLabelBuilder: (String option) => option,
                onChanged: (String value) {
                  final int index = channelOptions.indexOf(value);
                  addSourceViewModel.setSelectedMonoChannel(index + 1);
                },
              ),
            if (state.selectedSignalType == SignalType.stereo && channelOptions.isNotEmpty) ...<Widget>[
              FusionOutlinedDropdown<String>(
                label: 'Channel 1 (Left)',
                hint: 'Assign',
                value: channelLabel(state.selectedLeftChannel),
                items: channelOptions,
                itemLabelBuilder: (String option) => option,
                onChanged: (String value) {
                  final int index = channelOptions.indexOf(value);
                  addSourceViewModel.setSelectedLeftChannel(index + 1);
                },
              ),
              const SizedBox(height: 20),
              FusionOutlinedDropdown<String>(
                label: 'Channel 2 (Right)',
                hint: 'Assign',
                value: channelLabel(state.selectedRightChannel),
                items: channelOptions,
                itemLabelBuilder: (String option) => option,
                onChanged: (String value) {
                  final int index = channelOptions.indexOf(value);
                  addSourceViewModel.setSelectedRightChannel(index + 1);
                },
              ),
            ],
          ],
        );
      },
    );
  }
}

class AddStreamAction {
  const AddStreamAction();
}
