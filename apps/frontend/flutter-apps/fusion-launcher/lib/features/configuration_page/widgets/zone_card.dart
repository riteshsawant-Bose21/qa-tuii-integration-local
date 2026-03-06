import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/sub_zone_card.dart';
import 'package:fusion_launcher/features/zone_functions/source_select.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/constants/assets_constants.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart' show SelectedItemType;
import '../viewModel/source_sets_viewmodel/config_source_sets_viewmodel.dart';
import '../viewModel/sources_viewmodel/config_sources_viewmodel.dart';
import '../viewModel/zones_viewmodel/config_zones_state.dart';
import '../viewModel/zones_viewmodel/config_zones_viewmodel.dart';
import '../../processing_block/view/processing_chain_view.dart';
import '../../zone_functions/source_matrix.dart';
import '../../zone_functions/source_mix.dart';

class ZoneCard extends StatefulWidget {
  final String zoneId;
  final String zoneName;
  final Color bgColor;
  final Zone zoneData;
  final Function(bool)? onExpansionChanged;

  const ZoneCard({
    super.key,
    required this.zoneId,
    required this.zoneName,
    required this.bgColor,
    required this.zoneData,
    this.onExpansionChanged,
  });

  @override
  State<ZoneCard> createState() => _ZoneCardState();
}

class _ZoneCardState extends State<ZoneCard> {
  late ValueNotifier<bool> _isZoneExpanded;
  bool isHovered = false;

  ZoneFunctionsType? selectedFunction;
  bool get _hasSelectedFunction => selectedFunction != null;

  List<String> selectedZoneSourceIds = <String>[];
  List<String> selectedZoneSourceSetIds = <String>[];
  int? _hoveredCircuitIndex;

  // Cubit getters
  ConfigZonesViewmodel get _zonesViewmodel => context.read<ConfigZonesViewmodel>();
  ConfigSourcesViewmodel get _sourcesViewmodel => context.read<ConfigSourcesViewmodel>();
  ConfigSourceSetsViewmodel get _sourceSetsViewmodel => context.read<ConfigSourceSetsViewmodel>();

  @override
  void initState() {
    super.initState();
    _isZoneExpanded = ValueNotifier<bool>(true);
  }

  @override
  void dispose() {
    _isZoneExpanded.dispose();
    super.dispose();
  }

