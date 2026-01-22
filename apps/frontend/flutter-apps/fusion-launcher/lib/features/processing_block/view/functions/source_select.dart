import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/processing_block/view/functions/source_mix.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../widgets/pb_radio.dart';
import 'widgets/priority_selection_widget.dart';

class SourceSelectZoneControlPanel extends StatefulWidget {
  final String zoneID;
  const SourceSelectZoneControlPanel({super.key, required this.zoneID});

  static void showDialog(BuildContext context, {required String zoneID}) {
    showGeneralDialog(
      context: context,
      barrierDismissible: true,
      barrierLabel: MaterialLocalizations.of(context).modalBarrierDismissLabel,
      barrierColor: Colors.black54,
      transitionDuration: const Duration(milliseconds: 200),
      pageBuilder: (BuildContext buildContext, _, __) {
        return SourceSelectZoneControlPanel(
          zoneID: zoneID,
        );
      },
    );
  }

  @override
  State<SourceSelectZoneControlPanel> createState() => _SourceSelectZoneControlPanelState();
}

class _SourceSelectZoneControlPanelState extends State<SourceSelectZoneControlPanel> {
  late List<Source> sources;
  final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
  ZoneFunctions? zoneFunction;

  @override
  void initState() {
    super.initState();
    sources = projectViewModel.getSourcesAndSourceSetSourcesInZone(zoneId: widget.zoneID);
    zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID);
  }

  @override
  Widget build(BuildContext context) {
    final double controlScreenWidth = MediaQuery.sizeOf(context).width * 0.85;

    return Dialog(
      constraints: BoxConstraints(
        maxWidth: controlScreenWidth,
        maxHeight: MediaQuery.sizeOf(context).height * 0.5,
      ),
      backgroundColor: context.colorScheme.elevation1,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(FusionSizes.borderRadius16))),
      child: BlocConsumer<ProjectViewModel, ProjectViewModelState>(
        listener: (BuildContext context, ProjectViewModelState state) {
          zoneFunction = projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneID);
        },
        builder: (BuildContext context, ProjectViewModelState state) {
          return Container(
            decoration: BoxDecoration(
              color: context.colorScheme.elevation1,
              border: Border.all(
                color: context.colorScheme.strokeLight,
              ),
              borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(FusionSizes.borderRadius16),
              child: Stack(
                children: <Widget>[
                  SemanticHelper.container(
                    testId: SemanticHelper.createTestId(SemanticTypes.container, "source_select_main_container"),
                    child: Container(
                      color: Colors.black,
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: <Widget>[
                          const SizedBox(height: 35),
                          Flexible(
                            fit: FlexFit.loose,
                            child: Container(
                              color: context.colorScheme.elevation1,
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  // LEFT COLUMN (Reorderable List)
                                  Flexible(
                                    child: SizedBox(
                                      width: 350,
                                      child: Column(
                                        children: <Widget>[
                                          Container(
                                            height: 28,
                                            width: double.infinity,
                                            alignment: Alignment.center,
                                            color: context.colorScheme.elevation2,
                                            child: FusionAppText(
                                              text: "SOURCE SELECT",
                                              style: Theme.of(context).textTheme.labelSmall,
                                            ),
                                          ),
                                          Divider(color: context.colorScheme.strokeLight, height: 0),
                                          Container(
                                            margin: const EdgeInsets.symmetric(horizontal: 8),
                                            padding: const EdgeInsets.all(8.0),
                                            child: Row(
                                              spacing: 10,
                                              children: <Widget>[
                                                Expanded(
                                                  flex: 2,
                                                  child: Center(
                                                    child: FusionAppText(
                                                      text: "Channels",
                                                      textAlign: TextAlign.center,
                                                      style: Theme.of(context).textTheme.labelSmall,
                                                    ),
                                                  ),
                                                ),
                                                FusionAppText(
                                                  text: "Out",
                                                  style: Theme.of(context).textTheme.labelSmall,
                                                ),
                                              ],
                                            ),
                                          ),
                                          Divider(color: context.colorScheme.strokeLight, height: 0),

                                          Expanded(
                                            child: Builder(
                                              builder: (BuildContext context) {
                                                if (sources.isEmpty) {
                                                  return Center(
                                                    child: FusionAppText(
                                                      text: "No sources selected for this function",
                                                      style: Theme.of(context).textTheme.labelSmall?.copyWith(
                                                        color: Colors.grey,
                                                      ),
                                                    ),
                                                  );
                                                }

                                                return ListView.builder(
                                                  padding: const EdgeInsets.symmetric(horizontal: 8),
                                                  physics: const ClampingScrollPhysics(),
                                                  itemCount: sources.length,
                                                  itemBuilder: (BuildContext context, int index) {
                                                    final Source source = sources[index];

                                                    final bool isSelected = source.id == zoneFunction?.selectedSourceId;

                                                    return GestureDetector(
                                                      onTap: () {
                                                        projectViewModel.selectSourceForFunction(
                                                          functionId: zoneFunction!.id,
                                                          sourceId: source.id,
                                                        );
                                                      },
                                                      child: Container(
                                                        key: ValueKey<String>(source.id),
                                                        margin: const EdgeInsets.symmetric(vertical: 2),
                                                        decoration: BoxDecoration(
                                                          border: Border.all(
                                                            color: isSelected ? context.colorScheme.primaryWhite : context.colorScheme.strokeLight,
                                                          ),
                                                          borderRadius: BorderRadius.circular(4),
                                                          color: context.colorScheme.elevation1,
                                                        ),
                                                        child: Row(
                                                          children: <Widget>[
                                                            Flexible(
                                                              child: Container(
                                                                height: 28,
                                                                margin: const EdgeInsets.all(4),
                                                                alignment: Alignment.center,
                                                                padding: const EdgeInsets.all(2),
                                                                decoration: BoxDecoration(
                                                                  color: context.colorScheme.elevation1,
                                                                  borderRadius: BorderRadius.circular(4),
                                                                ),
                                                                child: FusionAppText(
                                                                  text: source.name,
                                                                  maxLine: 1,
                                                                  style: Theme.of(context).textTheme.labelSmall,
                                                                ),
                                                              ),
                                                            ),
                                                            SemanticHelper.toggle(
                                                              testId: SemanticHelper.createTestId(SemanticTypes.toggle, "source_select_radio_$index"),
                                                              value: isSelected,
                                                              child: PBRadio(
                                                                value: isSelected,
                                                                size: const Size(28, 28),
                                                                padding: const EdgeInsets.all(2),
                                                                onChanged: (bool value) {
                                                                  projectViewModel.selectSourceForFunction(
                                                                    functionId: zoneFunction!.id,
                                                                    sourceId: source.id,
                                                                  );
                                                                },
                                                              ),
                                                            ),

                                                            const SizedBox(width: 5),
                                                          ],
                                                        ),
                                                      ),
                                                    );
                                                  },
                                                );
                                              },
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ),
                                  VerticalDivider(width: 1, color: context.colorScheme.strokeLight),

                                  PrioritySelectionWidget(zoneId: widget.zoneID),

                                  // RIGHT COLUMN (Static)
                                  Flexible(child: ZoneControlSliderBuilder(zoneID: widget.zoneID)),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),

                  // HEADER TITLE
                  Positioned(
                    left: 0,
                    child: Container(
                      height: 35,
                      color: Colors.black,
                      alignment: Alignment.centerLeft,
                      padding: const EdgeInsets.symmetric(horizontal: 12.0),
                      child: Text(
                        "ZONE CONTROL PANEL - SOURCE SELECT",
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          color: Colors.white,
                          fontSize: 11,
                        ),
                      ),
                    ),
                  ),

                  // CLOSE BUTTON
                  Positioned(
                    right: 0,
                    child: SemanticHelper.button(
                      testId: SemanticHelper.createTestId(SemanticTypes.button, "source_select_close_button"),
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
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}
