import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/core/service_locator.dart';
import 'package:fusion_launcher/core/widgets/title_text_field_switcher.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_lib/fusion_building_view/floor_canvas_controller.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

class ListeningAreasPanel extends StatefulWidget {
  final FloorCanvasController floorCanvasController;

  const ListeningAreasPanel({super.key, required this.floorCanvasController});

  @override
  ListeningAreasPanelState createState() => ListeningAreasPanelState();
}

class ListeningAreasPanelState extends State<ListeningAreasPanel> with TickerProviderStateMixin {
  final Set<String> _expandedListeningAreas = <String>{};
  final ProjectViewModel _projectViewModel = serviceLocator<ProjectViewModel>();

  @override
  void initState() {
    super.initState();
    _initializeExpandedStates();
  }

  void _initializeExpandedStates() {
    // Expand all listening areas by default
    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().getAllListeningAreas();
    for (final ListeningArea area in listeningAreas) {
      _expandedListeningAreas.add(area.id);
    }
  }

  void _toggleListeningAreaExpansion(String listeningAreaId) {
    setState(() {
      if (_expandedListeningAreas.contains(listeningAreaId)) {
        _expandedListeningAreas.remove(listeningAreaId);
      } else {
        _expandedListeningAreas.add(listeningAreaId);
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        return SizedBox(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              // Listening Areas List
              _buildListeningAreasList(),
              const SizedBox(height: 8),
            ],
          ),
        );
      },
    );
  }

  Widget _buildListeningAreasList() {
    final List<ListeningArea> listeningAreas = serviceLocator<ProjectViewModel>().getAllListeningAreas();

    if (listeningAreas.isEmpty) {
      return _buildEmptyState();
    }

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "listening_area_lists"),
      child: Container(
        constraints: const BoxConstraints(),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: <Widget>[
            const SizedBox(height: 3),
            ...listeningAreas.map(
              (ListeningArea area) {
                final int index = listeningAreas.indexOf(area);
                return SemanticHelper.listItem(
                  testId: SemanticHelper.createTestId(SemanticTypes.listItem, "listening_area_item_$index"),
                  index: index,
                  child: _buildListeningAreaCard(area),
                );
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      constraints: const BoxConstraints(),
      padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        mainAxisAlignment: MainAxisAlignment.center,
        children: <Widget>[
          Icon(
            Icons.layers_outlined,
            size: 48,
            color: Colors.grey[400],
          ),
          const SizedBox(height: 16),
          FusionAppText(
            text: 'No listening areas yet',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 11,
              fontWeight: FontWeight.w500,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildListeningAreaCard(ListeningArea area) {
    final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedListeningAreaId == area.id;
    final bool isExpanded = _expandedListeningAreas.contains(area.id);
    final String floorName = serviceLocator<ProjectViewModel>().getFloorForListeningArea(areaId: area.id)?.name ?? '';

    // Get speakers for this listening area
    final List<HardwareComponent> allHardware = serviceLocator<ProjectViewModel>().getHardwareForListeningArea(listeningAreaId: area.id);
    final List<Speaker> speakers = allHardware.whereType<Speaker>().where((Speaker element) => element.pos != null).toList();

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: <Widget>[
        // Listening Area Header
        ValueListenableBuilder<bool>(
          valueListenable: widget.floorCanvasController.isDrawing,
          builder: (BuildContext context, bool isDrawingValue, Widget? child) {
            return Container(
              decoration: BoxDecoration(
                color: isSelected ? Colors.grey[200] : Colors.transparent,
              ),
              child: Container(
                padding: const EdgeInsets.fromLTRB(8, 6, 8, 6),
                child: GestureDetector(
                  onTap: () {
                    print("outside single");

                    serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(area.id);
                    serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(null);
                    print("Selected listening area: ${area.name}");
                    if (!area.isDrawn) {
                      widget.floorCanvasController.setDraw(true);
                    } else if (area.isDrawn && widget.floorCanvasController.isDrawing.value) {
                      widget.floorCanvasController.setDraw(false);
                    }
                  },
                  child: Row(
                    children: <Widget>[
                      // Expand/Collapse icon
                      GestureDetector(
                        onTap: () => _toggleListeningAreaExpansion(area.id),
                        child: AnimatedRotation(
                          duration: const Duration(milliseconds: 200),
                          turns: isExpanded ? 0.25 : 0.0,
                          child: SemanticHelper.toggle(
                            testId: SemanticHelper.createTestId(SemanticTypes.toggle, "listening_area_expand_collapse"),
                            value: isExpanded,
                            child: Icon(
                              Icons.keyboard_arrow_right,
                              size: 16,
                              color: Colors.grey[600],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 4),
                      Icon(
                        LucideIcons.maximize200,
                        size: 12,
                        color: context.colorScheme.onSurface,
                      ),
                      const SizedBox(width: 4),

                      /// Listening area name display
                      Expanded(
                        child: Row(
                          children: <Widget>[
                            FusionAppText(
                              text: "$floorName /",
                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                fontSize: 11,
                                fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                color: (!area.isDrawn) ? context.colorScheme.error : null,
                              ),
                            ),
                            Expanded(
                              child: TitleTextFieldSwitcher(
                                value: area.name,
                                hintText: "listening area name",
                                style: Theme.of(context).textTheme.bodySmall!.copyWith(
                                  fontSize: 11,
                                  fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                                  color: (!area.isDrawn) ? context.colorScheme.error : null,
                                ),
                                save: (String value) {
                                  if (value.trim().isNotEmpty) {
                                    final ListeningArea updatedLA = area.copyWith(name: value.trim());
                                    _projectViewModel.updateListeningArea(area: updatedLA);
                                  }
                                },
                              ),
                            ),
                          ],
                        ),
                      ),

                      if (!area.isDrawn) ...<Widget>[
                        Tooltip(
                          message: 'Start drawing to place this listening area',
                          child: Container(
                            padding: const EdgeInsets.all(4),
                            color: (isSelected && widget.floorCanvasController.isDrawing.value) ? context.colorScheme.errorContainer : Colors.transparent,
                            child: Icon(
                              Icons.info_outline_rounded,
                              size: 12,
                              color: context.colorScheme.error,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ),
            );
          },
        ),

        // Expandable Speakers Section
        AnimatedCrossFade(
          duration: const Duration(milliseconds: 250),
          crossFadeState: isExpanded ? CrossFadeState.showFirst : CrossFadeState.showSecond,
          firstChild: Column(
            mainAxisSize: MainAxisSize.min,
            children: <Widget>[
              if (speakers.isNotEmpty) ...<Widget>[
                ...speakers.map(
                  (Speaker speaker) {
                    final int index = speakers.indexOf(speaker);
                    return SemanticHelper.container(
                      testId: SemanticHelper.createTestId(SemanticTypes.container, "listening_area_speaker_$index"),
                      child: _buildSpeakerItem(speaker),
                    );
                  },
                ),
              ] else
                SemanticHelper.staticText(
                  testId: SemanticHelper.createTestId(SemanticTypes.text, "no_speakers_message"),
                  child: _buildNoSpeakersMessage(),
                ),
            ],
          ),
          secondChild: const SizedBox.shrink(),
        ),
      ],
    );
  }

  Widget _buildSpeakerItem(Speaker speaker) {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final bool isSelected = serviceLocator<ProjectViewModel>().currentSelectedHardwareId == speaker.id;

        return Container(
          margin: const EdgeInsets.only(left: 24, top: 2),
          decoration: BoxDecoration(
            color: isSelected ? Colors.grey[200] : Colors.transparent,
            borderRadius: BorderRadius.circular(4),
          ),
          child: GestureDetector(
            onTap: () {
              serviceLocator<ProjectViewModel>().setCurrentSelectedHardware(speaker.id);
              serviceLocator<ProjectViewModel>().setCurrentSelectedListeningArea(null);
            },
            // borderRadius: BorderRadius.circular(4),
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
              child: Row(
                children: <Widget>[
                  Image.asset(
                    speaker.assetImagePath,
                    width: 14,
                    height: 14,
                  ),
                  const SizedBox(width: 6),

                  // Expanded(
                  //   child: FusionAppText(
                  //     text: speaker.name,
                  //     style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  //       fontSize: 11,
                  //       fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                  //       color: Colors.grey[700],
                  //     ),
                  //   ),
                  // ),
                  Expanded(
                    child: TitleTextFieldSwitcher(
                      value: speaker.name,
                      hintText: "Enter speaker name",
                      style: Theme.of(context).textTheme.bodySmall!.copyWith(
                        fontSize: 11,
                        fontWeight: isSelected ? FontWeight.w500 : FontWeight.w400,
                        color: Colors.grey[700],
                      ),
                      save: (String value) {
                        if (value.trim().isNotEmpty) {
                          final HardwareComponent updated = speaker.copyWith(name: value);
                          _projectViewModel.updateHardware(hardware: updated);
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildNoSpeakersMessage() {
    return Container(
      margin: const EdgeInsets.only(left: 24, right: 16, top: 4, bottom: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.grey[200]!, width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.max,
        children: <Widget>[
          Icon(
            Icons.info_outline,
            size: 10,
            color: Colors.grey[500],
          ),
          const SizedBox(width: 8),
          Flexible(
            child: FusionAppText(
              text: 'No speakers',
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey[600],
                fontWeight: FontWeight.w400,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
