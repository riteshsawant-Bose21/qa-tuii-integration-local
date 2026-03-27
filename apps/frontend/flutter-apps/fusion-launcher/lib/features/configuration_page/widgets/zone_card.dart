import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/sub_zone_card.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/zoneControlmode/config_zone_control_mode_panel.dart';
import 'package:fusion_launcher/features/zone_functions/source_select.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_zones_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';

import '../../../core/constants/assets_constants.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart'
    show SelectedItemType, ProjectViewModel, ProjectPropertiesViewModel, HardwareViewModel;
import '../../processing_block/view/processing_chain_view.dart';
import '../../zone_functions/source_matrix.dart';
import '../../zone_functions/source_mix.dart';
import '../viewModel/source_sets_viewmodel/config_source_sets_viewmodel.dart';
import '../viewModel/sources_viewmodel/config_sources_viewmodel.dart';
import '../viewModel/zones_viewmodel/config_zones_state.dart';
import '../viewModel/zones_viewmodel/config_zones_viewmodel.dart';

class ZoneCard extends StatefulWidget {
  final String zoneId;
  final String zoneName;
  final Color bgColor;
  final Zone zoneData;
  final Function(bool)? onExpansionChanged;
  final int? index;

  const ZoneCard({
    this.index,
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
  Set<dynamic> _tempSelectedItems = <dynamic>{};
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
  bool get isInControlMode => serviceLocator<ProjectViewModel>().isInControlMode;
  int popupRefreshKey = 0;

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

  String _prioritySemanticId({required int priorityIndex, required String element}) {
    return 'priority_${priorityIndex}_$element';
  }

  /// Default proxy decorator for reorderable list view
  Widget _defaultProxyDecorator(Widget child, int index, Animation<double> animation) {
    return FadeTransition(
      opacity: animation.drive(Tween<double>(begin: 0.95, end: 1.0)),
      child: Material(
        color: context.colorScheme.elevation2.withAlpha(100),
        child: MultiBlocProvider(
          providers: <BlocProvider<dynamic>>[
            BlocProvider<ConfigZonesViewmodel>.value(value: _zonesViewmodel),
            BlocProvider<ConfigSourcesViewmodel>.value(value: _sourcesViewmodel),
            BlocProvider<ConfigSourceSetsViewmodel>.value(value: _sourceSetsViewmodel),
          ],
          child: child,
        ),
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
              return SemanticHelper.container(
                testId: SemanticHelper.createTestId(SemanticTypes.container, "${FusionTestKeys.instance.zoneitem}_${widget.index}"),
                child: Column(
                  children: <Widget>[
                    SemanticHelper.container(
                      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.zoneitmheader),
                      child: MouseRegion(
                        onEnter: (_) => setState(() => isHovered = true),
                        onExit: (_) => setState(() => isHovered = false),
                        child: _buildZoneHeader(
                          context: context,
                          expanded: zoneExpanded,
                          isHovered: isHovered,
                          isSelected: false,
                        ),
                      ),
                    ),

                    /// Zone Content - shows subzones when expanded
                    if (zoneExpanded) _buildZoneContent(),
                  ],
                ),
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
            FusionIcon.icon(
              semanticId: FusionTestKeys.instance.zonelisticonexpandcollapse,
              expanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              color: Theme.of(context).colorScheme.primaryWhite,
            ),

            const SizedBox(width: 4),

            /// Zone name
            Expanded(
              child: FusionAppText(
                semanticId: FusionTestKeys.instance.zonelistname,
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
              child: FusionImage.asset(
                semanticId: FusionTestKeys.instance.zonelistprocessingbutton,
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

            return SemanticHelper.container(
              testId: SemanticHelper.createTestId(
                SemanticTypes.container,
                FusionTestKeys.instance.zonelistcontent,
              ),
              child: SingleChildScrollView(
                child: Container(
                  margin: const EdgeInsets.symmetric(horizontal: 12),
                  color: context.colorScheme.elevation2.withAlpha(100),

                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: <Widget>[
                      /// Functions Panel
                      SemanticHelper.container(
                        testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.zonelistfunctionspanel),
                        child: Container(
                          decoration: BoxDecoration(
                            //left border
                            border: Border(
                              right: BorderSide(
                                color: context.colorScheme.elevation2,
                              ),
                            ),
                          ),
                          width: MediaQuery.of(context).size.width * 0.14,
                          padding: const EdgeInsets.all(16),
                          child: _buildZoneFunctionsPanel(),
                        ),
                      ),

                      /// Subzone Panel
                      Expanded(
                        child: Container(
                          decoration: BoxDecoration(
                            //left border
                            border: Border(
                              left: BorderSide(
                                color: context.colorScheme.elevation2,
                              ),
                            ),
                          ),
                          child:
                              isInControlMode
                                  ? ConfigZoneControlModePanel(
                                    zone: widget.zoneData,
                                  )
                                  : _buildSubZonePanel(subZonesForZone),
                        ),
                      ),
                    ],
                  ),
                ),
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
        SemanticHelper.container(
          testId: SemanticHelper.createTestId(SemanticTypes.container, "${FusionTestKeys.instance.zonelistfunctionspanelheader}_${widget.index}"),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: <Widget>[
              SemanticHelper.staticText(
                testId: SemanticHelper.createTestId(SemanticTypes.text, "${FusionTestKeys.instance.zonelistfunctionspanelheaderlabel}_${widget.index}"),
                child: FusionAppText(
                  text: 'FUNCTIONS',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: context.colorScheme.textBody,
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        buildFunctionWidget(),
        const SizedBox(height: 24),

        // const Spacer(),
        _buildReorderablePriorityWidgets(),
        const SizedBox(height: 10),
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
      width: MediaQuery.of(context).size.width * 0.2,
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
                padding: const EdgeInsets.only(bottom: 12.0),
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
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "${FusionTestKeys.instance.functionselect}_${widget.index}"),
      child: _hasSelectedFunction ? buildSelectedFunctionButton() : buildAddFunctionButton(),
    );
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
          Expanded(
            child: DragTarget<Source>(
              onWillAcceptWithDetails: (DragTargetDetails<Source> details) {
                final String incomingId = details.data.id;
                if (incomingId == selectedSourceId) return false;
                if (prioritySources.contains(incomingId)) return false;

                return true;
              },
              onAcceptWithDetails: (DragTargetDetails<Source> details) {
                final String sourceId = details.data.id;

                setState(() {
                  _zonesViewmodel.removeSourceFromZone(zoneId: widget.zoneId, sourceId: sourceId);

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
                final bool isSelected = selectedSource != null;

                return PopupMenuButton<String>(
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
                          semanticId: "${FusionTestKeys.instance.sorcprioitypopupheader}_${widget.index}",
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
                              semanticId: "${FusionTestKeys.instance.sorcprioitypopuptext}_${widget.index}",
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
                    return entries;
                  },

                  child: Container(
                    height: 30,
                    padding: const EdgeInsets.only(right: 8, left: 8, top: 4, bottom: 4),

                    decoration: BoxDecoration(
                      color:
                          cannotAccept
                              ? context.colorScheme.errorFill
                              : canAccept
                              ? Theme.of(context).colorScheme.primary.withAlpha(10)
                              : isSelected
                              ? context.colorScheme.elevation1
                              : Colors.transparent,

                      border: Border.all(
                        color:
                            cannotAccept
                                ? context.colorScheme.errorStroke
                                : canAccept
                                ? Theme.of(context).colorScheme.primary
                                : isSelected
                                ? Colors.transparent
                                : context.colorScheme.strokeLight,
                        width: 1,
                      ),

                      borderRadius: BorderRadius.circular(6),

                      boxShadow:
                          isSelected
                              ? <BoxShadow>[
                                BoxShadow(color: context.colorScheme.shadowDark, offset: const Offset(1.5, 1.5), blurRadius: 7),
                                BoxShadow(
                                  color: context.colorScheme.shadowLight,
                                  offset: const Offset(-1.5, -1.5),
                                  blurRadius: 5,
                                  blurStyle: BlurStyle.solid,
                                ),
                              ]
                              : <BoxShadow>[],
                    ),

                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: FusionAppText(
                            text: selectedSource ?? 'Select',
                            maxLine: 1,
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: isSelected ? context.colorScheme.primaryWhite : context.colorScheme.primaryWhite.withAlpha(120),
                            ),
                          ),
                        ),

                        const SizedBox(width: 6),

                        Container(
                          width: 24,
                          height: 24,
                          alignment: Alignment.center,
                          decoration: BoxDecoration(
                            color: isSelected ? context.colorScheme.infoStroke : context.colorScheme.elevation2,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: FusionAppText(
                            text: 'P$priorityIndex',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: isSelected ? context.colorScheme.textPrimary : context.colorScheme.textDisabled,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.008,
          ),

          /// delete button
          SizedBox(
            width: 20,
            height: 20,
            child:
                selectedSourceId != null
                    ? GestureDetector(
                      onTap: () {
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
                      ),
                    )
                    : null,
          ),
        ],
      ),
    );
  }

  /// Add Function button (Popup Menu)
  Widget buildAddFunctionButton({bool isEdit = false}) {
    return SemanticHelper.button(
      testId: SemanticHelper.createTestId(SemanticTypes.button, FusionTestKeys.instance.zonelistfunctionspaneleditbutton),
      child: PopupMenuButton<ZoneFunctionsType>(
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
                ? FusionIcon.icon(Icons.edit, size: 14, color: context.colorScheme.textPrimary)
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
                      FusionIcon.icon(Icons.add, color: context.colorScheme.iconWhite, size: 12),
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
      ),
    );
  }

  /// Selected Function button
  Widget buildSelectedFunctionButton() {
    return SizedBox(
      width: MediaQuery.of(context).size.width * 0.2,
      child: Row(
        children: <Widget>[
          Expanded(
            child: GestureDetector(
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
                height: 30,
                width: MediaQuery.of(context).size.width * 0.1,
                padding: const EdgeInsets.all(8),

                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  boxShadow: <BoxShadow>[
                    BoxShadow(color: context.colorScheme.shadowDark, offset: const Offset(1.5, 1.5), blurRadius: 7),
                    BoxShadow(color: context.colorScheme.shadowLight, offset: const Offset(-1.5, -1.5), blurRadius: 5, blurStyle: BlurStyle.solid),
                  ],
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: <Widget>[
                    Flexible(
                      fit: FlexFit.loose,
                      child: FusionAppText(
                        semanticId: FusionTestKeys.instance.functionselecttext,
                        text: selectedFunction?.displayName ?? '',
                        maxLine: 1,
                        style: context.textTheme.bodySmall?.withColor(context.colorScheme.textPrimary),
                      ),
                    ),
                    const SizedBox(width: 8),
                    FusionImage.asset(
                      semanticId: FusionTestKeys.instance.functionselecticon,
                      Assets.configurationIcon,
                      width: 24,
                      height: 24,
                      fit: BoxFit.contain,
                      assetColor: context.colorScheme.primaryWhite,
                    ),
                  ],
                ),
              ),
            ),
          ),
          SizedBox(
            width: MediaQuery.of(context).size.width * 0.01,
          ),
          if (_hasSelectedFunction) buildAddFunctionButton(isEdit: true),
        ],
      ),
    );
  }

  /// Multi-select source selection for zone (checkboxes)
  void _initializeTempSelection() {
    _tempSelectedItems = <dynamic>{
      ..._zonesViewmodel.getSourcesInZone(zoneId: widget.zoneId),
      ..._zonesViewmodel.getSourceSetsInZone(zoneId: widget.zoneId),
    };
  }

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
      child: Builder(
        builder: (BuildContext context) {
          _initializeTempSelection();

          return FusionMultiSelectPopupMenu<dynamic>(
            maxHeight: 450,
            semanticsId: FusionTestKeys.instance.selectsrc,
            saveButtonLabel: "ADD",
            tooltip: "Select Sources",

            items: <dynamic>[
              _HeaderItem('SOURCES_BLOCK'),
              _HeaderItem('DIVIDER'),
              _HeaderItem('SOURCE_SETS_BLOCK'),
            ],

            selectedItems: <dynamic>{
              ...currentZoneSources,
              ...currentZoneSourceSets,
            },

            onSave: (Set<dynamic> _) {
              final List<String> priorityIds = _zonesViewmodel.getPrioritySourcesInZone(zoneId: widget.zoneId);

              final List<Source> selectedSources = _tempSelectedItems.whereType<Source>().where((Source s) => !priorityIds.contains(s.id)).toList();

              final List<SourceSet> selectedSourceSets = _tempSelectedItems.whereType<SourceSet>().toList();

              _zonesViewmodel.updateSourcesInZone(
                zoneId: widget.zoneId,
                sourceIds: selectedSources.map((Source e) => e.id).toList(),
              );

              _zonesViewmodel.updateSourceSets(
                zoneId: widget.zoneId,
                sourceSetIds: selectedSourceSets.map((SourceSet e) => e.id).toList(),
              );

              setState(() {
                _tempSelectedItems.clear(); // optional cleanup
              });
            },

            itemBuilder: (BuildContext context, dynamic item, bool _) {
              // -------- DIVIDER --------
              if (item is _HeaderItem && item.title == 'DIVIDER') {
                return const Padding(
                  padding: EdgeInsets.symmetric(vertical: 6),
                  child: Divider(thickness: 1),
                );
              }

              // -------- SOURCES --------
              if (item is _HeaderItem && item.title == 'SOURCES_BLOCK') {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setPopupState) {
                    return SemanticHelper.container(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.container,
                        FusionTestKeys.instance.srcSection,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          const SizedBox(height: 4),

                          FusionAppText(
                            text: 'SOURCES',
                            semanticId: FusionTestKeys.instance.sourceText,
                            maxLine: 1,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 10),

                          ...availableSources.asMap().entries.map((MapEntry<int, Source> entry) {
                            final Source src = entry.value;

                            final bool isPrioritySource = _zonesViewmodel.getPrioritySourcesInZone(zoneId: widget.zoneId).contains(src.id);

                            final bool isSelected = _tempSelectedItems.contains(src);

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                if (isPrioritySource) return;

                                isSelected ? _tempSelectedItems.remove(src) : _tempSelectedItems.add(src);

                                setPopupState(() {});
                              },
                              child: Opacity(
                                opacity: isPrioritySource ? 0.5 : 1,
                                child: Padding(
                                  padding: const EdgeInsets.symmetric(vertical: 5.0),
                                  child: Row(
                                    children: <Widget>[
                                      FusionCheckbox(
                                        semanticId: FusionTestKeys.instance.srcSetListCheckbox,
                                        value: isSelected,
                                        onChanged: () {
                                          if (isPrioritySource) return;

                                          isSelected ? _tempSelectedItems.remove(src) : _tempSelectedItems.add(src);

                                          setPopupState(() {});
                                        },
                                      ),
                                      const SizedBox(width: 6),
                                      Expanded(
                                        child: Row(
                                          children: <Widget>[
                                            Expanded(
                                              child: FusionAppText(
                                                semanticId: FusionTestKeys.instance.srcListTxt,
                                                text: src.name,
                                                maxLine: 1,
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                                              ),
                                            ),
                                            if (isPrioritySource)
                                              FusionAppText(
                                                text: '(Priority source)',
                                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                                  fontSize: 9,
                                                  fontStyle: FontStyle.italic,
                                                ),
                                              ),
                                          ],
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              }

              // -------- SOURCE SETS --------
              if (item is _HeaderItem && item.title == 'SOURCE_SETS_BLOCK') {
                return StatefulBuilder(
                  builder: (BuildContext context, StateSetter setPopupState) {
                    return SemanticHelper.container(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.container,
                        FusionTestKeys.instance.srcSetSection,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: <Widget>[
                          FusionAppText(
                            semanticId: FusionTestKeys.instance.sourceSetText,
                            text: 'SOURCE SETS',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),

                          const SizedBox(height: 10),

                          ...sourceSetList.asMap().entries.map((MapEntry<int, SourceSet> entry) {
                            final SourceSet setItem = entry.value;

                            final List<Source> sourcesInSet = _sourceSetsViewmodel.getSourcesInSourceSet(sourceSetId: setItem.id);

                            final bool isSelected = _tempSelectedItems.contains(setItem);

                            return GestureDetector(
                              behavior: HitTestBehavior.opaque,
                              onTap: () {
                                isSelected ? _tempSelectedItems.remove(setItem) : _tempSelectedItems.add(setItem);

                                setPopupState(() {});
                              },
                              child: Padding(
                                padding: const EdgeInsets.symmetric(vertical: 5.0),
                                child: Row(
                                  children: <Widget>[
                                    FusionCheckbox(
                                      semanticId: FusionTestKeys.instance.sourceSetListCheckbox,
                                      value: isSelected,
                                      onChanged: () {
                                        isSelected ? _tempSelectedItems.remove(setItem) : _tempSelectedItems.add(setItem);

                                        setPopupState(() {});
                                      },
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: FusionAppText(
                                        semanticId: FusionTestKeys.instance.srcSetListTxt,
                                        text: '${setItem.name} (${sourcesInSet.length} sources)',
                                        maxLine: 1,
                                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            );
                          }),
                        ],
                      ),
                    );
                  },
                );
              }

              return const SizedBox();
            },
            child: SemanticHelper.button(
              testId: SemanticHelper.createTestId(
                SemanticTypes.container,
                FusionTestKeys.instance.selectSourceButton,
              ),
              child: Container(
                width: MediaQuery.of(context).size.width * 0.3,
                height: 30,
                padding: const EdgeInsets.only(right: 9, left: 8, top: 4, bottom: 4),

                decoration: BoxDecoration(
                  color: context.colorScheme.elevation1,
                  borderRadius: BorderRadius.circular(6),

                  boxShadow: <BoxShadow>[
                    BoxShadow(color: context.colorScheme.shadowDark, offset: const Offset(1.5, 1.5), blurRadius: 7),
                    BoxShadow(
                      color: context.colorScheme.shadowLight,
                      offset: const Offset(-1.5, -1.5),
                      blurRadius: 5,
                      blurStyle: BlurStyle.solid,
                    ),
                  ],
                ),

                child: Row(
                  children: <Widget>[
                    Expanded(
                      child: FusionAppText(
                        text: hasSelection ? 'Selected' : 'Select sources',
                        maxLine: 1,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                          fontWeight: FontWeight.w500,
                          color: hasSelection ? context.colorScheme.primaryWhite : context.colorScheme.primaryWhite.withAlpha(140),
                        ),
                      ),
                    ),

                    Container(
                      height: 24,
                      width: 24,
                      alignment: Alignment.center,
                      decoration: BoxDecoration(
                        color: hasSelection ? context.colorScheme.elevation3 : context.colorScheme.elevation2,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child:
                          hasSelection
                              ? Center(
                                child: FusionAppText(
                                  semanticId: FusionTestKeys.instance.selectSourceText,
                                  text: _zonesViewmodel.getSourceCountInZone(zoneId: widget.zoneId).toString(),
                                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                    fontWeight: FontWeight.w600,
                                    color: context.colorScheme.primaryWhite,
                                  ),
                                ),
                              )
                              : const Center(
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                ),
                              ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  /// Subzone panel (now scrollable)
  Widget _buildSubZonePanel(List<SubZone> subZonesForZone) {
    final List<CircuitModel> zoneCircuit = _zonesViewmodel.getCircuitsInZone(widget.zoneId);

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        FusionTestKeys.instance.zonecircuit,
      ),
      child: Container(
        child:
            /// circuit and subzone list
            (subZonesForZone.isEmpty && zoneCircuit.isEmpty)
                ? Center(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 50.0),
                    child: SemanticHelper.staticText(
                      testId: SemanticHelper.createTestId(
                        SemanticTypes.text,
                        FusionTestKeys.instance.zonenocircuit,
                      ),
                      child: FusionAppText(
                        semanticId: "${FusionTestKeys.instance.zonenocircuit}_${widget.index}",
                        text: 'No sub zones / circuits added yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
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
                        proxyDecorator: _defaultProxyDecorator,

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
                            child: SemanticHelper.container(
                              testId: SemanticHelper.createTestId(
                                SemanticTypes.container,
                                "${FusionTestKeys.instance.subzoneitem}_$index",
                              ),
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
                            ),
                          );
                        },
                      ),
                    ],
                  ),
                ),
      ),
    );
  }

  /// Circuit card widget
  Widget _buildCircuitCard({required int index, required CircuitModel circuitData, required List<Speaker> speakersList}) {
    final bool isThisCircuitHovered = _hoveredCircuitIndex == index;

    final String assetImagePath =
        serviceLocator<ProjectViewModel>().getHardwareImage(
          productId: speakersList.isNotEmpty ? speakersList.first.productId ?? 0 : 0,
          currentImagePath: speakersList.isNotEmpty ? speakersList.first.assetImagePath : '',
        ) ??
        "";

    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(
        SemanticTypes.container,
        "${FusionTestKeys.instance.zonecircuititm}_$index",
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isThisCircuitHovered ? context.colorScheme.elevation2 : null,
          borderRadius: BorderRadius.circular(8),
        ),
        padding: const EdgeInsets.only(top: 4, bottom: 4, left: 10, right: 13),
        margin: const EdgeInsets.only(bottom: 4, top: 4, left: 10),
        child: Row(
          children: <Widget>[
            FusionImage.asset(
              semanticId: "${FusionTestKeys.instance.zonecircuititmimg}_${widget.index}",
              // speakersList.isNotEmpty ? speakersList.first.assetImagePath : "",
              assetImagePath,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 6),
            Expanded(
              child: FusionAppText(
                semanticId: FusionTestKeys.instance.zonecircuititmtxt,
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
                semanticId: FusionTestKeys.instance.zonecircuititmimg2,
                Assets.processingBlocksFilledIcon,
                width: 24,
                height: 24,
                assetColor: context.colorScheme.primaryWhite,
                fit: BoxFit.contain,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _HeaderItem {
  final String title;
  _HeaderItem(this.title);
}
