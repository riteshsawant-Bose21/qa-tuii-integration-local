import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_svg/svg.dart' show SvgPicture;
import 'package:fusion_launcher/features/processing_block/view/functions/source_mix.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../../core/service_locator.dart';
import '../../../configuration/presentation/viewmodel/project_view_model.dart';
import 'widgets/mix_scene.dart';
import 'widgets/neumorphic_audio_toggle_button.dart';
import 'widgets/neumorphic_text_with_popup_slider_button.dart';
import 'widgets/priority_selection_widget.dart';

class MiniMatrixZoneControlPanel extends StatefulWidget {
  final String zoneID;

  const MiniMatrixZoneControlPanel({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return MiniMatrixZoneControlPanel(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<MiniMatrixZoneControlPanel> createState() => _MiniMatrixZoneControlPanelState();
}

class _MiniMatrixZoneControlPanelState extends State<MiniMatrixZoneControlPanel> {
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
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.85;

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth,
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {
          zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID)!;
        },
        builder: (BuildContext context, ProjectViewModelState state) {
          return ClipRRect(
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
                        child: Container(
                          color: const Color(0xFFF5F5F5),

                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              // Left scrollable section
                              Flexible(
                                fit: FlexFit.loose,
                                child: MiniMatrixControls(
                                  zoneID: widget.zoneID,
                                  zoneFunctions: zoneFunction,
                                ),
                              ),
                              const VerticalDivider(width: 1, color: Colors.black12),

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
                                    projectViewModel.applyMixSceneToFunction(
                                      functionId: zoneFunction.id,
                                      sceneId: scene.id,
                                    );
                                  } catch (e) {
                                    // We might get StateError if the scene is not found.
                                  }
                                },
                                onDeleteTap: () {
                                  try {
                                    final MixScene? scene = selectedMixScene(zoneFunction);
                                    if (scene != null) {
                                      projectViewModel.removeMixScene(
                                        functionId: zoneFunction.id,
                                        sceneId: scene.id,
                                      );
                                    }
                                  } catch (e) {
                                    // We might get StateError if the scene is not found.
                                  }
                                },
                              ),

                              const VerticalDivider(width: 1, color: Colors.black12),
                              Container(
                                color: Colors.white,
                                child: PrioritySelectionWidget(zoneId: widget.zoneID),
                              ),
                              // const VerticalDivider(width: 1, color: Colors.black12),
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
                      "ZONE CONTROL PANEL -  MINI MATRIX",
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
          );
        },
      ),
    );
  }
}

class MiniMatrixControls extends StatelessWidget {
  final String zoneID;
  final ZoneFunctions zoneFunctions;

