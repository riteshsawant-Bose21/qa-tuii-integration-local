import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/sub_zone_card.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';

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

  String? selectedFunction;
  bool get _hasSelectedFunction => (selectedFunction != null && selectedFunction!.isNotEmpty);
  String? selectedPrioritySource1;
  String? selectedPrioritySource2;
  List<String> selectedZoneSources = <String>[]; // multi-select sources (ordered)

  final List<String> functions = <String>[
    'Priority Override',
    'Mix',
    'Mix + Priority Override',
    'Automatic Mic Mixer (Gain)',
    'Automatic Mic Mixer (Gated)',
    'Mini-Matrix',
    'Priority-Ladder',
  ];

  @override
  void initState() {
    super.initState();
    _isZoneExpanded = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isZoneExpanded.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isZoneExpanded,
      builder: (BuildContext context, bool zoneExpanded, Widget? child) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            final SelectedItem? selectedDevice = _projectViewModel.selectedDevice;
            // final bool isSelected = selectedDevice?.id == widget.zoneId && selectedDevice?.type == SelectedItemType.zone;

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
            // Debug
            print('Zone ${widget.zoneId} (${widget.zoneName}) -> subZones: $subZoneCount');

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

        buildPriorityFunctionWidget(priorityIndex: 1), // fixed invalid 'd'
        const SizedBox(height: 8),
        buildPriorityFunctionWidget(priorityIndex: 2),
        const SizedBox(height: 8),
        buildSourceSelectionForZone(), // new multi-select source widget
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

    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          if (priorityIndex == 1) {
            selectedPrioritySource1 = value;
          } else {
            selectedPrioritySource2 = value;
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
            height: 28,
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

        /// Individual sources
        for (final Source src in _projectViewModel.sources) {
          final String value = src.name;
          entries.add(
            PopupMenuItem<String>(
              value: value,
              height: 32,
              child: Row(
                children: <Widget>[
                  Radio<String>(
                    value: value,
                    groupValue: selectedSource,
                    materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                    onChanged: (String? v) {
                      if (v != null) Navigator.pop(context, v);
                    },
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: FusionAppText(
                      text: src.name,
                      maxLine: 1,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                    ),
                  ),
                ],
              ),
            ),
          );
        }

        /// Divider
        entries.add(const PopupMenuDivider(height: 4));

        /// Header: Source Sets
        entries.add(
          PopupMenuItem<String>(
            enabled: false,
            height: 28,
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

        /// Source sets with their sources
        for (final SourceSet sourceSet in _projectViewModel.getSourceSetsInZone(zoneId: widget.zoneId)) {
          final List<Source> sources = _projectViewModel.getSourcesInSourceSet(sourceSetId: sourceSet.id);
          for (final Source src in sources) {
            final String value = '${sourceSet.name} • ${src.name}';
            entries.add(
              PopupMenuItem<String>(
                value: value,
                height: 32,
                child: Row(
                  children: <Widget>[
                    Radio<String>(
                      value: value,
                      groupValue: selectedSource,
                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                      visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                      onChanged: (String? v) {
                        if (v != null) Navigator.pop(context, v);
                      },
                    ),
                    Expanded(
                      child: FusionAppText(
                        text: value,
                        maxLine: 1,
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(fontSize: 11),
                      ),
                    ),
                  ],
                ),
              ),
            );
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
                color: selectedSource == null ? Theme.of(context).colorScheme.grey : Theme.of(context).colorScheme.primary,
                borderRadius: BorderRadius.circular(3),
              ),
              child: FusionAppText(
                text: 'P$priorityIndex',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 10,
                  color: Theme.of(context).colorScheme.white,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// Add Function button (Popup Menu)
  Widget buildAddFunctionButton({bool isEdit = false}) {
    return PopupMenuButton<String>(
      onSelected: (String value) {
        setState(() {
          selectedFunction = value;
        });
      },
      offset: const Offset(0, 10),
      tooltip: isEdit ? "Edit Function" : "Add Function",
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.white,
      itemBuilder: (BuildContext context) {
        return functions.map((String function) {
          return PopupMenuItem<String>(
            height: 32,
            value: function,
            child: SizedBox(
              width: 164,
              child: FusionAppText(
                text: function,
                maxLine: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
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
                        fontSize: 11,
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
            Expanded(
              child: FusionAppText(
                text: selectedFunction ?? '',
                maxLine: 1,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w400,
                ),
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
    final bool hasSelection = selectedZoneSources.isNotEmpty;

    return PopupMenuButton<String>(
      onSelected: (String? value) {
        if (value == 'add') {
          setState(() {});
        }
      },
      offset: const Offset(0, 25),
      tooltip: "Select Sources",
      padding: EdgeInsets.zero,
      color: Theme.of(context).colorScheme.white,
      itemBuilder: (BuildContext context) {
        /// Use a temporary list for selection inside the popup
        final List<String> tempSelectedSources = List<String>.from(selectedZoneSources);

        final List<PopupMenuEntry<String>> entries = <PopupMenuEntry<String>>[];

        /// Header: Sources
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

        /// Sources (individual)
        for (final Source src in _projectViewModel.sources) {
          final String value = 'SRC:${src.name}';
          entries.add(
            PopupMenuItem<String>(
              enabled: false,
              height: 20,
              child: StatefulBuilder(
                builder: (BuildContext context, setStatePopup) {
                  return GestureDetector(
                    onTap: () {
                      if (tempSelectedSources.contains(value)) {
                        tempSelectedSources.remove(value);
                      } else {
                        tempSelectedSources.add(value);
                      }
                      setStatePopup(() {});
                    },
                    child: Row(
                      children: <Widget>[
                        Transform.scale(
                          scale: 0.7,
                          child: Checkbox(
                            value: tempSelectedSources.contains(value),
                            activeColor: Theme.of(context).colorScheme.greyDark,
                            onChanged: (bool? checked) {
                              if (tempSelectedSources.contains(value)) {
                                tempSelectedSources.remove(value);
                              } else {
                                tempSelectedSources.add(value);
                              }
                              setStatePopup(() {});
                            },

                            materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                            visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                            splashRadius: 8,

                            // color of the check mark itself (when checked)
                            checkColor: Colors.white,

                            // optional: make the border/side gray when unchecked and match when checked
                            side: BorderSide(width: 1.0, color: Theme.of(context).colorScheme.grey),
                          ),
                        ),

                        const SizedBox(width: 4),
                        Expanded(
                          child: FusionAppText(
                            text: src.name,
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

        /// Divider
        entries.add(const PopupMenuDivider(height: 12));

        /// Header: Source Sets
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

        /// Source sets and their sources
        for (final SourceSet set in _projectViewModel.getAllSourceSets()) {
          final List<Source> sources = _projectViewModel.getSourcesInSourceSet(sourceSetId: set.id);
          for (final Source src in sources) {
            final String value = 'SET:${set.name} • ${src.name}';
            entries.add(
              PopupMenuItem<String>(
                enabled: false,
                height: 20,
                child: StatefulBuilder(
                  builder: (BuildContext context, setStatePopup) {
                    return GestureDetector(
                      onTap: () {
                        if (tempSelectedSources.contains(value)) {
                          tempSelectedSources.remove(value);
                        } else {
                          tempSelectedSources.add(value);
                        }
                        setStatePopup(() {});
                      },
                      child: Row(
                        children: <Widget>[
                          Transform.scale(
                            scale: 0.7,
                            child: Checkbox(
                              value: tempSelectedSources.contains(value),
                              activeColor: Theme.of(context).colorScheme.greyDark,
                              onChanged: (bool? checked) {
                                if (tempSelectedSources.contains(value)) {
                                  tempSelectedSources.remove(value);
                                } else {
                                  tempSelectedSources.add(value);
                                }
                                setStatePopup(() {});
                              },

                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                              visualDensity: const VisualDensity(horizontal: -4, vertical: -4),
                              splashRadius: 8,

                              // color of the check mark itself (when checked)
                              checkColor: Colors.white,

                              // optional: make the border/side gray when unchecked and match when checked
                              side: BorderSide(width: 1.0, color: Theme.of(context).colorScheme.grey),
                            ),
                          ),

                          const SizedBox(width: 4),
                          Expanded(
                            child: FusionAppText(
                              text: '${set.name} • ${src.name}',
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

        /// Divider before Add button
        entries.add(
          const PopupMenuDivider(
            height: 14,
            color: Colors.transparent,
          ),
        );

        /// Add button to close popup and update selection
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
                  setState(() {
                    selectedZoneSources = List<String>.from(tempSelectedSources);
                  });
                  Navigator.pop(context, 'add');
                },
              ),
            ),
          ),
        );

        return entries;
      },
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
                    color: hasSelection ? Theme.of(context).colorScheme.greyDark : Theme.of(context).colorScheme.grey,
                    borderRadius: BorderRadius.circular(3),
                  ),
                  child: FusionAppText(
                    text: '${selectedZoneSources.length}',
                    maxLine: 1,
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      fontSize: 10,
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
    return Container(
      decoration: BoxDecoration(
        border: Border(
          bottom: BorderSide(color: Theme.of(context).colorScheme.grey),
        ),
      ),
      child:
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
    );
  }
}
