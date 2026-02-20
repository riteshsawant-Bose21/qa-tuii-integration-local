import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/priority_selection_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/service_locator.dart';
import '../configuration/presentation/viewmodel/project_view_model.dart';
import '../zone_function_settings/mix_settings/mix_settings.dart';
import 'widgets/horizontal_scroll_effect_wrapper.dart';
import 'widgets/mix_scene.dart';
import 'widgets/neumorphic_audio_toggle_button.dart';
import 'widgets/neumorphic_gain_text_field.dart';
import 'widgets/slider_and_meter_widget.dart';

class SourceMixZoneControlPanel extends StatefulWidget {
  final String zoneID;
  const SourceMixZoneControlPanel({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceMixZoneControlPanel(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceMixZoneControlPanel> createState() => _SourceMixZoneControlPanelState();
}

class _SourceMixZoneControlPanelState extends State<SourceMixZoneControlPanel> {
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
                          text: "ZONE CONTROL PANEL - SOURCE MIX",
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
                                        child: SourceMixLeftWidget(
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
                                SourceMixAdditionalSettingsDialog.showDialog(
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

class SourceMixLeftWidget extends StatefulWidget {
  final String zoneID;
  final ZoneFunctions zoneFunctions;

  const SourceMixLeftWidget({
    super.key,
    required this.zoneID,
    required this.zoneFunctions,
  });

  @override
  State<SourceMixLeftWidget> createState() => _SourceMixLeftWidgetState();
}

class _SourceMixLeftWidgetState extends State<SourceMixLeftWidget> {
  late final ScrollController _scrollController = ScrollController();

  late List<Source> sources;

  @override
  void initState() {
    super.initState();
    late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneID);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    return Column(
      children: <Widget>[
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: FusionAppText(
            text: "SOURCES",
            textAlign: TextAlign.center,
            style: context.textTheme.labelMedium,
          ),
        ),
        Expanded(
          child: Builder(
            builder: (BuildContext context) {
              if (sources.isEmpty) {
                return Container(
                  padding: const EdgeInsets.all(16.0),
                  decoration: BoxDecoration(
                    border: Border(
                      top: BorderSide(
                        color: context.colorScheme.strokeLight,
                      ),
                    ),
                  ),
                  child: Center(
                    child: FusionAppText(
                      text: "No sources selected for this function",
                      textAlign: TextAlign.center,
                      style: context.textTheme.labelMedium?.copyWith(
                        color: context.colorScheme.textPlaceholder,
                      ),
                    ),
                  ),
                );
              }

              return HorizontalScrollWithShadows(
                controller: _scrollController,
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: List<Widget>.generate(sources.length, (int index) {
                    final Source source = sources[index];

                    final MixSettings mixSetting = widget.zoneFunctions.mixSettings!.singleWhere(
                      (MixSettings setting) => setting.sourceId == source.id,
                      orElse: () => MixSettings(sourceId: source.id, gain: 0, muted: true),
                    );

                    return Container(
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border(
                          top: BorderSide(
                            color: context.colorScheme.strokeLight,
                          ),
                          right: BorderSide(
                            color: context.colorScheme.strokeLight,
                          ),
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Padding(
                            padding: const EdgeInsetsGeometry.all(16),
                            child: Center(
                              child: FusionAppText(
                                text: source.name,
                                textAlign: TextAlign.center,
                                maxLine: 1,
                                style: Theme.of(context).textTheme.labelMedium,
                              ),
                            ),
                          ),
                          Divider(color: context.colorScheme.strokeLight, height: 0),
                          const SizedBox(height: 10),
                          SemanticHelper.formControl(
                            testId: SemanticHelper.createTestId(SemanticTypes.textInput, "source_mix_gain_text_field"),
                            child: NeumorphicGainTextField(
                              controllerValue: mixSetting.gain,
                              minGain: -60,
                              maxGain: 12,
                              onSubmitted: (double value) {
                                projectViewModel.updateMixSettings(
                                  mixSettings: mixSetting.copyWith(
                                    gain: value,
                                  ),
                                  functionId: widget.zoneFunctions.id,
                                );
                              },
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  child: SemanticHelper.button(
                                    testId: SemanticHelper.createTestId(SemanticTypes.button, "source_mix_gain_slider"),
                                    child: SliderAndMeterWidget(
                                      sliderValue: mixSetting.gain,
                                      onSliderChanged: (num value) {
                                        projectViewModel.updateMixSettings(
                                          mixSettings: mixSetting.copyWith(
                                            gain: value.toDouble(),
                                          ),
                                          functionId: widget.zoneFunctions.id,
                                        );
                                      },
                                    ),
                                  ),
                                ),
                                SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "source_mix_mute_button"),
                                  child: NeumorphicAudioToggleButton(
                                    isActive: mixSetting.muted,
                                    backgroundColor: context.colorScheme.elevation2,
                                    width: 100,
                                    onTap: () {
                                      projectViewModel.updateMixSettings(
                                        mixSettings: mixSetting.copyWith(
                                          muted: !mixSetting.muted,
                                        ),
                                        functionId: widget.zoneFunctions.id,
                                      );
                                    },
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  }),
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}

// Updated ZoneControlSliderBuilder using the wrapper
class ZoneControlSliderBuilder extends StatefulWidget {
  final String zoneID;
  final Color? headerBackgroundColor;

  const ZoneControlSliderBuilder({
    super.key,
    required this.zoneID,
    this.headerBackgroundColor,
  });

  @override
  State<ZoneControlSliderBuilder> createState() => _ZoneControlSliderBuilderState();
}

class _ZoneControlSliderBuilderState extends State<ZoneControlSliderBuilder> {
  late final ScrollController _scrollController = ScrollController();
  late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  late List<SubZone> subZones;
  late Zone? zone;

  @override
  void initState() {
    super.initState();
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    context.watch<ProjectViewModel>();

    subZones = projectViewModel.getSubZonesForZone(parentZoneId: widget.zoneID);
    if (subZones.isEmpty) zone = projectViewModel.getZone(zoneId: widget.zoneID);

    final bool isSubZonesAvailable = subZones.isNotEmpty;

    return Column(
      children: <Widget>[
        if (isSubZonesAvailable) ...<Widget>[
          Padding(
            padding: const EdgeInsets.all(16.0),
            child: FusionAppText(
              text: "SUB ZONE VOLUME",
              textAlign: TextAlign.center,
              style: context.textTheme.labelMedium,
            ),
          ),
        ],
        Expanded(
          child: Builder(
            builder: (BuildContext context) {
              return HorizontalScrollWithShadows(
                controller: _scrollController,
                child: ListView.separated(
                  itemCount: isSubZonesAvailable ? subZones.length : 1,
                  shrinkWrap: true,
                  scrollDirection: Axis.horizontal,
                  physics: const ClampingScrollPhysics(),
                  separatorBuilder: (BuildContext context, int index) => Divider(color: context.colorScheme.strokeLight, height: 0),
                  itemBuilder: (BuildContext context, int index) {
                    final SubZone? subZone = isSubZonesAvailable ? subZones[index] : null;

                    final String? title = isSubZonesAvailable ? subZone!.name : zone?.name;
                    if (title == null) return const SizedBox.shrink();

                    final String zoneOrSubzoneID = isSubZonesAvailable ? subZone!.id : zone!.id;
                    final bool isMuted = isSubZonesAvailable ? subZone!.muted : zone!.muted;
                    final double zoneOrSubzoneGain = isSubZonesAvailable ? subZone!.gain : zone!.gain;

                    return Container(
                      width: 150,
                      decoration: BoxDecoration(
                        border: Border(
                          right: BorderSide(color: context.colorScheme.strokeLight),
                          top: isSubZonesAvailable ? BorderSide(color: context.colorScheme.strokeLight) : BorderSide.none,
                        ),
                      ),
                      child: Column(
                        children: <Widget>[
                          Container(
                            padding: const EdgeInsets.all(16.0),
                            alignment: Alignment.center,
                            child: FusionAppText(
                              text: title,
                              textAlign: TextAlign.center,
                              style: Theme.of(context).textTheme.labelMedium,
                            ),
                          ),
                          Divider(color: context.colorScheme.strokeLight, height: 0),
                          const SizedBox(height: 10),
                          SemanticHelper.formControl(
                            testId: SemanticHelper.createTestId(SemanticTypes.formControl, "source_mix_zone_gain_text_field"),
                            child: NeumorphicGainTextField(
                              controllerValue: zoneOrSubzoneGain,
                              minGain: -60,
                              maxGain: 12,
                              onSubmitted: (double value) {
                                projectViewModel.updateZoneGain(
                                  zoneId: zoneOrSubzoneID,
                                  gain: value,
                                );
                              },
                              width: 100,
                              height: 32,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Expanded(
                            child: Column(
                              children: <Widget>[
                                Expanded(
                                  child: SliderAndMeterWidget(
                                    sliderValue: zoneOrSubzoneGain,
                                    onSliderChanged: (num value) {
                                      projectViewModel.updateZoneGain(
                                        zoneId: zoneOrSubzoneID,
                                        gain: value.toDouble(),
                                      );
                                    },
                                  ),
                                ),
                                SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "source_mix_mute_button"),
                                  child: NeumorphicAudioToggleButton(
                                    isActive: isMuted,
                                    width: 100,
                                    onTap: () {
                                      projectViewModel.muteZone(
                                        zoneId: zoneOrSubzoneID,
                                        isMuted: !isMuted,
                                      );
                                    },
                                    backgroundColor: widget.headerBackgroundColor ?? context.colorScheme.elevation2,
                                  ),
                                ),
                                const SizedBox(height: 10),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
