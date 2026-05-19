import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration/presentation/viewmodel/project_view_model.dart';
import 'package:fusion_launcher/features/speaker_selection_popup/viewmodel/product_query_view_model.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/product_data/models/models.dart';
import 'package:lucide_icons_flutter/lucide_icons.dart';

import '../../../../core/service_locator.dart';
import '../../../projects/viewmodel/building_page_viewmodel.dart';
import '../../../speaker_selection/views/speaker_selection_popup.dart';
import 'auto_place_dialog.dart';

class SpeakerSelectionWidget extends StatefulWidget {
  const SpeakerSelectionWidget({super.key});

  @override
  State<SpeakerSelectionWidget> createState() => _SpeakerSelectionWidgetState();
}

class _SpeakerSelectionWidgetState extends State<SpeakerSelectionWidget> {
  final GlobalKey<PopupMenuButtonState<String>> _autoPlacementSettingsKey = GlobalKey<PopupMenuButtonState<String>>();

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
                      padding: const EdgeInsets.all(8),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        crossAxisAlignment: CrossAxisAlignment.center,
                        children: <Widget>[
                          FusionAppText(
                            text: "SPEAKERS",
                            style: context.textTheme.l1Medium.copyWith(
                              color: context.colorScheme.textBody,
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

                              return GestureDetector(
                                onTap: () {
                                  SpeakerSelectionPopup.show(
                                    context: context,
                                    isFromBuildingPage: true,
                                    // zoneId: areaId,
                                    // subZoneId: null,
                                  );
                                },
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
                          final SpeakerProduct? product = pq.speakers.where((SpeakerProduct s) => s.productId == productId).firstOrNull;
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

                        return Flexible(
                          child: SingleChildScrollView(
                            padding: const EdgeInsets.symmetric(horizontal: 8.0),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: <Widget>[
                                // if (_isExpanded) ...<Widget>[
                                if (hasSubwooferSpeakerInLA) ...<Widget>[
                                  buildSpeakerGroupSection(
                                    title: 'Mid-High',
                                    allGroup: allMidHigh,
                                    placedGroup: placedMidHigh,
                                    nonPlacedGroup: nonPlacedMidHigh,
                                    isSpeakerPlacementMode: isSpeakerPlacementMode,
                                    listeningArea: listeningArea,
                                    hasSubwooferSpeakerInLA: hasSubwooferSpeakerInLA,
                                  ),
                                  const SizedBox(height: 10),
                                  buildSpeakerGroupSection(
                                    title: 'Subwoofer',
                                    allGroup: allSubwoofer,
                                    placedGroup: placedSubwoofer,
                                    nonPlacedGroup: nonPlacedSubwoofer,
                                    isSpeakerPlacementMode: isSpeakerPlacementMode,
                                    listeningArea: listeningArea,
                                    hasSubwooferSpeakerInLA: hasSubwooferSpeakerInLA,
                                  ),
                                ] else
                                  buildSpeakerGroupSection(
                                    title: 'Full Range',
                                    allGroup: allMidHigh,
                                    placedGroup: placedMidHigh,
                                    nonPlacedGroup: nonPlacedMidHigh,
                                    isSpeakerPlacementMode: isSpeakerPlacementMode,
                                    listeningArea: listeningArea,
                                    hasSubwooferSpeakerInLA: hasSubwooferSpeakerInLA,
                                  ),

                                // ],
                                const SizedBox(height: 20),

                                Row(
                                  spacing: 4,
                                  children: <Widget>[
                                    Expanded(
                                      child: FusionAppText(
                                        text: "Auto-Placement",
                                        style: context.textTheme.bodySmall?.copyWith(color: context.colorScheme.textBody),
                                      ),
                                    ),
                                    if (listeningArea.autoPlacement)
                                      PopupMenuButton<String>(
                                        key: _autoPlacementSettingsKey,
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
                                        } else {
                                          // Auto-placement disabled: clear currently placed speakers.
                                          final List<Speaker> placedSpeakers = projectViewModel.getPlacedSpeakersForCurrentListeningArea();
                                          for (final Speaker speaker in placedSpeakers) {
                                            projectViewModel.removeHardware(hardwareId: speaker.id);
                                          }
                                        }
                                        final ListeningArea updatedLA = listeningArea.copyWith(autoPlacement: value);
                                        projectViewModel.updateListeningArea(area: updatedLA);

                                        // Auto open the auto-placement settings dialog when toggled on.
                                        if (value) {
                                          // Wait for the widget to rebuild with the new state before opening the menu
                                          WidgetsBinding.instance.addPostFrameCallback((_) {
                                            _autoPlacementSettingsKey.currentState?.showButtonMenu();
                                          });
                                        }
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

  Widget buildSpeakerGroupSection({
    required String title,
    required List<Speaker> allGroup,
    required List<Speaker> placedGroup,
    required List<Speaker> nonPlacedGroup,
    required bool hasSubwooferSpeakerInLA,
    required ListeningArea listeningArea,
    required bool isSpeakerPlacementMode,
  }) {
    final Speaker? representative = allGroup.firstOrNull;
    final bool canPlace = nonPlacedGroup.isNotEmpty;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        // if (hasSubwooferSpeakerInLA)
        Padding(
          padding: const EdgeInsets.only(bottom: 6),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: title,
                  style: context.textTheme.l2Regular.copyWith(
                    color: context.colorScheme.textBody,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              SemanticHelper.button(
                testId: SemanticHelper.createTestId(
                  SemanticTypes.button,
                  'edit_speaker_button_${title.toLowerCase().replaceAll(' ', '_')}',
                ),
                child: GestureDetector(
                  onTap: () {
                    SpeakerSelectionPopup.show(
                      context: context,
                      isFromBuildingPage: true,
                    );
                  },
                  child: Padding(
                    padding: const EdgeInsets.all(3.0),
                    child: Icon(
                      LucideIcons.pencil200,
                      size: 12,
                      color: context.colorScheme.onSurface,
                    ),
                  ),
                ),
              ),
            ],
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
                  child: FusionImageAuto(
                    path: serviceLocator<ProductQueryViewModel>().getSpeakerImage(representative.productId) ?? "",
                    height: 24,
                    width: 24,
                    fit: BoxFit.contain,
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
                    style: context.textTheme.l2Medium.copyWith(
                      color: context.colorScheme.textBody,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _IncrementDecrementButton(
                  value: '${placedGroup.length}',
                  valueSemanticId: "placed_speakers_value",
                  incrementSemanticId: 'add_one_more_placed_speaker_to_non_placed_$title',
                  onIncrement:
                      (nonPlacedGroup.isEmpty && !listeningArea.autoPlacement)
                          ? () {
                            final ProjectViewModel pvm = context.read<ProjectViewModel>();
                            final Speaker clonedSpeaker = placedGroup.last.getClone();
                            clonedSpeaker.pos = null;
                            pvm.addHardware(hardware: clonedSpeaker);
                          }
                          : null,
                ),
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
                    style: context.textTheme.l2Medium.copyWith(
                      color: context.colorScheme.textBody,
                    ),
                  ),
                ),

                _IncrementDecrementButton(
                  value: nonPlacedGroup.length.toString(),
                  valueSemanticId: 'non_placed_speaker_quantity',
                  decrementSemanticId: 'decrease_non_placed_speaker_quantity_button_${title.toLowerCase().replaceAll(' ', '_')}',
                  onDecrement:
                      nonPlacedGroup.isEmpty
                          ? null
                          : () {
                            final ProjectViewModel pvm = context.read<ProjectViewModel>();
                            pvm.removeHardware(hardwareId: nonPlacedGroup.last.id);
                          },
                  incrementSemanticId: 'increase_non_placed_speaker_quantity_button_${title.toLowerCase().replaceAll(' ', '_')}',
                  onIncrement:
                      listeningArea.autoPlacement
                          ? null
                          : () {
                            final ProjectViewModel pvm = context.read<ProjectViewModel>();
                            final Speaker clonedSpeaker = nonPlacedGroup.last.getClone();
                            clonedSpeaker.pos = null;
                            pvm.addHardware(hardware: clonedSpeaker);
                          },
                ),

                if (canPlace && !listeningArea.autoPlacement) ...<Widget>[
                  const SizedBox(width: 8),
                  InkWell(
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
                ],
              ],
            ),
          ),
        ],
      ],
    );
  }
}

class _IncrementDecrementButton extends StatelessWidget {
  const _IncrementDecrementButton({
    super.key,
    this.onIncrement,
    this.incrementSemanticId,
    this.onDecrement,
    this.decrementSemanticId,
    required this.value,
    this.valueSemanticId,
  });
  final VoidCallback? onIncrement;
  final VoidCallback? onDecrement;

  final String? incrementSemanticId;
  final String? decrementSemanticId;
  final String? valueSemanticId;
  final String value;
  @override
  Widget build(BuildContext context) {
    return Row(
      children: <Widget>[
        if (onDecrement != null)
          InkWell(
            onTap: onDecrement,
            child: FusionContainer(
              raised: true,
              padding: const EdgeInsets.all(4),
              borderRadius: 4,
              child: SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, decrementSemanticId ?? ""),
                child: const Icon(
                  LucideIcons.minus200,
                  size: 12,
                ),
              ),
            ),
          ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
          child: SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, valueSemanticId ?? ""),
            child: FusionAppText(
              text: value,
              style: context.textTheme.l1Medium,
            ),
          ),
        ),
        if (onIncrement != null)
          InkWell(
            onTap: onIncrement,
            child: FusionContainer(
              raised: true,
              padding: const EdgeInsets.all(4),
              borderRadius: 4,
              child: SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, incrementSemanticId ?? ""),
                child: const Icon(
                  LucideIcons.plus200,
                  size: 12,
                ),
              ),
            ),
          ),
      ],
    );
  }
}
