import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/service_locator.dart';
import '../../../projects/viewmodel/building_page_viewmodel.dart';
import '../speaker_selection_popup.dart';
import 'auto_place_dialog.dart';

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

            if (currentSelectedListeningAreaId == null || context.watch<BuildingPageViewModel>().state.toolbarMode == ToolbarMode.system) {
              return const SizedBox.shrink();
            }

            return SemanticHelper.container(
              testId: SemanticHelper.createTestId(SemanticTypes.container, "side_speaker_selection_section"),
              child: Container(
                padding: const EdgeInsets.symmetric(vertical: 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Padding(
                      padding: const EdgeInsets.all(12),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          FusionAppText(
                            text: "SPEAKERS",
                            style: context.textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              color: context.colorScheme.textPrimary,
                            ),
                          ),
                          Builder(
                            builder: (BuildContext context) {
                              final String? areaId = projectViewModel.currentSelectedListeningAreaId;
                              if (areaId == null) return const SizedBox.shrink();

                              final List<Speaker> nonPlacedSpeakers = projectViewModel.getNonPlacedSpeakersForCurrentListeningArea();
                              final List<Speaker> placedSpeakers = projectViewModel.getPlacedSpeakersForCurrentListeningArea();
                              final List<Speaker> allSpeakers = <Speaker>[...nonPlacedSpeakers, ...placedSpeakers];

                              if (allSpeakers.isNotEmpty) return const SizedBox.shrink();

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
                                        child: const SpeakerSelectionPopup(
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

                        final List<Speaker> nonPlacedSpeakers = projectViewModel.getNonPlacedSpeakersForCurrentListeningArea();
                        final List<Speaker> placedSpeakers = projectViewModel.getPlacedSpeakersForCurrentListeningArea();
                        final List<Speaker> allSpeakers = <Speaker>[...nonPlacedSpeakers, ...placedSpeakers];

                        if (allSpeakers.isEmpty) return const SizedBox.shrink();

                        final ProductQueryViewModel pq = context.read<ProductQueryViewModel>();

                        bool isSubwooferSpeaker(Speaker sp) {
                          final int? productId = sp.productId;
                          if (productId == null) return false;
                          final SpeakerProduct? product = pq.speakers.where((SpeakerProduct s) => s.id == productId).firstOrNull;
                          return product?.isSubwoofer ?? false;
                        }

                        final List<Speaker> placedMidHigh = placedSpeakers.where((Speaker sp) => !isSubwooferSpeaker(sp)).toList();
                        final List<Speaker> nonPlacedMidHigh = nonPlacedSpeakers.where((Speaker sp) => !isSubwooferSpeaker(sp)).toList();
                        final List<Speaker> allMidHigh = <Speaker>[...nonPlacedMidHigh, ...placedMidHigh];

                        final List<Speaker> placedSubwoofer = placedSpeakers.where((Speaker sp) => isSubwooferSpeaker(sp)).toList();
                        final List<Speaker> nonPlacedSubwoofer = nonPlacedSpeakers.where((Speaker sp) => isSubwooferSpeaker(sp)).toList();
                        final List<Speaker> allSubwoofer = <Speaker>[...nonPlacedSubwoofer, ...placedSubwoofer];

                        final bool hasSubwooferSpeakerInLA = allSubwoofer.isNotEmpty;
                        final bool isSpeakerPlacementMode = context.watch<BuildingPageViewModel>().isSpeakerPlacementMode;

                        Widget buildSpeakerGroupSection({
                          required String title,
                          required List<Speaker> allGroup,
                          required List<Speaker> placedGroup,
                          required List<Speaker> nonPlacedGroup,
                        }) {
                          final Speaker? representative = allGroup.firstOrNull;
                          final bool canPlace = nonPlacedGroup.isNotEmpty;

                          return Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              if (hasSubwooferSpeakerInLA)
                                Padding(
                                  padding: const EdgeInsets.only(bottom: 6),
                                  child: FusionAppText(
                                    text: title,
                                    style: context.textTheme.bodySmall?.copyWith(
                                      color: context.colorScheme.onSurface.withValues(alpha: 0.7),
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ),
                              Container(
                                padding: const EdgeInsets.all(4).copyWith(right: 0),
                                decoration: BoxDecoration(
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Row(
                                  children: <Widget>[
                                    if (representative != null)
                                      Container(
                                        width: 24,
                                        height: 24,
                                        padding: const EdgeInsets.all(4),
                                        decoration: BoxDecoration(
                                          color: Colors.white,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: FusionImage.asset(
                                          serviceLocator<ProjectViewModel>().getHardwareImage(
                                            productId: representative.productId ?? 0,
                                            currentImagePath: representative.assetImagePath,
                                          ),
                                        ),
                                      )
                                    else
                                      Container(
                                        width: 24,
                                        height: 24,
                                        decoration: BoxDecoration(
                                          color: context.colorScheme.elevation2,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                      ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: FusionAppText(
                                        text: representative?.speakerSKU ?? 'None selected',
                                        style: context.textTheme.bodySmall?.copyWith(
                                          fontWeight: FontWeight.w500,
                                        ),
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    PopupMenuButton<String>(
                                      color: Colors.transparent,
                                      shadowColor: Colors.transparent,
                                      tooltip: 'Edit speakers',
                                      padding: EdgeInsets.zero,
                                      menuPadding: EdgeInsets.zero,
                                      clipBehavior: Clip.none,
                                      offset: const Offset(60, 0),
                                      constraints: const BoxConstraints(minWidth: 1000),
                                      child: SemanticHelper.button(
                                        testId: SemanticHelper.createTestId(
                                          SemanticTypes.button,
                                          'edit_speaker_button_${title.toLowerCase().replaceAll(' ', '_')}',
                                        ),
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
                                              child: const SpeakerSelectionPopup(isFromBuildingPage: true),
                                            ),
                                          ),
                                        ];
                                      },
                                    ),
                                    if (canPlace && !listeningArea.autoPlacement) ...<Widget>[
                                      const SizedBox(width: 8),
                                      MouseRegion(
                                        cursor: SystemMouseCursors.click,
                                        child: GestureDetector(
                                          onTap: () {
                                            final BuildingPageViewModel buildingPageViewModel = context.read<BuildingPageViewModel>();
                                            if (listeningArea.autoPlacement) return buildingPageViewModel.setShouldPlaceNonPlacedSpeakers(false);
                                            buildingPageViewModel.setShouldPlaceNonPlacedSpeakers(!isSpeakerPlacementMode);
                                          },
                                          child: Tooltip(
                                            message: 'Place non-placed speakers',
                                            child: Icon(
                                              LucideIcons.mapPin200,
                                              size: 16,
                                              color: isSpeakerPlacementMode ? context.colorScheme.primaryColor : context.colorScheme.iconDefault,
                                            ),
                                          ),
                                        ),
                                      ),
                                    ],
                                  ],
                                ),
                              ),
                              if (placedGroup.isNotEmpty && !listeningArea.autoPlacement) ...<Widget>[
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
                                        text: '${placedGroup.length}',
                                        style: context.textTheme.bodySmall?.copyWith(
                                          color: context.colorScheme.onSurface,
                                        ),
                                      ),
                                      if (nonPlacedGroup.isEmpty && !listeningArea.autoPlacement) ...<Widget>[
                                        const SizedBox(width: 8),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              final ProjectViewModel pvm = context.read<ProjectViewModel>();
                                              final Speaker clonedSpeaker = placedGroup.last.getClone();
                                              clonedSpeaker.pos = null;
                                              pvm.addHardware(hardware: clonedSpeaker);
                                            },
                                            child: SemanticHelper.button(
                                              testId: SemanticHelper.createTestId(SemanticTypes.button, 'add_one_more_placed_speaker_to_non_placed_$title'),
                                              child: Icon(
                                                LucideIcons.plus200,
                                                size: 12,
                                                color: context.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                              if (nonPlacedGroup.isNotEmpty && !listeningArea.autoPlacement) ...<Widget>[
                                const SizedBox(height: 5),
                                Padding(
                                  padding: const EdgeInsets.only(left: 36),
                                  child: Row(
                                    children: <Widget>[
                                      Expanded(
                                        child: FusionAppText(
                                          text: 'Unplaced',
                                          style: context.textTheme.bodySmall?.copyWith(
                                            color: context.colorScheme.onSurface,
                                          ),
                                        ),
                                      ),
                                      if (!listeningArea.autoPlacement) ...<Widget>[
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              final ProjectViewModel pvm = context.read<ProjectViewModel>();
                                              pvm.removeHardware(hardwareId: nonPlacedGroup.last.id);
                                            },
                                            child: SemanticHelper.button(
                                              testId: SemanticHelper.createTestId(
                                                SemanticTypes.button,
                                                'decrease_non_placed_speaker_quantity_button_${title.toLowerCase().replaceAll(' ', '_')}',
                                              ),
                                              child: Icon(
                                                LucideIcons.minus200,
                                                size: 12,
                                                color: context.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 8),
                                      ],
                                      FusionAppText(
                                        text: '${nonPlacedGroup.length}',
                                        style: context.textTheme.bodySmall,
                                      ),
                                      if (!listeningArea.autoPlacement) ...<Widget>[
                                        const SizedBox(width: 8),
                                        MouseRegion(
                                          cursor: SystemMouseCursors.click,
                                          child: GestureDetector(
                                            onTap: () {
                                              final ProjectViewModel pvm = context.read<ProjectViewModel>();
                                              final Speaker clonedSpeaker = nonPlacedGroup.last.getClone();
                                              clonedSpeaker.pos = null;
                                              pvm.addHardware(hardware: clonedSpeaker);
                                            },
                                            child: SemanticHelper.button(
                                              testId: SemanticHelper.createTestId(
                                                SemanticTypes.button,
                                                'increase_non_placed_speaker_quantity_button_${title.toLowerCase().replaceAll(' ', '_')}',
                                              ),
                                              child: Icon(
                                                LucideIcons.plus200,
                                                size: 12,
                                                color: context.colorScheme.onSurface,
                                              ),
                                            ),
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ],
                          );
                        }

                        return Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.all(12.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
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
                                  const SizedBox(height: 10),
                                  if (hasSubwooferSpeakerInLA) ...<Widget>[
                                    buildSpeakerGroupSection(
                                      title: 'Mid-High',
                                      allGroup: allMidHigh,
                                      placedGroup: placedMidHigh,
                                      nonPlacedGroup: nonPlacedMidHigh,
                                    ),
                                    const SizedBox(height: 10),
                                    buildSpeakerGroupSection(
                                      title: 'Subwoofer',
                                      allGroup: allSubwoofer,
                                      placedGroup: placedSubwoofer,
                                      nonPlacedGroup: nonPlacedSubwoofer,
                                    ),
                                  ] else
                                    buildSpeakerGroupSection(
                                      title: 'Full Range',
                                      allGroup: allMidHigh,
                                      placedGroup: placedMidHigh,
                                      nonPlacedGroup: nonPlacedMidHigh,
                                    ),
                                ],

                                const SizedBox(height: 20),

                                Row(
                                  spacing: 4,
                                  children: <Widget>[
                                    Expanded(
                                      child: FusionAppText(
                                        text: "Auto-Placement",
                                        style: context.textTheme.bodySmall,
                                      ),
                                    ),
                                    if (listeningArea.autoPlacement)
                                      PopupMenuButton<String>(
                                        color: Colors.transparent,
                                        shadowColor: Colors.transparent,
                                        tooltip: 'Auto-place speaker settings',
                                        padding: EdgeInsets.zero,
                                        menuPadding: EdgeInsets.zero,
                                        clipBehavior: Clip.none,
                                        offset: const Offset(90, 0),
                                        constraints: const BoxConstraints(minWidth: 1000),
                                        child: SemanticHelper.button(
                                          testId: SemanticHelper.createTestId(SemanticTypes.button, 'auto_place_speaker_settings_button'),
                                          child: FusionFlatContainer(
                                            padding: const EdgeInsets.all(3),
                                            borderRadius: 4,
                                            child: Icon(
                                              LucideIcons.pencil200,
                                              size: 12,
                                              color: context.colorScheme.iconDefault,
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
                                                child: AutoPlaceDialog(
                                                  result: listeningArea.autoPlacementResult,
                                                ),
                                              ),
                                            ),
                                          ];
                                        },
                                      ),

                                    FusionSwitch(
                                      value: listeningArea.autoPlacement,
                                      height: 24,
                                      width: 40,
                                      onChanged: (bool value) {
                                        if (value) {
                                          final BuildingPageViewModel buildingPageViewModel = context.read<BuildingPageViewModel>();
                                          buildingPageViewModel.setShouldPlaceNonPlacedSpeakers(false);
                                        }
                                        final ListeningArea updatedLA = listeningArea.copyWith(autoPlacement: value);
                                        projectViewModel.updateListeningArea(area: updatedLA);
                                      },
                                    ),
                                  ],
                                ),
                              ],
                            ),
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
