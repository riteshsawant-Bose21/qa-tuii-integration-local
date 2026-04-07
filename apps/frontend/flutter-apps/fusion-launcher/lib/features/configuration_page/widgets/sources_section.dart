import 'package:flutter/cupertino.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/search_bar_sources.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/section_header.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/source_item.dart';
import 'package:fusion_lib/constants/semantics/features/configuration/processing/config_sources.dart';
import 'package:fusion_lib/constants/semantics/test_keys.dart';
import 'package:fusion_lib/fusion_lib.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';

import '../../configuration/presentation/viewmodel/project_view_model.dart';
import '../viewModel/source_sets_viewmodel/config_source_sets_viewmodel.dart';
import '../viewModel/sources_viewmodel/config_sources_state.dart';
import '../viewModel/sources_viewmodel/config_sources_viewmodel.dart';

class SourcesSection extends StatefulWidget {
  const SourcesSection({super.key});

  @override
  State<SourcesSection> createState() => _SourcesSectionState();
}

class _SourcesSectionState extends State<SourcesSection> {
  final TextEditingController searchController = TextEditingController();
  ConfigSourcesViewmodel get _sourcesViewmodel => context.read<ConfigSourcesViewmodel>();
  ConfigSourceSetsViewmodel get _sourceSetsViewmodel => context.read<ConfigSourceSetsViewmodel>();
  ProjectViewModel get _projectViewModel => context.read<ProjectViewModel>();
  bool _isSearching = false;

  @override
  Widget build(BuildContext context) {
    return SemanticHelper.container(
      testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.sourcesec),
      child: Column(
        children: <Widget>[
          SectionHeader(
            semanticLabel: FusionTestKeys.instance.sourcehead,
            assetPath: 'assets/images/source_icon.png',

            title: 'Sources',
            trailing: GestureDetector(
              onTap: () {
                setState(() {
                  _isSearching = !_isSearching;
                });

                if (!_isSearching) {
                  searchController.clear();
                  _sourcesViewmodel.clearSearch();
                }
              },
              child: FusionIcon.icon(
                size: 16,
                _isSearching ? CupertinoIcons.clear : CupertinoIcons.search,
              ),
            ),
          ),

          AnimatedSize(
            duration: const Duration(milliseconds: 250),
            curve: Curves.easeInOut,
            child:
                _isSearching
                    ? SearchBarSources(
                      searchController: searchController,
                      hasActiveFilters: () => false,
                      onClearSearch: () {
                        searchController.clear();
                        _sourcesViewmodel.clearSearch();
                      },
                      onSearchChanged: (String value) {
                        _sourcesViewmodel.filterSources(value);
                      },
                    )
                    : const SizedBox(),
          ),

          /// Search bar with filters and sorting
          // SearchBarSources(
          //   searchController: searchController,
          //   hasActiveFilters: () => false,
          //   onClearSearch: () {
          //     searchController.clear();
          //     _sourcesViewmodel.clearSearch();
          //   },
          //   onSearchChanged: (String value) {
          //     _sourcesViewmodel.filterSources(value);
          //   },
          // ),

          /// Sources list with controlled height
          SemanticHelper.container(
            testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.sourcedata),
            child: DragTarget<Source>(
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
                      padding: const EdgeInsets.all(16),
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
                            return SemanticHelper.container(
                              testId: SemanticHelper.createTestId(SemanticTypes.container, FusionTestKeys.instance.sourceempty),
                              child: Center(
                                child: FusionAppText(
                                  semanticId: FusionTestKeys.instance.sourcedescription,
                                  text: state.searchQuery.isNotEmpty ? 'No search data for "${state.searchQuery}"' : 'No sources added yet',
                                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                  ),
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
                                        isInControlMode: _projectViewModel.isInControlMode,
                                      ),
                                    ),
                                  ),
                                ),
                                childWhenDragging: Opacity(
                                  opacity: 0.5,
                                  child: SourceItem(
                                    index: index,
                                    source: source,
                                    isDragging: true,
                                    isInControlMode: _projectViewModel.isInControlMode,
                                  ),
                                ),
                                child: SourceItem(
                                  semanticId: 'sources_section',
                                  index: index,
                                  source: source,
                                  isInControlMode: _projectViewModel.isInControlMode,
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
          ),
        ],
      ),
    );
  }
}
