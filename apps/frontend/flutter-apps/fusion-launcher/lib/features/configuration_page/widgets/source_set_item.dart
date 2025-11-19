import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:fusion_launcher/features/configuration_page/widgets/source_item.dart';
import 'package:fusion_lib/fusion_theme/app_theme.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_button.dart';
import 'package:fusion_lib/fusion_widgets/buttons/fusion_outlined_button.dart';
import 'package:fusion_lib/fusion_widgets/form_fields/fusion_text_field.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_image.dart';
import 'package:fusion_lib/fusion_widgets/others/fusion_toast.dart';
import 'package:fusion_lib/fusion_widgets/text_views/fusion_app_text.dart';
import 'package:fusion_lib/models/project_entities/source_model.dart';
import 'package:fusion_lib/models/project_entities/source_set_model.dart';

import '../../../core/constants/assets_constants.dart';
import '../../../core/service_locator.dart';
import '../../configuration/presentation/viewmodel/project_view_model.dart';

class SelectedSource {
  final String id;
  final String name;

  SelectedSource({required this.id, required this.name});
}

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
  final TextEditingController _sourceSetNameController = TextEditingController();
  final List<SelectedSource> _selectedSources = <SelectedSource>[];
  bool _isHovered = false;

  /// Track drag state for visual feedback
  String? _draggingSourceId;

  final GlobalKey _addSourceIconKey = GlobalKey(); // anchor for popup

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

  /// Add source set to project view model
  void _editSourceSet() {
    /// create source set and add to project view model
    final SourceSet newSourceSet = widget.sourceSet.copyWith(
      name: _sourceSetNameController.text.trim(),
    );

    /// Add selected sources to the new source set
    _projectViewModel.updateSourceSet(sourceSet: newSourceSet);

    _projectViewModel.updateSourcesInSourceSet(
      sourceSetId: newSourceSet.id,
      sourceIds: _selectedSources.map((SelectedSource s) => s.id).toList(),
    );

    /// Expand source set to show updated sources
    _isSourcesSetExpanded.value = true;

    /// Show success toast
    FusionToast.success(
      context,
      message: "Source set updated successfully",
    );

    /// Clear dialog and close popup
    _clearSourceSetDialog();
  }

  /// Clear source set dialog inputs
  void _clearSourceSetDialog() {
    _sourceSetNameController.clear();
    _selectedSources.clear();
    Navigator.of(context).pop();
    setState(() {});
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

                          Visibility(
                            visible: _projectViewModel.canLinkSourceSet(sourceSetId: widget.sourceSet.id),
                            child: BlocBuilder<ProjectViewModel, ProjectViewModelState>(
                              builder: (BuildContext context, ProjectViewModelState state) {
                                return GestureDetector(
                                  onTap: () {
                                    if (widget.sourceSet.isLinked) {
                                      _projectViewModel.unlinkSourceSet(sourceSetId: widget.sourceSet.id);
                                      FusionToast.success(
                                        context,
                                        message: "Source set unlinked successfully",
                                      );
                                    } else {
                                      _projectViewModel.linkSourceSet(sourceSetId: widget.sourceSet.id);
                                      FusionToast.success(
                                        context,
                                        message: "Source set linked successfully",
                                      );
                                    }
                                  },
                                  child: FusionImage.asset(
                                    widget.sourceSet.isLinked ? Assets.linkIcon : Assets.unLinkIcon,
                                    width: 22,
                                    height: 22,
                                    fit: BoxFit.contain,
                                  ),
                                );
                              },
                            ),
                          ),

                          const SizedBox(width: 8),
                          const FusionImage.asset(
                            Assets.processingBlocksIcon,
                            width: 18,
                            height: 12,
                            fit: BoxFit.contain,
                          ),
                          const SizedBox(width: 8),
                          GestureDetector(
                            key: _addSourceIconKey,
                            onTap: _showEditSourceSetPopup,
                            child: const FusionImage.asset(
                              Assets.addSourceIcon,
                              width: 22,
                              height: 22,
                              fit: BoxFit.contain,
                            ),
                          ),
                          GestureDetector(
                            onTap: _confirmDeleteSourceSet,
                            child: const FusionImage.asset(
                              Assets.deleteIcon,
                              width: 17,
                              height: 17,
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

  /// Show popup to edit source set
  Future<void> _showEditSourceSetPopup() async {
    /// Pre-fill name
    if (_sourceSetNameController.text.isEmpty) {
      _sourceSetNameController.text = widget.sourceSet.name;
    }

    /// Pre-select sources already in this source set
    final List<Source> currentSourcesInSet = _projectViewModel.getSourcesInSourceSet(sourceSetId: widget.sourceSet.id);
    for (final Source s in currentSourcesInSet) {
      final bool alreadyAdded = _selectedSources.any((SelectedSource sel) => sel.id == s.id);
      if (!alreadyAdded) {
        _selectedSources.add(SelectedSource(id: s.id, name: s.name));
      }
    }

    final RenderBox button = _addSourceIconKey.currentContext!.findRenderObject() as RenderBox;
    final RenderBox overlay = Overlay.of(context).context.findRenderObject() as RenderBox;
    final Offset offset = button.localToGlobal(Offset.zero, ancestor: overlay);
    final RelativeRect position = RelativeRect.fromLTRB(
      offset.dx,
      offset.dy + button.size.height,
      overlay.size.width - offset.dx - button.size.width,
      overlay.size.height - offset.dy - button.size.height,
    );
    await showMenu<dynamic>(
      context: context,
      position: position,
      color: Theme.of(context).colorScheme.white,
      constraints: const BoxConstraints(maxHeight: 500, maxWidth: 250),
      items: <PopupMenuEntry<dynamic>>[
        PopupMenuItem<dynamic>(
          enabled: false,
          padding: EdgeInsets.zero,
          child: SizedBox(
            width: 250,
            child: StatefulBuilder(
              builder: (BuildContext context, StateSetter setMenuState) {
                return SingleChildScrollView(
                  child: _SourceSetCreationWidget(
                    sourceSetNameController: _sourceSetNameController,
                    availableSources: _projectViewModel.sources,
                    selectedSources: _selectedSources,
                    onAddSourceSet: () {
                      _editSourceSet();
                    },
                    onCancel: () {
                      _clearSourceSetDialog();
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
      ],
    );

    setState(() {}); // refresh after popup closes if needed
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

  Future<void> _confirmDeleteSourceSet() async {
    await showDialog<void>(
      context: context,
      barrierDismissible: true,
      builder: (BuildContext ctx) {
        final ColorScheme scheme = Theme.of(ctx).colorScheme;
        return Dialog(
          backgroundColor: scheme.white,
          insetPadding: const EdgeInsets.symmetric(horizontal: 40, vertical: 24),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 50),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: <Widget>[
                  FusionAppText(
                    text: "Delete source set?",
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 12),
                  FusionAppText(
                    text: "This will remove '${widget.sourceSet.name}' from the source set. Sources will be moved to sources section.",
                    style: Theme.of(ctx).textTheme.bodySmall?.copyWith(fontSize: 11),
                  ),
                  const SizedBox(height: 20),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: <Widget>[
                      SizedBox(
                        width: 90,
                        child: FusionOutlinedButton(
                          label: "Cancel",
                          textStyle: Theme.of(ctx).textTheme.labelLarge?.copyWith(fontSize: 11),
                          onTap: () => Navigator.of(ctx).pop(),
                        ),
                      ),
                      const SizedBox(width: 8),
                      SizedBox(
                        width: 90,
                        child: FusionButton(
                          label: "Delete",
                          textStyle: Theme.of(ctx).textTheme.labelLarge?.copyWith(
                            fontSize: 11,
                            color: scheme.fusionButtonTextColor,
                          ),
                          isActive: true,
                          onTap: () {
                            Navigator.of(ctx).pop();
                            _projectViewModel.removeSourceSet(sourceSetId: widget.sourceSet.id);
                          },
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
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
    return Container(
      color: Theme.of(context).colorScheme.white,
      width: 250,
      padding: const EdgeInsets.all(12),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.start,
        children: <Widget>[
          FusionAppText(
            text: "Edit source set",
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
            decoration: FusionInputDecoration.fusionDense(
              colorScheme: Theme.of(context).colorScheme,
              hintText: 'Enter source set name',
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
              border: Border.all(color: Colors.grey[300]!),
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
              color: Theme.of(context).colorScheme.white,
              offset: const Offset(0, 35),
              itemBuilder: (BuildContext context) {
                return <PopupMenuEntry<String>>[
                  PopupMenuItem<String>(
                    enabled: false,
                    padding: EdgeInsets.zero,
                    child: StatefulBuilder(
                      builder: (BuildContext context, StateSetter setPopupState) {
                        return Container(
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
                                    bottom: BorderSide(color: Colors.grey[300]!),
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
                                    InkWell(
                                      onTap: () {
                                        Navigator.of(context).pop();
                                      },
                                      child: Icon(
                                        Icons.close,
                                        size: 16,
                                        color: Theme.of(context).colorScheme.fusionTextViewColor,
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
                                            children: <Widget>[
                                              /// Selected sources at the top (if any)
                                              if (widget.selectedSources.isNotEmpty) ...<Widget>[
                                                Container(
                                                  width: double.infinity,
                                                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                                                  color: Theme.of(context).colorScheme.greyLight.withAlpha(40),
                                                  child: FusionAppText(
                                                    text: "Selected (${widget.selectedSources.length})",
                                                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                      fontSize: 10,
                                                      fontWeight: FontWeight.w600,
                                                      color: Theme.of(context).colorScheme.fusionTextViewColor,
                                                    ),
                                                  ),
                                                ),

                                                /// List of selected sources (interactive to unselect)
                                                ...widget.selectedSources.map((SelectedSource sel) {
                                                  final Source source = widget.availableSources.firstWhere(
                                                    (Source s) => s.id == sel.id,
                                                    // orElse: () => Source(id: sel.id, name: sel.name),
                                                  );
                                                  return InkWell(
                                                    onTap: () {
                                                      widget.onSourceChanged(source!, false);
                                                      setPopupState(() {});
                                                      setState(() {});
                                                    },
                                                    child: Container(
                                                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 10),
                                                      child: Row(
                                                        children: <Widget>[
                                                          SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: Checkbox(
                                                              value: true,
                                                              onChanged: (bool? value) {
                                                                widget.onSourceChanged(source!, false);
                                                                setPopupState(() {});
                                                                setState(() {});
                                                              },
                                                              activeColor: Theme.of(context).colorScheme.greyDark,
                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              visualDensity: VisualDensity.compact,
                                                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: FusionAppText(
                                                              text: source?.name ?? sel.name,
                                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                fontWeight: FontWeight.w500,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }),
                                                const Divider(height: 8, thickness: 0.5),
                                              ],

                                              /// Remaining (unselected) sources
                                              ...(() {
                                                final List<Source> remaining =
                                                    widget.availableSources
                                                        .where(
                                                          (Source s) => !widget.selectedSources.any((SelectedSource sel) => sel.id == s.id),
                                                        )
                                                        .toList();
                                                return remaining.map<Widget>((Source source) {
                                                  final bool isSelected = widget.selectedSources.any((SelectedSource sel) => sel.id == source.id);
                                                  return InkWell(
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
                                                          SizedBox(
                                                            width: 14,
                                                            height: 14,
                                                            child: Checkbox(
                                                              value: isSelected,
                                                              onChanged: (bool? value) {
                                                                widget.onSourceChanged(source, value ?? false);
                                                                setPopupState(() {});
                                                                setState(() {});
                                                              },
                                                              activeColor: Theme.of(context).colorScheme.greyDark,
                                                              materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                                              visualDensity: VisualDensity.compact,
                                                              shape: const RoundedRectangleBorder(borderRadius: BorderRadius.zero),
                                                            ),
                                                          ),
                                                          const SizedBox(width: 12),
                                                          Expanded(
                                                            child: FusionAppText(
                                                              text: source.name,
                                                              style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                                                fontWeight: FontWeight.w500,
                                                                fontSize: 10,
                                                              ),
                                                            ),
                                                          ),
                                                        ],
                                                      ),
                                                    ),
                                                  );
                                                }).toList();
                                              })(),
                                            ],
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
                        );
                      },
                    ),
                  ),
                ];
              },
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
                          color: widget.selectedSources.isEmpty ? Theme.of(context).colorScheme.greyDark : Theme.of(context).textTheme.bodySmall?.color,
                        ),
                      ),
                    ),
                    Icon(
                      Icons.keyboard_arrow_down,
                      size: 20,
                      color: Theme.of(context).colorScheme.greyDark,
                    ),
                  ],
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
                  textStyle: Theme.of(context).textTheme.labelLarge?.copyWith(fontSize: 10, color: Theme.of(context).colorScheme.fusionButtonTextColor),

                  label: "Edit",
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
    );
  }
}
