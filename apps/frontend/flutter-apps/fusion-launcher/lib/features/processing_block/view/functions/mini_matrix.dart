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
  late String functionId;

  @override
  void initState() {
    super.initState();
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
    functionId = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID)!.id;
  }

  @override
  Widget build(BuildContext context) {
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.85;
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    // sources

    final List<MixScene> savedMixScenes = projectViewModel.getAllMixScenesForFunction(functionId: functionId);
    final MixScene? selectedMixScene = projectViewModel.getSelectedMixSceneForFunction(functionId);

    final List<MatrixSettings> matrixSettings = projectViewModel.getCurrentMatrixSettingsForFunction(functionId: functionId);

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth < 800 ? controlScreenWidth : 800,
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(6))),
      child: ClipRRect(
        borderRadius: const BorderRadius.all(Radius.circular(6)),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            Container(
              height: 28,
              width: double.infinity,
              color: Colors.black,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                spacing: 10,
                children: <Widget>[
                  Expanded(
                    child: FusionAppText(
                      text: "ZONE CONTROL PANEL - MINI MATRIX",
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        color: Colors.white,
                        fontSize: 11,
                      ),
                    ),
                  ),
                  Material(
                    color: Colors.transparent,
                    child: InkWell(
                      onTap: Navigator.of(context).pop,
                      borderRadius: BorderRadius.circular(30),
                      child: const Icon(
                        Icons.close,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
            ),
            Flexible(
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  Expanded(
                    flex: 4,
                    child: MiniMatrixControls(
                      zoneID: widget.zoneID,
                      functionId: functionId,
                    ),
                  ),

                  const VerticalDivider(width: 1, color: Colors.black12),

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
                      } catch (e) {
                        // We might get StateError if the scene is not found.
                      }
                    },
                    onDeleteTap: () {
                      try {
                        // TODO: Implement delete functionality. Currently, it is not possible to delete a mix scene from the project.
                        // Because we dont know which one is currently selected.

                        // final MixScene scene = savedMixScenes.firstWhere((MixScene scene) => scene.name == value);
                        // projectViewModel.removeScene(sceneId: scene.id);
                      } catch (e) {
                        // We might get StateError if the scene is not found.
                      }
                    },
                  ),
                  const VerticalDivider(width: 1, color: Colors.black12),

                  Expanded(
                    flex: 3,
                    child: ZoneControlSliderBuilder(
                      zoneID: widget.zoneID,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class MiniMatrixControls extends StatelessWidget {
  final String zoneID;
  final String functionId;

  const MiniMatrixControls({super.key, required this.zoneID, required this.functionId});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = context.watch<ProjectViewModel>();

    final List<Source> sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: zoneID);

    final List<MatrixSettings> miniMatrixSettings = projectViewModel.getCurrentMatrixSettingsForFunction(functionId: functionId);

    const BorderSide borderSide = BorderSide(color: Color(0xFFE5E5E5), width: 1);

    return Container(
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
                  flex: 2,
                  child: Container(
                    height: 28,
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: const Color(0xFFF5F5F5),
                    child: FusionAppText(
                      text: "SOURCES",
                      style: Theme.of(context).textTheme.labelMedium,
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
                      style: Theme.of(context).textTheme.labelMedium,
                    ),
                  ),
                ),
              ],
            ),
          ),

          // TOP MUTE TOGGLE BUTTONS
          const Row(
            children: <Widget>[
              Expanded(flex: 2, child: SizedBox()),
              Expanded(
                child: NeumorphicAudioToggleButton(
                  isActive: false,
                  width: 72,
                  height: 24,
                  iconSize: 16,
                ),
              ),
            ],
          ),

          Row(
            children: <Widget>[
              const Expanded(flex: 2, child: SizedBox()),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(8.0).copyWith(top: 4.0),
                  child: const NeumorphicTextWithPopupSliderButton(
                    isActive: false, // DONT ALLOW ACTIVE STATE.
                    height: 30,
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
                  0: const FlexColumnWidth(2),
                  1: const FlexColumnWidth(),
                  2: const FlexColumnWidth(),
                },
                children: <TableRow>[
                  ...List<TableRow>.generate(sources.length, (int index) {
                    final bool isLast = index == sources.length - 1;
                    final Source source = sources[index];

                    final MonoMatrixSettings matrixSetting =
                        miniMatrixSettings.firstWhere((MatrixSettings ms) => ms.sourceId == source.id) as MonoMatrixSettings;

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
                                flex: 4,
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
                              Expanded(
                                flex: 3,
                                child: NeumorphicTextWithPopupSliderButton(
                                  isActive: false, // DONT ALLOW ACTIVE STATE.
                                  value: matrixSetting.gain,
                                  height: 30,
                                  onChanged: (double value) {
                                    projectViewModel.updateMatrixSettings(
                                      matrixSettings: matrixSetting.copyWith(
                                        gain: value,
                                      ),
                                    );
                                  },
                                ),
                              ),
                            ],
                          ),
                        ),

                        Row(
                          children: <Widget>[
                            Expanded(
                              child: Container(
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
                                    );
                                  },
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    );
                  }),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class NeumorphicWithPopupSlider extends StatelessWidget {
  const NeumorphicWithPopupSlider({super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 150,
      color: const Color(0xFFF5F5F5),
      child: Column(
        spacing: 10,
        children: <Widget>[
          Container(
            height: 28,
            width: double.infinity,
            alignment: Alignment.center,
            color: const Color(0xFFF5F5F5),
            child: FusionAppText(
              text: "CONTROLS",
              style: Theme.of(context).textTheme.labelSmall,
            ),
          ),

          Expanded(
            child: Container(
              color: Colors.white,
              child: const Column(
                spacing: 10,
                children: <Widget>[
                  // Padding(
                  //   padding: EdgeInsets.symmetric(horizontal: 8.0),
                  //   child: NeumorphicPopupButton(
                  //     height: 28,
                  //     borderRadius: 8,
                  //   ),
                  // ), // TODO: IMPLEMENT STORE AND DELETE BUTTONS

                  // PBButton(
                  //   text: "STORE",
                  //   width: 72,
                  //   height: 28,
                  //   borderRadius: 9,
                  //   onTap: () {
                  //     //
                  //   },
                  // ),
                  // PBButton(
                  //   text: "DELETE",
                  //   width: 72,
                  //   height: 28,
                  //   borderRadius: 9,
                  //   textColor: Colors.black12,
                  //   onTap: () {
                  //     //
                  //   },
                  // ), // TODO: IMPLEMENT STORE AND DELETE BUTTONS
                  SizedBox(height: 10),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
