import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/source_item.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';
import 'package:fusion_lib/models/project_entities/source_set_model.dart';

import '../../../core/constants/assets_constants.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

class SourceSetItem extends StatefulWidget {
  final SourceSet sourceSet;
  final bool isDragHovered;
  final VoidCallback? onSourceDropped;

  const SourceSetItem({required this.sourceSet, this.isDragHovered = false, this.onSourceDropped, super.key});

  @override
  State<SourceSetItem> createState() => _SourceSetItemState();
}

class _SourceSetItemState extends State<SourceSetItem> {
  late ValueNotifier<bool> _isSourcesSetExpanded;
  ProjectViewModel get _projectViewModel => serviceLocator<ProjectViewModel>();
  bool _isHovered = false;

  /// Track drag state for visual feedback
  String? _draggingSourceId;

  @override
  void initState() {
    super.initState();
    _isSourcesSetExpanded = ValueNotifier<bool>(false);
  }

  @override
  void dispose() {
    _isSourcesSetExpanded.dispose();
    super.dispose();
  }

  /// Add method to expand source set externally
  void expandSourceSet() {
    if (!_isSourcesSetExpanded.value) {
      _isSourcesSetExpanded.value = true;
    }
  }

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<bool>(
      valueListenable: _isSourcesSetExpanded,
      builder: (BuildContext context, bool subZoneExpanded, Widget? child) {
        return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
          builder: (BuildContext context, ProjectViewModelState state) {
            return Column(
              children: <Widget>[
                MouseRegion(
                  onEnter: (_) => setState(() => _isHovered = true),
                  onExit: (_) => setState(() => _isHovered = false),

                  child: GestureDetector(
                    onTap: () {
                      /// Toggle expand/collapse
                      _isSourcesSetExpanded.value = !_isSourcesSetExpanded.value;
                    },
                    child: Container(
                      margin: const EdgeInsets.only(top: 8),
                      padding: const EdgeInsets.only(left: 12, right: 12),
                      height: 36,
                      decoration: BoxDecoration(
                        border: Border.all(
                          color: widget.isDragHovered ? Theme.of(context).colorScheme.primary : Colors.transparent,
                          width: 1.0,
                        ),
                        color:
                            widget.isDragHovered
                                ? Theme.of(context).colorScheme.primary.withOpacity(0.1)
                                : (_isHovered ? Theme.of(context).colorScheme.grey.withAlpha(200) : Theme.of(context).colorScheme.greyLight),
                      ),
                      child: Row(
                        children: <Widget>[
                          /// Expand/collapse icon
                          Icon(
                            _isSourcesSetExpanded.value ? Icons.arrow_drop_up_rounded : Icons.arrow_drop_down_rounded,
                            color: Theme.of(context).colorScheme.fusionTextViewColor.withAlpha(90),
                          ),
                          const SizedBox(width: 4),

                          /// Source set name
                          Expanded(
                            child: FusionAppText(
                              text: widget.sourceSet.name,
                              maxLine: 1,
                              style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),

                          const FusionImage.asset(
                            Assets.linkIcon,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),

                          const SizedBox(width: 8),
                          const FusionImage.asset(
                            Assets.processingBlocksIcon,
                            width: 18,
                            height: 12,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          const FusionImage.asset(
                            Assets.addSourceIcon,
                            width: 22,
                            height: 22,
                            fit: BoxFit.contain,
                          ),
                          // delete icon
                          const SizedBox(width: 8),
                          GestureDetector(
                            onTap: () {
                              _projectViewModel.removeSourceSet(sourceSetId: widget.sourceSet.id);
                            },
                            child: const FusionImage.asset(
                              Assets.trashIcon,
                              width: 20,
                              height: 20,
                              fit: BoxFit.contain,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                if (subZoneExpanded) _buildSourcesList(),
              ],
            );
          },
        );
      },
    );
  }

  /// Build the list of sources within the source set
  Widget _buildSourcesList() {
    return BlocBuilder<ProjectViewModel, ProjectViewModelState>(
      builder: (BuildContext context, ProjectViewModelState state) {
        final List<Source> sourceList = _projectViewModel.getSourcesInSourceSet(sourceSetId: widget.sourceSet.id);
        return Container(
          color: Theme.of(context).colorScheme.greyLight.withAlpha(50),
          child: ReorderableListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            buildDefaultDragHandles: false,
            itemCount: sourceList.length,
            onReorder: (int oldIndex, int newIndex) {},
            itemBuilder: (BuildContext context, int index) {
              final Source sourceData = sourceList[index];
              return Draggable<Source>(
                data: sourceData,
                key: ValueKey<String>(sourceList[index].id),
                dragAnchorStrategy: pointerDragAnchorStrategy,
                onDragStarted: () {
                  setState(() {
                    _draggingSourceId = sourceData.id;
                  });
                },
                onDraggableCanceled: (_, __) {
                  setState(() {
                    _draggingSourceId = null;
                  });
                },
                onDragEnd: (_) {
                  setState(() {
                    _draggingSourceId = null;
                  });
                },
                feedback: Material(
                  color: Colors.transparent,
                  child: Opacity(
                    opacity: 0.8,
                    child: Container(color: context.colorScheme.white, width: 220, child: SourceItem(source: sourceData, isDragging: true)),
                  ),
                ),
                childWhenDragging: Opacity(
                  opacity: 0.5,
                  child: SourceItem(source: sourceData, isDragging: true),
                ),
                child: SourceItem(source: sourceData, isDragging: _draggingSourceId == sourceData.id),
              );
            },
          ),
        );
      },
    );
  }
}
