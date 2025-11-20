import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import '../widgets/pb_button.dart';
import 'widgets/neumorphic_audio_toggle_button.dart';
import 'widgets/neumorphic_gain_text_field.dart';
import 'widgets/neumorphic_popup_button.dart';
import 'widgets/slider_and_meter_widget.dart';

class SourceMixZoneControlPanel extends StatelessWidget {
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
  Widget build(BuildContext context) {
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.8;

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
                            zoneID: zoneID,
                          ),
                        ),

                        const SourceMixMixScenes(),

                        // Right side (only one widget)
                        Flexible(
                          fit: FlexFit.loose,
                          child: ColoredBox(
                            color: Colors.white,
                            child: ZoneControlSliderBuilder(
                              zoneID: zoneID,
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

  late List<Source> sources;

  late final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

  @override
  void initState() {
    super.initState();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneID);
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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

              return SizedBox(
                width: 150,
                child: Column(
                  spacing: 10,
                  children: <Widget>[
                    const SizedBox(height: 5),
                    FusionAppText(
                      text: source.name,
                      textAlign: TextAlign.center,
                      maxLine: 1,
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                    NeumorphicGainTextField(
                      controllerValue: null, // TODO: How to get source mix level from projectViewModel?
                      minGain: -60,
                      maxGain: 12,
                      width: 100,
                      height: 32,
                      onSubmitted: (double value) {
                        // projectViewModel.updateSourceMix(
                        //   sourceId: sources[index].id,
                        //   leftMix: value,
                        //   rightMix: widget.rightMix,
                        // );
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
                                // TODO: How to get source mix level from projectViewModel?
                                sliderMax: 12,
                                sliderMin: -60,
                                sliderValue: 10,
                                onSliderChanged: (num value) {
                                  // projectViewModel.updateSourceMix(
                                  //   sourceId: sources[index].id,
                                  //   leftMix: value.toDouble(),
                                  //   rightMix: widget.rightMix,
                                  // );
                                },
                              ),
                            ),
                            NeumorphicAudioToggleButton(
                              isActive: index % 2 == 0, // TODO: How to get source mix mute state from projectViewModel?
                              width: 100,
                              height: 35,
                              onTap: () {
                                projectViewModel.muteSource(
                                  sourceId: source.id,
                                  isMuted: true, // TODO: Toggle mute state
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

class SourceMixMixScenes extends StatelessWidget {
  const SourceMixMixScenes({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: const Color(0xFFF5F5F5),
      child: Column(
        spacing: 10,
        children: <Widget>[
          const SizedBox(height: 5),
          FusionAppText(
            text: "MIX SCENES",
            style: Theme.of(context).textTheme.labelMedium,
          ),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 8.0),
            child: NeumorphicPopupButton(
              height: 28,
              borderRadius: 8,
              options: <String>[
                // TODO: Populate mix scenes from projectViewModel
              ],
              onChanged: (String? value) {
                // TODO: How to set mix scene from projectViewModel
              },
            ),
          ),

          const SizedBox(height: 10),
          PBButton(
            text: "STORE",
            width: 72,
            height: 24,
            borderRadius: 9,
            onTap: () {
              // projectViewModel.addPreset(preset: preset);
              // TODO: How to add mix scene to projectViewModel
            },
          ),
          PBButton(
            text: "DELETE",
            width: 72,
            height: 24,
            borderRadius: 9,
            textColor: Colors.black12,
            onTap: () {
              // projectViewModel.removePreset(presetId: preset.id);
              // TODO: How to delete mix scene from projectViewModel
            },
          ),
          const SizedBox(height: 10),
        ],
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
                      controllerValue: zoneOrSubzoneGain.toString(),
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
                              width: 100,
                              height: 35,
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
