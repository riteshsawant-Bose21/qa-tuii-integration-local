import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:fusion_launcher/features/zone_functions/source_mix.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/service_locator.dart';
import '../configuration/presentation/viewmodel/project_view_model.dart';
import '../zone_function_settings/matrix_settings/matrix_settings.dart';
import 'widgets/mix_scene.dart';
import 'widgets/neumorphic_audio_toggle_button.dart';
import 'widgets/neumorphic_text_with_popup_slider_button.dart';
import 'widgets/priority_selection_widget.dart';

class SourceMatrixZoneControlPanel extends StatefulWidget {
  final String zoneID;
  const SourceMatrixZoneControlPanel({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceMatrixZoneControlPanel(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceMatrixZoneControlPanel> createState() => _SourceMatrixZoneControlPanelState();
}

class _SourceMatrixZoneControlPanelState extends State<SourceMatrixZoneControlPanel> {
  late ZoneFunctions zoneFunction;

  @override
  void initState() {
    super.initState();
    zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID)!;
  }

  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  MixScene? selectedMixScene(ZoneFunctions zoneFunction) {
    final String? selectedId = zoneFunction.selectedMixSceneId;
    if (selectedId == null) return null;
    try {
      return zoneFunction.mixScenes.firstWhere((MixScene scene) => scene.id == selectedId);
    } catch (e) {
      return null;
    }
  }

  @override
  Widget build(BuildContext context) {
    final ZoneFunctions? existingFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID);
    final bool hasPriority = existingFunction?.hasPriority ?? false;

    return Material(
      color: Colors.transparent,
      type: MaterialType.transparency,
      child: Stack(
        children: <Widget>[
          GestureDetector(
            onTap: Navigator.of(context).pop,
            child: Container(color: Colors.transparent),
          ),

          Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Container(
                margin: const EdgeInsets.all(24.0),
                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  border: Border.all(color: context.colorScheme.strokeLight),
                  borderRadius: BorderRadius.circular(16),
                ),
                child: Stack(
                  fit: StackFit.loose,
                  children: <Widget>[
                    // TITLTE
                    Positioned(
                      top: 0,
                      left: 0,
                      child: Padding(
                        padding: const EdgeInsets.symmetric(vertical: 15, horizontal: 20),
                        child: FusionAppText(
                          semanticId: "zone_control_panel_heading",
                          text: "ZONE CONTROL PANEL - SOURCE MATRIX",
                          style: context.textTheme.titleSmall,
                          maxLine: 1,
                        ),
                      ),
                    ),

                    // CLOSE BUTTON
                    Positioned(
                      top: 0,
                      right: 0,
                      child: Material(
                        color: Colors.transparent,
                        child: Padding(
                          padding: const EdgeInsets.all(8.0),
                          child: SemanticHelper.button(
                            testId: SemanticHelper.createTestId(SemanticTypes.button, "zone_control_panel_close_button"),
                            child: InkWell(
                              onTap: Navigator.of(context).pop,
                              customBorder: const CircleBorder(),
                              child: Padding(
                                padding: const EdgeInsets.all(8.0),
                                child: Icon(
                                  LucideIcons.x200,
                                  color: context.colorScheme.iconDefault,
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),

                    /// --------------------------------------------------------------------------------
                    ///                             MAIN CONTENT
                    /// --------------------------------------------------------------------------------
                    Padding(
                      padding: const EdgeInsets.symmetric(vertical: 50.0).copyWith(bottom: hasPriority ? null : 0),
                      child: SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, "source_select_main_container"),
                        child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
                          listener: (BuildContext context, ProjectViewModelState state) {
                            zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID)!;
                          },
                          builder: (BuildContext context, ProjectViewModelState state) {
                            return Container(
                              decoration: BoxDecoration(
                                border: Border(
                                  top: BorderSide(
                                    color: context.colorScheme.strokeLight,
                                    width: 0.5,
                                  ),
                                ),
                              ),
                              padding: const EdgeInsets.all(16.0),
                              child: ClipRRect(
                                borderRadius: BorderRadius.circular(16),
                                child: Container(
                                  decoration: BoxDecoration(
                                    color: context.colorScheme.elevation2,
                                    border: Border.all(color: context.colorScheme.strokeLight),
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: <Widget>[
                                      Flexible(
                                        flex: 2,
                                        fit: FlexFit.loose,
                                        child: SourceMatrixControls(
                                          zoneID: widget.zoneID,
                                          zoneFunctions: zoneFunction,
                                        ),
                                      ),

                                      VerticalDivider(width: 1, color: context.colorScheme.strokeLight),
                                      MixScenes(
                                        selectedMixSceneName: selectedMixScene(zoneFunction)?.name,
                                        zoneId: widget.zoneID,
                                        onStoreTap: (String? value) {
                                          if (value == null || value.isEmpty) {
                                            return FusionToast.error(
                                              context,
                                              message: "Please enter a name for the mix scene",
                                            );
                                          } else {
                                            projectViewModel.saveCurrentSettingsAsMixScene(
                                              functionId: zoneFunction.id,
                                              sceneName: value,
                                            );
                                          }
                                        },
                                        mixScenes: zoneFunction.mixScenes.map((MixScene e) => e.name).toList(),
                                        onMixSceneSelect: (String value) {
                                          try {
                                            final MixScene scene = zoneFunction.mixScenes.firstWhere((MixScene scene) => scene.name == value);
                                            projectViewModel.applyMixSceneToFunction(functionId: zoneFunction.id, sceneId: scene.id);
                                          } catch (e) {
                                            // We might get StateError if the scene is not found.
                                          }
                                        },
                                        onDeleteTap: () {
                                          final MixScene? scene = selectedMixScene(zoneFunction);
                                          if (scene != null) {
                                            projectViewModel.removeMixScene(
                                              sceneId: scene.id,
                                              functionId: zoneFunction.id,
                                            );
                                          }
                                        },
                                      ),

                                      VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

                                      PrioritySelectionWidget(zoneId: widget.zoneID),

                                      // RIGHT COLUMN (Static)
                                      Flexible(
                                        flex: 2,
                                        child: ZoneControlSliderBuilder(zoneID: widget.zoneID),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                    ),
                    if (hasPriority) ...<Widget>[
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: InkWell(
                              onTap: () {
                                SourceMatrixAdditionalSettingsDialog.showDialog(
                                  context,
                                  zoneID: widget.zoneID,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              splashColor: Colors.transparent,
                              child: Ink(
                                padding: const EdgeInsets.all(12),
                                decoration: BoxDecoration(
                                  color: context.colorScheme.elevation2,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  mainAxisSize: MainAxisSize.min,
                                  children: <Widget>[
                                    Flexible(
                                      child: FusionAppText(
                                        text: "Additional Settings",
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Icon(
                                      LucideIcons.arrowUpRight200,
                                      size: 16,
                                      color: context.colorScheme.iconDefault,
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class SourceMatrixControls extends StatefulWidget {
  final String zoneID;
  final ZoneFunctions zoneFunctions;

  const SourceMatrixControls({
    super.key,
    required this.zoneID,
    required this.zoneFunctions,
  });

  @override
  State<SourceMatrixControls> createState() => _SourceMatrixControlsState();
}

class _SourceMatrixControlsState extends State<SourceMatrixControls> {
  late final ScrollController sourcesScrollController = ScrollController();
  late final ScrollController outScrollController = ScrollController();

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
  }

  @override
  void dispose() {
    sourcesScrollController.dispose();
    outScrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
              const SizedBox(height: 120),
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

                      return Row(
                        children: <Widget>[
                          Expanded(
                            flex: 2,
                            child: Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                              child: Row(
                                spacing: 6,
                                children: <Widget>[
                                  Container(
                                    height: 16,
                                    width: 16,
                                    decoration: BoxDecoration(
                                      color: context.colorScheme.primaryColor,
                                      borderRadius: BorderRadius.circular(4),
                                    ),
                                  ),
                                  Expanded(
                                    child: Center(
                                      child: FusionAppText(
                                        text: source.name,
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ),
                                  ),
                                  FusionNeumorphicButton(
                                    semanticId: 'source_matrix_icon',
                                    onTap: () {
                                      projectViewModel.updateMatrixSettings(
                                        matrixSettings: matrixSetting.copyWith(
                                          muted: !matrixSetting.muted,
                                        ),
                                        functionId: widget.zoneFunctions.id,
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
                                      color: matrixSetting.muted ? context.colorScheme.iconDisabled : context.colorScheme.primaryWhite,
                                    ),
                                  ),
                                  Expanded(
                                    child: NeumorphicTextWithPopupSliderButton(
                                      isActive: false, // DONT ALLOW ACTIVE STATE.
                                      value: matrixSetting.gain,
                                      borderRadius: 6,
                                      onChanged: (double value) {
                                        projectViewModel.updateMatrixSettings(
                                          matrixSettings: matrixSetting.copyWith(
                                            gain: value,
                                          ),
                                          functionId: widget.zoneFunctions.id,
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
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
        VerticalDivider(width: 1, color: context.colorScheme.strokeLight),
        Expanded(
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
                height: 120,
                child: Column(
                  children: <Widget>[
                    NeumorphicAudioToggleButton(
                      isActive: widget.zoneFunctions.matrixMixer! is MonoMatrixMixer ? (widget.zoneFunctions.matrixMixer! as MonoMatrixMixer).outMuted : false,
                      iconSize: 16,
                      backgroundColor: context.colorScheme.elevation2,
                      onTap: () {
                        projectViewModel.updateMatrixMixer(
                          matrixMixer:
                              widget.zoneFunctions.matrixMixer! is MonoMatrixMixer
                                  ? (widget.zoneFunctions.matrixMixer! as MonoMatrixMixer).copyWith(
                                    outMuted: !(widget.zoneFunctions.matrixMixer! as MonoMatrixMixer).outMuted,
                                  )
                                  : widget.zoneFunctions.matrixMixer!,
                          functionId: widget.zoneFunctions.id,
                        );
                      },
                    ),

                    const SizedBox(height: 16),

                    //
                    // OUT GAIN SLIDER
                    //
                    Builder(
                      builder: (BuildContext context) {
                        final MonoMatrixMixer? monoMatrixMixer =
                            widget.zoneFunctions.matrixMixer is MonoMatrixMixer ? widget.zoneFunctions.matrixMixer as MonoMatrixMixer : null;

                        return Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16.0),
                          child: GestureDetector(
                            onTap: () {
                              if (monoMatrixMixer == null) return;
                              projectViewModel.updateMatrixMixer(
                                matrixMixer: monoMatrixMixer.copyWith(outActive: !monoMatrixMixer.outActive),
                                functionId: widget.zoneFunctions.id,
                              );
                            },
                            child: NeumorphicTextWithPopupSliderButton(
                              isActive: monoMatrixMixer != null ? monoMatrixMixer.outActive : false,
                              value: monoMatrixMixer != null ? monoMatrixMixer.outGain : 0.0,
                              onChanged: (double value) {
                                projectViewModel.updateMatrixMixer(
                                  matrixMixer: monoMatrixMixer != null ? monoMatrixMixer.copyWith(outGain: value) : widget.zoneFunctions.matrixMixer!,
                                  functionId: widget.zoneFunctions.id,
                                );
                              },
                            ),
                          ),
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
                        projectViewModel.updateMatrixSettings(
                          matrixSettings: matrixSetting.copyWith(outActive: !matrixSetting.outActive),
                          functionId: widget.zoneFunctions.id,
                        );
                      },
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                        child: NeumorphicTextWithPopupSliderButton(
                          isActive: matrixSetting.outActive,
                          value: matrixSetting.mixLevel,
                          borderRadius: 6,
                          onChanged: (double value) {
                            projectViewModel.updateMatrixSettings(
                              matrixSettings: matrixSetting.copyWith(mixLevel: value),
                              functionId: widget.zoneFunctions.id,
                            );
                          },
                        ),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
