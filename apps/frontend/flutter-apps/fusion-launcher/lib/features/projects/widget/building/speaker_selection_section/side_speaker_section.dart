import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/projects/widget/building/speaker_selection_section/view_model/product_query_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_theme/color_scheme.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../../core/service_locator.dart';
import 'parts/select_speaker_popup.dart';

class SpeakerSelectionWidget extends StatefulWidget {
  const SpeakerSelectionWidget({super.key});

  @override
  State<SpeakerSelectionWidget> createState() => _SpeakerSelectionWidgetState();
}

class _SpeakerSelectionWidgetState extends State<SpeakerSelectionWidget> {
  bool _isExpanded = true; // intialized to true

  @override
  Widget build(BuildContext context) {
    return BlocBuilder<ProductQueryViewModel, ProductQueryViewModelState>(
      builder: (BuildContext context, ProductQueryViewModelState _) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();
            final ListeningArea? currentSelectedListeningAreaId = projectViewModel.getCurrentSelectedListeningArea();

            if (currentSelectedListeningAreaId == null || projectViewModel.currentToolbarMode == ToolbarMode.system) {
              return const SizedBox.shrink();
            }

            return SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "side_speaker_selection_section"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                decoration: BoxDecoration(
                  border: Border(
                    bottom: BorderSide(
                      color: Theme.of(context).colorScheme.primaryBlack,
                      width: 1,
                    ),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 16),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          Expanded(
                            child: FusionAppText(
                              text: "SPEAKERS",
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                              ),
                            ),
                          ),

                          Builder(
                            builder: (BuildContext context) {
                              final String? areaId = projectViewModel.currentSelectedListeningAreaId;
                              if (areaId == null) return const SizedBox.shrink();

                              final List<HardwareComponent> speakers = projectViewModel.getPlacedSpeakersForCurrentListeningArea();

                              if (speakers.isNotEmpty) return const SizedBox.shrink();

                              return PopupMenuButton<String>(
                                color: Colors.transparent,
                                shadowColor: Colors.transparent,
                                tooltip: 'Add speakers',
                                padding: EdgeInsets.zero,
                                menuPadding: EdgeInsets.zero,
                                clipBehavior: Clip.none,
                                offset: const Offset(45, 0),
                                constraints: const BoxConstraints(minWidth: 1000),
                                child: SemanticHelper.button(
                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "add_speaker_button"),
                                  child: Padding(
                                    padding: const EdgeInsets.all(3.0),
                                    child: Icon(
                                      LucideIcons.plus200,
                                      size: 14,
                                      color: Theme.of(context).colorScheme.textPrimary,
                                    ),
                                  ),
                                ),
                                itemBuilder: (BuildContext context) {
                                  return <PopupMenuEntry<String>>[
                                    PopupMenuItem<String>(
                                      enabled: false,
                                      padding: EdgeInsets.zero,
                                      child: Theme(
                                        data: ThemeData.dark(),
                                        child: const SpeakerQueryPopup(
                                          isFromBuildingPage: true,
                                        ),
                                      ),
                                    ),
                                  ];
                                },
                              );
                            },
                          ),
                        ],
                      ),
                    ),

                    BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                      builder: (BuildContext context, ProjectViewModelState state) {
                        final String? listeningAreaId = projectViewModel.currentSelectedListeningAreaId;
                        if (listeningAreaId == null) return const SizedBox.shrink();

                        final ListeningArea listeningArea = projectViewModel.getListeningArea(areaId: listeningAreaId);

                        final List<HardwareComponent> nonPlacedSpeakers = projectViewModel.getNonPlacedSpeakersForCurrentListeningArea();
                        final List<Speaker> placedSpeakers = projectViewModel.getPlacedSpeakersForCurrentListeningArea();

                        final List<Speaker> allSpeaekers = <Speaker>[...nonPlacedSpeakers.whereType<Speaker>(), ...placedSpeakers];

                        if (allSpeaekers.isEmpty) return const SizedBox.shrink();

                        final bool shouldPlaceNonPlacedSpeakers = projectViewModel.shouldPlaceNonPlacedSpeakers;

                        return Padding(
                          padding: const EdgeInsets.all(12.0),
                          child: Column(
                            children: <Widget>[
                              SemanticHelper.container(
                                testId: SemanticHelper.createTestId(SemanticTypes.container, "side_speaker_selection_section_expansion_section"),
                                child: GestureDetector(
                                  onTap: () {
                                    setState(() {
                                      _isExpanded = !_isExpanded;
                                    });
                                  },
                                  behavior: HitTestBehavior.translucent,
                                  child: Row(
                                    children: <Widget>[
                                      SemanticHelper.toggle(
                                        testId: SemanticHelper.createTestId(SemanticTypes.toggle, "side_speaker_selection_section_expand_collapse"),
                                        value: _isExpanded,
                                        child: Icon(
                                          _isExpanded ? LucideIcons.chevronDown200 : LucideIcons.chevronRight200,
                                          size: 16,
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                      const SizedBox(width: 8),
                                      SemanticHelper.staticText(
                                        testId: SemanticHelper.createTestId(SemanticTypes.text, "side_speaker_selection_section_name"),
                                        child: FusionAppText(
                                          text: listeningArea.name,
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 11,
                                            fontWeight: FontWeight.w500,
                                          ),
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),

                              if (_isExpanded) ...<Widget>[
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: <Widget>[
                                    const SizedBox(height: 10),
                                    GestureDetector(
                                      onTap: () {
                                        if (nonPlacedSpeakers.isNotEmpty) {
                                          projectViewModel.setShouldPlaceNonPlacedSpeakers(!projectViewModel.shouldPlaceNonPlacedSpeakers);
                                        }
                                      },
                                      child: Container(
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          borderRadius: BorderRadius.circular(8),
                                          border: Border.all(
                                            color: shouldPlaceNonPlacedSpeakers ? context.colorScheme.surfaceDim : Colors.transparent,
                                            width: 1,
                                          ),
                                        ),
                                        child: Row(
                                          children: <Widget>[
                                            Container(
                                              width: 24,
                                              height: 24,
                                              padding: const EdgeInsets.all(4),
                                              decoration: BoxDecoration(
                                                color: Colors.white,
                                                borderRadius: BorderRadius.circular(6),
                                              ),
                                              child: Image.asset(allSpeaekers.first.assetImagePath),
                                            ),
                                            const SizedBox(width: 12),
                                            Expanded(
                                              child: FusionAppText(
                                                text: allSpeaekers.first.name,
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  fontWeight: FontWeight.w500,
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 12),
                                            if (allSpeaekers.isNotEmpty) ...<Widget>[
                                              // edit icon
                                              PopupMenuButton<String>(
                                                color: Colors.transparent,
                                                shadowColor: Colors.transparent,
                                                tooltip: 'Edit speakers',
                                                padding: EdgeInsets.zero,
                                                menuPadding: EdgeInsets.zero,
                                                clipBehavior: Clip.none,
                                                offset: const Offset(45, 0),
                                                constraints: const BoxConstraints(minWidth: 1000),
                                                child: SemanticHelper.button(
                                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "edit_speaker_button"),
                                                  child: Padding(
                                                    padding: const EdgeInsets.all(3.0),
                                                    child: Icon(
                                                      LucideIcons.pencil200,
                                                      size: 12,
                                                      color: context.colorScheme.onSurface,
                                                    ),
                                                  ),
                                                ),
                                                itemBuilder: (BuildContext context) {
                                                  return <PopupMenuEntry<String>>[
                                                    PopupMenuItem<String>(
                                                      enabled: false,
                                                      padding: EdgeInsets.zero,
                                                      child: Theme(
                                                        data: ThemeData.dark(),
                                                        child: const SpeakerQueryPopup(isFromBuildingPage: true),
                                                      ),
                                                    ),
                                                  ];
                                                },
                                              ),
                                            ],
                                          ],
                                        ),
                                      ),
                                    ),
                                    if (placedSpeakers.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 5),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 36),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: FusionAppText(
                                                text: 'Placed',
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  color: context.colorScheme.onSurface,
                                                ),
                                              ),
                                            ),

                                            const SizedBox(width: 8),
                                            FusionAppText(
                                              text: "${placedSpeakers.length}",
                                              style: context.textTheme.bodySmall?.copyWith(
                                                color: context.colorScheme.onSurface,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],

                                    if (nonPlacedSpeakers.isNotEmpty) ...<Widget>[
                                      const SizedBox(height: 5),
                                      Padding(
                                        padding: const EdgeInsets.only(left: 36),
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: FusionAppText(
                                                text: 'Non-placed',
                                                style: context.textTheme.bodySmall?.copyWith(
                                                  color: context.colorScheme.onSurface,
                                                ),
                                              ),
                                            ),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: () {
                                                  final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
                                                  projectViewModel.decreaseQty();
                                                },
                                                child: SemanticHelper.button(
                                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "decrease_non_placed_speaker_quantity_button"),
                                                  child: Icon(
                                                    LucideIcons.minus200,
                                                    size: 12,
                                                    color: context.colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ),
                                            const SizedBox(width: 8),
                                            FusionAppText(
                                              text: "${nonPlacedSpeakers.length}",
                                              style: context.textTheme.bodySmall,
                                            ),
                                            const SizedBox(width: 8),
                                            MouseRegion(
                                              cursor: SystemMouseCursors.click,
                                              child: GestureDetector(
                                                onTap: () {
                                                  final ProjectViewModel projectViewModel = context.read<ProjectViewModel>();
                                                  projectViewModel.increaseQty();
                                                },
                                                child: SemanticHelper.button(
                                                  testId: SemanticHelper.createTestId(SemanticTypes.button, "increase_non_placed_speaker_quantity_button"),
                                                  child: Icon(
                                                    LucideIcons.plus200,
                                                    size: 12,
                                                    color: context.colorScheme.onSurface,
                                                  ),
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ],
                            ],
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }
}