  const MiniMatrixControls({
    super.key,
    required this.zoneID,
    required this.zoneFunctions,
  });

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    final List<Source> sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: zoneID);

    const BorderSide borderSide = BorderSide(color: Color(0xFFE5E5E5), width: 1);

    const int sourcesFlex = 3;

    return Container(
      width: 400,
      color: const Color(0xFFF5F5F5),
      height: double.infinity,
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: <Widget>[
          SizedBox(
            height: 28,
            child: Row(
              children: <Widget>[
                // HEADING
                Expanded(
                  flex: sourcesFlex,
                  child: Container(
                    height: 28,
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: const Color(0xFFF5F5F5),
                    child: FusionAppText(
                      text: "SOURCES",
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
                const VerticalDivider(width: 1, color: Colors.black12),
                Expanded(
                  child: Container(
                    height: 28,
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: const Color(0xFFF5F5F5),
                    child: FusionAppText(
                      text: "OUT",
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ),
                ),
              ],
            ),
          ),
          const Divider(color: Colors.black12, height: 0),

          if (sources.isEmpty) ...<Widget>[
            Expanded(
              child: Center(
                child: FusionAppText(
                  text: "No sources selected for this function",
                  style: Theme.of(context).textTheme.labelSmall?.copyWith(color: Colors.black26),
                ),
              ),
            ),
          ] else ...<Widget>[
            // TOP MUTE TOGGLE BUTTONS
            Row(
              children: <Widget>[
                const Expanded(flex: sourcesFlex, child: SizedBox()),
                Expanded(
                  child: NeumorphicAudioToggleButton(
                    isActive: zoneFunctions.matrixMixer! is MonoMatrixMixer ? (zoneFunctions.matrixMixer! as MonoMatrixMixer).outMuted : false,
                    width: 72,
                    height: 28,
                    iconSize: 16,
                    onTap: () {
                      projectViewModel.updateMatrixMixer(
                        matrixMixer:
                            zoneFunctions.matrixMixer! is MonoMatrixMixer
                                ? (zoneFunctions.matrixMixer! as MonoMatrixMixer).copyWith(
                                  outMuted: !(zoneFunctions.matrixMixer! as MonoMatrixMixer).outMuted,
                                )
                                : zoneFunctions.matrixMixer!,
                        functionId: zoneFunctions.id,
                      );
                    },
                  ),
                ),
              ],
            ),

            Row(
              children: <Widget>[
                const Expanded(flex: sourcesFlex, child: SizedBox()),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0).copyWith(top: 4.0),
                    child: NeumorphicTextWithPopupSliderButton(
                      isActive: false, // DONT ALLOW ACTIVE STATE.
                      height: 30,
                      value: zoneFunctions.matrixMixer! is MonoMatrixMixer ? (zoneFunctions.matrixMixer! as MonoMatrixMixer).outGain : 0.0,
                      onChanged: (double value) {
                        projectViewModel.updateMatrixMixer(
                          matrixMixer:
                              zoneFunctions.matrixMixer! is MonoMatrixMixer
                                  ? (zoneFunctions.matrixMixer! as MonoMatrixMixer).copyWith(
                                    outGain: value,
                                  )
                                  : zoneFunctions.matrixMixer!,
                          functionId: zoneFunctions.id,
                        );
                      },
                    ),
                  ),
                ),
              ],
            ),

            Flexible(
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(8.0),
                physics: const ClampingScrollPhysics(),
                child: Table(
                  columnWidths: <int, TableColumnWidth>{
                    0: FlexColumnWidth(sourcesFlex.toDouble()),
                    1: const FlexColumnWidth(),
                    2: const FlexColumnWidth(),
                  },
                  children: <TableRow>[
                    ...List<TableRow>.generate(sources.length, (int index) {
                      final bool isLast = index == sources.length - 1;
                      final Source source = sources[index];

                      final MonoMatrixSettings matrixSetting =
                          zoneFunctions.matrixMixer!.settings.firstWhere((MatrixSettings ms) => ms.sourceId == source.id) as MonoMatrixSettings;

                      return TableRow(
                        children: <Widget>[
                          Container(
                            height: 40,
                            margin: const EdgeInsets.only(left: 4, right: 4),
                            padding: const EdgeInsets.all(4),
                            decoration: BoxDecoration(
                              border: Border.all(color: const Color(0xFFE5E5E5), width: 1),
                            ),
                            child: Row(
                              spacing: 6,
                              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                              children: <Widget>[
                                Expanded(
                                  flex: 2,
                                  child: Container(
                                    height: 40,
                                    width: double.infinity,
                                    alignment: Alignment.center,
                                    padding: const EdgeInsets.all(4),
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      border: Border(
                                        right: borderSide,
                                        left: borderSide,
                                        top: isLast ? BorderSide.none : borderSide,
                                        bottom: isLast ? borderSide : BorderSide.none,
                                      ),
                                      borderRadius: const BorderRadius.all(Radius.circular(4)),
                                    ),
                                    child: Center(
                                      child: FusionAppText(
                                        text: source.name,
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.labelSmall,
                                      ),
                                    ),
                                  ),
                                ),
                                GestureDetector(
                                  onTap: () {
                                    projectViewModel.updateMatrixSettings(
                                      matrixSettings: matrixSetting.copyWith(
                                        muted: !matrixSetting.muted,
                                      ),
                                      functionId: zoneFunctions.id,
                                    );
                                  },
                                  child: Container(
                                    height: 28,
                                    width: 28,
                                    alignment: Alignment.center,
                                    decoration: BoxDecoration(
                                      color: const Color(0xFFF5F5F5),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.black12),
                                    ),
                                    child: SvgPicture.asset(
                                      'assets/svg/volume.svg',
                                      width: 16,
                                      height: 16,
                                      // ignore: deprecated_member_use
                                      color: matrixSetting.muted ? Colors.black12 : Colors.black,
                                    ),
                                  ),
                                ),
                                Flexible(
                                  child: NeumorphicTextWithPopupSliderButton(
                                    isActive: false, // DONT ALLOW ACTIVE STATE.
                                    value: matrixSetting.gain,
                                    onChanged: (double value) {
                                      projectViewModel.updateMatrixSettings(
                                        matrixSettings: matrixSetting.copyWith(
                                          gain: value,
                                        ),
                                        functionId: zoneFunctions.id,
                                      );
                                    },
                                  ),
                                ),
                              ],
                            ),
                          ),

                          Container(
                            height: 40,
                            alignment: Alignment.center,
                            padding: const EdgeInsets.all(4),
                            margin: const EdgeInsets.only(left: 4, right: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFF5F5F5),
                              border: Border(
                                right: borderSide,
                                left: borderSide,
                                top: isLast ? BorderSide.none : borderSide,
                                bottom: isLast ? borderSide : BorderSide.none,
                              ),
                            ),
                            child: NeumorphicTextWithPopupSliderButton(
                              isActive: false,
                              value: matrixSetting.mixLevel,
                              height: 30,
                              onChanged: (double value) {
                                projectViewModel.updateMatrixSettings(
                                  matrixSettings: matrixSetting.copyWith(
                                    mixLevel: value,
                                  ),
                                  functionId: zoneFunctions.id,
                                );
                              },
                            ),
                          ),
                        ],
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
