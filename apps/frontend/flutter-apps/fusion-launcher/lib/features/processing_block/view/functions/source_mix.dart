import 'dart:developer';

import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/processing_block/view/functions/widgets/priority_selection_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
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
  late String functionId;

  @override
  void initState() {
    super.initState();
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    functionId = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID)!.id;
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.8;

    final List<MixScene> savedMixScenes = projectViewModel.getAllMixScenesForFunction(functionId: functionId);
    final MixScene? selectedMixScene = projectViewModel.getSelectedMixSceneForFunction(functionId);

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth,
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Stack(
          children: <Widget>[
            Container(
              color: Colors.black,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: <Widget>[
                  const SizedBox(height: 35),
                  Flexible(
                    fit: FlexFit.loose,
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: <Widget>[
                        // Left scrollable section
                        Flexible(
                          fit: FlexFit.loose,
                          child: SourceMixLeftWidget(
                            zoneID: widget.zoneID,
                          ),
                        ),

                        MixScenes(
                          selectedMixSceneName: selectedMixScene?.name,
                          zoneId: widget.zoneID,
                          onStoreTap: (String? value) {
                            if (value == null || value.isEmpty) {
                              return FusionToast.error(
                                context,
                                message: "Please enter a name for the mix scene",
                              );
                            } else {
                              projectViewModel.saveCurrentSettingsAsMixScene(
                                functionId: functionId,
                                sceneName: value,
                              );
                            }
                          },
                          mixScenes: savedMixScenes.map((MixScene e) => e.name).toList(),
                          onMixSceneSelect: (String value) {
                            try {
                              final MixScene scene = savedMixScenes.firstWhere((MixScene scene) => scene.name == value);
                              projectViewModel.applyMixSceneToFunction(
                                functionId: functionId,
                                sceneId: scene.id,
                              );
                              log("Selected mix scene: ${scene.name}");
                            } catch (e) {
                              // We might get StateError if the scene is not found.
                            }
                          },
                          onDeleteTap: () {
                            try {
                              // TODO: Implement delete functionality. Currently, it is not possible to delete a mix scene from the project.
                              // Because we dont know which one is currently selected.
                              // TWO TASK HERE:
                              // 1. Get the selected mix scene for the function.
                              // 2. update the scene if changes are made.
                            } catch (e) {
                              // We might get StateError if the scene is not found.
                            }
                          },
                        ),

                        DecoratedBox(
                          decoration: const BoxDecoration(
                            color: Color(0xFFF5F5F5),
                            border: Border(
                              left: BorderSide(
                                color: Colors.black12,
                              ),
                            ),
                          ),
                          child: PrioritySelectionWidget(zoneId: widget.zoneID),
                        ),

                        // Right side (only one widget)
                        Flexible(
                          fit: FlexFit.loose,
                          child: ColoredBox(
                            color: Colors.white,
                            child: ZoneControlSliderBuilder(
                              zoneID: widget.zoneID,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Used Stack to fit content according to content size.
            // HEADERS
            Positioned(
              left: 0,
              child: Container(
                height: 35,
                color: Colors.black,
                alignment: Alignment.centerLeft,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: Text(
                  "ZONE CONTROL PANEL - SOURCE MIX",
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    color: Colors.white,
                    fontSize: 11,
                  ),
                ),
              ),
            ),

            Positioned(
              right: 0,
              child: Container(
                height: 35,
                color: Colors.black,
                alignment: Alignment.centerRight,
                padding: const EdgeInsets.symmetric(horizontal: 12.0),
                child: MouseRegion(
                  cursor: SystemMouseCursors.click,
                  child: GestureDetector(
                    onTap: Navigator.of(context).pop,
                    child: const Icon(
                      Icons.close,
                      color: Colors.white,
                      size: 16,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SourceMixLeftWidget extends StatefulWidget {
  final String zoneID;
  const SourceMixLeftWidget({super.key, required this.zoneID});

  @override
  State<SourceMixLeftWidget> createState() => _SourceMixLeftWidgetState();
}

class _SourceMixLeftWidgetState extends State<SourceMixLeftWidget> {
  late final ScrollController _scrollController = ScrollController();
  late final String functionId;

  late List<Source> sources;

  @override
  void initState() {
    super.initState();
    late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneID);
    functionId = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID)!.id;
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    if (sources.isEmpty) {
      return ColoredBox(
        color: const Color(0xFFF5F5F5),
        child: Padding(
          padding: const EdgeInsets.all(12.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              FusionAppText(
                text: "No sources selected for this function",
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  color: Colors.grey,
                ),
              ),
            ],
          ),
        ),
      );
    }
    final List<MixSettings> mixSettings = projectViewModel.getCurrentMixSettingsForFunction(functionId: functionId);

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: ColoredBox(
          color: const Color(0xFFF5F5F5),
          child: Row(
            mainAxisSize: MainAxisSize.min,
            children: List<Widget>.generate(sources.length, (int index) {
              final Source source = sources[index];

              final MixSettings mixSetting = mixSettings.singleWhere(
                (MixSettings setting) => setting.sourceId == source.id,
                orElse: () => MixSettings(functionId: functionId, sourceId: source.id, gain: 0, muted: true),
              );

              return SizedBox(
                width: 150,
                child: Column(
                  spacing: 10,
                  children: <Widget>[
                    Container(
                      height: 28,
                      color: const Color(0xFFF5F5F5),
                      child: Center(
                        child: FusionAppText(
                          text: source.name,
                          textAlign: TextAlign.center,
                          maxLine: 1,
                          style: Theme.of(context).textTheme.labelMedium,
                        ),
                      ),
                    ),
                    NeumorphicGainTextField(
                      controllerValue: mixSetting.gain,
                      minGain: -60,
                      maxGain: 12,
                      onSubmitted: (double value) {
                        projectViewModel.updateMixSettings(
                          mixSettings: mixSetting.copyWith(
                            gain: value,
                          ),
                        );
                      },
                    ),
                    Expanded(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(
                              color: Colors.black12,
                            ),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SliderAndMeterWidget(
                                sliderValue: mixSetting.gain,
                                sliderMax: 12,
                                sliderMin: -60,
                                onSliderChanged: (num value) {
                                  projectViewModel.updateMixSettings(
                                    mixSettings: mixSetting.copyWith(
                                      gain: value.toDouble(),
                                    ),
                                  );
                                },
                              ),
                            ),
                            NeumorphicAudioToggleButton(
                              isActive: mixSetting.muted,
                              width: 72,
                              height: 24,
                              onTap: () {
                                projectViewModel.updateMixSettings(
                                  mixSettings: mixSetting.copyWith(
                                    muted: !mixSetting.muted,
                                  ),
                                );
                              },
                              backgroundColor: const Color(0xFFF5F5F5),
                            ),
                            const SizedBox(height: 10),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
          ),
        ),
      ),
    );
  }
}

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
    context.watch<ProjectViewModel>(); // To rebuild when ProjectViewModel changes.

    subZones = projectViewModel.getSubZonesForZone(parentZoneId: widget.zoneID);
    if (subZones.isEmpty) zone = projectViewModel.getZone(zoneId: widget.zoneID);

    final bool isSubZonesAvailable = subZones.isNotEmpty;

    return Scrollbar(
      controller: _scrollController,
      child: SingleChildScrollView(
        controller: _scrollController,
        physics: const ClampingScrollPhysics(),
        scrollDirection: Axis.horizontal,
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: List<Widget>.generate(
            isSubZonesAvailable ? subZones.length : 1,
            (int index) {
              final SubZone? subZone = isSubZonesAvailable ? subZones[index] : null;

              final String? title = isSubZonesAvailable ? subZone!.name : zone?.name;
              // Just for safer mode.
              if (title == null) return const SizedBox.shrink();

              final String zoneOrSubzoneID = isSubZonesAvailable ? subZone!.id : zone!.id;
              final bool isMuted = isSubZonesAvailable ? subZone!.muted : zone!.muted;
              final double zoneOrSubzoneGain = isSubZonesAvailable ? subZone!.gain : zone!.gain;

              return Container(
                width: 150,
                decoration: const BoxDecoration(
                  border: Border(
                    left: BorderSide(color: Colors.black12),
                  ),
                ),
                child: Column(
                  spacing: 10,
                  children: <Widget>[
                    Container(
                      height: 28,
                      color: widget.headerBackgroundColor ?? const Color(0xFFF5F5F5),
                      alignment: Alignment.center,
                      child: FusionAppText(
                        text: title,
                        textAlign: TextAlign.center,
                        style: Theme.of(context).textTheme.labelMedium,
                      ),
                    ),
                    NeumorphicGainTextField(
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
                    Expanded(
                      child: DecoratedBox(
                        decoration: const BoxDecoration(
                          border: Border(
                            right: BorderSide(color: Colors.black12),
                          ),
                        ),
                        child: Column(
                          children: <Widget>[
                            Expanded(
                              child: SliderAndMeterWidget(
                                sliderValue: zoneOrSubzoneGain,
                                sliderMax: 12,
                                sliderMin: -60,
                                onSliderChanged: (num value) {
                                  projectViewModel.updateZoneGain(
                                    zoneId: zoneOrSubzoneID,
                                    gain: value.toDouble(),
                                  );
                                },
                              ),
                            ),
                            NeumorphicAudioToggleButton(
                              isActive: isMuted,
                              width: 72,
                              height: 24,
                              onTap: () {
                                projectViewModel.muteZone(
                                  zoneId: zoneOrSubzoneID,
                                  isMuted: !isMuted,
                                );
                              },
                              backgroundColor: const Color(0xFFF5F5F5),
                            ),
                            const SizedBox(height: 10),
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
    );
  }
}