  /// Default proxy decorator for reorderable list view
  Widget _defaultProxyDecorator(Widget child, int index, Animation<double> animation) {
    return FadeTransition(
      opacity: animation.drive(Tween<double>(begin: 0.95, end: 1.0)),
      child: Material(
        color: Colors.transparent,
        child: child,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedSize(
      duration: const Duration(milliseconds: 250),
      alignment: AlignmentGeometry.topCenter,
      child: ValueListenableBuilder<bool>(
        valueListenable: _isZoneExpanded,
        builder: (BuildContext context, bool zoneExpanded, Widget? child) {
          return BlocBuilder<ConfigZonesViewmodel, ConfigZonesState>(
            builder: (BuildContext context, ConfigZonesState state) {
              return Column(
                children: <Widget>[
                  MouseRegion(
                    onEnter: (_) => setState(() => isHovered = true),
                    onExit: (_) => setState(() => isHovered = false),
                    child: _buildZoneHeader(
                      context: context,
                      expanded: zoneExpanded,
                      isHovered: isHovered,
                      isSelected: false,
                    ),
                  ),

                  /// Zone Content - shows subzones when expanded
                  if (zoneExpanded) _buildZoneContent(),
                ],
              );
            },
          );
        },
      ),
    );
  }

  /// Zone header - always visible
  Widget _buildZoneHeader({required BuildContext context, required bool expanded, required bool isHovered, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        final bool newExpandedState = !_isZoneExpanded.value;
        _isZoneExpanded.value = newExpandedState;

        /// Trigger the expansion callback
        widget.onExpansionChanged?.call(newExpandedState);

        /// Select zone on tap
        _zonesViewmodel.setSelectedDevice(widget.zoneId, SelectedItemType.zone);
      },
      child: Container(
        margin: const EdgeInsets.only(top: 6, right: 8, left: 8),
        padding: const EdgeInsets.only(left: 14, right: 14),
        height: 32,
        decoration: BoxDecoration(
          color: isHovered ? widget.bgColor.withAlpha(80) : widget.bgColor.withAlpha(100),
          border: Border.all(
            color: isSelected ? context.colorScheme.strokeLight : Colors.transparent,
          ),
          borderRadius: BorderRadius.circular(6),
        ),
        child: Row(
          children: <Widget>[
            /// Expand/collapse icon
            Icon(
              expanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              color: Theme.of(context).colorScheme.primaryWhite,
            ),
            const SizedBox(width: 4),

            /// Zone name
            Expanded(
              child: FusionAppText(
                text: widget.zoneName,
                maxLine: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
            InkWell(
              onTap: () {
                ProcessingChainView.showForZone(context, widget.zoneData);
              },
              child: const FusionImage.asset(
                Assets.processingBlocksFilledWhiteIcon,
                width: 24,
                height: 24,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Zone content
  Widget _buildZoneContent() {
    return LayoutBuilder(
      builder: (BuildContext context, BoxConstraints constraints) {
        return BlocBuilder<ConfigZonesViewmodel, ConfigZonesState>(
          builder: (BuildContext context, ConfigZonesState state) {
            final List<SubZone> subZonesForZone = _zonesViewmodel.getSubZonesForZone(parentZoneId: widget.zoneId);
            final int subZoneCount = subZonesForZone.length;
            final double calculatedHeight = subZoneCount * 100.0;
            final double constrainedHeight = calculatedHeight.clamp(200.0, 400.0);

            return Container(
              height: constrainedHeight,
              margin: const EdgeInsets.symmetric(horizontal: 12),
              color: context.colorScheme.elevation2.withAlpha(100),

              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  /// Functions Panel
                  Container(
                    width: constraints.maxWidth * 0.34,
                    height: constrainedHeight,

                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      border: Border(
                        bottom: BorderSide(color: context.colorScheme.elevation2),
                      ),
                    ),
                    child: _buildZoneFunctionsPanel(),
                  ),

                  /// Full height divider
                  Container(
                    width: 1,
                    height: constrainedHeight,
                    color: context.colorScheme.elevation2,
                  ),

                  /// Subzone Panel
                  Expanded(
                    child: SizedBox(
                      height: constrainedHeight,
                      child: _buildSubZonePanel(subZonesForZone),
                    ),
                  ),
                ],
              ),
            );
          },
        );
      },
    );
  }

  /// Zone functions panel
  Widget _buildZoneFunctionsPanel() {
    /// Sync with model if underlying zone function changed externally
    final ZoneFunctions? existingFunction = _zonesViewmodel.getZoneFunctionForZone(zoneId: widget.zoneId);
    if (existingFunction != null && selectedFunction != existingFunction.type) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          setState(() {
            selectedFunction = existingFunction.type;
          });
        }
      });
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: <Widget>[
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FusionAppText(
              text: 'FUNCTIONS',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 10,
                fontWeight: FontWeight.w600,
              ),
            ),

            if (_hasSelectedFunction) buildAddFunctionButton(isEdit: true),
          ],
        ),
        const SizedBox(height: 12),
        buildFunctionWidget(),

        const Spacer(),

        _buildReorderablePriorityWidgets(),
        const SizedBox(height: 8),
        buildSourceSelectionForZone(),
      ],
    );
  }

  /// Build reorderable priority function widgets
  Widget _buildReorderablePriorityWidgets() {
    final ZoneFunctions? existingFunction = _zonesViewmodel.getZoneFunctionForZone(zoneId: widget.zoneId);

    if (!(existingFunction?.hasPriority ?? false)) {
      return const SizedBox.shrink();
    }

    return SizedBox(
      height: 60,
      child: Material(
        color: Colors.transparent,
        child: ReorderableListView.builder(
          proxyDecorator: _defaultProxyDecorator,
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          buildDefaultDragHandles: false,
          itemCount: 2,
          onReorder: (int oldIndex, int newIndex) {
            if (oldIndex < newIndex) newIndex -= 1;

            /// Handle the reordering logic - swap sources using reOrderPrioritySourcesInZone
            if (oldIndex != newIndex) {
              /// Get current source IDs directly from view model
              final List<String> prioritySources = _zonesViewmodel.getPrioritySourcesInZone(zoneId: widget.zoneId);
              final String? source1 = prioritySources.isNotEmpty ? prioritySources[0] : null;
              final String? source2 = prioritySources.length > 1 ? prioritySources[1] : null;

              /// Create new order list with swapped sources
              final List<String> newOrder = <String>[];
              if (oldIndex == 0 && newIndex == 1) {
                /// P1 moved to P2 position
                newOrder.add(source2 ?? '');
                newOrder.add(source1 ?? '');
              } else if (oldIndex == 1 && newIndex == 0) {
                /// P2 moved to P1 position
                newOrder.add(source2 ?? '');
                newOrder.add(source1 ?? '');
              }

              /// Use the new reOrderPrioritySourcesInZone method
              _zonesViewmodel.reOrderPrioritySourcesInZone(
                zoneId: widget.zoneId,
                newOrder: newOrder,
              );
            }
          },
          itemBuilder: (BuildContext context, int index) {
            final int priorityIndex = index + 1;
            return ReorderableDragStartListener(
              key: ValueKey<String>('priority_widget_$index'),
              index: index,
              child: Padding(
                padding: const EdgeInsets.only(bottom: 8.0),
                child: buildPriorityFunctionWidget(priorityIndex: priorityIndex),
              ),
            );
          },
        ),
      ),
    );
  }

