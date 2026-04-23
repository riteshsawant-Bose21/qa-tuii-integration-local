import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../projects/models/meter_data.dart';
import '../../../projects/view_model/meter_data/meter_data_view_model.dart';
import '../../view_model/mini_matrix/matrix_mixer_viewmodel.dart';
import '../neumorphic_audio_toggle_button.dart';
import '../neumorphic_text_with_popup_slider_button.dart';

class SourceMatrixControlsPanel extends StatefulWidget {
  final String zoneID;
  final ZoneFunctions zoneFunctions;

  const SourceMatrixControlsPanel({
    super.key,
    required this.zoneID,
    required this.zoneFunctions,
  });

  @override
  State<SourceMatrixControlsPanel> createState() => _SourceMatrixControlsPanelState();
}

class _SourceMatrixControlsPanelState extends State<SourceMatrixControlsPanel> {
  late final ScrollController sourcesScrollController = ScrollController();
  late final ScrollController outScrollController = ScrollController();
  late final MatrixMixerViewModel _matrixMixerViewModel;
  late final MeterDataViewModel _meterDataViewModel;

  bool _isSyncing = false;

  @override
  void initState() {
    super.initState();

    sourcesScrollController.addListener(() {
      if (_isSyncing) return;
      _isSyncing = true;
      outScrollController.jumpTo(sourcesScrollController.offset);
      _isSyncing = false;
    });

    outScrollController.addListener(() {
      if (_isSyncing) return;
      _isSyncing = true;
      sourcesScrollController.jumpTo(outScrollController.offset);
      _isSyncing = false;
    });

    _matrixMixerViewModel = MatrixMixerViewModel();
    _meterDataViewModel = serviceLocator<MeterDataViewModel>();

    // Register as meter observer so telemetry stays alive while this widget is mounted.
    _meterDataViewModel.registerObserver(this, blockIds : <String>{widget.zoneFunctions.id});

    // Fetch the latest server values on load.
    _matrixMixerViewModel.updateParamsAsPerServer(function: widget.zoneFunctions);

    // Subscribe to live WebSocket block-data updates for cross-device sync.
    _matrixMixerViewModel.subscribeToBlockData(functionId: widget.zoneFunctions.id);
  }

  @override
  void dispose() {
    _matrixMixerViewModel.unsubscribeFromBlockData();
    _matrixMixerViewModel.close();
    _meterDataViewModel.unregisterObserver(this);
    sourcesScrollController.dispose();
    outScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // Watch ProjectViewModel to rebuild when matrix settings change.
    context.watch<ProjectViewModel>();
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final List<Source> sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneID);

    final int sourcesLength = sources.length;

