import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/source_set_item.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_sources.dart';
import 'package:fusion_lib/constants/semantics/test_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_outlined_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_helper.dart';
import 'package:fusion_lib/fusion_widgets/semantics/semantic_type.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';
import 'package:fusion_lib/models/project_entities/source_set_model.dart';
import '../viewModel/source_sets_viewmodel/config_source_sets_state.dart';
import '../viewModel/source_sets_viewmodel/config_source_sets_viewmodel.dart';
import '../viewModel/sources_viewmodel/config_sources_viewmodel.dart';

class SourceSetSection extends StatefulWidget {
  const SourceSetSection({super.key});

  @override
  State<SourceSetSection> createState() => _SourceSetSectionState();
}

class _SourceSetSectionState extends State<SourceSetSection> {
  ConfigSourceSetsViewmodel get _sourceSetsViewmodel => context.read<ConfigSourceSetsViewmodel>();
  final TextEditingController _sourceSetNameController = TextEditingController();
  final List<SelectedSource> _selectedSources = <SelectedSource>[];
  ConfigSourcesViewmodel get _sourcesViewmodel => context.read<ConfigSourcesViewmodel>();
  final Map<String, GlobalKey> _sourceSetKeys = <String, GlobalKey<State<StatefulWidget>>>{};

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.sourcesetsec),
      child: Column(
        children: <Widget>[
          SectionHeader(
            semanticLabel: FusionTestKeys.instance.sourcesetheader,
            title: 'Source Sets',
            isRounded: false,
            assetPath: 'assets/images/source_set_icon.png',
            trailing: PopupMenuButton<dynamic>(
              onCanceled: () {
                _clearSourceSetDialog();
                setState(() {});
              },
              tooltip: "Add Source Set",
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(
                maxHeight: 500,
                maxWidth: 250,
              ),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
              color: context.colorScheme.elevation1,
              menuPadding: EdgeInsets.zero,

              itemBuilder: (BuildContext context) {
                return <PopupMenuItem<dynamic>>[
                  PopupMenuItem<dynamic>(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: SizedBox(
                      width: 250,
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setMenuState) {
                          final List<Source> sourcesWithoutSourceSet = _sourceSetsViewmodel.getAvailableSources();

                          return SingleChildScrollView(
                            child: _SourceSetCreationWidget(
                              sourceSetNameController: _sourceSetNameController,
                              availableSources: sourcesWithoutSourceSet,
                              selectedSources: _selectedSources,
                              onAddSourceSet: () {
                                /// Pass popup context so only the menu closes.
                                _addSourceSet(context);
                              },
                              onCancel: () {
                                /// Cancel inside popup: close only popup.
                                _clearSourceSetDialog(pop: true, popContext: context);
                              },
                              onSourceChanged: (Source source, bool isSelected) {
                                setState(() {
                                  if (isSelected) {
                                    _selectedSources.add(SelectedSource(id: source.id, name: source.name));
                                  } else {
                                    _selectedSources.removeWhere((SelectedSource s) => s.id == source.id);
                                  }
                                });
                                setMenuState(() {});
                              },
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                ];
              },
              child: SemanticHelper.button(
                testId: SemanticHelper.createTestId(SemanticTypes.button, "add_source_button"),
                child: IconButton(
                  icon: FusionIcon.icon(
                    semanticId: FusionTestKeys.instance.sourcesetheadicon,
                    Icons.add_sharp,
                    size: 16,
                    color: context.colorScheme.primaryWhite,
                  ),
                  onPressed: null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ),

          Expanded(
            child: Container(
              decoration: BoxDecoration(
                borderRadius: const BorderRadius.only(
                  bottomLeft: Radius.circular(12),
                  bottomRight: Radius.circular(12),
                ),
                border: Border(
                  bottom: BorderSide(
                    color: context.colorScheme.elevation2,
                  ),
                  left: BorderSide(
                    color: context.colorScheme.elevation2,
                  ),
                  right: BorderSide(
                    color: context.colorScheme.elevation2,
                  ),
                ),
              ),
              child: BlocBuilder<ConfigSourceSetsViewmodel, ConfigSourceSetsState>(
                builder: (BuildContext context, ConfigSourceSetsState state) {
                  if (state.sourceSets.isEmpty) {
                    /// Show informational text when no source sets exist
                    return SingleChildScrollView(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: SemanticHelper.staticText(
                          testId: SemanticHelper.createTestId(SemanticTypes.text, FusionTestKeys.instance.sourcesetsdescription),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              FusionAppText(
                                text: 'Create Source Sets',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FusionAppText(
                                text: 'Combine multiple audio sources into a single source set for simplified routing and control.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                              const SizedBox(height: 8),
                              FusionAppText(
                                text:
                                    'Select from available sources, group them as needed, and assign a clear name to the set. Source sets help streamline system configuration and enable flexible audio distribution.',
                                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                  fontSize: 10,
                                  fontWeight: FontWeight.w400,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    );
                  }
                  return Container(
                    clipBehavior: Clip.none,
                    child: ReorderableListView.builder(
                      shrinkWrap: true,
                      proxyDecorator: (Widget child, int index, Animation<double> animation) {
                        return Material(
                          color: context.colorScheme.elevation1,
                          child: SizedBox(
                            width: 220,
                            // child: child,
                            child: BlocProvider<ConfigSourceSetsViewmodel>.value(value: _sourceSetsViewmodel, child: child),
                          ),
                        );
                      },
                      physics: const ClampingScrollPhysics(),
                      buildDefaultDragHandles: false,
                      itemCount: state.sourceSets.length,
                      onReorder: (int oldIndex, int newIndex) {
                        _sourceSetsViewmodel.reorderSourceSets(oldIndex, newIndex);
                      },
                      itemBuilder: (BuildContext context, int index) {
                        final SourceSet sourceSet = state.sourceSets[index];

                        /// Create or get the GlobalKey for this source set
                        _sourceSetKeys.putIfAbsent(sourceSet.id, () => GlobalKey());
                        final GlobalKey<State<StatefulWidget>> sourceSetKey = _sourceSetKeys[sourceSet.id]!;

                        return DragTarget<Source>(
                          key: ValueKey<String>(sourceSet.id),
                          onWillAcceptWithDetails: (DragTargetDetails<Source> details) {
                            /// Check if source is not already in this source set
                            return !_sourceSetsViewmodel.isSourceInSourceSet(
                              sourceId: details.data.id,
                              sourceSetId: sourceSet.id,
                            );
                          },
                          onLeave: (Source? data) {},
                          onAcceptWithDetails: (DragTargetDetails<Source> details) {
                            _sourceSetsViewmodel.addSourceToSourceSet(
                              sourceId: details.data.id,
                              sourceSetId: sourceSet.id,
                            );
                            _sourcesViewmodel.syncWithProjectViewModel();

                            /// Expand the source set after dropping
                            final dynamic sourceSetState = sourceSetKey.currentState as dynamic;
                            sourceSetState?.expandSourceSet();

                            _sourcesViewmodel.endDrag();
                          },
                          builder: (BuildContext context, List<Source?> candidateData, List<dynamic> rejectedData) {
                            final bool isHovered = candidateData.isNotEmpty;
                            return ReorderableDragStartListener(
                              index: index,
                              child: SourceSetItem(
                                index: index,
                                key: sourceSetKey,
                                sourceSet: sourceSet,
                                isDragHovered: isHovered,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  void _clearSourceSetDialog({bool pop = false, BuildContext? popContext}) {
    _sourceSetNameController.clear();
    _selectedSources.clear();
    if (pop && popContext != null && Navigator.of(popContext).canPop()) {
      Navigator.of(popContext).pop();
    }
    setState(() {});
  }

  void _addSourceSet(BuildContext popupContext) {
    _sourceSetsViewmodel.addSourceSet(
      name: _sourceSetNameController.text.trim(),
      sourceIds: _selectedSources.map((SelectedSource s) => s.id).toList(),
    );
    _sourcesViewmodel.syncWithProjectViewModel();

    /// Clear dialog and close popup
    _clearSourceSetDialog(pop: true, popContext: popupContext);
  }
}

class _SourceSetCreationWidget extends StatefulWidget {
  final TextEditingController sourceSetNameController;
  final List<Source> availableSources;
  final List<SelectedSource> selectedSources;
  final VoidCallback onAddSourceSet;
  final VoidCallback onCancel;
  final Function(Source, bool) onSourceChanged;

  const _SourceSetCreationWidget({
    required this.sourceSetNameController,
    required this.availableSources,
    required this.selectedSources,
    required this.onAddSourceSet,
    required this.onCancel,
    required this.onSourceChanged,
  });

  @override
  State<_SourceSetCreationWidget> createState() => _SourceSetCreationWidgetState();
}

class _SourceSetCreationWidgetState extends State<_SourceSetCreationWidget> {
  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, "source_set_creation_widget"),
      child: Container(
        color: context.colorScheme.elevation1,
        width: 250,
        padding: const EdgeInsets.all(12),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: <Widget>[
            FusionAppText(
              text: "Create source set",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 12),

            FusionAppText(
              text: "Source Set Name",
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 8),

            /// Source Set Name Input
            FusionTextField(
              controller: widget.sourceSetNameController,
              hintText: "Enter source set name",
              semanticFieldId: "source_set_name_input",
              decoration: InputDecoration(
                hintText: 'Enter source set name',

                hintStyle: Theme.of(context).inputDecorationTheme.hintStyle,
                counterText: '',
                fillColor: context.colorScheme.elevation2,
                filled: true,
                border: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                enabledBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                focusedBorder: const OutlineInputBorder(borderSide: BorderSide(color: Colors.transparent)),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
              ),
              onChanged: (String value) {
                setState(() {});
              },
            ),
            const SizedBox(height: 12),

            /// Source Selection Label
            SemanticHelper.container(
              testId: SemanticHelper.createTestId(
                SemanticTypes.container,
                FusionTestKeys.instance.srcselectionlabel,
              ),
              child: FusionAppText(
                text: 'Select sources',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
            const SizedBox(height: 8),

            /// Source Selection Dropdown
            Container(
              height: 28,
              decoration: BoxDecoration(
                color: context.colorScheme.elevation2,
                border: Border.all(color: context.colorScheme.elevation4),
                borderRadius: BorderRadius.circular(4),
              ),
              child: PopupMenuButton<String>(
                onCanceled: () {
                  // Handle popup close if needed
                },
                constraints: const BoxConstraints(
                  maxHeight: 500,
                  maxWidth: 240,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                color: context.colorScheme.elevation2,
                offset: const Offset(0, 35),
                itemBuilder: (BuildContext context) {
                  return <PopupMenuEntry<String>>[
                    PopupMenuItem<String>(
                      enabled: false,
                      padding: EdgeInsets.zero,
                      child: StatefulBuilder(
                        builder: (BuildContext context, StateSetter setPopupState) {
                          return SemanticHelper.container(
                            testId: SemanticHelper.createTestId(SemanticTypes.container, "source_set_creation_widget"),
                            child: Container(
                              width: 240,
                              constraints: const BoxConstraints(maxHeight: 460),
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: <Widget>[
                                  /// Header with close button
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                                    decoration: BoxDecoration(
                                      border: Border(
                                        bottom: BorderSide(
                                          color: context.colorScheme.elevation4,
                                        ),
                                      ),
                                    ),
                                    child: Row(
                                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                      children: <Widget>[
                                        SemanticHelper.container(
                                          testId: SemanticHelper.createTestId(
                                            SemanticTypes.dropdown,
                                            FusionTestKeys.instance.srccreationdropdownitemheader,
                                          ),
                                          child: FusionAppText(
                                            text: "Select source",
                                            style: Theme.of(
                                              context,
                                            ).textTheme.bodySmall?.copyWith(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                            ),
                                          ),
                                        ),
                                        SemanticHelper.button(
                                          testId: SemanticHelper.createTestId(SemanticTypes.button, "select_source_close"),
                                          child: InkWell(
                                            onTap: () {
                                              Navigator.of(context).pop();
                                            },
                                            child: Icon(
                                              Icons.close,
                                              size: 16,
                                              color: Theme.of(context).colorScheme.iconWhite,
                                            ),
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),

                                  /// Scrollable list of sources
                                  Flexible(
                                    child:
                                        widget.availableSources.isNotEmpty
                                            ? SingleChildScrollView(
                                              physics: const ClampingScrollPhysics(),
                                              child: Column(
                                                children:
                                                    widget.availableSources.asMap().entries.map<Widget>((MapEntry<int, Source> entry) {
                                                      final Source source = entry.value;
                                                      final int index = entry.key;
                                                      final bool isSelected = widget.selectedSources.any(
                                                        (SelectedSource selectedSource) => selectedSource.id == source.id,
                                                      );

                                                      return SemanticHelper.button(
                                                        testId: SemanticHelper.createTestId(SemanticTypes.button, "source_selection_checkbox_$index"),
                                                        child: InkWell(
                                                          onTap: () {
                                                            widget.onSourceChanged(source, !isSelected);
                                                            setPopupState(() {});
                                                            setState(() {});
                                                          },
                                                          child: Container(
                                                            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                            color: Colors.transparent,
                                                            child: Row(
                                                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                                              children: <Widget>[
                                                                /// Checkbox for selection
                                                                SizedBox(
                                                                  width: 14,
                                                                  height: 14,
                                                                  child: SemanticHelper.button(
                                                                    testId: SemanticHelper.createTestId(
                                                                      SemanticTypes.button,
                                                                      "sementic_source_selection_checkbox_$index",
                                                                    ),
                                                                    child: Checkbox(
                                                                      value: isSelected,
                                                                      onChanged: (bool? value) {
                                                                        widget.onSourceChanged(source, value ?? false);
                                                                        setPopupState(() {}); // Update popup state
                                                                        setState(() {}); // Update main widget state
                                                                      },

                                                                      activeColor: context.colorScheme.elevation4,
                                                                      materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                                      visualDensity: VisualDensity.compact,
                                                                      shape: const RoundedRectangleBorder(
                                                                        borderRadius: BorderRadius.zero,
                                                                        side: BorderSide(width: 0.5),
                                                                      ),

                                                                      side: WidgetStateBorderSide.resolveWith(
                                                                        (Set<WidgetState> states) {
                                                                          if (states.contains(WidgetState.selected)) {
                                                                            return BorderSide(
                                                                              color: context.colorScheme.primaryWhite,
                                                                              width: 1,
                                                                            );
                                                                          }
                                                                          return BorderSide(
                                                                            color: context.colorScheme.primaryWhite,
                                                                            width: 1,
                                                                          );
                                                                        },
                                                                      ),
                                                                    ),
                                                                  ),
                                                                ),
                                                                const SizedBox(width: 12),

                                                                /// Source name
                                                                Expanded(
                                                                  child: FusionAppText(
                                                                    text: source.name,
                                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                      fontWeight: FontWeight.w500,
                                                                      fontSize: 10,
                                                                      color: Theme.of(context).textTheme.bodySmall?.color,
                                                                    ),
                                                                  ),
                                                                ),
                                                              ],
                                                            ),
                                                          ),
                                                        ),
                                                      );
                                                    }).toList(),
                                              ),
                                            )
                                            : Padding(
                                              padding: const EdgeInsets.all(12.0),
                                              child: FusionAppText(
                                                text: "No Source Available",
                                                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                  fontSize: 10,
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
                    ),
                  ];
                },
                child: SemanticHelper.button(
                  testId: SemanticHelper.createTestId(SemanticTypes.button, "source_set_creation_widget"),
                  child: Container(
                    height: 29,
                    padding: const EdgeInsets.symmetric(horizontal: 8),
                    child: Row(
                      children: <Widget>[
                        Expanded(
                          child: SemanticHelper.container(
                            testId: SemanticHelper.createTestId(
                              SemanticTypes.container,
                              FusionTestKeys.instance.srcdropdowntxt,
                            ),
                            child: FusionAppText(
                              text:
                                  widget.selectedSources.isEmpty
                                      ? "Select Sources"
                                      : "${widget.selectedSources.length} source${widget.selectedSources.length > 1 ? 's' : ''} selected",
                              style: Theme.of(
                                context,
                              ).textTheme.bodySmall?.copyWith(
                                color:
                                    widget.selectedSources.isEmpty
                                        ? context.colorScheme.textSecondary
                                        : Theme.of(
                                          context,
                                        ).textTheme.bodySmall?.color,
                              ),
                            ),
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down,
                          size: 20,
                          color: context.colorScheme.iconWhite,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 12),

            Row(
              mainAxisAlignment: MainAxisAlignment.end,
              children: <Widget>[
                Flexible(
                  child: FusionOutlinedButton(
                    semanticsId: 'cancel',
                    width: double.infinity,
                    label: "Cancel",
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                    onTap: () {
                      widget.onCancel.call();
                    },
                    accessLabel: '',
                  ),
                ),
                const SizedBox(width: 8),
                Flexible(
                  child: FusionButton(
                    width: double.infinity,
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(
                      fontSize: 10,
                    ),

                    label: "Create",
                    isActive: widget.sourceSetNameController.text.trim().isNotEmpty && widget.selectedSources.length >= 2,
                    onTap: () {
                      widget.onAddSourceSet.call();
                    },
                    accessLabel: 'create',
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class SelectedSource {
  final String id;
  final String name;

  SelectedSource({required this.id, required this.name});
}
