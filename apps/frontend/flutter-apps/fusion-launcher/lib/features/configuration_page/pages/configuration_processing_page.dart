import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/search_bar_sources.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_lib/fusion_lib.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../../../core/widgets/configuration_widgets/drag_divider.dart';
import '../viewModel/sources_viewmodel/config_sources_state.dart';
import '../viewModel/sources_viewmodel/config_sources_viewmodel.dart';
import '../viewModel/source_sets_viewmodel/config_source_sets_state.dart';
import '../viewModel/source_sets_viewmodel/config_source_sets_viewmodel.dart';
import '../viewModel/zones_viewmodel/config_zones_state.dart';
import '../viewModel/zones_viewmodel/config_zones_viewmodel.dart';
import '../widgets/source_item.dart';
import '../widgets/source_set_item.dart';
import '../widgets/zone_card.dart';

class SelectedSource {
  final String id;
  final String name;

  SelectedSource({required this.id, required this.name});
}

class ConfigurationProcessingPage extends StatelessWidget {
  const ConfigurationProcessingPage({super.key});

  @override
  Widget build(BuildContext context) {
    final ProjectViewModel projectViewModel = serviceLocator<ProjectViewModel>();

    return MultiBlocProvider(
      providers: <BlocProvider<dynamic>>[
        BlocProvider<ConfigSourcesViewmodel>(
          create:
              (BuildContext context) => ConfigSourcesViewmodel(
                projectViewModel: projectViewModel,
              ),
        ),
        BlocProvider<ConfigSourceSetsViewmodel>(
          create:
              (BuildContext context) => ConfigSourceSetsViewmodel(
                projectViewModel: projectViewModel,
              ),
        ),
        BlocProvider<ConfigZonesViewmodel>(
          create:
              (BuildContext context) => ConfigZonesViewmodel(
                projectViewModel: projectViewModel,
              ),
        ),
      ],
      child: const _ConfigurationProcessingPageBody(),
    );
  }
}

class _ConfigurationProcessingPageBody extends StatefulWidget {
  const _ConfigurationProcessingPageBody();

  @override
  State<_ConfigurationProcessingPageBody> createState() => _ConfigurationProcessingPageBodyState();
}

class _ConfigurationProcessingPageBodyState extends State<_ConfigurationProcessingPageBody> {
  final TextEditingController searchController = TextEditingController();
  final TextEditingController _sourceSetNameController = TextEditingController();
  final List<SelectedSource> _selectedSources = <SelectedSource>[];
  final ScrollController _zonesScrollController = ScrollController();

  ConfigSourcesViewmodel get _sourcesViewmodel => context.read<ConfigSourcesViewmodel>();
  ConfigSourceSetsViewmodel get _sourceSetsViewmodel => context.read<ConfigSourceSetsViewmodel>();
  ConfigZonesViewmodel get _zonesViewmodel => context.read<ConfigZonesViewmodel>();

  /// Map to store GlobalKeys for each SourceSetItem
  final Map<String, GlobalKey> _sourceSetKeys = <String, GlobalKey<State<StatefulWidget>>>{};