    return Row(
      children: <Widget>[
        //
        // SOURCES
        //
        Expanded(
          flex: 2,
          child: Column(
            children: <Widget>[
              Padding(
                padding: const EdgeInsets.all(16.0),
                child: Center(
                  child: FusionAppText(
                    text: "SOURCES",
                    style: Theme.of(context).textTheme.labelSmall,
                  ),
                ),
              ),
              Divider(color: context.colorScheme.strokeLight, height: 0),
              const SizedBox(height: 60),
              Divider(color: context.colorScheme.strokeLight, height: 0),
              Expanded(
                child: ScrollConfiguration(
                  behavior: const ScrollBehavior().copyWith(scrollbars: false),
                  child: ListView.separated(
                    controller: sourcesScrollController,
                    itemCount: sourcesLength,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    separatorBuilder: (BuildContext context, int index) => Divider(color: context.colorScheme.strokeLight, height: 0),
                    itemBuilder: (BuildContext context, int index) {
                      final Source source = sources[index];

                      final MonoMatrixSettings matrixSetting =
                          widget.zoneFunctions.matrixMixer!.settings.firstWhere((MatrixSettings ms) => ms.sourceId == source.id) as MonoMatrixSettings;

                      final int sourceChannelIndex =
                          widget.zoneFunctions.sourceIndex != null && widget.zoneFunctions.sourceIndex!.containsKey(source.id)
                              ? widget.zoneFunctions.sourceIndex![source.id]!
                              : 0;
                      final int sourceIndexForControl = sourceChannelIndex.clamp(0, sourceChannelIndex);

                      return SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, "sourcemtx_source_$index"),
                        child: Row(
                          children: <Widget>[
                            Expanded(
                              flex: 2,
                              child: Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                                child: Row(
                                  spacing: 6,
                                  children: <Widget>[
                                    // Input presence indicator — driven by meter data.
                                    _MatrixInputPresenceIndicator(
                                      blockId: widget.zoneFunctions.id,
                                      dimension: sourceIndexForControl,
                                      meterDataViewModel: _meterDataViewModel,
                                    ),
                                    Expanded(
                                      child: Center(
                                        child: FusionAppText(
                                          semanticId: 'source_name',
                                          text: source.name,
                                          maxLine: 1,
                                          style: Theme.of(context).textTheme.labelSmall,
                                        ),
                                      ),
                                    ),
                                    FusionNeumorphicButton(
                                      semanticId: 'mute_unmute',
                                      selected: matrixSetting.isSelected,
                                      onTap: () {
                                        _matrixMixerViewModel.updateInputMute(
                                          function: widget.zoneFunctions,
                                          sourceId: source.id,
                                          currentSettings: matrixSetting,
                                          isMuted: !matrixSetting.inputMute,
                                        );
                                      },
                                      width: 24,
                                      height: 24,
                                      borderRadius: 6,
                                      child: SvgPicture.asset(
                                        'assets/svg/volume.svg',
                                        width: 12,
                                        height: 12,
                                        // ignore: deprecated_member_use
                                        color: matrixSetting.inputMute ? context.colorScheme.iconDisabled : context.colorScheme.primaryWhite,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: context.colorScheme.strokeLight),
        Expanded(
          child: SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, 'source_matrix_out_column'),
            child: Column(
              children: <Widget>[
                Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Center(
                    child: FusionAppText(
                      text: "OUT",
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                Divider(color: context.colorScheme.strokeLight, height: 0),
                //
                // TOP OUT MUTE / UNMUTE BUTTON
                //
                SizedBox(
                  height: 60,
                  child: Column(
                    children: <Widget>[
                      NeumorphicAudioToggleButton(
                        isActive:
                            widget.zoneFunctions.matrixMixer! is MonoMatrixMixer ? (widget.zoneFunctions.matrixMixer! as MonoMatrixMixer).outMuted : false,
                        iconSize: 16,
                        backgroundColor: context.colorScheme.elevation2,
                        onTap: () {
                          _matrixMixerViewModel.updateOutputMute(
                            function: widget.zoneFunctions,
                            isMuted:
                                widget.zoneFunctions.matrixMixer! is MonoMatrixMixer ? !(widget.zoneFunctions.matrixMixer! as MonoMatrixMixer).outMuted : true,
                          );
                        },
                      ),
                    ],
                  ),
                ),
                Divider(color: context.colorScheme.strokeLight, height: 0),
                Expanded(
                  child: ListView.separated(
                    controller: outScrollController,
                    itemCount: sourcesLength,
                    padding: EdgeInsets.zero,
                    physics: const ClampingScrollPhysics(),
                    separatorBuilder: (BuildContext context, int index) => Divider(color: context.colorScheme.strokeLight, height: 0),
                    itemBuilder: (BuildContext context, int index) {
                      final Source source = sources[index];

                      final MonoMatrixSettings matrixSetting =
                          widget.zoneFunctions.matrixMixer!.settings.firstWhere((MatrixSettings ms) => ms.sourceId == source.id) as MonoMatrixSettings;

                      return GestureDetector(
                        onTap: () {
                          _matrixMixerViewModel.updateCrosspointMute(
                            function: widget.zoneFunctions,
                            sourceId: source.id,
                            currentSettings: matrixSetting,
                            isSelected: !matrixSetting.isSelected,
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                          child: SemanticHelper.container(
                            testId: SemanticHelper.createTestId(SemanticTypes.container, "crosspoint_channel_gain_$index"),
                            child: NeumorphicTextWithPopupSliderButton(
                              isActive: matrixSetting.isSelected,
                              value: matrixSetting.mixLevel,
                              borderRadius: 6,
                              onChanged: (double value) {
                                //validate values are between -60 and 0
                                if (value < -60) value = -60;
                                if (value > 0) value = 0;
                                _matrixMixerViewModel.updateCrosspointLevel(
                                  function: widget.zoneFunctions,
                                  sourceId: source.id,
                                  currentSettings: matrixSetting,
                                  newLevel: value,
                                );
                              },
                              semanticId: 'crosspoint_channel_gain',
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

// ─────────────────────────────────────────────────────────────────────────────
// _MatrixInputPresenceIndicator
// ─────────────────────────────────────────────────────────────────────────────

class _MatrixInputPresenceIndicator extends StatelessWidget {
  final String blockId;
  final int dimension;
  final MeterDataViewModel meterDataViewModel;

  const _MatrixInputPresenceIndicator({
    required this.blockId,
    required this.dimension,
    required this.meterDataViewModel,
  });

  static MeterBlock? _findInputPresenceBlock(
    MeterDataState state,
    String blockId,
  ) {
    for (final MeterPacket packet in state.packets.values) {
      for (final MeterBlock block in packet.blocks) {
        if (block.blockName == blockId && block.meterName == 'input_presence') {
          return block;
        }
      }
    }
    return null;
  }

  @override
  Widget build(BuildContext context) {
    return BlocSelector<MeterDataViewModel, MeterDataState, bool>(
      bloc: meterDataViewModel,
      selector: (MeterDataState state) {
        final MeterBlock? meter = _findInputPresenceBlock(state, blockId);
        if (meter == null || dimension < 0 || dimension >= meter.value.length) return false;
        return meter.value[dimension] >= 1.0;
      },
      builder: (BuildContext context, bool isPresent) {
        return SemanticHelper.container(
          testId: SemanticHelper.createTestId(
            SemanticTypes.container,
            'input_presence_${blockId}_$dimension',
          ),
          child: Container(
            height: 16,
            width: 16,
            decoration: BoxDecoration(
              color: isPresent ? const Color(0xFF48BB78) : context.colorScheme.iconDisabled,
              borderRadius: BorderRadius.circular(4),
            ),
          ),
        );
      },
    );
  }
}
