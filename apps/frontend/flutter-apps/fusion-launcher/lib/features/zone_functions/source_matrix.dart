import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/zone_functions/source_mix.dart';
import 'package:fusion_launcher/features/zone_functions/widgets/matrix_mixer_panel/matrix_mixer_panel_widget.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../core/service_locator.dart';
import '../configuration/presentation/viewmodel/project_view_model.dart';
import '../zone_function_settings/matrix_settings/matrix_settings.dart';
import 'widgets/mix_scene.dart';
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
                child: SemanticHelper.container(
                  testId: SemanticHelper.createTestId(SemanticTypes.container, 'zone_control_panel'),
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
                        padding: const EdgeInsets.symmetric(vertical: 50.0).copyWith(bottom: hasPriority ? null : null),
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
                                          child: SemanticHelper.container(
                                            testId: SemanticHelper.createTestId(SemanticTypes.container, 'zone_control_sources'),
                                            child: SourceMatrixControlsPanel(
                                              zoneID: widget.zoneID,
                                              zoneFunctions: zoneFunction,
                                            ),
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
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Material(
                          color: Colors.transparent,
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                            child: SemanticHelper.container(
                              testId: SemanticHelper.createTestId(SemanticTypes.container, "source_select_additional_settings_button"),
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
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