  /// Function selection widget
  Widget buildFunctionWidget() {
    return _hasSelectedFunction ? buildSelectedFunctionButton() : buildAddFunctionButton();
  }

  /// Priority Override function button (Popup Menu) - supports independent P1 / P2
  Widget buildPriorityFunctionWidget({required int priorityIndex}) {
    String? selectedSourceId;
    String? selectedSource;
    final List<String> prioritySources = _zonesViewmodel.getPrioritySourcesInZone(zoneId: widget.zoneId);

    /// priority 1
    if (priorityIndex == 1) {
      if (prioritySources.isNotEmpty && prioritySources[0].isNotEmpty) {
        final HardwareComponent? sourceData = _zonesViewmodel.getHardware(hardwareId: prioritySources[0]);
        if (sourceData != null) {
          selectedSource = sourceData.name;
          selectedSourceId = prioritySources[0];
        }
      }
    } else {
      /// priority 2
      if (prioritySources.length > 1 && prioritySources[1].isNotEmpty) {
        final HardwareComponent? sourceData = _zonesViewmodel.getHardware(hardwareId: prioritySources[1]);
        if (sourceData != null) {
          selectedSource = sourceData.name;
          selectedSourceId = prioritySources[1];
        }
      }
    }

    final ZoneFunctions? existingFunction = _zonesViewmodel.getZoneFunctionForZone(zoneId: widget.zoneId);

    return Visibility(
      visible: existingFunction?.hasPriority ?? false,
      child: Row(
        children: <Widget>[
          /// Priority Source Selection
          DragTarget<Source>(
            onWillAcceptWithDetails: (DragTargetDetails<Source> details) {
              final String incomingId = details.data.id;

              /// Reject if already selected for this slot
              if (priorityIndex == 1 && incomingId == selectedSourceId) return false;
              if (priorityIndex == 2 && incomingId == selectedSourceId) return false;

              /// incomingId should not be in both the priority slots
              if (prioritySources.contains(incomingId)) return false;

              return true;
            },
            onLeave: (Source? data) {},
            onAcceptWithDetails: (DragTargetDetails<Source> details) {
              final Source source = details.data;
              final String sourceId = source.id;
              setState(() {
                /// Remove from regular source selection if it's currently selected
                _zonesViewmodel.removeSourceFromZone(zoneId: widget.zoneId, sourceId: sourceId);

                /// Add to priority
                _zonesViewmodel.addPrioritySourceToZone(
                  zoneId: widget.zoneId,
                  sourceId: sourceId,
                  priority: priorityIndex,
                );
              });
            },
            builder: (BuildContext context, List<Source?> candidateData, List<dynamic> rejectedData) {
              final bool canAccept = candidateData.isNotEmpty;
              final bool cannotAccept = rejectedData.isNotEmpty;
              return Theme(
                data: Theme.of(context).copyWith(
                  tooltipTheme: TooltipThemeData(
                    decoration: BoxDecoration(
                      color: context.colorScheme.primaryBlack,
                      borderRadius: BorderRadius.circular(6),
                    ),
                    textStyle: context.textTheme.bodySmall,
                  ),
                ),
                child: PopupMenuButton<String>(
                  onSelected: (String value) {
                    setState(() {
                      /// Remove from regular source selection if it's currently selected
                      _zonesViewmodel.removeSourceFromZone(zoneId: widget.zoneId, sourceId: value);

                      /// Add to priority
                      _zonesViewmodel.addPrioritySourceToZone(
                        zoneId: widget.zoneId,
                        sourceId: value,
                        priority: priorityIndex,
                      );
                    });
                  },
                  offset: const Offset(0, 25),
                  tooltip: "Select Priority Source P$priorityIndex",
                  color: context.colorScheme.elevation1,

                  padding: EdgeInsets.zero,
                  itemBuilder: (BuildContext context) {
                    final List<PopupMenuEntry<String>> entries = <PopupMenuEntry<String>>[];

                    /// Header: Sources
                    entries.add(
                      PopupMenuItem<String>(
                        enabled: false,
                        height: 20,
                        child: FusionAppText(
                          text: 'SOURCES',
                          maxLine: 1,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                            color: context.colorScheme.textPrimary,
                          ),
                        ),
                      ),
                    );

                    /// Individual sources
                    final List<Source> availableSources = _sourcesViewmodel.state.sources;
                    if (availableSources.isEmpty) {
                      entries.add(
                        PopupMenuItem<String>(
                          enabled: false,
                          height: 20,
                          child: Center(
                            child: FusionAppText(
                              text: 'No available sources',
                              maxLine: 1,
                              style: context.textTheme.bodyMedium?.copyWith(
                                fontSize: 10,
                                color: context.colorScheme.textPrimary,
                              ),
                            ),
                          ),
                        ),
                      );
                    } else {
                      for (final Source src in availableSources) {
                        final String value = src.id;
                        final String assetPath = src.assetImagePath;
                        final bool isAlreadyInPriority = prioritySources.contains(value);
                        final bool isCurrentSelection = selectedSourceId == value;

                        entries.add(
                          PopupMenuItem<String>(
                            value: isAlreadyInPriority && !isCurrentSelection ? null : value,
                            enabled: !isAlreadyInPriority || isCurrentSelection,
                            height: 20,
                            child: Opacity(
                              opacity: isAlreadyInPriority && !isCurrentSelection ? 0.9 : 1.0,
                              child: Row(
                                children: <Widget>[
                                  Transform.scale(
                                    scale: 0.7,
                                    child: Radio<String>(
                                      value: value,
                                      groupValue: isAlreadyInPriority && !isCurrentSelection ? value : selectedSourceId,
                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                      activeColor: context.colorScheme.primaryWhite,
                                      onChanged:
                                          isAlreadyInPriority && !isCurrentSelection
                                              ? null
                                              : (String? v) {
                                                if (v != null) Navigator.pop(context, v);
                                              },
                                    ),
                                  ),

                                  FusionImage.asset(
                                    assetPath,
                                    width: 14,
                                    height: 14,
                                    fit: BoxFit.contain,
                                  ),
                                  const SizedBox(width: 4),
                                  Expanded(
                                    child: FusionAppText(
                                      text: isAlreadyInPriority && !isCurrentSelection ? '${src.name} (already selected)' : src.name,
                                      capitalize: true,
                                      maxLine: 1,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 10,
                                        color: isAlreadyInPriority && !isCurrentSelection ? context.colorScheme.elevation5 : context.colorScheme.primaryWhite,
                                      ),
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        );
                      }
                    }

                    // todo : source sets priority selection disabled for now according to robs feedback
                    /*/// Divider
                    entries.add(const PopupMenuDivider(height: 4));

                    /// Header: Source Sets
                    entries.add(
                      PopupMenuItem<String>(
                        enabled: false,
                        height: 20,
                        child: FusionAppText(
                          text: 'SOURCE SETS',
                          maxLine: 1,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontSize: 10,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    );

                    /// Source sets with their sources
                    final List<SourceSet> allSourceSets = _sourceSetsViewmodel.getAllSourceSets();
                    if (allSourceSets.isEmpty) {
                      entries.add(
                        PopupMenuItem<String>(
                          enabled: false,
                          height: 20,
                          child: Center(
                            child: FusionAppText(
                              text: 'No available source sets',
                              maxLine: 1,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                            ),
                          ),
                        ),
                      );
                    } else
                    {
                      for (final SourceSet sourceSet in allSourceSets) {
                        final List<Source> sources = _sourceSetsViewmodel.getSourcesInSourceSet(sourceSetId: sourceSet.id);
                        for (final Source src in sources) {
                          final String name = '${src.name} (${sourceSet.name})';
                          final String value = src.id;
                          final String assetPath = src.assetImagePath;
                          final bool isAlreadyInPriority = prioritySources.contains(value);
                          final bool isCurrentSelection = selectedSourceId == value;

                          entries.add(
                            PopupMenuItem<String>(
                              value: isAlreadyInPriority && !isCurrentSelection ? null : value,
                              enabled: !isAlreadyInPriority || isCurrentSelection,
                              height: 20,
                              child: Opacity(
                                opacity: isAlreadyInPriority && !isCurrentSelection ? 0.9 : 1.0,
                                child: Row(
                                  children: <Widget>[
                                    Transform.scale(
                                      scale: 0.7,
                                      child: Radio<String>(
                                        value: value,
                                        groupValue: isAlreadyInPriority && !isCurrentSelection ? value : selectedSourceId,
                                        materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                        visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                        activeColor: context.colorScheme.primaryBlack,
                                        onChanged:
                                            isAlreadyInPriority && !isCurrentSelection
                                                ? null
                                                : (String? v) {
                                                  if (v != null) Navigator.pop(context, v);
                                                },
                                      ),
                                    ),

                                    FusionImage.asset(
                                      assetPath,
                                      width: 14,
                                      height: 14,
                                      fit: BoxFit.contain,
                                    ),
                                    const SizedBox(width: 4),

                                    Expanded(
                                      child: FusionAppText(
                                        text: isAlreadyInPriority && !isCurrentSelection ? '$name (already selected)' : name,
                                        capitalize: true,
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                          fontSize: 10,
                                          color: isAlreadyInPriority && !isCurrentSelection ? context.colorScheme.primaryBlack.withAlpha(150) : null,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ),
                          );
                        }
                      }
                    }*/

                    return entries;
                  },
                  child: Container(
                    height: 22,
                    width: 170,
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color:
                          cannotAccept
                              ? context.colorScheme.errorFill
                              : canAccept
                              ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                              : null,
                      border: Border.all(
                        color:
                            cannotAccept
                                ? context.colorScheme.errorStroke
                                : canAccept
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.3)
                                : selectedSource == null
                                ? context.colorScheme.elevation5.withAlpha(150)
                                : context.colorScheme.elevation5,
                      ),
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      mainAxisAlignment: MainAxisAlignment.start,
                      children: <Widget>[
                        Expanded(
                          child: FusionAppText(
                            text: selectedSource ?? 'Select priority',
                            maxLine: 1,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              color: selectedSource == null ? context.colorScheme.primaryWhite.withAlpha(150) : context.colorScheme.primaryWhite,
                            ),
                          ),
                        ),
                        const SizedBox(width: 4),
                        Container(
                          width: 14,
                          height: 14,

                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: selectedSource == null ? context.colorScheme.primaryWhite.withAlpha(150) : context.colorScheme.primaryWhite,
                            borderRadius: BorderRadius.circular(3),
                          ),
                          child: FusionAppText(
                            text: 'P$priorityIndex',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 8,
                              color: context.colorScheme.primaryBlack,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          const SizedBox(width: 8),

          /// Delete priority source button (now active)
          if (selectedSourceId != null)
            GestureDetector(
              onTap: () {
                /// Remove priority source from zone using the actual ID from view model
                _zonesViewmodel.removePrioritySourceFromZone(
                  zoneId: widget.zoneId,
                  sourceId: selectedSourceId!,
                );
                setState(() {});
              },
              child: FusionImage.asset(
                Assets.deleteIcon,
                width: 17,
                height: 17,
                assetColor: context.colorScheme.primaryWhite,
                fit: BoxFit.contain,
              ),
            ),
        ],
      ),
    );
  }

  /// Add Function button (Popup Menu)
  Widget buildAddFunctionButton({bool isEdit = false}) {
    return PopupMenuButton<ZoneFunctionsType>(
      shadowColor: Colors.transparent,
      position: PopupMenuPosition.under,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(9),
        side: BorderSide(
          color: context.colorScheme.strokeLight,
        ),
      ),
      padding: EdgeInsets.zero,
      menuPadding: EdgeInsets.zero,
      clipBehavior: Clip.none,
      onSelected: (ZoneFunctionsType value) {
        setState(() => selectedFunction = value);
        _zonesViewmodel.addFunctionToZone(
          zoneId: widget.zoneId,
          function: getNewZoneFunction(type: value),
        );
      },
      offset: const Offset(0, 10),
      tooltip: isEdit ? "Edit Function" : "Add Function",
      color: context.colorScheme.elevation1,
      itemBuilder: (BuildContext context) {
        return ZoneFunctionsType.values.map((ZoneFunctionsType function) {
          return PopupMenuItem<ZoneFunctionsType>(
            height: 32,
            value: function,
            child: SizedBox(
              width: 169,
              child: FusionAppText(
                text: function.displayName,
                maxLine: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 10,
                ),
              ),
            ),
          );
        }).toList();
      },
      child:
          isEdit
              ? Icon(Icons.edit, size: 14, color: context.colorScheme.textPrimary)
              : Container(
                height: 22,
                width: 170,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: context.colorScheme.elevation5,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.add, color: context.colorScheme.iconWhite, size: 12),
                    const SizedBox(width: 4),
                    FusionAppText(
                      text: 'Add Function',
                      maxLine: 1,
                      style: context.textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
                      ),
                    ),
                  ],
                ),
              ),
    );
  }

  /// Selected Function button
  Widget buildSelectedFunctionButton() {
    return GestureDetector(
      onTap: () {
        if (selectedFunction == ZoneFunctionsType.sourceSelect || selectedFunction == ZoneFunctionsType.sourceSelectWithPriority) {
          SourceSelectZoneControlPanel.showDialog(
            context,
            zoneID: widget.zoneId,
          );
        } else if (selectedFunction == ZoneFunctionsType.sourceMix || selectedFunction == ZoneFunctionsType.sourceMixWithPriority) {
          SourceMixZoneControlPanel.showDialog(
            context,
            zoneID: widget.zoneId,
          );
        } else if (selectedFunction == ZoneFunctionsType.sourceMatrix || selectedFunction == ZoneFunctionsType.sourceMatrixWithPriority) {
          SourceMatrixZoneControlPanel.showDialog(
            context,
            zoneID: widget.zoneId,
          );
        }
      },
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),

        decoration: BoxDecoration(
          border: Border.all(
            color: context.colorScheme.elevation5,
          ),
          borderRadius: BorderRadius.circular(3),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: <Widget>[
            FusionAppText(
              text: selectedFunction?.displayName ?? '',
              maxLine: 1,
              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                fontSize: 11,
                fontWeight: FontWeight.w400,
              ),
            ),
            const SizedBox(width: 8),
            FusionImage.asset(
              Assets.configurationFilledIcon,
              width: 14,
              height: 14,
              fit: BoxFit.contain,
              assetColor: context.colorScheme.primaryWhite,
            ),
          ],
        ),
      ),
    );
  }