  /// Map to store GlobalKeys for each ZoneCard
  final Map<String, GlobalKey> _zoneKeys = <String, GlobalKey<State<StatefulWidget>>>{};

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final double screenHeight = MediaQuery.of(context).size.height;
    _sourcesViewmodel.initializeSourcesHeight(screenHeight);
  }

  void _updateSourcesHeight(double delta) {
    final double screenHeight = MediaQuery.of(context).size.height;
    _sourcesViewmodel.updateSourcesHeight(delta, screenHeight);
  }

  @override
  void dispose() {
    searchController.dispose();
    _sourceSetNameController.dispose();
    _zonesScrollController.dispose();
    _sourceSetKeys.clear();
    _zoneKeys.clear();
    super.dispose();
  }

  /// Scroll expanded zone into view using GlobalKey for accurate positioning
  void _scrollZoneIntoView(String zoneId) {
    final GlobalKey? zoneKey = _zoneKeys[zoneId];
    if (zoneKey?.currentContext == null || !_zonesScrollController.hasClients) {
      return;
    }

    final RenderObject? renderObject = zoneKey!.currentContext!.findRenderObject();
    if (renderObject is! RenderBox) return;

    // Get the position of the zone relative to the scroll view
    final RenderObject? scrollViewRenderObject = _zonesScrollController.position.context.storageContext.findRenderObject();
    if (scrollViewRenderObject is! RenderBox) return;

    try {
      // Get zone position relative to the scrollable area
      final Offset zonePosition = renderObject.localToGlobal(Offset.zero, ancestor: scrollViewRenderObject);
      final double zoneTop = zonePosition.dy + _zonesScrollController.offset;

      // Get viewport dimensions
      final double viewportHeight = _zonesScrollController.position.viewportDimension;
      final double currentScrollOffset = _zonesScrollController.offset;

      // Calculate the expanded content height (estimated)
      final List<SubZone> subZones = _zonesViewmodel.getSubZonesForZone(parentZoneId: zoneId);
      final double expandedContentHeight = (subZones.length * 100.0).clamp(200.0, 400.0);
      final double totalZoneHeight = 32.0 + expandedContentHeight; // header + content

      // Check if zone fits in current viewport
      final double zoneBottom = zoneTop + totalZoneHeight;
      final double viewportTop = currentScrollOffset;
      final double viewportBottom = currentScrollOffset + viewportHeight;

      // Calculate optimal scroll position
      double targetScrollPosition = currentScrollOffset;

      if (zoneTop < viewportTop) {
        // Zone starts above viewport, scroll up to show zone at top with padding
        targetScrollPosition = zoneTop - 20; // 20px padding
      } else if (zoneBottom > viewportBottom) {
        // Zone extends below viewport, scroll down to fit the zone
        if (totalZoneHeight <= viewportHeight) {
          // Zone fits in viewport, position it optimally
          targetScrollPosition = zoneBottom - viewportHeight + 20; // 20px padding from bottom
        } else {
          // Zone is larger than viewport, just ensure the header is visible at top
          targetScrollPosition = zoneTop - 20;
        }
      }

      // Clamp to valid scroll range
      targetScrollPosition = targetScrollPosition.clamp(0.0, _zonesScrollController.position.maxScrollExtent);

      // Animate to target position if it's different from current
      if ((targetScrollPosition - currentScrollOffset).abs() > 5) {
        _zonesScrollController.animateTo(
          targetScrollPosition,
          duration: const Duration(milliseconds: 400),
          curve: Curves.easeInOut,
        );
      }
    } catch (e) {
      // Fallback to index-based scrolling if GlobalKey method fails
      final int zoneIndex = _zonesViewmodel.getZoneIndex(zoneId);
      if (zoneIndex != -1) {
        _scrollToZone(zoneIndex);
      }
    }
  }

  /// Fallback scroll method using zone index
  void _scrollToZone(int zoneIndex) {
    if (_zonesScrollController.hasClients) {
      // Calculate the position of the zone
      final double zoneHeaderHeight = 32.0; // Height of zone header
      final double estimatedPosition = zoneIndex * zoneHeaderHeight;

      // Add some padding and scroll to the estimated position
      _zonesScrollController.animateTo(
        (estimatedPosition - 50.0).clamp(0.0, _zonesScrollController.position.maxScrollExtent),
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<ProjectViewModel, ProjectViewModelState>(
      listener: (BuildContext context, ProjectViewModelState state) {
        /// Sync all cubits when ProjectViewModel state changes
        context.read<ConfigSourcesViewmodel>().syncWithProjectViewModel();
        context.read<ConfigSourceSetsViewmodel>().syncWithProjectViewModel();
        context.read<ConfigZonesViewmodel>().syncWithProjectViewModel();
      },
      child: Scaffold(
        backgroundColor: Theme.of(context).colorScheme.primaryBlack,
        body: LayoutBuilder(
          builder: (BuildContext context, BoxConstraints constraints) {
            final bool isWideScreen = constraints.maxWidth > 600;

            if (isWideScreen) {
              return Row(
                children: <Widget>[
                  SizedBox(width: constraints.maxWidth * 0.3, child: _buildInputPanel(context)),
                  const SizedBox(width: 4),
                  Expanded(child: _buildOutputPanel()),
                ],
              );
            } else {
              return Column(
                children: <Widget>[
                  Expanded(flex: 1, child: _buildInputPanel(context)),
                  Expanded(flex: 2, child: _buildOutputPanel()),
                ],
              );
            }
          },
        ),
      ),
    );
  }

  /// Build Input Panel
  Widget _buildInputPanel(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.elevation1,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
      ),
      child: Column(
        children: <Widget>[
          const SectionHeader(
            title: 'Sources',
            assetPath: 'assets/images/source_icon.png',
          ),

          /// Search bar with filters and sorting
          SearchBarSources(
            searchController: searchController,
            hasActiveFilters: () => false,
            onClearSearch: () {
              searchController.clear();
              _sourcesViewmodel.clearSearch();
            },
            onSearchChanged: (String value) {
              _sourcesViewmodel.filterSources(value);
            },
          ),

          /// Sources list with controlled height
          DragTarget<Source>(
            onWillAcceptWithDetails: (DragTargetDetails<Source> details) {
              /// Accept only if this source currently lives inside any source set.
              /// This prevents dropping a source back onto the same sources list when dragging from itself.
              return _sourcesViewmodel.shouldAcceptDropOnSources(details.data.id);
            },
            onLeave: (Source? data) {},
            onAcceptWithDetails: (DragTargetDetails<Source> details) {
              _sourcesViewmodel.handleDropOnSources(details.data);
              _sourceSetsViewmodel.syncWithProjectViewModel();
            },
            builder: (BuildContext context, List<Source?> candidateData, List<dynamic> rejectedData) {
              final bool isHovered = candidateData.isNotEmpty;
              return BlocBuilder<ConfigSourcesViewmodel, ConfigSourcesState>(
                builder: (BuildContext context, ConfigSourcesState state) {
                  return Container(
                    padding: const EdgeInsets.all(10),
                    height: state.sourcesHeight,
                    decoration: BoxDecoration(
                      color: isHovered ? Theme.of(context).colorScheme.primary.withOpacity(0.1) : Colors.transparent,
                      border:
                          isHovered
                              ? Border.all(
                                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
                                width: 2,
                              )
                              : Border.symmetric(
                                vertical: BorderSide(color: context.colorScheme.elevation2, width: 1),
                              ),
                    ),
                    child: Builder(
                      builder: (BuildContext context) {
                        final List<Source> filteredSources = state.filteredSources;

                        if (filteredSources.isEmpty) {
                          return Center(
                            child: FusionAppText(
                              text: state.searchQuery.isNotEmpty ? 'No search data for "${state.searchQuery}"' : 'No sources added yet',
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 12,
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          );
                        }
                        return ListView.separated(
                          itemCount: filteredSources.length,
                          separatorBuilder: (BuildContext context, int index) => const SizedBox(height: 4),
                          itemBuilder: (BuildContext context, int index) {
                            final Source source = filteredSources[index];
                            return Draggable<Source>(
                              data: source,
                              dragAnchorStrategy: pointerDragAnchorStrategy,
                              onDragStarted: () {
                                _sourcesViewmodel.startDrag(source.id);
                              },
                              onDraggableCanceled: (_, __) {
                                _sourcesViewmodel.endDrag();
                              },
                              onDragEnd: (_) {
                                _sourcesViewmodel.endDrag();
                              },
                              feedback: Material(
                                color: Colors.transparent,
                                child: Opacity(
                                  opacity: 0.8,
                                  child: Container(
                                    width: 220,
                                    decoration: BoxDecoration(
                                      color: context.colorScheme.primary.withAlpha(150),
                                      borderRadius: BorderRadius.circular(8),
                                    ),
                                    child: SourceItem(
                                      index: index,
                                      source: source,
                                      isDragging: true,
                                    ),
                                  ),
                                ),
                              ),
                              childWhenDragging: Opacity(
                                opacity: 0.5,
                                child: SourceItem(index: index, source: source, isDragging: true),
                              ),
                              child: SourceItem(
                                index: index,
                                source: source,
                                isDragging: state.draggingSourceId == source.id,
                              ),
                            );
                          },
                        );
                      },
                    ),
                  );
                },
              );
            },
          ),

          /// Draggable divider
          DragDivider(onDragUpdate: _updateSourcesHeight),

          SectionHeader(
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
                  icon: Icon(Icons.add_sharp, size: 16, color: context.colorScheme.primaryWhite),
                  onPressed: null,
                  padding: EdgeInsets.zero,
                  constraints: const BoxConstraints(),
                ),
              ),
            ),
          ),

          /// Source sets section takes remaining space
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
                            child: child,

                            // child: BlocProvider.value(value: _sourceSetsViewmodel, child: child),
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
                                key: sourceSetKey,
                                sourceSet: sourceSet,
                                isDragHovered: isHovered,
                                onUpdateSourceSet: (SourceSet updatedSourceSet) {
                                  _sourceSetsViewmodel.updateSourceSet(updatedSourceSet);
                                },
                                onUpdateSourcesInSourceSet: ({required String sourceSetId, required List<String> sourceIds}) {
                                  _sourceSetsViewmodel.updateSourcesInSourceSet(
                                    sourceSetId: sourceSetId,
                                    sourceIds: sourceIds,
                                  );
                                },
                                onSyncWithProjectViewModel: () {
                                  _sourcesViewmodel.syncWithProjectViewModel();
                                },
                                onDeleteSourceSet: (String sourceSetId) {
                                  _sourceSetsViewmodel.deleteSourceSet(sourceSetId);
                                },
                                onLinkSourceSet: ({required String sourceSetId}) {
                                  _sourceSetsViewmodel.linkSourceSet(sourceSetId: sourceSetId);
                                },
                                onUnlinkSourceSet: ({required String sourceSetId}) {
                                  _sourceSetsViewmodel.unlinkSourceSet(sourceSetId: sourceSetId);
                                },
                                canLinkSourceSet: ({required String sourceSetId}) {
                                  return _sourceSetsViewmodel.canLinkSourceSet(sourceSetId: sourceSetId);
                                },
                                getSourcesInSourceSet: ({required String sourceSetId}) {
                                  return _sourceSetsViewmodel.getSourcesInSourceSet(sourceSetId: sourceSetId);
                                },
                                getAllSources: () {
                                  return _sourceSetsViewmodel.getAllSources();
                                },
                                sourcesInSourceSet: _sourceSetsViewmodel.getSourcesInSourceSet(sourceSetId: sourceSet.id),
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

  /// Add source set to project view model
  void _addSourceSet(BuildContext popupContext) {
    _sourceSetsViewmodel.addSourceSet(
      name: _sourceSetNameController.text.trim(),
      sourceIds: _selectedSources.map((SelectedSource s) => s.id).toList(),
    );
    _sourcesViewmodel.syncWithProjectViewModel();

    /// Clear dialog and close popup
    _clearSourceSetDialog(pop: true, popContext: popupContext);
  }

  /// Clear source set dialog inputs
  void _clearSourceSetDialog({bool pop = false, BuildContext? popContext}) {
    _sourceSetNameController.clear();
    _selectedSources.clear();
    if (pop && popContext != null && Navigator.of(popContext).canPop()) {
      Navigator.of(popContext).pop();
    }
    setState(() {});
  }

  /// Build Output Panel
  Widget _buildOutputPanel() {
    return Container(
      decoration: BoxDecoration(
        color: context.colorScheme.primaryBlack,
        borderRadius: const BorderRadius.all(Radius.circular(12)),
        border: Border(
          left: BorderSide(color: context.colorScheme.elevation2, width: 1),
          right: BorderSide(color: context.colorScheme.elevation2, width: 1),
          bottom: BorderSide(color: context.colorScheme.elevation2, width: 1),
        ),
      ),
      child: Column(
        children: <Widget>[
          /// Zones Section
          const SectionHeader(
            title: 'Zones',
            assetPath: 'assets/images/zone_icon.png',
          ),

          /// Zones List
          Expanded(
            child: BlocBuilder<ConfigZonesViewmodel, ConfigZonesState>(
              builder: (BuildContext context, ConfigZonesState state) {
                return state.zones.isEmpty
                    ? Padding(
                      padding: EdgeInsets.only(top: MediaQuery.of(context).size.height * 0.3),
                      child: FusionAppText(
                        text: 'No zones added yet',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                          fontSize: 12,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    )
                    : SingleChildScrollView(
                      physics: const ClampingScrollPhysics(),
                      controller: _zonesScrollController,
                      child: ReorderableListView.builder(
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        buildDefaultDragHandles: false,
                        itemCount: state.zones.length,
                        onReorder: (int oldIndex, int newIndex) {
                          _zonesViewmodel.reorderZones(oldIndex, newIndex);
                        },
                        itemBuilder: (BuildContext context, int index) {
                          final Zone zoneData = state.zones[index];

                          // Ensure we have a GlobalKey for each zone
                          _zoneKeys[zoneData.id] ??= GlobalKey();
                          final GlobalKey zoneKey = _zoneKeys[zoneData.id]!;

                          return ReorderableDragStartListener(
                            key: ValueKey<String>(zoneData.id),
                            index: index,
                            child: ZoneCard(
                              key: zoneKey,
                              zoneId: zoneData.id,
                              zoneName: zoneData.name,
                              bgColor: zoneData.color,
                              zoneData: zoneData,
                              onExpansionChanged: (bool isExpanded) {
                                if (isExpanded) {
                                  // Small delay to allow the widget to expand first
                                  Future<void>.delayed(const Duration(milliseconds: 100), () {
                                    _scrollZoneIntoView(zoneData.id);
                                  });
                                }
                              },
                            ),
                          );
                        },
                      ),
                    );
              },
            ),
          ),
        ],
      ),
    );
  }
}

/// Widget for creating a new source set
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
            FusionAppText(
              text: 'Select sources',
              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                fontSize: 12,
                fontWeight: FontWeight.w500,
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
                                        FusionAppText(
                                          text: "Select source",
                                          style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                            fontSize: 12,
                                            fontWeight: FontWeight.w600,
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
                                                    widget.availableSources.map<Widget>((Source source) {
                                                      final bool isSelected = widget.selectedSources.any(
                                                        (SelectedSource selectedSource) => selectedSource.id == source.id,
                                                      );

                                                      final int index = widget.selectedSources.indexWhere(
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
                          child: FusionAppText(
                            text:
                                widget.selectedSources.isEmpty
                                    ? "Select Sources"
                                    : "${widget.selectedSources.length} source${widget.selectedSources.length > 1 ? 's' : ''} selected",
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              color: widget.selectedSources.isEmpty ? context.colorScheme.textSecondary : Theme.of(context).textTheme.bodySmall?.color,
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
                    width: double.infinity,
                    label: "Cancel",
                    textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10),
                    onTap: () {
                      widget.onCancel.call();
                    },
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
