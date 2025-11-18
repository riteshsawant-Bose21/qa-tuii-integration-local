import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/sub_zone_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/models/project_entities/zone_functions.dart';

import '../../../core/constants/assets_constants.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

class ZoneCard extends StatefulWidget {
  final String zoneId;
  final String zoneName;
  final Color bgColor;
  const ZoneCard({
    super.key,
    required this.zoneId,
    required this.zoneName,
    required this.bgColor,
  });

  @override
  State<ZoneCard> createState() => _ZoneCardState();
}

class _ZoneCardState extends State<ZoneCard> {
  late ValueNotifier<bool> _isZoneExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();
  bool isHovered = false;

  ZoneFunctionsType? selectedFunction;
  bool get _hasSelectedFunction => selectedFunction != null;

  String? selectedPrioritySource1;
  String? selectedPrioritySource2;
  List<String> selectedZoneSourceIds = <String>[];
  List<String> selectedZoneSourceSetIds = <String>[];
  int? _hoveredCircuitIndex;

  @override
  void initState() {
    super.initState();
    _isZoneExpanded = ValueNotifier<bool>(false);
    _loadPrioritySources();
  }

  @override
  void dispose() {
    _isZoneExpanded.dispose();
    super.dispose();
  }

  void _loadPrioritySources() {
    final List<String> prioritySources = _projectViewModel.getPrioritySourcesInZone(zoneId: widget.zoneId);

    // priority 1
    if (prioritySources.isNotEmpty && prioritySources[0].isNotEmpty) {
      final HardwareComponent? hw = _projectViewModel.getHardware(hardwareId: prioritySources[0]);
      if (hw != null) selectedPrioritySource1 = hw.name;
    }

    // priority 2
    if (prioritySources.length > 1 && prioritySources[1].isNotEmpty) {
      final HardwareComponent? hw = _projectViewModel.getHardware(hardwareId: prioritySources[1]);
      if (hw != null) selectedPrioritySource2 = hw.name;
    }

    setState(() {});
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isZoneExpanded,
      builder: (BuildContext context, bool zoneExpanded, Widget? child) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
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
    );
  }

  /// Zone header - always visible
  Widget _buildZoneHeader({required BuildContext context, required bool expanded, required bool isHovered, required bool isSelected}) {
    return GestureDetector(
      onTap: () {
        _isZoneExpanded.value = !_isZoneExpanded.value;

        /// Select zone on tap
        _projectViewModel.setSelectedDevice(widget.zoneId, SelectedItemType.zone);
      },
      child: Container(
        padding: const EdgeInsets.only(left: 14, right: 14),
        height: 32,
        decoration: BoxDecoration(
          color: isHovered ? widget.bgColor.withAlpha(100) : widget.bgColor.withAlpha(120),
          border: Border.all(
            color: isSelected ? Theme.of(context).colorScheme.greyDark : Colors.transparent,
          ),
        ),
        child: Row(
          children: <Widget>[
            /// Expand/collapse icon
            Icon(
              expanded ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
              color: Theme.of(context).colorScheme.fusionTextViewColor.withAlpha(90),
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
            const FusionImage.asset(
              Assets.processingBlocksFilledWhiteIcon,
              width: 24,
              height: 24,
              fit: BoxFit.contain,
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
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final List<SubZone> subZonesForZone = _projectViewModel.getSubZonesForZone(parentZoneId: widget.zoneId);
            final int subZoneCount = subZonesForZone.length;
            final double calculatedHeight = subZoneCount * 100.0;
            final double constrainedHeight = calculatedHeight.clamp(200.0, 400.0);

            return SizedBox(
              height: constrainedHeight,
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
                        bottom: BorderSide(color: Theme.of(context).colorScheme.grey),
                      ),
                    ),
                    child: _buildZoneFunctionsPanel(),
                  ),

                  /// Full height divider
                  Container(
                    width: 1,
                    height: constrainedHeight,
                    color: Theme.of(context).colorScheme.grey,
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
    final ZoneFunctions? existingFunction = _projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);
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

        buildPriorityFunctionWidget(priorityIndex: 1),
        const SizedBox(height: 8),
        buildPriorityFunctionWidget(priorityIndex: 2),
        const SizedBox(height: 8),
        buildSourceSelectionForZone(),
      ],
    );
  }

  /// Function selection widget
  Widget buildFunctionWidget() {
    return _hasSelectedFunction ? buildSelectedFunctionButton() : buildAddFunctionButton();
  }

  /// Priority Override function button (Popup Menu) - supports independent P1 / P2
  Widget buildPriorityFunctionWidget({required int priorityIndex}) {
    final String? selectedSource = priorityIndex == 1 ? selectedPrioritySource1 : selectedPrioritySource2;
    final ZoneFunctions? existingFunction = _projectViewModel.getZoneFunctionForZone(zoneId: widget.zoneId);

    return Visibility(
      visible: existingFunction!.hasPriority,
      child: PopupMenuButton<String>(
        onSelected: (String value) {
          setState(() {
            if (priorityIndex == 1) {
              selectedPrioritySource1 = _projectViewModel.getHardware(hardwareId: value)?.name;
              _projectViewModel.addPrioritySourceToZone(
                zoneId: widget.zoneId,
                sourceId: value,
                priority: 1,
              );
            } else {
              selectedPrioritySource2 = _projectViewModel.getHardware(hardwareId: value)?.name;
              _projectViewModel.addPrioritySourceToZone(
                zoneId: widget.zoneId,
                sourceId: value,
                priority: 2,
              );
            }
          });
        },
        offset: const Offset(0, 25),
        tooltip: "Select Priority Source P$priorityIndex",
        padding: EdgeInsets.zero,
        color: Theme.of(context).colorScheme.white,
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
                ),
              ),
            ),
          );

          /// Individual sources
          final List<Source> availableSources = _projectViewModel.getSourcesWithoutSourceSet();
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
              final String value = src.id;
              final String assetPath = src.assetImagePath;

              entries.add(
                PopupMenuItem<String>(
                  value: value,
                  height: 20,
                  child: Row(
                    children: <Widget>[
                      Transform.scale(
                        scale: 0.7,
                        child: Radio<String>(
                          value: value,
                          groupValue: selectedSource,
                          materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                          visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                          activeColor: Theme.of(context).colorScheme.greyDark,
                          onChanged: (String? v) {
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
                          text: src.name,
                          capitalize: true,
                          maxLine: 1,
                          style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                        ),
                      ),
                    ],
                  ),
                ),
              );
            }
          }

          /// Divider
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
          final List<SourceSet> allSourceSets = _projectViewModel.getAllSourceSets();
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
          } else {
            for (final SourceSet sourceSet in allSourceSets) {
              final List<Source> sources = _projectViewModel.getSourcesInSourceSet(sourceSetId: sourceSet.id);
              for (final Source src in sources) {
                final String name = '${src.name} (${sourceSet.name})';
                final String value = src.id;
                final String assetPath = src.assetImagePath;

                entries.add(
                  PopupMenuItem<String>(
                    value: value,
                    height: 20,
                    child: Row(
                      children: <Widget>[
                        Transform.scale(
                          scale: 0.7,
                          child: Radio<String>(
                            value: value,
                            groupValue: selectedSource,
                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            activeColor: Theme.of(context).colorScheme.greyDark,
                            onChanged: (String? v) {
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
                            text: name,
                            capitalize: true,
                            maxLine: 1,
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 10),
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }
            }
          }

          return entries;
        },
        child: Container(
          height: 22,
          width: 170,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
          decoration: BoxDecoration(
            border: Border.all(
              color: selectedSource == null ? Theme.of(context).colorScheme.grey : Theme.of(context).colorScheme.greyDark,
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
                    color: selectedSource == null ? Theme.of(context).colorScheme.grey : Theme.of(context).colorScheme.greyDark,
                  ),
                ),
              ),
              const SizedBox(width: 4),
              Container(
                width: 14,
                height: 14,

                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: selectedSource == null ? Theme.of(context).colorScheme.grey : Theme.of(context).colorScheme.greyDark,
                  borderRadius: BorderRadius.circular(3),
                ),
                child: FusionAppText(
                  text: 'P$priorityIndex',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    fontSize: 8,
                    color: Theme.of(context).colorScheme.white,
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
  }

  /// Add Function button (Popup Menu)
  Widget buildAddFunctionButton({bool isEdit = false}) {
    return PopupMenuButton<ZoneFunctionsType>(
      onSelected: (ZoneFunctionsType value) {
        setState(() => selectedFunction = value);
        _projectViewModel.addFunctionToZone(
          zoneId: widget.zoneId,
          function: getNewZoneFunction(type: value),
        );
      },
      offset: const Offset(0, 10),
      tooltip: isEdit ? "Edit Function" : "Add Function",
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.white,
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
              ? Icon(
                Icons.edit,
                size: 14,
                color: Theme.of(context).colorScheme.fusionTextViewColor.withAlpha(90),
              )
              : Container(
                height: 22,
                width: 170,
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: Theme.of(context).colorScheme.greyDark,
                  ),
                  borderRadius: BorderRadius.circular(3),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  mainAxisAlignment: MainAxisAlignment.start,
                  children: <Widget>[
                    Icon(Icons.add, color: Theme.of(context).colorScheme.greyDark, size: 12),
                    const SizedBox(width: 4),
                    FusionAppText(
                      text: 'Add Function',
                      maxLine: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.greyDark,
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
        print('Selected function: $selectedFunction');
      },
      child: Container(
        height: 22,
        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
        decoration: BoxDecoration(
          border: Border.all(
            color: Theme.of(context).colorScheme.greyDark,
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
            const FusionImage.asset(
              Assets.configurationFilledIcon,
              width: 14,
              height: 14,
              fit: BoxFit.contain,
            ),
          ],
        ),
      ),
    );
  }

  /// Multi-select source selection for zone (checkboxes)
  Widget buildSourceSelectionForZone() {
    /// Get current selections from the zone
    final List<Source> currentZoneSources = _projectViewModel.getSourcesInZone(zoneId: widget.zoneId);
    final List<SourceSet> currentZoneSourceSets = _projectViewModel.getSourceSetsInZone(zoneId: widget.zoneId);

    final bool hasSelection = currentZoneSources.isNotEmpty || currentZoneSourceSets.isNotEmpty;

    final List<Source> availableSources = _projectViewModel.getSourcesWithoutSourceSet();
    final List<SourceSet> sourceSetList = _projectViewModel.getAllSourceSets();

    return PopupMenuButton<String>(
      onSelected: (String? value) {
        if (value == 'add') {
          setState(() {});

          /// refresh zone tile UI
        }
      },
      offset: const Offset(0, 25),
      tooltip: "Select Sources",
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.white,
      itemBuilder: (BuildContext context) {
        /// Temporary selections mirror existing selections
        final List<String> tempSelectedSources = currentZoneSources.map((Source e) => e.id).toList();

        final List<String> tempSelectedSourceSets = currentZoneSourceSets.map((SourceSet e) => e.id).toList();

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

            entries.add(
              PopupMenuItem<String>(
                enabled: false,
                height: 20,
                child: StatefulBuilder(
                  builder: (BuildContext c, StateSetter setPopupState) {
                    return GestureDetector(
                      onTap: () {
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
                              activeColor: Theme.of(context).colorScheme.greyDark,
                              onChanged: (bool? _) {
                                if (tempSelectedSources.contains(id)) {
                                  tempSelectedSources.remove(id);
                                } else {
                                  tempSelectedSources.add(id);
                                }
                                setPopupState(() {});
                              },
                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              checkColor: Colors.white,
                              side: BorderSide(
                                width: 1,
                                color: Theme.of(context).colorScheme.grey,
                              ),
                            ),
                          ),
                          const SizedBox(width: 4),
                          Expanded(
                            child: FusionAppText(
                              text: src.name,
                              capitalize: true,
                              maxLine: 1,
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
            final List<Source> sourcesInSet = _projectViewModel.getSourcesInSourceSet(sourceSetId: s.id);

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
                              activeColor: Theme.of(context).colorScheme.greyDark,
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
                              checkColor: Colors.white,
                              side: BorderSide(
                                width: 1,
                                color: Theme.of(context).colorScheme.grey,
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
                  _projectViewModel.updateSourcesInZone(
                    zoneId: widget.zoneId,
                    sourceIds: tempSelectedSources,
                  );

                  _projectViewModel.updateSourceSets(
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
            color: hasSelection ? Theme.of(context).colorScheme.greyDark : Theme.of(context).colorScheme.grey,
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
                  color: hasSelection ? Theme.of(context).colorScheme.greyDark : Theme.of(context).colorScheme.grey,
                ),
              ),
            ),
            if (hasSelection)
              IntrinsicWidth(
                child: Container(
                  height: 14,
                  padding: const EdgeInsets.symmetric(horizontal: 4),
                  alignment: Alignment.center,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.greyDark,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FusionAppText(
                    text: (currentZoneSources.length + currentZoneSourceSets.length).toString(),
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 8,
                      color: Theme.of(context).colorScheme.white,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// Subzone panel (now uses filtered list)
  Widget _buildSubZonePanel(List<SubZone> subZonesForZone) {
    final List<CircuitModel> zoneCircuit = _projectViewModel.getCircuitsInZone(widget.zoneId);

    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child: Column(
        children: <Widget>[
          if (zoneCircuit.isNotEmpty)
            ListView.builder(
              shrinkWrap: true,
              physics: const ClampingScrollPhysics(),
              itemCount: zoneCircuit.length,
              itemBuilder: (BuildContext context, int index) {
                final CircuitModel circuitData = zoneCircuit[index];
                final List<Speaker> speakersList = _projectViewModel.getHardwareForCircuit(circuitId: circuitData.id).whereType<Speaker>().toList();
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
          subZonesForZone.isEmpty
              ? Center(
                child: FusionAppText(
                  text: 'No sub zones added yet',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              )
              : SingleChildScrollView(
                child: ReorderableListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  buildDefaultDragHandles: false,
                  itemCount: subZonesForZone.length,
                  onReorder: (int oldIndex, int newIndex) {
                    if (oldIndex < newIndex) newIndex -= 1;
                    _projectViewModel.reOrderSubZoneInZone(
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
                      child: Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: SubZoneCard(
                          subZoneId: subZone.id,
                          subZoneName: subZone.name,
                        ),
                      ),
                    );
                  },
                ),
              ),
        ],
      ),
    );
  }

  Widget _buildCircuitCard({required int index, required CircuitModel circuitData, required List<Speaker> speakersList}) {
    final bool isThisCircuitHovered = _hoveredCircuitIndex == index;

    return Container(
      decoration: BoxDecoration(
        color: isThisCircuitHovered ? Colors.grey[200] : null,
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
          const FusionImage.asset(
            Assets.processingBlocksFilledIcon,
            width: 24,
            height: 24,
            fit: BoxFit.contain,
          ),
        ],
      ),
    );
  }
}