  /// Multi-select source selection for zone (checkboxes)
  Widget buildSourceSelectionForZone() {
    /// Get current selections from the zone
    final List<Source> currentZoneSources = _zonesViewmodel.getSourcesInZone(zoneId: widget.zoneId);
    final List<SourceSet> currentZoneSourceSets = _zonesViewmodel.getSourceSetsInZone(zoneId: widget.zoneId);

    final bool hasSelection = currentZoneSources.isNotEmpty || currentZoneSourceSets.isNotEmpty;

    final List<Source> availableSources = _sourcesViewmodel.state.sources;
    final List<SourceSet> sourceSetList = _sourceSetsViewmodel.getAllSourceSets();

    return Theme(
      data: Theme.of(context).copyWith(
        tooltipTheme: TooltipThemeData(
          decoration: BoxDecoration(
            color: context.colorScheme.primaryBlack,
            borderRadius: BorderRadius.circular(8),
          ),
          textStyle: context.textTheme.bodySmall,
        ),
      ),
      child: PopupMenuButton<String>(
        onSelected: (String? value) {
          if (value == 'add') {
            setState(() {});

            /// refresh zone tile UI
          }
        },
        offset: const Offset(0, 25),
        tooltip: "Select Sources",
        padding: EdgeInsets.zero,
        color: context.colorScheme.elevation1,
        itemBuilder: (BuildContext context) {
          /// Temporary selections mirror existing selections
          final List<String> tempSelectedSources = currentZoneSources.map((Source e) => e.id).toList();

          final List<String> tempSelectedSourceSets = currentZoneSourceSets.map((SourceSet e) => e.id).toList();

          /// Get priority sources to disable them in source list
          final List<String> prioritySources = _zonesViewmodel.getPrioritySourcesInZone(zoneId: widget.zoneId);

          final List<PopupMenuEntry<String>> entries = <PopupMenuEntry<String>>[];

          // ----------------------------------------------------------
          // SOURCES HEADER
          // ----------------------------------------------------------
          entries.add(
            PopupMenuItem<String>(
              enabled: false,
              height: 24,
              child: FusionAppText(
                text: 'SOURCES',
                maxLine: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );

          // ----------------------------------------------------------
          // SOURCES LIST
          // ----------------------------------------------------------
          if (availableSources.isEmpty) {
            entries.add(
              PopupMenuItem<String>(
                enabled: false,
                height: 20,
                child: Center(
                  child: FusionAppText(
                    text: 'No available sources',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                  ),
                ),
              ),
            );
          } else {
            for (final Source src in availableSources) {
              final String id = src.id;

              /// Check if this source is already a priority source
              final bool isPrioritySource = prioritySources.contains(id);

              entries.add(
                PopupMenuItem<String>(
                  enabled: false,
                  height: 20,
                  child: StatefulBuilder(
                    builder: (BuildContext c, StateSetter setPopupState) {
                      return GestureDetector(
                        onTap:
                            isPrioritySource
                                ? null
                                : () {
                                  if (tempSelectedSources.contains(id)) {
                                    tempSelectedSources.remove(id);
                                  } else {
                                    tempSelectedSources.add(id);
                                  }
                                  setPopupState(() {});
                                },
                        child: Row(
                          children: <Widget>[
                            Transform.scale(
                              scale: 0.7,
                              child: Checkbox(
                                value: tempSelectedSources.contains(id),
                                activeColor: isPrioritySource ? context.colorScheme.elevation5 : context.colorScheme.primaryBlack,
                                onChanged:
                                    isPrioritySource
                                        ? null
                                        : (bool? _) {
                                          if (tempSelectedSources.contains(id)) {
                                            tempSelectedSources.remove(id);
                                          } else {
                                            tempSelectedSources.add(id);
                                          }
                                          setPopupState(() {});
                                        },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                checkColor: context.colorScheme.primaryWhite,
                                side: BorderSide(
                                  width: 1,
                                  color: isPrioritySource ? context.colorScheme.elevation5 : context.colorScheme.primaryWhite,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Row(
                                children: <Widget>[
                                  Expanded(
                                    child: FusionAppText(
                                      text: src.name,
                                      capitalize: true,
                                      maxLine: 1,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 10,
                                        color: isPrioritySource ? context.colorScheme.elevation5 : null,
                                      ),
                                    ),
                                  ),
                                  if (isPrioritySource) const SizedBox(width: 4),
                                  if (isPrioritySource)
                                    FusionAppText(
                                      text: '(Priority source)',
                                      maxLine: 1,
                                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                        fontSize: 9,
                                        fontStyle: FontStyle.italic,
                                        color: context.colorScheme.elevation5,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          }

          entries.add(const PopupMenuDivider(height: 12));

          // ----------------------------------------------------------
          // SOURCE SETS HEADER
          // ----------------------------------------------------------
          entries.add(
            PopupMenuItem<String>(
              enabled: false,
              height: 24,
              child: FusionAppText(
                text: 'SOURCE SETS',
                maxLine: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          );

          // ----------------------------------------------------------
          // SOURCE SETS LIST
          // ----------------------------------------------------------
          if (sourceSetList.isEmpty) {
            entries.add(
              PopupMenuItem<String>(
                enabled: false,
                height: 20,
                child: Center(
                  child: FusionAppText(
                    text: 'No available source sets',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                  ),
                ),
              ),
            );
          } else {
            for (final SourceSet s in sourceSetList) {
              final String id = s.id;
              final List<Source> sourcesInSet = _sourceSetsViewmodel.getSourcesInSourceSet(sourceSetId: s.id);

              entries.add(
                PopupMenuItem<String>(
                  enabled: false,
                  height: 20,
                  child: StatefulBuilder(
                    builder: (BuildContext c, StateSetter setPopupState) {
                      return GestureDetector(
                        onTap: () {
                          if (tempSelectedSourceSets.contains(id)) {
                            tempSelectedSourceSets.remove(id);
                          } else {
                            tempSelectedSourceSets.add(id);
                          }
                          setPopupState(() {});
                        },
                        child: Row(
                          children: <Widget>[
                            Transform.scale(
                              scale: 0.7,
                              child: Checkbox(
                                value: tempSelectedSourceSets.contains(id),
                                activeColor: context.colorScheme.primaryBlack,
                                onChanged: (bool? _) {
                                  if (tempSelectedSourceSets.contains(id)) {
                                    tempSelectedSourceSets.remove(id);
                                  } else {
                                    tempSelectedSourceSets.add(id);
                                  }
                                  setPopupState(() {});
                                },
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                                checkColor: context.colorScheme.primaryWhite,
                                side: BorderSide(
                                  width: 1,
                                  color: context.colorScheme.primaryWhite,
                                ),
                              ),
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: FusionAppText(
                                text: '${s.name} (${sourcesInSet.length} sources)',
                                maxLine: 1,
                                capitalize: true,
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              );
            }
          }

          entries.add(
            const PopupMenuDivider(height: 14, color: Colors.transparent),
          );

          // ----------------------------------------------------------
          // ADD BUTTON – FINAL SAVE
          // ----------------------------------------------------------
          entries.add(
            PopupMenuItem<String>(
              enabled: true,
              height: 28,
              value: 'add',
              child: Center(
                child: FusionButton(
                  label: 'Add',
                  height: 28,
                  width: double.infinity,
                  onTap: () {
                    /// Save full final selected lists
                    _zonesViewmodel.updateSourcesInZone(
                      zoneId: widget.zoneId,
                      sourceIds: tempSelectedSources,
                    );

                    _zonesViewmodel.updateSourceSets(
                      zoneId: widget.zoneId,
                      sourceSetIds: tempSelectedSourceSets,
                    );

                    Navigator.pop(context, 'add');
                    setState(() {});

                    /// rebuild UI
                  },
                ),
              ),
            ),
          );

          return entries;
        },

        // ----------------------------------------------------------
        // BUTTON VIEW (with count)
        // ----------------------------------------------------------
        child: Container(
          height: 22,
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: hasSelection ? context.colorScheme.elevation5 : context.colorScheme.elevation5.withAlpha(150),
            ),
            borderRadius: BorderRadius.circular(3),
          ),
          child: Row(
            children: <Widget>[
              Expanded(
                child: FusionAppText(
                  text: hasSelection ? 'Sources selected' : 'Select sources',
                  maxLine: 1,
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 11,
                    color: hasSelection ? context.colorScheme.primaryWhite : context.colorScheme.primaryWhite.withAlpha(150),
                  ),
                ),
              ),
              hasSelection
                  ? IntrinsicWidth(
                    child: Container(
                      height: 14,
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: context.colorScheme.primaryWhite,
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: FusionAppText(
                        text: _zonesViewmodel.getSourceCountInZone(zoneId: widget.zoneId).toString(),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontSize: 8,
                          color: context.colorScheme.primaryBlack,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                  : Icon(Icons.add, color: context.colorScheme.primaryWhite.withAlpha(150), size: 16),
            ],
          ),
        ),
      ),
    );
  }

  /// Subzone panel (now scrollable)
  Widget _buildSubZonePanel(List<SubZone> subZonesForZone) {
    final List<CircuitModel> zoneCircuit = _zonesViewmodel.getCircuitsInZone(widget.zoneId);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: context.colorScheme.elevation2),
        ),
      ),
      child:
          /// circuit and subzone list
          (subZonesForZone.isEmpty && zoneCircuit.isEmpty)
              ? Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 50.0),
                  child: FusionAppText(
                    text: 'No sub zones / circuits added yet',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
              : SingleChildScrollView(
                physics: const ClampingScrollPhysics(),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: <Widget>[
                    /// if no subzones then show available circuits
                    if (zoneCircuit.isNotEmpty)
                      ListView.builder(
                        scrollDirection: Axis.vertical,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        itemCount: zoneCircuit.length,
                        itemBuilder: (BuildContext context, int index) {
                          final CircuitModel circuitData = zoneCircuit[index];
                          final List<Speaker> speakersList = _zonesViewmodel.getHardwareForCircuit(circuitId: circuitData.id).whereType<Speaker>().toList();
                          return MouseRegion(
                            onEnter: (_) => setState(() => _hoveredCircuitIndex = index),
                            onExit: (_) => setState(() => _hoveredCircuitIndex = null),
                            child: _buildCircuitCard(
                              index: index,
                              circuitData: circuitData,
                              speakersList: speakersList,
                            ),
                          );
                        },
                      ),

                    /// else show subzones in reorderable list
                    ReorderableListView.builder(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: subZonesForZone.length,
                      onReorder: (int oldIndex, int newIndex) {
                        if (oldIndex < newIndex) newIndex -= 1;
                        _zonesViewmodel.reOrderSubZoneInZone(
                          parentId: widget.zoneId,
                          oldIndex: oldIndex,
                          newIndex: newIndex,
                        );
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final SubZone subZone = subZonesForZone[index];
                        return ReorderableDragStartListener(
                          key: ValueKey<String>(subZone.id),
                          index: index,
                          child: SubZoneCard(
                            subZoneId: subZone.id,
                            subZoneName: subZone.name,
                            subZoneData: subZone,
                            onExpansionChanged: (bool isExpanded) {
                              if (isExpanded) {
                                /// Trigger the zone's expansion callback to scroll the zone into view
                                /// when a subzone expands
                                widget.onExpansionChanged?.call(true);
                              }
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ),
    );
  }

  /// Circuit card widget
  Widget _buildCircuitCard({required int index, required CircuitModel circuitData, required List<Speaker> speakersList}) {
    final bool isThisCircuitHovered = _hoveredCircuitIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: isThisCircuitHovered ? context.colorScheme.elevation2 : null,
        borderRadius: BorderRadius.circular(8),
      ),
      padding: const EdgeInsets.only(top: 4, bottom: 4, left: 10, right: 13),
      margin: const EdgeInsets.only(bottom: 4, top: 4, left: 10),
      child: Row(
        children: <Widget>[
          FusionImage.asset(
            speakersList.isNotEmpty ? speakersList.first.assetImagePath : "",
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
          const SizedBox(width: 6),
          Expanded(
            child: FusionAppText(
              text: circuitData.name,
              maxLine: 1,
              style: Theme.of(context).textTheme.bodySmall?.copyWith(fontSize: 11),
            ),
          ),
          InkWell(
            onTap: () {
              ProcessingChainView.showForCircuit(context, circuitData);
            },
            child: FusionImage.asset(
              Assets.processingBlocksFilledIcon,
              width: 24,
              height: 24,
              assetColor: context.colorScheme.primaryWhite,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
    );
  }
}
